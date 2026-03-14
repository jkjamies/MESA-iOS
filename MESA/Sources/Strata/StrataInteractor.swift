/*
 * Copyright 2026 Jason Jamieson
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
import os

/// Default timeout duration for `StrataInteractor.execute` (5 minutes).
public let strataInteractorDefaultTimeout: TimeInterval = 300

// MARK: - StrataInteractor

/// Base class for one-shot business operations with built-in loading state.
/// Subclasses override `doWork(params:)` to implement business logic.
/// The `inProgress` state is automatically managed during execution.
open class StrataInteractor<P: Sendable, T: Sendable>: @unchecked Sendable {
    
    // MARK: - inProgress State
    
    private let _inProgress = OSAllocatedUnfairLock<Bool>(initialState: false)
    
    /// Current loading state (thread-safe).
    public var inProgress: Bool {
        _inProgress.withLock { $0 }
    }
    
    private var inProgressContinuation: AsyncStream<Bool>.Continuation?
    
    /// Stream for observing loading state changes.
    ///
    /// Emits the current value immediately upon subscription, then emits on every
    /// ``execute(params:)`` start/finish. Only one stream is created per interactor instance.
    ///
    /// - Important: `AsyncStream` is single-consumer. Only one `for await` loop should iterate
    ///   this stream. A second consumer on the same stream will receive no values. If you need
    ///   multiple observers, collect this stream once and fan out from the reducer.
    public private(set) lazy var inProgressStream: AsyncStream<Bool> = {
        AsyncStream { [weak self] continuation in
            self?.inProgressContinuation = continuation
            // Emit initial state
            continuation.yield(self?.inProgress ?? false)
            continuation.onTermination = { [weak self] _ in
                self?.inProgressContinuation = nil
            }
        }
    }()
    
    private func setInProgress(_ value: Bool) {
        _inProgress.withLock { $0 = value }
        inProgressContinuation?.yield(value)
    }
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Execution
    
    /// Override this method to implement business logic.
    /// Do NOT call this directly — use `execute(params:)`.
    open func doWork(params: P) async -> StrataResult<T> {
        fatalError("doWork(params:) must be overridden")
    }
    
    /// Default timeout for interactor execution (5 minutes).
    public static var defaultTimeout: TimeInterval { strataInteractorDefaultTimeout }

    /// Executes the interactor, automatically managing `inProgress` state.
    ///
    /// - Parameters:
    ///   - params: The input parameters.
    ///   - timeout: Maximum execution time. Defaults to ``defaultTimeout`` (5 minutes).
    /// - Returns: A `StrataResult` containing the result or a timeout/execution failure.
    public final func execute(
        params: P,
        timeout: TimeInterval = strataInteractorDefaultTimeout
    ) async -> StrataResult<T> {
        setInProgress(true)
        defer { setInProgress(false) }

        do {
            return try await withThrowingTaskGroup(of: StrataResult<T>?.self) { group in
                group.addTask {
                    await self.doWork(params: params)
                }
                group.addTask {
                    try await Task.sleep(for: .seconds(timeout))
                    return nil
                }

                for try await result in group {
                    group.cancelAll()
                    if let result = result {
                        return result
                    } else {
                        return .failure(StrataTimeoutException(duration: timeout))
                    }
                }
                // Unreachable with two tasks — the loop always executes and
                // returns above. Required by the compiler for exhaustive coverage.
                return .failure(StrataTimeoutException(duration: timeout))
            }
        } catch is CancellationError {
            return .failure(StrataCancellationException())
        } catch {
            return .failure(StrataExecutionException(error: error))
        }
    }
    
    /// Helper to bridge throws to StrataResult in doWork implementations.
    ///
    /// Delegates to ``strataRunCatching(_:)`` so that `CancellationError` is mapped to
    /// `StrataCancellationException`, `StrataException` is preserved, and all other errors
    /// are wrapped in `StrataExecutionException`.
    public func executeCatching(params: P, block: (P) async throws -> T) async -> StrataResult<T> {
        await strataRunCatching { try await block(params) }
    }
}

// MARK: - Helper Functions

/// Wraps an async block in a `StrataResult`, catching any errors.
///
/// `CancellationError` is mapped to `.failure(StrataCancellationException)` so that
/// cancellation is represented uniformly inside `StrataResult` without throwing.
public func strataRunCatching<T>(_ block: () async throws -> T) async -> StrataResult<T> {
    do {
        let result = try await block()
        return .success(result)
    } catch is CancellationError {
        return .failure(StrataCancellationException())
    } catch let error as any StrataException {
        return .failure(error)
    } catch {
        return .failure(StrataExecutionException(error: error))
    }
}

/// Wraps an unexpected (non-`StrataException`) error caught during interactor execution.
///
/// Preserves the original error for inspection while conforming to `StrataException`
/// for uniform error handling in `StrataResult` chains.
///
/// `@unchecked Sendable` because `underlyingError` is `Error` (not `Sendable`).
/// Safe: both stored properties are immutable (`let`), so no cross-isolation mutation is possible.
public struct StrataExecutionException: StrataException, @unchecked Sendable {
    public let message: String
    public let underlyingError: Error

    public init(error: Error) {
        self.message = error.localizedDescription
        self.underlyingError = error
    }
}
