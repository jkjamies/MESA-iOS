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
    
    /// Executes the interactor, automatically managing `inProgress` state.
    public final func execute(params: P) async -> StrataResult<T> {
        setInProgress(true)
        defer { setInProgress(false) }
        return await doWork(params: params)
    }
    
    /// Helper to bridge throws to StrataResult in doWork implementations.
    public func executeCatching(params: P, block: (P) async throws -> T) async -> StrataResult<T> {
        return await strataRunCatching {
            try await block(params)
        }
    }
}

// MARK: - Helper Functions

/// Wraps an async block in a StrataResult, catching any errors.
public func strataRunCatching<T>(_ block: () async throws -> T) async -> StrataResult<T> {
    do {
        let result = try await block()
        return .success(result)
    } catch let error as any StrataException {
        return .failure(error)
    } catch {
        return .failure(GenericStrataException(message: error.localizedDescription))
    }
}

private struct GenericStrataException: StrataException {
    let message: String
}
