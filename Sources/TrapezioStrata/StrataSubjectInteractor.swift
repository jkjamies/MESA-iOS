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

/// A base class for interactors that produce a stream of data based on input parameters.
/// Mirrors `StrataSubjectInteractor` from Android, adapted for Swift Concurrency (AsyncStream).
/// Marked @MainActor to ensure thread safety of `value` and simplify usage in UI.
@MainActor
open class StrataSubjectInteractor<P: Sendable, T: Sendable> {
    
    // We use an AsyncStream to expose the values.
    // To feed the stream, we'll keep a continuation or use a buffering mechanism if needed.
    // For a "Subject" pattern where we push params and get a stream of output, 
    // we can Model this by observing the params injection.
    
    private let paramContinuation: AsyncStream<P>.Continuation
    private let paramStream: AsyncStream<P>
    
    // Latest value holder, protected by actor isolation or lock if needed.
    // Since this class is open and likely non-isolated, we need to be careful.
    // For simplicity in this architectural pattern, we assume MainActor for state or use strict isolation.
    // However, interactors are often nonisolated.
    // We'll use a thread-safe property wrapper or lock for `value` if we want to expose it synchronously,
    // but typically we just expose the stream.
    
    private var _value: T?
    public var value: T? {
        get { _value }
        set { _value = newValue }
    }

    public init() {
        var continuation: AsyncStream<P>.Continuation!
        self.paramStream = AsyncStream { cont in
            continuation = cont
        }
        self.paramContinuation = continuation
        
        // Start processing immediately? 
        // In AsyncStream world, we create the stream lazily when requested usually.
    }
    
    /// Triggers the stream with new parameters.
    public func callAsFunction(_ params: P) {
        paramContinuation.yield(params)
    }
    
    /// The output stream.
    /// Note: This implementation simplifies the "flatMapLatest" behavior of Combine/Flow.
    /// A robust implementation would need a task to manage the stream mapping.
    public var stream: AsyncStream<T> {
        AsyncStream { continuation in
            let task = Task { [weak self] in
                guard let self = self else { return }
                for await param in self.paramStream {

                    
                    let outputStream = self.createObservable(params: param)
                    for await output in outputStream {
                        continuation.yield(output)
                        // Note: Writing to 'self.value' here is still risky if 'self' is not isolated.
                        // Ideally StrataSubjectInteractor should be an Actor or bound to a global actor.
                        // For parity with Android (which uses thread-safe StateFlow), we might need locking.
                        // For now, removing the direct side-effect `self.value = output` inside the loop 
                        // or ignoring it to solve the race, relying on stream consumers.
                        // BUT, value is public. Let's make it MainActor isolated if generally used in UI.
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

