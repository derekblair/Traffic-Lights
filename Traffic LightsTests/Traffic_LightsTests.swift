//
//  Traffic_LightsTests.swift
//  Traffic LightsTests
//

import XCTest
@testable import Traffic_Lights

class StubPresenter : TrafficLightPresenter {
    var lastState : AppState?
    func present(state:AppState) {
        lastState = state
    }
}

class Traffic_LightsTests: XCTestCase {

    var stubPresenter = StubPresenter()
    override func setUp() {
        super.setUp()
        stubPresenter.lastState = nil
    }


    // MARK: - Initial State Tests

    // Is the initial state set correctly based on the config object?
    func testInitialStateApplication() {
        let config = TrafficLightsCoordinatorConfig(amberDuration: 5, cycleDuration: 30, initialState: [.east:.green,.north:.red], initialElapsedTime: 4)
        let coordinator = TrafficLightsCoordinator(config:config)
        coordinator?.start(initialPresenter: stubPresenter)
        XCTAssert(stubPresenter.lastState?.state[.east] == .green && stubPresenter.lastState?.state[.north] == .red && stubPresenter.lastState?.elapsedTime == 4)
    }

     // MARK: - State Transition Tests

    // Does the system turn a green light amber at the correct time?
    func testBeginAmberTransition() {
        let config = TrafficLightsCoordinatorConfig(amberDuration: 5, cycleDuration: 30, initialState: [.east:.red,.north:.green], initialElapsedTime: 23)
        let coordinator = TrafficLightsCoordinator(config:config)
        coordinator?.start(initialPresenter: stubPresenter)
        coordinator?.tick()
        coordinator?.tick()
        XCTAssert(stubPresenter.lastState?.state[.north] == .amber && stubPresenter.lastState?.state[.east] == .red && stubPresenter.lastState?.elapsedTime == 25)
    }

    // Does the system turn a green light on and an amber light to red at the correct time. 
    func testEndAmberTransition() {
        let config = TrafficLightsCoordinatorConfig(amberDuration: 5, cycleDuration: 30, initialState: [.east:.amber,.north:.red], initialElapsedTime: 28)
        let coordinator = TrafficLightsCoordinator(config:config)
        coordinator?.start(initialPresenter: stubPresenter)
        coordinator?.tick()
        coordinator?.tick()
        XCTAssert(stubPresenter.lastState?.state[.north] == .green && stubPresenter.lastState?.state[.east] == .red && stubPresenter.lastState?.elapsedTime == 0)
    }


    // MARK: - Atomic Action Tests


    func testIncrementAction() {

        let config = TrafficLightsCoordinatorConfig(amberDuration: 1, cycleDuration: 4, initialState: [.east:.red,.north:.green], initialElapsedTime: 1)
        var store = Store(state:TrafficLightsState(config:config),reducer:TrafficLightReducer())
        store.dispatch(action: TrafficLightIncrementTimeAction(cycle: config.cycleDuration))
        XCTAssert(store.state.elapsedTime == 2)
    }

    func testIncrementActionRollover() {

        let config = TrafficLightsCoordinatorConfig(amberDuration: 1, cycleDuration: 4, initialState: [.east:.red,.north:.green], initialElapsedTime: 3)
        var store = Store(state:TrafficLightsState(config:config),reducer:TrafficLightReducer())
        store.dispatch(action: TrafficLightIncrementTimeAction(cycle: config.cycleDuration))
        XCTAssert(store.state.elapsedTime == 0)
    }


    func testChangeToRedColorAction() {
        let config = TrafficLightsCoordinatorConfig(amberDuration: 1, cycleDuration: 4, initialState: [.east:.red,.north:.green], initialElapsedTime: 1)
        var store = Store(state:TrafficLightsState(config:config),reducer:TrafficLightReducer())
        store.dispatch(action: TrafficLightChangeColorAction(position: .north, newColorState: .red))
        XCTAssert(store.state.state[.north] == .red)
        XCTAssert(store.state.state[.east] == .red)
    }


    func testChangeToGreenColorAction() {
        let config = TrafficLightsCoordinatorConfig(amberDuration: 1, cycleDuration: 4, initialState: [.east:.red,.north:.green], initialElapsedTime: 1)
        var store = Store(state:TrafficLightsState(config:config),reducer:TrafficLightReducer())
        store.dispatch(action: TrafficLightChangeColorAction(position: .east, newColorState: .green))
        XCTAssert(store.state.state[.north] == .red)
        XCTAssert(store.state.state[.east] == .green)
    }

    func testChangeToAmberColorAction() {
        let config = TrafficLightsCoordinatorConfig(amberDuration: 1, cycleDuration: 4, initialState: [.east:.red,.north:.green], initialElapsedTime: 1)
        var store = Store(state:TrafficLightsState(config:config),reducer:TrafficLightReducer())
        store.dispatch(action: TrafficLightChangeColorAction(position: .north, newColorState: .amber))
        XCTAssert(store.state.state[.north] == .amber)
        XCTAssert(store.state.state[.east] == .red)
    }


    // MARK: - Invalid Config Tests


    func testInvalidAmberDuration() {
        let config = TrafficLightsCoordinatorConfig(amberDuration: 31, cycleDuration: 30, initialState: [.east:.red,.north:.green], initialElapsedTime: 1)
        let coordinator = TrafficLightsCoordinator(config:config)
        XCTAssert(coordinator == nil)
    }

    func testInvalidZeroCycleDuration() {
        let config = TrafficLightsCoordinatorConfig(amberDuration: 0, cycleDuration: 0, initialState: [.east:.red,.north:.green], initialElapsedTime: 1)
        let coordinator = TrafficLightsCoordinator(config:config)
        XCTAssert(coordinator == nil)
    }


    func testMultiGreenCondition() {
        let config = TrafficLightsCoordinatorConfig(amberDuration: 3, cycleDuration: 8, initialState: [.east:.green,.north:.green], initialElapsedTime: 1)
        let coordinator = TrafficLightsCoordinator(config:config)
        XCTAssert(coordinator == nil)
    }

    func testMultiAmberCondition() {
        let config = TrafficLightsCoordinatorConfig(amberDuration: 3, cycleDuration: 8, initialState: [.east:.amber,.north:.amber], initialElapsedTime: 1)
        let coordinator = TrafficLightsCoordinator(config:config)
        XCTAssert(coordinator == nil)
    }

    func testMixedAmberGreenCondition() {
        let config = TrafficLightsCoordinatorConfig(amberDuration: 3, cycleDuration: 8, initialState: [.east:.amber,.north:.green], initialElapsedTime: 1)
        let coordinator = TrafficLightsCoordinator(config:config)
        XCTAssert(coordinator == nil)
    }

    
}


