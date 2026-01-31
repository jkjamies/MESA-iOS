# Trapezio Framework

A type-safe, Circuit-inspired architecture for SwiftUI. This framework enforces a strict separation between logic (Store), presentation (UI), and identity (Screen).

## Libraries

- **Trapezio**: The core types (`Store`, `State`, `Screen`, `Event`, `UI`).
- **TrapezioNavigation**: The navigation layer (`TrapezioNavigator`, `TrapezioNavigationHost`, `TrapezioInterop`).

## Core Architecture

### 1. The Screen (Identity)
The `TrapezioScreen` is a "Parcelable" data structure. It acts as the unique identifier for a feature and carries all necessary initialization parameters.

### 2. The Store (Logic)
The `TrapezioStore` is the brain of the feature. It is isolated to the `@MainActor` to ensure thread-safe state management. It receives `Events` and produces a new `State`.

### 3. The UI (Stateless View)
The `TrapezioUI` is a pure mapping function. It takes a `State` and returns a `View`. It communicates user interactions back to the Store via a closure.

### 4. The Runtime (The Weld)
The `TrapezioRuntime` uses `TrapezioContainer` to own the Store as a `@StateObject`, preventing re-initialization during view updates.

## Example: Counter Feature

```swift
import Trapezio
import TrapezioNavigation
import SwiftUI

// 1. Definition (Screen, State, Event)
struct CounterScreen: TrapezioScreen { let initialValue: Int }
struct CounterState: TrapezioState { var count: Int }
enum CounterEvent: TrapezioEvent { case increment }

// 2. Store Implementation
@MainActor
final class CounterStore: TrapezioStore<CounterScreen, CounterState, CounterEvent> {
    private let navigator: (any TrapezioNavigator)?

    init(screen: CounterScreen, navigator: (any TrapezioNavigator)?) {
        self.navigator = navigator
        super.init(screen: screen, initialState: CounterState(count: screen.initialValue))
    }

    override func handle(event: CounterEvent) {
        if event == .increment { 
            update { $0.count += 1 } 
        }
    }
}

// 3. UI Implementation
struct CounterUI: TrapezioUI {
    func map(state: CounterState, onEvent: @escaping @MainActor (CounterEvent) -> Void) -> some View {
        Button("\(state.count)") { onEvent(.increment) }
    }
}
```

## Navigation Host

Use `TrapezioNavigationHost` to drive navigation with a native `NavigationStack`.

- Features call `navigator.goTo(...)`, `navigator.dismiss()`, and `navigator.dismissToRoot()`.
- The host owns the stack state.
- The builder returns `some View` (no `AnyView` required at the call site).

```swift
import SwiftUI
import Trapezio
import TrapezioNavigation

struct AppRoot: View {
    var body: some View {
        TrapezioNavigationHost(root: CounterScreen(initialValue: 0)) { screen, navigator, interop in
            switch screen {
            case let counter as CounterScreen:
                CounterFactory.make(screen: counter, navigator: navigator, interop: interop)
            case let summary as SummaryScreen:
                SummaryFactory.make(screen: summary, navigator: navigator)
            default:
                EmptyView()
            }
        }
    }
}
```

## Interop (Advanced)

For legacy apps, tab switching, or system alerts, use the `TrapezioInterop` protocol.

1. **Define Events**:
   ```swift
   enum AppInterop: TrapezioInteropEvent {
       case showAlert(message: String)
       case switchTab(index: Int)
   }
   ```

2. **Send from Store**:
   ```swift
   // Inject 'interop: (any TrapezioInterop)?' into your Store
   interop?.send(AppInterop.showAlert(message: "Hello"))
   ```

3. **Handle in Host**:
   ```swift
   TrapezioNavigationHost(
       root: HomeScreen(),
       onInterop: { event in
           if let appEvent = event as? AppInterop {
               switch appEvent {
               case .showAlert(let msg): print(msg)
               case .switchTab(let idx): tabSelection = idx
               }
           }
       }
   ) { ... }
   ```
