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
@testable import Strata

final class FakeSimpleSubjectInteractor: StrataSubjectInteractor<Int, String>, @unchecked Sendable {
    override func createObservable(params: Int) -> AsyncStream<String> {
        AsyncStream { continuation in
            continuation.yield("value:\(params)")
            continuation.finish()
        }
    }
}

final class FakeContinuousSubjectInteractor: StrataSubjectInteractor<Int, Int>, @unchecked Sendable {
    override func createObservable(params: Int) -> AsyncStream<Int> {
        AsyncStream { continuation in
            for i in 0..<3 {
                continuation.yield(params * 10 + i)
            }
            continuation.finish()
        }
    }
}
