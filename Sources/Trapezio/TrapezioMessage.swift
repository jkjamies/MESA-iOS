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
@preconcurrency import Combine

/// A transient message to be displayed to the user (e.g., Snackbar, Alert).
public struct TrapezioMessage: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let message: String
    
    public init(message: String, id: UUID = UUID()) {
        self.message = message
        self.id = id
    }
    
    public init(error: Error, id: UUID = UUID()) {
        self.message = error.localizedDescription
        self.id = id
    }
}

/// Manages a queue of transient messages.
/// Observe `message` to show the current message.
@MainActor
public class TrapezioMessageManager: ObservableObject {
    @Published public private(set) var messages: [TrapezioMessage] = []
    
    public var message: TrapezioMessage? {
        messages.first
    }
    
    public var messagesStream: AnyPublisher<[TrapezioMessage], Never> {
        $messages.eraseToAnyPublisher()
    }
    
    public var messagesSequence: AsyncStream<[TrapezioMessage]> {
        AsyncStream { continuation in
            let cancellable = $messages
                .sink { messages in
                    continuation.yield(messages)
                }
            
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
    
    public init() {}
    
    public func emitMessage(_ message: TrapezioMessage) {
        messages.append(message)
    }
    
    public func emitMessage(_ message: String) {
        emitMessage(TrapezioMessage(message: message))
    }
    
    public func emitError(_ error: Error) {
        emitMessage(TrapezioMessage(error: error))
    }
    
    public func clearMessage(id: UUID) {
        messages.removeAll { $0.id == id }
    }
    
    public func clearAll() {
        messages.removeAll()
    }
}
