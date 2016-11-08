//
//  LyftAvailability.swift
//  SFParties
//
//  Created by Genady Okrain on 5/10/16.
//  Copyright © 2016 Okrain. All rights reserved.
//

//  Examples:
//
//  Lyft.requestRideTypes(rideTypesQuery: RideTypesQuery(lat: 37.7833, lng: -122.4167)) { result, response, error in
//
//  }
//
//  Lyft.requestETA(etaQuery: ETAQuery(lat: 37.7833, lng: -122.4167)) { result, response, error in
//
//  }
//
//  Lyft.requestCost(costQuery: CostQuery(startLat: 37.7833, startLng: -122.4167, endLat: 37.7972, endLng: -122.4533)) { result, response, error in
//
//  }
//
//  Lyft.requestNearbyDrivers(nearbyDriversQuery: NearbyDriversQuery(lat: 37.7789, lng: -122.45690)) { result, response, error in
//
//  }

import Foundation

public extension Lyft {
    static func requestRideTypes(rideTypesQuery: RideTypesQuery, completionHandler: ((_ result: [RideTypesResponse]?, _ response: [String: AnyObject]?, _ error: NSError?) -> ())?) {
        request(.GET, path: "/ridetypes", params: ["lat": "\(rideTypesQuery.lat)" as AnyObject, "lng": "\(rideTypesQuery.lng)" as AnyObject, "ride_type": rideTypesQuery.rideType.rawValue as AnyObject]) { response, error in
            var rideTypesResponse = [RideTypesResponse]()
            if let response = response {
                if let rideTypes = response["ride_types"] as? [AnyObject] {
                    for r in rideTypes {
                        if let r = r as? [String: AnyObject],
                            let pricingDetails = r["pricing_details"] as? [String: AnyObject],
                            let baseCharge = pricingDetails["base_charge"] as? Int,
                            let costPerMile = pricingDetails["cost_per_mile"] as? Int,
                            let costPerMinute = pricingDetails["cost_per_minute"] as? Int,
                            let costMinimum = pricingDetails["cost_minimum"] as? Int,
                            let trustAndService = pricingDetails["trust_and_service"] as? Int,
                            let currency = pricingDetails["currency"] as? String ,
                            let cancelPenaltyAmount = pricingDetails["cancel_penalty_amount"] as? Int,
                            let rType = r["ride_type"] as? String,
                            let rideType = RideType(rawValue: rType),
                            let displayName = r["display_name"] as? String,
                            let imageURL = r["image_url"] as? String,
                            let seats = r["seats"] as? Int {
                            let pricingDetails = PricingDetails(baseCharge: baseCharge,
                                                                costPerMile: costPerMile,
                                                                costPerMinute: costPerMinute,
                                                                costMinimum: costMinimum,
                                                                trustAndService: trustAndService,
                                                                currency: currency,
                                                                cancelPenaltyAmount: cancelPenaltyAmount)
                            rideTypesResponse.append(
                                RideTypesResponse(
                                    pricingDetails: pricingDetails,
                                    rideType: rideType,
                                    displayName: displayName,
                                    imageURL: imageURL,
                                    seats: seats
                                )
                            )
                        }
                    }
                }
            }
            completionHandler?(rideTypesResponse, response, error)
        }
    }

    static func requestETA(etaQuery: ETAQuery, completionHandler: ((_ result: [ETAEstimate]?, _ response: [String: AnyObject]?, _ error: NSError?) -> ())?) {
        request(.GET, path: "/eta", params: ["lat": "\(etaQuery.lat)" as AnyObject, "lng": "\(etaQuery.lng)" as AnyObject, "ride_type": etaQuery.rideType.rawValue as AnyObject]) { response, error in
            var etaEstimatesResponse = [ETAEstimate]()
            if let response = response {
                if let etaEstimates = response["eta_estimates"] as? [AnyObject] {
                    for e in etaEstimates {
                        if let e = e as? [String: AnyObject],
                            let displayName = e["display_name"] as? String,
                            let rType = e["ride_type"] as? String,
                            let rideType = RideType(rawValue: rType),
                            let etaSeconds = e["eta_seconds"] as? Int {
                            etaEstimatesResponse.append(
                                ETAEstimate(
                                    displayName: displayName,
                                    rideType: rideType,
                                    etaSeconds: etaSeconds
                                )
                            )
                        }
                    }
                }
            }
            completionHandler?(etaEstimatesResponse, response, error)
        }
    }

    static func requestCost(costQuery: CostQuery, completionHandler: ((_ result: [CostEstimate]?, _ response: [String: AnyObject]?, _ error: NSError?) -> ())?) {
        request(.GET, path: "/cost", params: [
            "start_lat": "\(costQuery.startLat)" as AnyObject,
            "start_lng": "\(costQuery.startLng)" as AnyObject,
            "end_lat": costQuery.endLat == 0 ? "" as AnyObject : "\(costQuery.endLat)" as AnyObject,
            "end_lng": costQuery.endLng == 0 ? "" as AnyObject : "\(costQuery.endLng)" as AnyObject,
            "ride_type": costQuery.rideType.rawValue as AnyObject]
        ) { response, error in
            var costEstimateResponse = [CostEstimate]()
            if let response = response {
                if let costEstimates = response["cost_estimates"] as? [AnyObject] {
                    for c in costEstimates {
                        if let c = c as? [String: AnyObject],
                            let rType = c["ride_type"] as? String,
                            let rideType = RideType(rawValue: rType),
                            let displayName = c["display_name"] as? String,
                            let currency = c["currency"] as? String,
                            let estimatedCostCentsMin = c["estimated_cost_cents_min"] as? Int,
                            let estimatedCostCentsMax = c["estimated_cost_cents_max"] as? Int,
                            let estimatedDurationSeconds = c["estimated_duration_seconds"] as? Int,
                            let estimatedDistanceMiles = c["estimated_distance_miles"] as? Float,
                            let primetimePercentage = c["primetime_percentage"] as? String {
                            costEstimateResponse.append(
                                CostEstimate(
                                    rideType: rideType,
                                    displayName: displayName,
                                    currency: currency,
                                    estimatedCostCentsMin: estimatedCostCentsMin,
                                    estimatedCostCentsMax: estimatedCostCentsMax,
                                    estimatedDurationSeconds: estimatedDurationSeconds,
                                    estimatedDistanceMiles: estimatedDistanceMiles,
                                    primetimeConfirmationToken: c["primetime_confirmation_token"] as? String,
                                    primetimePercentage: primetimePercentage
                                )
                            )
                        }
                    }
                }
            }
            completionHandler?(costEstimateResponse, response, error)
        }
    }

    static func requestNearbyDrivers(nearbyDriversQuery: NearbyDriversQuery, completionHandler: ((_ result: [NearbyDrivers]?, _ response: [String: AnyObject]?, _ error: NSError?) -> ())?) {
        request(.GET, path: "/drivers", params: ["lat": "\(nearbyDriversQuery.lat)" as AnyObject, "lng": "\(nearbyDriversQuery.lng)" as AnyObject]) { response, error in
            var nearbyDriversResponse = [NearbyDrivers]()
            if let response = response {
                if let nearbyDrivers = response["nearby_drivers"] as? [AnyObject] {
                    for n in nearbyDrivers {
                        if let driver = n["drivers"] as? [AnyObject] {
                            var drivers = [Driver]()
                            for d in driver {
                                var locs = [Location]()
                                if let locations = d["locations"] as? [AnyObject] {
                                    for l in locations {
                                        if let l = l as? [String: AnyObject], let lat = l["lat"] as? Float, let lng = l["lng"] as? Float {
                                            locs.append(Location(lat: lat, lng: lng))
                                        }
                                    }
                                }
                                drivers.append(Driver(locations: locs))
                            }
                            if let rType = n["ride_type"] as? String,
                                let rideType = RideType(rawValue: rType) {
                                nearbyDriversResponse.append(NearbyDrivers(drivers: drivers, rideType: rideType))
                            }
                        }
                    }
                }
            }
            completionHandler?(nearbyDriversResponse, response, error)
        }
    }
}
