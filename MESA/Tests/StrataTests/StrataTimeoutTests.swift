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

/// Interactor that sleeps for a configurable duration.
private final class FakeConfigurableSlowInteractor: StrataInteractor<TimeInterval, String>, @unchecked Sendable {
    override func doWork(params: TimeInterval) async -> StrataResult<String> {
        try? await Task.sleep(for: .seconds(params))
        return .success("done")
    }
}

@Suite("StrataInteractor Timeout")
struct StrataTimeoutTests {

    @Test("fast doWork completes before timeout")
    func fastWorkCompletes() async {
        let interactor = FakeConfigurableSlowInteractor()

        let result = await interactor.execute(params: 0.01, timeout: 5.0)

        #expect(result.getOrNull() == "done")
    }

    @Test("slow doWork with short timeout returns failure")
    func slowWorkTimesOut() async {
        let interactor = FakeConfigurableSlowInteractor()

        let result = await interactor.execute(params: 10.0, timeout: 0.05)

        #expect(result.getOrNull() == nil)
        var isTimeout = false
        result.onFailure { isTimeout = $0 is StrataTimeoutException }
        #expect(isTimeout)
    }

    @Test("StrataTimeoutException.duration matches configured timeout")
    func timeoutDurationMatches() async {
        let interactor = FakeConfigurableSlowInteractor()

        let result = await interactor.execute(params: 10.0, timeout: 0.05)

        var duration: TimeInterval?
        result.onFailure { error in
            if let timeout = error as? StrataTimeoutException {
                duration = timeout.duration
            }
        }
        #expect(duration == 0.05)
    }

    @Test("inProgress is false after timeout")
    func inProgressFalseAfterTimeout() async {
        let interactor = FakeConfigurableSlowInteractor()

        _ = await interactor.execute(params: 10.0, timeout: 0.05)

        #expect(interactor.inProgress == false)
    }

    @Test("default timeout is 300 seconds")
    func defaultTimeout() {
        #expect(FakeConfigurableSlowInteractor.defaultTimeout == 300)
    }
}
