//
//  DivideUseCase.swift
//  Trapezio
//
//  Created by Jason Jamieson on 1/10/26.
//

import Foundation

public struct DivideUsecase: Sendable {
    nonisolated public init() {}
    
    func execute(value: Int) async -> Int {
        try? await Task.sleep(nanoseconds: 100_000_000)
        return value / 2
    }
}
