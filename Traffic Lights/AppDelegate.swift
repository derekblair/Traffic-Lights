//
//  AppDelegate.swift
//  Traffic Lights
//
//  Created by Derek Blair on 2016-12-06.
//
//

import UIKit

private let UnitTestingEnvVar = "TrafficTesting"

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    lazy var coordinator: TrafficLightsCoordinator? = {
        let env = ProcessInfo.processInfo.environment
        return env[UnitTestingEnvVar] == nil ? TrafficLightsCoordinator(config:TrafficLightsCoordinatorConfig(launchEnv:env)) : nil
    }()
   

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        coordinator?.start()
        coordinator?.subscribe(presenter: window?.rootViewController as? TrafficLightPresenter)
        return true
    }
}

extension TrafficLightsCoordinatorConfig {
    init(launchEnv: [String:String]) {
        self.amberDuration = 5
        self.cycleDuration  = 30
        self.initialElapsedTime = 0
        self.initialState = [.east:.green,.north:.red]
    }
}

