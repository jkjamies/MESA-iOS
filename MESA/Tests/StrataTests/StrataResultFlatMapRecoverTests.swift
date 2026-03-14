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
import Testing
@testable import Strata

@Suite("StrataResult flatMap & recover")
struct StrataResultFlatMapRecoverTests {

    @Test("flatMap on success transforms to new success")
    func flatMapSuccessToSuccess() {
        let result: StrataResult<Int> = .success(5)

        let mapped = result.flatMap { .success("value:\($0)") }

        #expect(mapped.getOrNull() == "value:5")
    }

    @Test("flatMap on success transforms to failure")
    func flatMapSuccessToFailure() {
        let result: StrataResult<Int> = .success(5)

        let mapped: StrataResult<String> = result.flatMap { _ in
            .failure(FakeStrataException(message: "dependent failed"))
        }

        var message: String?
        mapped.onFailure { message = $0.message }
        #expect(mapped.getOrNull() == nil)
        #expect(message == "dependent failed")
    }

    @Test("flatMap on failure short-circuits")
    func flatMapFailureShortCircuits() {
        let result: StrataResult<Int> = .failure(FakeStrataException(message: "original"))
        var transformCalled = false

        let mapped: StrataResult<String> = result.flatMap { _ in
            transformCalled = true
            return .success("never")
        }

        #expect(!transformCalled)
        var message: String?
        mapped.onFailure { message = $0.message }
        #expect(message == "original")
    }

    @Test("recover on success returns original")
    func recoverOnSuccess() async {
        let result: StrataResult<Int> = .success(42)
        var transformCalled = false

        let recovered = await result.recover { _ in
            transformCalled = true
            return .success(0)
        }

        #expect(!transformCalled)
        #expect(recovered.getOrNull() == 42)
    }

    @Test("recover on failure calls transform and returns fallback")
    func recoverOnFailure() async {
        let result: StrataResult<Int> = .failure(FakeStrataException(message: "fail"))

        let recovered = await result.recover { _ in .success(99) }

        #expect(recovered.getOrNull() == 99)
    }

    @Test("recover on failure where fallback also fails")
    func recoverOnFailureFallbackFails() async {
        let result: StrataResult<Int> = .failure(FakeStrataException(message: "first"))

        let recovered = await result.recover { _ in
            .failure(FakeStrataException(message: "second"))
        }

        var message: String?
        recovered.onFailure { message = $0.message }
        #expect(recovered.getOrNull() == nil)
        #expect(message == "second")
    }
}
