//
//  TrapezioInterop.swift
//  TrapezioNavigation
//
//  Created by Jason Jamieson on 1/31/26.
//

import Foundation

/// Marker protocol for all external navigation/interop events.
/// Consumers should define their own enums conforming to this protocol.
public protocol TrapezioInteropEvent {}

/// Handles legacy or external navigation requests that fall outside the
/// pure Trapezio screen system (e.g., deep links, UIKit bridges).
public protocol TrapezioInterop {
    /// Sends a type-safe interop event to the host.
    func send(_ event: any TrapezioInteropEvent)
}

/// A concrete implementation of TrapezioInterop that delegates to a closure.
public struct ClosureTrapezioInterop: TrapezioInterop {
    private let onEvent: (TrapezioInteropEvent) -> Void

    public init(onEvent: @escaping (TrapezioInteropEvent) -> Void) {
        self.onEvent = onEvent
    }

    public func send(_ event: any TrapezioInteropEvent) {
        onEvent(event)
    }
}
