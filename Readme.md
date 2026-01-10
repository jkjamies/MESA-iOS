# Trapezio Framework

A type-safe, Circuit-inspired architecture for SwiftUI. This framework enforces a strict separation between logic (Store), presentation (UI), and identity (Screen).

## Core Architecture

### 1. The Screen (Identity)
The `TrapezioScreen` is a "Parcelable" data structure. It acts as the unique identifier for a feature and carries all necessary initialization parameters.

### 2. The Store (Logic)
The `TrapezioStore` is the brain of the feature. It is isolated to the `@MainActor` to ensure thread-safe state management. It receives `Events` and produces a new `State`.

### 3. The UI (Stateless View)
The `TrapezioUI` is a pure mapping function. It takes a `State` and returns a `View`. It communicates user interactions back to the Store via a closure.

### 4. The Runtime (The Weld)
The `TrapezioRuntime` is the engine that connects the Store to the UI. It ensures that the generic types for State and Event match across all components at compile-time.

## Example: Counter Feature

```swift
// 1. Definition (Screen, State, Event)
struct CounterScreen: TrapezioScreen { let initialValue: Int }
struct CounterState: TrapezioState { var count: Int }
enum CounterEvent: TrapezioEvent { case increment }

// 2. Store Implementation
final class CounterStore: TrapezioStore<CounterScreen, CounterState, CounterEvent> {
    override func handle(event: CounterEvent) {
        if event == .increment { update { $0.count += 1 } }
    }
}

// 3. UI Implementation
struct CounterUI: TrapezioUI {
    func map(state: CounterState, onEvent: @escaping (CounterEvent) -> Void) -> some View {
        Button("\(state.count)") { onEvent(.increment) }
    }
}
