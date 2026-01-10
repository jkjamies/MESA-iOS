//
//  CounterStoreTests.swift
//  Trapezio
//
//  Created by Jason Jamieson on 1/10/26.
//

import XCTest
import Trapezio
@testable import TrapezioCounter

@MainActor
final class CounterStoreTests: XCTestCase {
    
    var store: CounterStore!
    
    override func setUp() {
        super.setUp()
        // Initialize fresh state for every test
        store = CounterStore(screen: CounterScreen(initialValue: 10))
    }

    func test_increment_increasesCount() {
        store.handle(event: .increment)
        XCTAssertEqual(store.state.count, 11)
    }

    func test_decrement_decreasesCount() {
        store.handle(event: .decrement)
        XCTAssertEqual(store.state.count, 9)
    }

    func test_printValue_doesNotMutateState() {
        let initialCount = store.state.count
        store.handle(event: .printValue)
        XCTAssertEqual(store.state.count, initialCount)
    }

    func test_divideByTwo_eventuallyUpdatesState() async {
        store.handle(event: .divideByTwo)
        // do better than sleep in tests, but for simplicity we will here
        try? await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(store.state.count, 5)
    }
}
