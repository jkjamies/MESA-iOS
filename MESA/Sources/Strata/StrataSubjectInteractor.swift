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

import os

/// Base class for interactors that produce a continuous stream of data.
///
/// Subclass this for observation-style use cases (e.g. watching a database query).
/// Override ``createObservable(params:)`` to define how input parameters map to an output stream.
///
/// ```swift
/// final class ObserveLastValueUseCase: StrataSubjectInteractor<Void, Int?> {
///     override func createObservable(params: Void) -> AsyncStream<Int?> {
///         repository.observeLastValue()
///     }
/// }
/// ```
///
/// - Note: The ``value`` property provides thread-safe synchronous access to the latest emitted value.
open class StrataSubjectInteractor<P: Sendable, T: Sendable>: @unchecked Sendable {

    private let paramContinuation: AsyncStream<P>.Continuation
    private let paramStream: AsyncStream<P>

    /// The latest value emitted by the stream (thread-safe, read-only externally).
    private let _value = OSAllocatedUnfairLock<T?>(initialState: nil)
    public private(set) var value: T? {
        get { _value.withLock { $0 } }
        set { _value.withLock { $0 = newValue } }
    }

    public init() {
        var continuation: AsyncStream<P>.Continuation!
        self.paramStream = AsyncStream { cont in
            continuation = cont
        }
        self.paramContinuation = continuation
    }

    /// Triggers the stream with new parameters.
    ///
    /// - Parameter params: The input to pass to ``createObservable(params:)``.
    public func callAsFunction(_ params: P) {
        paramContinuation.yield(params)
    }

    /// The output stream that yields values from ``createObservable(params:)``.
    ///
    /// Each access creates a **new** `AsyncStream` backed by its own `Task`. The task is
    /// automatically cancelled when the stream's consumer stops iterating (via `onTermination`).
    /// Typically you should call this once and collect it with `strataCollect`.
    ///
    /// When a new parameter arrives via ``callAsFunction(_:)``, the previous inner stream is
    /// cancelled before starting the new one, preventing duplicate or stale emissions.
    ///
    /// - Important: Calling this property multiple times creates independent streams and tasks.
    public var stream: AsyncStream<T> {
        AsyncStream { continuation in
            let task = Task { [weak self] in
                guard let self = self else { return }
                var innerTask: Task<Void, Never>?
                for await param in self.paramStream {
                    innerTask?.cancel()
                    innerTask = Task { [weak self] in
                        guard let self = self else { return }
                        let outputStream = self.createObservable(params: param)
                        for await output in outputStream {
                            guard !Task.isCancelled else { break }
                            continuation.yield(output)
                            self.value = output
                        }
                    }
                }
                innerTask?.cancel()
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /// Override to define how input parameters produce an output stream.
    ///
    /// - Parameter params: The input parameters provided via ``callAsFunction(_:)``.
    /// - Returns: An `AsyncStream` of output values to forward to subscribers.
    open func createObservable(params: P) -> AsyncStream<T> {
        fatalError("createObservable(params:) must be implemented")
    }
}

