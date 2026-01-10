//
//  DivideUseCaseTests.swift
//  Trapezio
//
//  Created by Jason Jamieson on 1/10/26.
//

import XCTest
@testable import TrapezioCounter

final class DivideUsecaseTests: XCTestCase {
    
    func test_execute_dividesByTwo() async {
        // Given
        let usecase = DivideUsecase()
        let input = 100
        
        // When
        let result = await usecase.execute(value: input)
        
        // Then
        XCTAssertEqual(result, 50, "Usecase should return half of the input.")
    }
    
    func test_execute_handlesZero() async {
        let usecase = DivideUsecase()
        let result = await usecase.execute(value: 0)
        XCTAssertEqual(result, 0)
    }
}
