//
//  FakeDivideUseCase.swift
//  Trapezio
//
//  Created by Jason Jamieson on 1/10/26.
//

import Foundation
@testable import TrapezioCounter

/// A deterministic version of DivideUsecase for testing.
/// It fulfills the protocol but removes the 100ms delay.
struct FakeDivideUsecase: DivideUsecaseProtocol {
    func execute(value: Int) async -> Int {
        // Instant math, no Task.sleep
        return value / 2
    }
}
