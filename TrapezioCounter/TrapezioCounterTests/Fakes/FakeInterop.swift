//
//  FakeInterop.swift
//  TrapezioCounterTests
//
//  Created by Jason Jamieson on 1/31/26.
//

import Foundation
import Trapezio
import TrapezioNavigation
@testable import TrapezioCounter

class FakeInterop: TrapezioInterop {
    var sentEvents: [any TrapezioInteropEvent] = []
    
    func send(_ event: any TrapezioInteropEvent) {
        sentEvents.append(event)
    }
}
