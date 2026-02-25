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

/// A transient message to be displayed to the user (e.g., Snackbar, Alert).
public struct TrapezioMessage: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let message: String

    public init(message: String, id: UUID = UUID()) {
        self.message = message
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
    
    /// A strict AsyncStream sequence of message list updates.
    /// This replaces the Combine `messagesStream`.
    public var messagesSequence: AsyncStream<[TrapezioMessage]> {
        AsyncStream { continuation in
            // Emit the initial value immediately
            continuation.yield(messages)
            
            // Register a listener for future updates
            let id = UUID()
            self.listeners[id] = { messages in
                continuation.yield(messages)
            }
            
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    self?.listeners.removeValue(forKey: id)
                }
            }
        }
    }
    
    private var listeners: [UUID: @Sendable ([TrapezioMessage]) -> Void] = [:]
    
    public init() {}
    
    public func emit(_ message: TrapezioMessage) {
        messages.append(message)
        notifyListeners()
    }
    
    public func clearMessage(id: UUID) {
        messages.removeAll { $0.id == id }
        notifyListeners()
    }
    
    public func clearAll() {
        messages.removeAll()
        notifyListeners()
    }
    
    private func notifyListeners() {
        for listener in listeners.values {
            listener(messages)
        }
    }
}
