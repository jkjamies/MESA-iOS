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

    /// Returns a new `StrataResult` with the encapsulated value transformed by `transform`
    /// if this instance represents success, or the original failure unchanged.
    public func map<R>(_ transform: (T) -> R) -> StrataResult<R> {
        switch self {
        case .success(let data): return .success(transform(data))
        case .failure(let error): return .failure(error)
        }
    }

    /// Returns the result of `onSuccess` for the encapsulated value if success,
    /// or the result of `onFailure` for the encapsulated error if failure.
    public func fold<R>(onSuccess: (T) -> R, onFailure: (any StrataException) -> R) -> R {
        switch self {
        case .success(let data): return onSuccess(data)
        case .failure(let error): return onFailure(error)
        }
    }

    /// Returns the encapsulated value if success, or `default` if failure.
    public func getOrDefault(_ default: T) -> T {
        getOrNull() ?? `default`
    }

    /// Returns the encapsulated value if success, or the result of `transform`
    /// applied to the `StrataException` if failure.
    public func getOrElse(_ transform: (any StrataException) -> T) -> T {
        switch self {
        case .success(let data): return data
        case .failure(let error): return transform(error)
        }
    }
}
