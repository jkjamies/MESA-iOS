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
}
