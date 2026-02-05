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
