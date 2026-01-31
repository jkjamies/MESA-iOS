//
//  AppInterop.swift
//  TrapezioCounter
//
//  Created by Jason Jamieson on 1/31/26.
//

import Foundation
import TrapezioNavigation

/// Defines the external navigation events for the TrapezioCounter app.
enum AppInterop: TrapezioInteropEvent {
    case showAlert(message: String)
}
