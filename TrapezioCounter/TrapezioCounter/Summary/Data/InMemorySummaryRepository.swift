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

/// A transient in-memory implementation for older iOS versions or testing.
public class InMemorySummaryRepository: SummaryRepository {
    private var value: Int?
    
    public init() {}
    
    public func saveValue(_ value: Int) async throws {
        self.value = value
    }
    
    public func observeLastValue() -> AsyncStream<Int?> {
        let current = value
        return AsyncStream { continuation in
            continuation.yield(current)
            continuation.finish()
        }
    }
}
