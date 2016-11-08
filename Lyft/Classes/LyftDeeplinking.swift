//
//  LyftDeeplinking.swift
//  SFParties
//
//  Created by Genady Okrain on 5/11/16.
//  Copyright © 2016 Okrain. All rights reserved.
//

// Examples:
//
//  Lyft.openLyftRide(rideType: .Line, destination: Address(lat: 37.7763592, lng: -122.4242038))

import Foundation

public extension Lyft {
    static func openLyftRide(rideType: RideType, pickup: Address? = nil, destination: Address) {
        let url: String
        if let pickup = pickup {
            url = "lyft://ridetype?id=\(rideType.rawValue)&pickup[latitude]=\(pickup.lat)&pickup[longitude]=\(pickup.lng)&destination[latitude]=\(destination.lat)&destination[longitude]=\(destination.lng)"
        } else {
            url = "lyft://ridetype?id=\(rideType.rawValue)&destination[latitude]=\(destination.lat)&destination[longitude]=\(destination.lng)"
        }

        if let url = URL(string: url) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.openURL(url)
            } else if let url = URL(string: "https://itunes.apple.com/us/app/lyft-taxi-bus-app-alternative/id529379082") {
                UIApplication.shared.openURL(url)
            }
        }
    }

    static func openLyftPromo(_ promoCode: String) {
        let url = "lyft://payment?credits=\(promoCode)"

        if let url = URL(string: url) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.openURL(url)
            } else if let url = URL(string: "https://itunes.apple.com/us/app/lyft-taxi-bus-app-alternative/id529379082") {
                UIApplication.shared.openURL(url)
            }
        }
    }
}
