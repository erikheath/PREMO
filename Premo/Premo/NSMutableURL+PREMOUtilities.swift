//
//  NSMutableURL+PREMOUtilities.swift
//  Premo
//
//  Created by ERIKHEATH A THOMAS on 1/16/16.
//  Copyright © 2016 Premo Network. All rights reserved.
//

import Foundation

extension NSMutableURLRequest {

    enum PREMOURLRequestError: Int, ErrorType {
        case unknownError = 5000
        case credentialError = 5001
        case creationError = 5002
        case missingAuthorizationToken = 5003
        case invalidJSONObject = 5004

        var objectType : NSError {
            get {
                return NSError(domain: "PREMOURLRequestError", code: self.rawValue, userInfo: nil)
            }
        }

        var description: String {
            var errorString: String = ""
            switch self._code {
            case 5000:
                errorString = "Unknown Error"
            case 5001:
                errorString = "Credential Error"
            case 5002:
                errorString = "Creation Error"
            case 5003:
                errorString = "Missing Authorization Token Error"
            case 5004:
                errorString = "Invalid JSON Object Error"
            default:
                errorString = "Unknown Error"
            }
            return errorString
        }
    }

    enum PREMORequestMethod: String {
        case POST = "POST"
        case GET = "GET"
    }

    static func PREMOURLRequest(urlPath: String, method: PREMORequestMethod?, HTTPBody: AnyObject?, authorizationRequired: Bool) throws -> NSMutableURLRequest {

        guard let PREMOURL = NSURL(string: urlPath, relativeToURL: AppDelegate.PREMOURL) else {
            throw PREMOURLRequestError.creationError
        }

        let urlRequest = NSMutableURLRequest(URL: PREMOURL, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 45.0)

        urlRequest.setValue("application/JSON", forHTTPHeaderField: "Content-Type")

        if let _ = method { urlRequest.HTTPMethod = method!.rawValue }

        if authorizationRequired == true {
            guard let _ = Account.authorizationToken else {
                throw PREMOURLRequestError.missingAuthorizationToken
            }
            urlRequest.setValue(Account.authorizationToken, forHTTPHeaderField: "Authorization")
        }

        if HTTPBody != nil {
            do {
                guard NSJSONSerialization.isValidJSONObject(HTTPBody!) == true else { throw PREMOURLRequestError.invalidJSONObject }
                let JSONBodyData: NSData = try NSJSONSerialization.dataWithJSONObject(HTTPBody!, options: NSJSONWritingOptions.init(rawValue: 0))
                urlRequest.HTTPBody = JSONBodyData
            } catch { throw error }
        }

        return urlRequest
    }

}