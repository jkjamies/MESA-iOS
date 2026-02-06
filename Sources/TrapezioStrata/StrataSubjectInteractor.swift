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

/// A base class for interactors that produce a stream of data based on input parameters.
open class StrataSubjectInteractor<P: Sendable, T: Sendable>: @unchecked Sendable {
    
    // Exposes values as an asynchronous stream.
    private let paramContinuation: AsyncStream<P>.Continuation
    private let paramStream: AsyncStream<P>
    
    // The latest value emitted by the stream.
    private let _value = OSAllocatedUnfairLock<T?>(initialState: nil)
    public var value: T? {
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
    public func callAsFunction(_ params: P) {
        paramContinuation.yield(params)
    }
    
    /// The output stream.
    public var stream: AsyncStream<T> {
        AsyncStream { continuation in
            let task = Task { [weak self] in
                guard let self = self else { return }
                for await param in self.paramStream {
                    let outputStream = self.createObservable(params: param)
                    for await output in outputStream {
                        continuation.yield(output)
                        self.value = output
                    }
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }


    /// Override to define how to create the stream from parameters.
    open func createObservable(params: P) -> AsyncStream<T> {
        fatalError("createObservable(params:) must be implemented")
    }
}

