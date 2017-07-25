# Traffic Lights

A simple iOS application demonstrating a system of traffic lights.

Inspired by [redux](http://redux.js.org), and focused on testability/modularity.

## Design

1. Outside of the delegate and view controller all code is in `TrafficLights.swift`

2. All application state is encapsulated in the `Store` structure.

3. When the state is changed , subscribers conforming to the `TrafficLightPresenter` protocol are notified and update themselves accordingly. 

4. In the main app this is the view controller, in the testing bundle it is a stub object. This allows for a minimal view controller that only handles UI related tasks and an easily testable set of modular components for the app.

5. The state is updated only by sending `Action` objects to the store. This allows for a clean, functional approach that can easily be debugged and tested.  

6. The business logic for the app is entirely encapsulated in `TrafficLightsCoordinator`, which has no knowledge of `UIKit`. In the main app, this coordinator is created and owned by the delegate. In the testing bundle it is created and tested separately.


