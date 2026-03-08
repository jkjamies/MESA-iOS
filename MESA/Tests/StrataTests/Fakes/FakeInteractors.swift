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

final class FakeDoubleInteractor: StrataInteractor<Int, String>, @unchecked Sendable {
    override func doWork(params: Int) async -> StrataResult<String> {
        return .success("value:\(params)")
    }
}

final class FakeFailingInteractor: StrataInteractor<Void, String>, @unchecked Sendable {
    override func doWork(params: Void) async -> StrataResult<String> {
        return .failure(FakeStrataException(message: "something went wrong"))
    }
}

final class FakeThrowingInteractor: StrataInteractor<Void, String>, @unchecked Sendable {
    override func doWork(params: Void) async -> StrataResult<String> {
        return await executeCatching(params: params) { _ in
            throw FakeStrataException(message: "thrown")
        }
    }
}

final class FakeSlowInteractor: StrataInteractor<Void, Void>, @unchecked Sendable {
    override func doWork(params: Void) async -> StrataResult<Void> {
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        return .success(())
    }
}
