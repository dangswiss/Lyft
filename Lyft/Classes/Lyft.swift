//
//  Lyft.swift
//  SFParties
//
//  Created by Genady Okrain on 5/3/16.
//  Copyright © 2016 Okrain. All rights reserved.
//

import Foundation

public enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
}

open class Lyft {
    static let sharedInstance = Lyft()
    static let lyftAPIURL = "https://api.lyft.com"
    static let lyftAPIOAuthURL = "\(lyftAPIURL)/oauth"
    static let lyftAPIv1URL = "\(lyftAPIURL)/v1"
    internal var clientId: String?
    internal var clientSecret: String?
    internal var sandbox = false
    internal var completionHandler: ((_ success: Bool, _ error: NSError?) -> ())?
    fileprivate var accessToken: String?
    var refreshToken: String?

    internal static func fetchAccessToken(_ code: String?, refresh: Bool = false, revoke: Bool = false) {
        guard let clientId = sharedInstance.clientId, let clientSecret = sharedInstance.clientSecret else {
            sharedInstance.completionHandler?(false, NSError(domain: "No clientId and clientSecret", code: 500, userInfo: nil))
            return
        }

        let u: String
        if revoke == true {
            u = "\(lyftAPIOAuthURL)/revoke_refresh_token"
        } else {
            u = "\(lyftAPIOAuthURL)/token"
        }

        if let url = URL(string: u) {
            let urlRequest = NSMutableURLRequest(url: url)
            let sessionConfiguration = URLSessionConfiguration.default
            urlRequest.httpMethod = HTTPMethod.POST.rawValue
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

            // Auth
            let authString: String
            if sharedInstance.sandbox == true {
                authString = "\(clientId):SANDBOX-\(clientSecret)"
            } else {
                authString = "\(clientId):\(clientSecret)"
            }
            let authData = authString.data(using: String.Encoding.utf8)
            if let authBase64 = authData?.base64EncodedString(options: []) {
                sessionConfiguration.httpAdditionalHeaders = ["Authorization" : "Basic \(authBase64)"]
            }

            do {
                let body: Data
                if let code = code {
                    body = try JSONSerialization.data(withJSONObject: ["grant_type": "authorization_code", "code": code], options: [])
                } else if let refreshToken = sharedInstance.refreshToken , refresh == true {
                    body = try JSONSerialization.data(withJSONObject: ["grant_type": "refresh_token", "refresh_token": refreshToken], options: [])
                } else if let refreshToken = sharedInstance.refreshToken  , revoke == true {
                    body = try JSONSerialization.data(withJSONObject: ["token": refreshToken], options: [])
                } else {
                    body = try JSONSerialization.data(withJSONObject: ["grant_type": "client_credentials", "scope": "public"], options: [])
                }
                urlRequest.httpBody = body

                let session = URLSession(configuration: sessionConfiguration)
                let task = session.dataTask(with: urlRequest as URLRequest, completionHandler: { data, response, error in
                    if let data = data {
                        do {
                            if let response = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject], let accessToken = response["access_token"] as? String {
                                sharedInstance.accessToken = accessToken
                                sharedInstance.refreshToken = response["refresh_token"] as? String
                                sharedInstance.completionHandler?(true, error as NSError?)
                                return
                            } else {
                                sharedInstance.completionHandler?(false, NSError(domain: "No access_token", code: 502, userInfo: nil))
                                return
                            }
                        } catch {
                            sharedInstance.completionHandler?(false, NSError(domain: "Response JSON Serialization Failed", code: 503, userInfo: nil))
                            return
                        }
                    } else {
                        sharedInstance.completionHandler?(false, NSError(domain: "data == nil", code: 504, userInfo: nil))
                        return
                    }
                }) 
                task.resume()
            } catch {
                sharedInstance.completionHandler?(false, NSError(domain: "Body JSON Serialization Failed", code: 505, userInfo: nil))
                return
            }
        }
    }

    open static func request(_ type: HTTPMethod, path: String, params: [String: AnyObject]?, completionHandler: ((_ response: [String: AnyObject]?, _ error: NSError?) -> ())?) {
        guard let accessToken = sharedInstance.accessToken else {
            completionHandler?(nil, NSError(domain: "No clientId and clientSecret", code: 500, userInfo: nil))
            return
        }

        var p = lyftAPIv1URL + path
        if let params = params as? [String: String] , type == .GET {
            p += urlQueryString(params: params)
        }

        if let url = URL(string: p) {
            let urlRequest = NSMutableURLRequest(url: url)
            let sessionConfiguration = URLSessionConfiguration.default
            sessionConfiguration.httpAdditionalHeaders = ["Authorization": "Bearer \(accessToken)"]
            urlRequest.httpMethod = type.rawValue
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

            do {
                if let params = params  , type == .POST || type == .PUT {
                    let body = try JSONSerialization.data(withJSONObject: params, options: [])
                    urlRequest.httpBody = body
                }

                let session = URLSession(configuration: sessionConfiguration)
                let task = session.dataTask(with: urlRequest as URLRequest, completionHandler: { data, response, error in
                    if let data = data {
                        if data.count == 0 {
                            completionHandler?([:], error as NSError?)
                            return
                        } else {
                            do {
                                if let response = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject] {
                                    completionHandler?(response, error as NSError?)
                                    return
                                } else {
                                    completionHandler?(nil, NSError(domain: "No response", code: 502, userInfo: nil))
                                    return
                                }
                            } catch {
                                completionHandler?(nil, NSError(domain: "Response JSON Serialization Failed", code: 503, userInfo: nil))
                                return
                            }
                        }
                    } else {
                        completionHandler?(nil, NSError(domain: "data == nil", code: 504, userInfo: nil))
                        return
                    }
                }) 
                task.resume()
            } catch {
                completionHandler?(nil, NSError(domain: "Body JSON Serialization Failed", code: 505, userInfo: nil))
                return
            }
        }
    }

    // MARK: Helper functions

    fileprivate static func urlQueryString(params: [String: String]) -> String {
        var vars = [String]()
        for (key, value) in params {
            if let encodedValue = value.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) , value != "" {
                vars.append(key + "=" + encodedValue)
            }
        }
        return vars.isEmpty ? "" : "?" + vars.joined(separator: "&")
    }
}
