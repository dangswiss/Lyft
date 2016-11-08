//
//  LyftOAuth.swift
//  SFParties
//
//  Created by Genady Okrain on 5/11/16.
//  Copyright © 2016 Okrain. All rights reserved.
//

import Foundation

public extension Lyft {
    // Initialize clientId & clientSecret
    static func set(clientId: String, clientSecret: String, sandbox: Bool? = nil) {
        sharedInstance.clientId = clientId
        sharedInstance.clientSecret = clientSecret
        sharedInstance.sandbox = sandbox ?? false
    }

    // 3-Legged flow for accessing user-specific endpoints
    static func userLogin(scope: String, state: String = "", completionHandler: ((_ success: Bool, _ error: NSError?) -> ())?) {
        guard let clientId = sharedInstance.clientId, let _ = sharedInstance.clientSecret else { return }

        let string = "\(lyftAPIOAuthURL)/authorize?client_id=\(clientId)&response_type=code&scope=\(scope)&state=\(state)"

        sharedInstance.completionHandler = completionHandler

        if let url = URL(string: string.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!) {
            UIApplication.shared.openURL(url)
        }
    }

    // Client Credentials (2-legged) flow for public endpoints
    static func publicLogin(_ completionHandler: ((_ success: Bool, _ error: NSError?) -> ())?) {
        guard let _ = sharedInstance.clientId, let _ = sharedInstance.clientSecret else { return }

        sharedInstance.completionHandler = completionHandler

        fetchAccessToken(nil)
    }

    // Refreshing the access token
    static func refreshToken(_ completionHandler: ((_ success: Bool, _ error: NSError?) -> ())?) {
        guard let _ = sharedInstance.clientId, let _ = sharedInstance.clientSecret else { return }

        sharedInstance.completionHandler = completionHandler

        fetchAccessToken(nil, refresh: true)
    }

    // Revoking the access token
    static func revokeToken(_ completionHandler: ((_ success: Bool, _ error: NSError?) -> ())?) {
        guard let _ = sharedInstance.clientId, let _ = sharedInstance.clientSecret else { return }

        sharedInstance.completionHandler = completionHandler

        fetchAccessToken(nil, refresh: false, revoke: true)
    }

    // func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool
    static func openURL(_ url: URL) -> Bool {
        guard let _ = sharedInstance.clientId, let _ = sharedInstance.clientSecret else { return false }
        guard let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.filter({ $0.name == "code" }).first?.value else { return false }

        fetchAccessToken(code)
        
        return true
    }
}
