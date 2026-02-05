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
