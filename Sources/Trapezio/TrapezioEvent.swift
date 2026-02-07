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

/// A user intent emitted by the UI layer and handled by a ``TrapezioStore``.
///
/// Model events as an enum so the store can exhaustively switch over all possible user actions.
///
/// ```swift
/// enum CounterEvent: TrapezioEvent {
///     case increment
///     case decrement
/// }
/// ```
///
/// - Note: Events flow unidirectionally: **UI -> Store**. The UI never reads events back.
public protocol TrapezioEvent {}
