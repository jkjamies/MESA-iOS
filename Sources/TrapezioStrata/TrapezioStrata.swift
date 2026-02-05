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

// MARK: - StrataException

/// Base error type for all Strata business logic failures
public protocol StrataException: Error {
    var message: String { get }
}

/// Default implementation for StrataException
extension StrataException {
    public var localizedDescription: String {
        return message
    }
}

// MARK: - StrataResult

/// A discriminated union that encapsulates a successful outcome with a value of type T
/// or a failure with a StrataException.
public enum StrataResult<T> {
    case success(T)
    case failure(any StrataException)
    
    public func getOrNull() -> T? {
        switch self {
        case .success(let data): return data
        case .failure: return nil
        }
    }
    
    @discardableResult
    public func onSuccess(_ action: (T) -> Void) -> StrataResult<T> {
        if case .success(let data) = self {
            action(data)
        }
        return self
    }
    
    @discardableResult
    public func onFailure(_ action: (any StrataException) -> Void) -> StrataResult<T> {
        if case .failure(let error) = self {
            action(error)
        }
        return self
    }
}

// MARK: - StrataInteractor

/// Base class for one-shot business operations.
// MARK: - StrataInteractor

/// Base protocol for one-shot business operations.
public protocol StrataInteractor {
    associatedtype P
    associatedtype T
    
    /// Executes the interactor logic.
    func execute(params: P) async -> StrataResult<T>
}

extension StrataInteractor {
    /// Helper to bridge throws to StrataResult
    public func executeCatching(params: P, block: (P) async throws -> T) async -> StrataResult<T> {
        return await strataRunCatching {
            try await block(params)
        }
    }
}

// MARK: - Helper Functions

/// Wraps an async block in a StrataResult, catching any errors and wrapping them if necessary.
/// Note: Ideally errors are already StrataExceptions.
public func strataRunCatching<T>(_ block: () async throws -> T) async -> StrataResult<T> {
    do {
        let result = try await block()
        return .success(result)
    } catch let error as any StrataException {
        return .failure(error)
    } catch {
        // Fallback wrapper
        return .failure(GenericStrataException(message: error.localizedDescription))
    }
}

private struct GenericStrataException: StrataException {
    let message: String
}

/// Helper to launch a Task on the MainActor, ensuring safe UI updates.
@discardableResult
public func strataLaunch(
    priority: TaskPriority? = nil,
    operation: @escaping @MainActor @Sendable () async -> Void
) -> Task<Void, Never> {
    return Task(priority: priority) { @MainActor in
        await operation()
    }
}

/// Helper to collect an AsyncStream on the MainActor.
/// Matches `strataLaunch` paradigm for stream observation.
@discardableResult
public func strataCollect<T: Sendable>(
    _ stream: AsyncStream<T>,
    priority: TaskPriority? = nil,
    action: @escaping @MainActor (T) -> Void
) -> Task<Void, Never> {
    return Task(priority: priority) { @MainActor in
        for await value in stream {
            action(value)
        }
    }
}
