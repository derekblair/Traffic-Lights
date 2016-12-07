//
//  TrafficLights.swift
//  Traffic Lights
//
//  Created by Derek Blair on 2016-12-06.
//
//

import Foundation


// MARK: Groundwork Types/Protocols

enum TrafficLightState : String {
    case green
    case amber
    case red
}

enum TrafficLightPosition {
    case east
    case north

    /// Determines which light turns green next.
    var next : TrafficLightPosition {
        return self == .east ? .north : .east
    }
}

protocol AppState  {
    var state : [TrafficLightPosition:TrafficLightState] {get set}
    var elapsedTime : UInt64 {get set}
}


extension AppState {
    var activePosition : TrafficLightPosition? {
        return state.keys.filter {self.state[$0] != .red}.first
    }
}

protocol TrafficLightPresenter : class {
    func present(state:AppState)
    var toggleTime : (()->())? {get set}
}

protocol Action {}
protocol Reducer {
    func handleAction(action: Action, state: AppState) -> AppState
}

protocol Coordinator {
    // Must be always called first.
    func start()
}


// MARK: Store/AppState

struct TrafficLightsState : AppState {
    var state : [TrafficLightPosition:TrafficLightState]
    var elapsedTime : UInt64

    init(config:TrafficLightsCoordinatorConfig) {
        state = config.initialState
        elapsedTime = config.initialElapsedTime
    }
}

struct Store {
    var state : AppState {
        didSet {
            notifyListeners()
        }
    }
    private let _reducer : Reducer


    init(state:AppState,reducer:Reducer) {
        self.state = state
        _reducer = reducer
    }


    private var listeners = NSHashTable<AnyObject>.weakObjects()
    func subscribe(presenter:TrafficLightPresenter?) {
        guard let presenter = presenter else { return }
        listeners.add(presenter)
        presenter.present(state: self.state)
    }

    func unsubscribe(presenter:TrafficLightPresenter?) {
        guard let presenter = presenter else { return }
        listeners.remove(presenter)
    }

    private func notifyListeners() {
        listeners.objectEnumerator().forEach {($0 as? TrafficLightPresenter)?.present(state: self.state)}
    }


    mutating func dispatch(action:Action) {
        state = _reducer.handleAction(action: action, state: state)
    }

}


// MARK: Reducer

struct TrafficLightReducer : Reducer {
    func handleAction(action: Action, state: AppState) -> AppState {
        var result = state
        switch action {
        case let changeColorAction as TrafficLightChangeColorAction:
            state.state.forEach {
                if $0.0 == changeColorAction.position {
                    result.state[$0.0] = changeColorAction.newColorState
                } else {
                    result.state[$0.0] = .red
                }
            }
        case let incAction as TrafficLightIncrementTimeAction:
             result.elapsedTime = ((result.elapsedTime+1) % incAction.cycle)
        default:
            break
        }
        return result
    }
}


// MARK: Actions


struct TrafficLightChangeColorAction : Action {
    var position : TrafficLightPosition
    var newColorState : TrafficLightState
}

struct TrafficLightIncrementTimeAction : Action {
    var cycle : UInt64
}

// MARK: TrafficLightsCoordinator

struct TrafficLightsCoordinatorConfig {
    var amberDuration : UInt64
    var cycleDuration : UInt64

    var initialState : [TrafficLightPosition:TrafficLightState]
    var initialElapsedTime : UInt64


    var areMultipleLightsNonRed : Bool {
        return Array(initialState.keys).filter {self.initialState[$0] != .red}.count > 1
    }
}


class TrafficLightsCoordinator : Coordinator {

    private let _config : TrafficLightsCoordinatorConfig
    private var _timer : Timer?


    deinit {
        pause()
    }

    init?(config:TrafficLightsCoordinatorConfig) {
        guard config.cycleDuration > 0 else {
            debugPrint("Must provide a non-zero cycle length.")
            return nil
        }
        guard config.amberDuration < config.cycleDuration else {
            debugPrint("Must provide an amber duration that is less than the total cycle.")
             return nil
        }
        guard !config.areMultipleLightsNonRed else {
            debugPrint("Illegal initial configuration. Only a maximum of 1 light can be non-red.")
             return nil
        }
        _config = config
        _store = Store(state:TrafficLightsState(config:config),reducer:TrafficLightReducer())
    }

    func pause() {
        _timer?.invalidate()
        _timer = nil
    }

    func resume() {
        _timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {[weak self] timer in
            self?.tick()
        }
    }

    func unsubscribe(presenter:TrafficLightPresenter?) {
        _store.unsubscribe(presenter: presenter)
    }

    func subscribe(presenter:TrafficLightPresenter?) {
        _store.subscribe(presenter: presenter)
        presenter?.toggleTime = {[weak self] _ in
            if self?._timer == nil {
                self?.resume()
            } else {
                self?.pause()
            }
        }
    }

    func start() {
        resume()
        tick(firstTime: true)
    }

    /// The actual business logic is found here for the application.
    func tick(firstTime : Bool = false) {
        //increment the timer
        if !firstTime {
            self._store.dispatch(action: TrafficLightIncrementTimeAction(cycle:(self._config.cycleDuration)))
        }
        let state = self._store.state
        if let activePos = state.activePosition {
            // There is a non-red light.

            if state.elapsedTime == 0 && !firstTime  {
                // dispatch action to turn the next light green
                self._store.dispatch(action: TrafficLightChangeColorAction(position:activePos.next,newColorState:.green))
            } else if state.elapsedTime == (self._config.cycleDuration-self._config.amberDuration)  {
                // dispatch action to turn yellow.
                self._store.dispatch(action: TrafficLightChangeColorAction(position:activePos,newColorState:.amber))
            }
        }
    }

    private var _store : Store
}

