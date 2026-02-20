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
@testable import Strata

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

final class SimpleSubjectInteractor: StrataSubjectInteractor<Int, String>, @unchecked Sendable {
    override func createObservable(params: Int) -> AsyncStream<String> {
        AsyncStream { continuation in
            continuation.yield("value:\(params)")
            continuation.finish()
        }
    }
}

final class ContinuousSubjectInteractor: StrataSubjectInteractor<Int, Int>, @unchecked Sendable {
    override func createObservable(params: Int) -> AsyncStream<Int> {
        AsyncStream { continuation in
            for i in 0..<3 {
                continuation.yield(params * 10 + i)
            }
            continuation.finish()
        }
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

// MARK: - StrataSubjectInteractor Tests

@Suite("StrataSubjectInteractor")
struct StrataSubjectInteractorTests {

    @Test("emits values from createObservable")
    func basicEmission() async {
        let interactor = SimpleSubjectInteractor()

        let task = Task { () -> [String] in
            var collected: [String] = []
            for await value in interactor.stream {
                collected.append(value)
                if collected.count >= 1 { break }
            }
            return collected
        }

        // Small delay to let stream setup
        try? await Task.sleep(nanoseconds: 10_000_000)
        interactor(42)

        let collected = await task.value

        #expect(collected == ["value:42"])
    }

    @Test("emits multiple values per trigger")
    func multipleEmissions() async {
        let interactor = ContinuousSubjectInteractor()

        let task = Task { () -> [Int] in
            var collected: [Int] = []
            for await value in interactor.stream {
                collected.append(value)
                if collected.count >= 3 { break }
            }
            return collected
        }

        try? await Task.sleep(nanoseconds: 10_000_000)
        interactor(1)

        let collected = await task.value

        #expect(collected == [10, 11, 12])
    }

    @Test("caches latest value")
    func valueCaching() async {
        let interactor = SimpleSubjectInteractor()

        #expect(interactor.value == nil)

        let task = Task {
            for await _ in interactor.stream {
                break
            }
        }

        try? await Task.sleep(nanoseconds: 10_000_000)
        interactor(7)

        await task.value
        // Small delay for value to be set
        try? await Task.sleep(nanoseconds: 10_000_000)

        #expect(interactor.value == "value:7")
    }

    @Test("re-trigger cancels previous inner stream")
    func retriggerCancelsPrevious() async {
        // Use a slow interactor that emits values with delays
        final class SlowSubjectInteractor: StrataSubjectInteractor<Int, Int>, @unchecked Sendable {
            override func createObservable(params: Int) -> AsyncStream<Int> {
                AsyncStream { continuation in
                    Task {
                        for i in 0..<5 {
                            guard !Task.isCancelled else { break }
                            continuation.yield(params * 100 + i)
                            try? await Task.sleep(nanoseconds: 20_000_000) // 20ms between values
                        }
                        continuation.finish()
                    }
                }
            }
        }

        let interactor = SlowSubjectInteractor()

        let task = Task { () -> [Int] in
            var collected: [Int] = []
            for await value in interactor.stream {
                collected.append(value)
                if collected.count >= 4 { break }
            }
            return collected
        }

        try? await Task.sleep(nanoseconds: 10_000_000)
        interactor(1) // Start emitting 100, 101, 102...

        // Wait for first emission then re-trigger
        try? await Task.sleep(nanoseconds: 30_000_000)
        interactor(2) // Should cancel first, start emitting 200, 201, 202...

        let collected = await task.value

        // The last values should be from the second trigger (params=2)
        let lastValue = collected.last!
        #expect(lastValue >= 200, "Expected values from second trigger, got \(collected)")
    }
}

// MARK: - StrataResult Additional Tests

@Suite("StrataResult helpers")
struct StrataResultHelperTests {

    @Test("map transforms success value")
    func mapSuccess() {
        let result: StrataResult<Int> = .success(5)

        let mapped = result.map { $0 * 2 }

        #expect(mapped.getOrNull() == 10)
    }

    @Test("map preserves failure")
    func mapFailure() {
        let result: StrataResult<Int> = .failure(TestException(message: "err"))

        let mapped = result.map { $0 * 2 }

        var message: String?
        mapped.onFailure { message = $0.message }
        #expect(mapped.getOrNull() == nil)
        #expect(message == "err")
    }

    @Test("fold returns onSuccess value for success")
    func foldSuccess() {
        let result: StrataResult<Int> = .success(3)

        let folded = result.fold(onSuccess: { "got \($0)" }, onFailure: { $0.message })

        #expect(folded == "got 3")
    }

    @Test("fold returns onFailure value for failure")
    func foldFailure() {
        let result: StrataResult<Int> = .failure(TestException(message: "bad"))

        let folded = result.fold(onSuccess: { "got \($0)" }, onFailure: { $0.message })

        #expect(folded == "bad")
    }

    @Test("getOrDefault returns value on success")
    func getOrDefaultSuccess() {
        let result: StrataResult<Int> = .success(42)

        #expect(result.getOrDefault(0) == 42)
    }

    @Test("getOrDefault returns default on failure")
    func getOrDefaultFailure() {
        let result: StrataResult<Int> = .failure(TestException(message: "err"))

        #expect(result.getOrDefault(0) == 0)
    }

    @Test("getOrElse returns value on success")
    func getOrElseSuccess() {
        let result: StrataResult<Int> = .success(42)

        #expect(result.getOrElse { _ in -1 } == 42)
    }

    @Test("getOrElse returns transform result on failure")
    func getOrElseFailure() {
        let result: StrataResult<Int> = .failure(TestException(message: "err"))

        #expect(result.getOrElse { _ in -1 } == -1)
    }
}

// MARK: - Concurrency Helper Tests

@Suite("Concurrency Helpers")
struct ConcurrencyHelperTests {

    @Test("strataLaunch executes work and reduces on main")
    @MainActor
    func strataLaunchBasic() async {
        var reduced: String?
        let expectation = AsyncStream<Void>.makeStream()

        strataLaunch(
            work: { "hello" },
            reduce: { value in
                reduced = value
                expectation.continuation.yield()
                expectation.continuation.finish()
            }
        )

        for await _ in expectation.stream { break }

        #expect(reduced == "hello")
    }

    @Test("strataLaunchWithResult wraps success")
    func strataLaunchWithResultSuccess() async {
        let task = strataLaunchWithResult { 42 }

        let result = await task.value

        #expect(result.getOrNull() == 42)
    }

    @Test("strataLaunchWithResult wraps thrown error")
    func strataLaunchWithResultFailure() async {
        let task = strataLaunchWithResult {
            throw TestException(message: "failed")
            return 0 // unreachable, needed for type inference
        }

        let result = await task.value

        #expect(result.getOrNull() == nil)
        var message: String?
        result.onFailure { message = $0.message }
        #expect(message == "failed")
    }

    @Test("strataCollect delivers stream values")
    @MainActor
    func strataCollectBasic() async {
        let (stream, continuation) = AsyncStream<Int>.makeStream()
        var collected: [Int] = []
        let done = AsyncStream<Void>.makeStream()

        strataCollect(stream) { value in
            collected.append(value)
            if collected.count >= 3 {
                done.continuation.yield()
                done.continuation.finish()
            }
        }

        continuation.yield(1)
        continuation.yield(2)
        continuation.yield(3)

        for await _ in done.stream { break }

        #expect(collected == [1, 2, 3])
    }
}
