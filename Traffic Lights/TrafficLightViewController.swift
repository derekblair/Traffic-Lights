//
//  TrafficLightViewController.swift
//  Traffic Lights
//
//  Created by Derek Blair on 2016-12-06.
//
//

import UIKit

final class TrafficLightViewController: UIViewController, TrafficLightPresenter {

    @IBOutlet weak var northLight: UIImageView?
    @IBOutlet weak var eastLight: UIImageView?
    @IBOutlet weak var elapsedTime: UILabel?
    @IBAction func timeTogglePressed(sender: UISwitch) {
        toggleTime?()
    }

    // MARK: TrafficLightPresenter

    var toggleTime: (()->())?

    func present(state: AppState) {
        northLight?.image = state.state[.north]?.image
        eastLight?.image = state.state[.east]?.image
        elapsedTime?.text = "\(state.elapsedTime) s"
    }
}

private extension TrafficLightState {
    var image: UIImage? {
        return UIImage(named: self.rawValue)
    }
}

