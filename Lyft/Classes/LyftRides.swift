//
//  LyftRides.swift
//  SFParties
//
//  Created by Genady Okrain on 5/10/16.
//  Copyright © 2016 Okrain. All rights reserved.
//

//  Examples:
//
//  Lyft.requestRide(requestRideQuery: RequestRideQuery(originLat: 34.305658, originLng: -118.8893667, originAddress: "123 Main St, Anytown, CA", destinationLat: 36.9442175, destinationLng: -123.8679133, destinationAddress: "123 Main St, Anytown, CA", rideType: .Lyft)) { result, response, error in
//
//  }
//
//  Lyft.requestRideDetails(rideId: "123456789") { result, response, error in
//
//  }
//
//  Lyft.cancelRide(rideId: "123456789") { result, response, error in
//
//  }
//
//  Lyft.rateAndTipRide(rideId: "123456789", rateAndTipQuery: RateAndTipQuery(rating: 5, tipAmount: 100, tipCurrency: "USA", feedback: "great ride!")  { result, response, error in
//
//  }
//
//  Lyft.requestRideReceipt(rideId: "123456789") { result, response, error in
//
//  }
//
//  Lyft.requestRidesHistory(ridesHistoryQuery: RidesHistoryQuery(startTime: "2015-12-01T21:04:22Z", endTime: "2015-12-04T21:04:22Z", limit: "10")) { result, response, error in
//
//  }

import Foundation

public extension Lyft {
    static func requestRide(requestRideQuery: RequestRideQuery, completionHandler: ((_ result: Ride?, _ response: [String: AnyObject]?, _ error: NSError?) -> ())?) {
        request(.POST, path: "/rides", params: [
            "origin": ["lat": "\(requestRideQuery.origin.lat)", "lng": "\(requestRideQuery.origin.lng)", "address": "\(requestRideQuery.origin.address)"] as AnyObject,
            "destination": ["lat": "\(requestRideQuery.destination.lat)", "lng": "\(requestRideQuery.destination.lng)", "address": "\(requestRideQuery.destination.address)"] as AnyObject,
            "ride_type": requestRideQuery.rideType.rawValue as AnyObject,
            "primetime_confirmation_token": requestRideQuery.primetimeConfirmationToken as AnyObject]
        ) { response, error in
            if let response = response {
                if let passenger = response["passenger"] as? [String: AnyObject],
                    let passengerFirstName = passenger["first_name"] as? String,
                    let origin = response["origin"] as? [String: AnyObject],
                    let originAddress = origin["address"] as? String,
                    let originLat = origin["lat"] as? Float,
                    let originLng = origin["lng"] as? Float,
                    let destination = response["destination"] as? [String: AnyObject],
                    let destinationAddress = destination["address"] as? String,
                    let destinationLat = destination["lat"] as? Float,
                    let destinationLng = destination["lng"] as? Float,
                    let s = response["status"] as? String,
                    let status = StatusType(rawValue: s),
                    let rideId = response["ride_id"] as? String  {
                    let origin = Address(lat: originLat, lng: originLng, address: originAddress)
                    let destination = Address(lat: destinationLat, lng: destinationLng, address: destinationAddress)
                    let passenger = Passenger(firstName: passengerFirstName)
                    let ride = Ride(rideId: rideId, status: status, origin: origin, destination: destination, passenger: passenger)
                    completionHandler?(ride, response, nil)
                    return
                }
            }
            completionHandler?(nil, response, error)
        }
    }

    static func requestRideDetails(rideId: String, completionHandler: ((_ result: Ride?, _ response: [String: AnyObject]?, _ error: NSError?) -> ())?) {
        request(.GET, path: "/rides/\(rideId)", params: nil) { response, error in
            if let response = response {
                if let passenger = response["passenger"] as? [String: AnyObject],
                    let firstName = passenger["first_name"] as? String,
                    let origin = response["origin"] as? [String: AnyObject],
                    let originAddress = origin["address"] as? String,
                    let originLat = origin["lat"] as? Float,
                    let originLng = origin["lng"] as? Float,
                    let destination = response["destination"] as? [String: AnyObject],
                    let destinationAddress = destination["address"] as? String,
                    let destinationLat = destination["lat"] as? Float,
                    let destinationLng = destination["lng"] as? Float,
                    let s = response["status"] as? String,
                    let status = StatusType(rawValue: s),
                    let rideId = response["ride_id"] as? String  {
                    let origin = Address(lat: originLat, lng: originLng, address: originAddress)
                    let destination = Address(lat: destinationLat, lng: destinationLng, address: destinationAddress)
                    let passenger = Passenger(firstName: firstName)
                    let ride = Ride(rideId: rideId, status: status, origin: origin, destination: destination, passenger: passenger)
                    completionHandler?(ride, response, nil)
                    return
                }
            }
            completionHandler?(nil, response, error)
        }
    }

    static func cancelRide(rideId: String, cancelConfirmationToken: String? = nil, completionHandler: ((_ result: CancelConfirmationToken?, _ response: [String: AnyObject]?, _ error: NSError?) -> ())?) {
        request(.POST, path: "/rides/\(rideId)/cancel", params: (cancelConfirmationToken != nil) ? (["cancel_confirmation_token": cancelConfirmationToken!] as AnyObject) as? [String : AnyObject] : nil) { response, error in
            if let response = response {
                if let amount = response["amount"] as? Int,
                    let currency = response["currency"] as? String,
                    let token = response["token"] as? String,
                    let tokenDuration = response["token_duration"] as? Int {
                    completionHandler?(CancelConfirmationToken(amount: amount, currency: currency, token: token, tokenDuration: tokenDuration), response, nil)
                    return
                }
            }
            completionHandler?(nil, response, error)
        }
    }

  static func rateAndTipRide(rideId: String, rateAndTipQuery: RateAndTipQuery, completionHandler: ((_ result: AnyObject?, _ response: [String: AnyObject]?, _ error: NSError?) -> ())?) {
        request(.PUT, path: "/rides/\(rideId)/rating", params: [
            "rating": rateAndTipQuery.rating as AnyObject,
            "tip": ["amount": rateAndTipQuery.tip.amount, "currency": rateAndTipQuery.tip.currency] as AnyObject,
            "feedback": rateAndTipQuery.feedback as AnyObject])
        { response, error in
            completionHandler?(nil, response, error)
        }
    }

    static func requestRideReceipt(rideId: String, completionHandler: ((_ result: RideReceipt?, _ response: [String: AnyObject]?, _ error: NSError?) -> ())?) {
        request(.GET, path: "/rides/\(rideId)/receipt", params: nil) { response, error in
            if let response = response {
                if let rideId = response["ride_id"] as? String,
                    let price = response["price"] as? [String: AnyObject],
                    let priceAmount = price["amount"] as? Int,
                    let priceCurrency = price["currency"] as? String,
                    let priceDescription = price["description"] as? String,
                    let lineItems = response["line_items"] as? [AnyObject],
                    let charges = response["charges"] as? [AnyObject],
                    let requestedAt = response["requested_at"] as? String {
                    var l = [LineItem]()
                    for lineItem in lineItems {
                        if let amount = lineItem["amount"] as? Int, let currency = lineItem["currency"] as? String, let type = lineItem["type"] as? String {
                            l.append(LineItem(amount: amount, currency: currency, type: type))
                        }
                    }
                    var c = [Charge]()
                    for charge in charges {
                        if let amount = charge["amount"] as? Int, let currency = charge["currency"] as? String, let paymentMethod = charge["payment_method"] as? String {
                            c.append(Charge(amount: amount, currency: currency, paymentMethod: paymentMethod))
                        }
                    }
                    let price = Price(amount: priceAmount, currency: priceCurrency, description: priceDescription)
                    completionHandler?(RideReceipt(rideId: rideId, price: price, lineItems: l, charge: c, requestedAt: requestedAt), response, nil)
                    return
                }
            }
            completionHandler?(nil, response, error)
        }
    }

    static func requestRidesHistory(ridesHistoryQuery: RidesHistoryQuery, completionHandler: ((_ result: [RideHistory]?, _ response: [String: AnyObject]?, _ error: NSError?) -> ())?) {
        request(.GET, path: "/rides", params: ["start_time": ridesHistoryQuery.startTime as AnyObject, "end_time": ridesHistoryQuery.endTime as AnyObject, "limit": ridesHistoryQuery.limit as AnyObject])
        { response, error in
            var ridesHistory = [RideHistory]()
            if let response = response, let rideHistory = response["ride_history"] as? [AnyObject] {
                for r in rideHistory {
                    if let rideId = r["ride_id"] as? String,
                        let s = r["status"] as? String,
                        let status = StatusType(rawValue: s),
                        let rType = r["ride_type"] as? String,
                        let rideType = RideType(rawValue: rType),
                        let passenger = r["passenger"] as? [String: AnyObject],
                        let passengerFirstName = passenger["first_name"] as? String,
                        let driver = r["driver"] as? [String: AnyObject],
                        let driverFirstName = driver["first_name"] as? String,
                        let driverPhoneNumber = driver["phone_number"] as? String,
                        let driverRating = driver["rating"] as? Float,
                        let driverImageURL = driver["image_url"] as? String,
                        let vehicle = r["vehicle"] as? [String: AnyObject],
                        let vehicleMake = vehicle["make"] as? String,
                        let vehicleModel = vehicle["model"] as? String,
                        let vehicleLicensePlate = vehicle["license_plate"] as? String,
                        let vehicleCode = vehicle["color"] as? String,
                        let vehicleImageURL = vehicle["image_url"] as? String,
                        let origin = r["origin"] as? [String: AnyObject],
                        let originLat = origin["lat"] as? Float,
                        let originLng = origin["lng"] as? Float,
                        let originAddress = origin["address"] as? String,
                        let originETASeconds = origin["eta_seconds"] as? Int,
                        let destination = r["destination"] as? [String: AnyObject],
                        let destinationLat = destination["lat"] as? Float,
                        let destinationLng = destination["lng"] as? Float,
                        let destinationAddress = destination["address"] as? String,
                        let destinationETASeconds = destination["eta_seconds"] as? Int,
                        let pickup = r["pickup"] as? [String: AnyObject],
                        let pickupLat = pickup["lat"] as? Float,
                        let pickupLng = pickup["lng"] as? Float,
                        let pickupAddress = pickup["address"] as? String,
                        let pickupTime = pickup["time"] as? String,
                        let dropoff = r["dropoff"] as? [String: AnyObject],
                        let dropoffLat = dropoff["lat"] as? Float,
                        let dropoffLng = dropoff["lng"] as? Float,
                        let dropoffAddress = dropoff["address"] as? String,
                        let dropoffTime = dropoff["time"] as? String,
                        let location = r["location"] as? [String: AnyObject],
                        let locationLat = location["lat"] as? Float,
                        let locationLng = location["lng"] as? Float,
                        let locationAddress = location["address"] as? String,
                        let primetimePercentage = r["primetime_percentage"] as? String,
                        let price = r["price"] as? [String: AnyObject],
                        let priceAmount = price["amount"] as? Int,
                        let priceCurrency = price["currency"] as? String,
                        let priceDescription = price["description"] as? String,
                        let lineItems = r["line_items"] as? [AnyObject],
                        let ETASeconds = r["eta_seconds"] as? Int,
                        let requestedAt = r["requested_at"] as? String {
                        let passenger = Passenger(firstName: passengerFirstName)
                        let driver = Driver(firstName: driverFirstName, phoneNumber: driverPhoneNumber, rating: driverRating, imageURL: driverImageURL)
                        let vehicle = Vehicle(make: vehicleMake, model: vehicleModel, licensePlate: vehicleLicensePlate, color: vehicleCode, imageURL: vehicleImageURL)
                        let origin = Address(lat: originLat, lng: originLng, address: originAddress, ETASeconds: originETASeconds)
                        let destination = Address(lat: destinationLat, lng: destinationLng, address: destinationAddress, ETASeconds: destinationETASeconds)
                        let pickup = Address(lat: pickupLat, lng: pickupLng, address: pickupAddress, time: pickupTime)
                        let dropoff = Address(lat: dropoffLat, lng: dropoffLng, address: dropoffAddress, time: dropoffTime)
                        let location = Address(lat: locationLat, lng: locationLng, address: locationAddress)
                        let price = Price(amount: priceAmount, currency: priceCurrency, description: priceDescription)
                        var l = [LineItem]()
                        for lineItem in lineItems {
                            if let amount = lineItem["amount"] as? Int, let currency = lineItem["currency"] as? String, let type = lineItem["type"] as? String {
                                l.append(LineItem(amount: amount, currency: currency, type: type))
                            }
                        }
                        let rideHistory = RideHistory(rideId: rideId, status: status, rideType: rideType, passenger: passenger, driver: driver, vehicle: vehicle, origin: origin, destination: destination, pickup: pickup, dropoff: dropoff, location: location, primetimePercentage: primetimePercentage, price: price, lineItems: l, ETAseconds: ETASeconds, requestedAt: requestedAt)
                        ridesHistory.append(rideHistory)
                    }
                }
            }
            completionHandler?(ridesHistory, response, error)
        }
    }
}
