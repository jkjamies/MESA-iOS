# Trapezio Project Guide

## Project Overview
The iOS implementation of the MESA framework using SwiftUI. Aligned with the Android Trapeze library to ensure logic parity and architectural consistency.

## MESA Pillars
- **Modular:** Encourages feature-based partitioning (e.g., via SPM).
- **Explicit:** Clear boundaries between routing (Screen), logic (Store), and rendering (View).
- **State-driven:** Unidirectional Data Flow via a State struct containing an EventSink.
- **Architecture:** A standard way to bridge logic and UI across the platform.

## Libraries
- **Trapezio (Core):** Contains the foundational protocols (`TrapezioStore`, `TrapezioScreen`, `TrapezioState`, `TrapezioEvent`, `TrapezioUI`).
- **TrapezioNavigation:** A separate library for the navigation layer (`TrapezioNavigator`, `TrapezioNavigationHost`, `TrapezioInterop`).
    - *Dependency:* Depends on `Trapezio`.

## Technical Contract
- **State:** An immutable struct containing all display data.
- **Logic (Store):** The engine that consumes a Screen and produces the State. MUST be `@MainActor`.
- **View:** A stateless SwiftUI View that observes the State object.

## Coding Standards
- **UDF Flow:** View triggers `eventSink` -> Store updates logic -> View renders new State.
- **Injection Agnostic:** Stores are provided to the architecture; the framework does not mandate a DI library.
- **Concurrency:** 
    - Stores and UI are strictly `@MainActor`.
    - `TrapezioUI` map function requires `onEvent` to be `@MainActor`.

## The Trapezio Contract
1. **Screen:** `Hashable` route identifier.
2. **Event:** Enum of user intents.
3. **State:** Struct with values.
4. **Store:** Manages state production and event handling.
5. **View:** SwiftUI View consuming the State object.
6. **Navigator:** Protocol for type-safe screen navigation (`TrapezioNavigator`).
7. **Interop:** Protocol for external/legacy navigation events (`TrapezioInterop`).
