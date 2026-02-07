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

import Testing
@testable import TrapezioStrata

// MARK: - Test Doubles

struct TestException: StrataException {
    let message: String
}

final class DoubleInteractor: StrataInteractor<Int, String>, @unchecked Sendable {
    override func doWork(params: Int) async -> StrataResult<String> {
        return .success("value:\(params)")
    }
}

final class FailingInteractor: StrataInteractor<Void, String>, @unchecked Sendable {
    override func doWork(params: Void) async -> StrataResult<String> {
        return .failure(TestException(message: "something went wrong"))
    }
}

final class ThrowingInteractor: StrataInteractor<Void, String>, @unchecked Sendable {
    override func doWork(params: Void) async -> StrataResult<String> {
        return await executeCatching(params: params) { _ in
            throw TestException(message: "thrown")
        }
    }
}

final class SlowInteractor: StrataInteractor<Void, Void>, @unchecked Sendable {
    override func doWork(params: Void) async -> StrataResult<Void> {
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        return .success(())
    }
}

// MARK: - StrataResult Tests

@Suite("StrataResult")
struct StrataResultTests {

    @Test("getOrNull returns value on success")
    func getOrNullSuccess() {
        let result: StrataResult<Int> = .success(42)

        #expect(result.getOrNull() == 42)
    }

    @Test("getOrNull returns nil on failure")
    func getOrNullFailure() {
        let result: StrataResult<Int> = .failure(TestException(message: "err"))

        #expect(result.getOrNull() == nil)
    }

    @Test("onSuccess executes for success case")
    func onSuccessCallback() {
        var captured: Int?
        let result: StrataResult<Int> = .success(7)

        result.onSuccess { captured = $0 }

        #expect(captured == 7)
    }

    @Test("onSuccess does not execute for failure case")
    func onSuccessSkipsFailure() {
        var called = false
        let result: StrataResult<Int> = .failure(TestException(message: "err"))

        result.onSuccess { _ in called = true }

        #expect(!called)
    }

    @Test("onFailure executes for failure case")
    func onFailureCallback() {
        var captured: String?
        let result: StrataResult<Int> = .failure(TestException(message: "bad"))

        result.onFailure { captured = $0.message }

        #expect(captured == "bad")
    }

    @Test("onFailure does not execute for success case")
    func onFailureSkipsSuccess() {
        var called = false
        let result: StrataResult<Int> = .success(1)

        result.onFailure { _ in called = true }

        #expect(!called)
    }

    @Test("chaining onSuccess and onFailure")
    func chaining() {
        var successValue: Int?
        var failureMessage: String?

        let success: StrataResult<Int> = .success(10)
        success.onSuccess { successValue = $0 }.onFailure { failureMessage = $0.message }

        #expect(successValue == 10)
        #expect(failureMessage == nil)
    }
}

// MARK: - strataRunCatching Tests

@Suite("strataRunCatching")
struct StrataRunCatchingTests {

    @Test("wraps successful result")
    func successCase() async {
        let result = await strataRunCatching { 42 }

        #expect(result.getOrNull() == 42)
    }

    @Test("wraps StrataException on throw")
    func strataExceptionCase() async {
        let result: StrataResult<Int> = await strataRunCatching {
            throw TestException(message: "domain error")
        }

        var message: String?
        result.onFailure { message = $0.message }

        #expect(message == "domain error")
    }

    @Test("wraps generic error as GenericStrataException")
    func genericErrorCase() async {
        struct PlainError: Error {}

        let result: StrataResult<Int> = await strataRunCatching {
            throw PlainError()
        }

        #expect(result.getOrNull() == nil)
    }
}

// MARK: - StrataException Tests

@Suite("StrataException")
struct StrataExceptionTests {

    @Test("localizedDescription returns message")
    func localizedDescription() {
        let err = TestException(message: "test error")

        #expect(err.localizedDescription == "test error")
    }
}

// MARK: - StrataInteractor Tests

@Suite("StrataInteractor")
struct StrataInteractorTests {

    @Test("execute returns success result")
    func executeSuccess() async {
        let interactor = DoubleInteractor()

        let result = await interactor.execute(params: 5)

        #expect(result.getOrNull() == "value:5")
    }

    @Test("execute returns failure result")
    func executeFailure() async {
        let interactor = FailingInteractor()

        let result = await interactor.execute(params: ())

        var message: String?
        result.onFailure { message = $0.message }

        #expect(result.getOrNull() == nil)
        #expect(message == "something went wrong")
    }

    @Test("executeCatching bridges thrown errors to failure")
    func executeCatchingBridgesThrows() async {
        let interactor = ThrowingInteractor()

        let result = await interactor.execute(params: ())

        var message: String?
        result.onFailure { message = $0.message }

        #expect(message == "thrown")
    }

    @Test("inProgress is false before execution")
    func inProgressInitiallyFalse() {
        let interactor = SlowInteractor()

        #expect(interactor.inProgress == false)
    }

    @Test("inProgress is false after execution completes")
    func inProgressFalseAfterComplete() async {
        let interactor = SlowInteractor()

        _ = await interactor.execute(params: ())

        #expect(interactor.inProgress == false)
    }
}
