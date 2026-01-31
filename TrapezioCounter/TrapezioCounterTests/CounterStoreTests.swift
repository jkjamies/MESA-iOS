//
//  CounterStoreTests.swift
//  Trapezio
//
//  Created by Jason Jamieson on 1/10/26.
//

import XCTest
import Trapezio
import TrapezioNavigation
@testable import TrapezioCounter

@MainActor
final class CounterStoreTests: XCTestCase {
    
    var store: CounterStore!
    var interop: FakeInterop!
    
    override func setUp() {
        super.setUp()
        
        // 2. Manual Injection: We provide the fake directly.
        // This is where we "simulate" a DI override.
        let screen = CounterScreen(initialValue: 10)
        let fakeUsecase = FakeDivideUsecase()
        interop = FakeInterop()
        
        store = CounterStore(
            screen: screen,
            divideUsecase: fakeUsecase,
            navigator: nil,
            interop: interop
        )
    }

    func test_increment_increasesCount() {
        store.handle(event: .increment)
        XCTAssertEqual(store.state.count, 11)
    }

    func test_decrement_decreasesCount() {
        store.handle(event: .decrement)
        XCTAssertEqual(store.state.count, 9)
    }

    func test_goToSummary_withNilNavigator_doesNotMutateState() {
        let initialCount = store.state.count
        store.handle(event: .goToSummary)
        XCTAssertEqual(store.state.count, initialCount)
    }

    func test_divideByTwo_isInstantAndDeterministic() async {
        store.handle(event: .divideByTwo)
        // No more long sleep!
        // Use yield to let the Store's Task { } block start and finish.
        await Task.yield()
        XCTAssertEqual(store.state.count, 5, "The count should be divided by 2 instantly using the fake.")
    }
    
    func test_requestHelp_sendsInteropEvent() {
        store.handle(event: .requestHelp)
        
        XCTAssertEqual(interop.sentEvents.count, 1)
        guard let event = interop.sentEvents.first as? AppInterop else {
            XCTFail("Event was not AppInterop")
            return
        }
        
        if case .showAlert(let message) = event {
            XCTAssertEqual(message, "This is a simple counter. Press +/- to change value.")
        } else {
            XCTFail("Wrong event type")
        }
    }
}
