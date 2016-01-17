//
//  RegistrationProcessor.swift
//

import Foundation
import StoreKit


final class RegistrationProcessor: NSObject, NSURLSessionDelegate, NSURLSessionDataDelegate {

    /**
     Registration errors that can be thrown by the registration object.
     */
    enum RegistrationError: Int, ErrorType {
        case unknownError = 5000
        case receiptError = 5001
        case creationError = 5002
        case responseError = 5003
        case requestError = 5400
        case credentialError = 5401
        case serverError = 5500


        var objectType : NSError {
            get {
                return NSError(domain: "RegistrationError", code: self.rawValue, userInfo: nil)
            }
        }

        var description: String {
            var errorString: String = ""
            switch self._code {
            case 5000:
                errorString = "Unknown Error"
            case 5001:
                errorString = "Receipt Error"
            case 5002:
                errorString = "Creation Error"
            case 5003:
                errorString = "Response Error"
            case 5400:
                errorString = "Request Error"
            case 5401:
                errorString = "Credential Error"
            case 5500:
                errorString = "Server Error"
            default:
                errorString = "Unknown Error"
            }
            return errorString
        }
    }

    /**
     The url path used for all premo registration requests
     */
     let registrationPath = "/api/v1/subscription/receipt"

    /**
     This enumeration provides the keys for registration status notifications dispatched by a RegistrationProcessor object.
     */
    enum RegistrationStatusNotification: String {
        case registering = "RegistrationProcessingNotification"
        case registered = "RegistrationCompleteNotification"
        case failed = "RegistrationFailedNotification"
        case unknown = "RegistrationUnknownErrorNotification"
        case receiptError = "ReceiptProcessingErrorNotification"
        case communicationError = "ServerCommunicationError"
        case registrationRequestError = "RegistrationRequestError"
        case registrationCredentialError = "RegistrationCredentialError"
        case registrationResponseError = "RegistrationResponseError"
        case transactionRequestError = "TransactionRequestError"
    }

    /**
     The NSURLSession used by the RegistrationProcessor to register transactions.
     */
   private lazy var registrationSession: NSURLSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: nil, delegateQueue: nil)


    //MARK: - OBJECT LIFECYCLE

    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "processTransactionNotification", name: TransactionProcessor.TransactionStatusNotification.purchased.rawValue, object: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: - REGISTRATION PROCESSING

    func processOnBoardReceipt() throws -> NSData {
        // Retrieve the receipt from the data store on the device.
        guard let receiptURL = NSBundle.mainBundle().appStoreReceiptURL, let receiptData = NSData(contentsOfURL: receiptURL) else {
            throw RegistrationError.receiptError
        }
        return receiptData
    }

    func constructRegistrationRequest(receiptData: NSData) throws -> NSMutableURLRequest {
        // Construct the request for the registration server.
        let HTTPBodyDictionary: NSDictionary = [ "token": receiptData, "platform": "ios"]
        let registrationRequest: NSMutableURLRequest
        do {
            registrationRequest = try NSMutableURLRequest.PREMOURLRequest(self.registrationPath, method: NSMutableURLRequest.PREMORequestMethod.POST, HTTPBody: HTTPBodyDictionary, authorizationRequired: true)
        } catch {
            throw RegistrationError.creationError
        }
        return registrationRequest
    }

    func processRestoreRequest() -> Void {
        /*
        TODO: Implement this abstract method if necessary
        This would support restoring by querying the receipt and then sending that to the server. This may be part of refreshing the account.
        */
    }

    func processTransactionNotification(notification: NSNotification) -> Void {

        // Retrieve the receipt from the data store on the device.
        let receiptData: NSData
        do {
            receiptData = try self.processOnBoardReceipt()
        } catch {
            let notification = NSNotification(name: RegistrationStatusNotification.receiptError.rawValue, object: nil, userInfo: nil)
            NSNotificationCenter.defaultCenter().postNotification(notification)
            return
        }

        // Retrieve the transaction from the notification
        guard let transaction = notification.object as? SKPaymentTransaction else {
            let notification = NSNotification(name: RegistrationStatusNotification.transactionRequestError.rawValue, object: nil, userInfo: nil)
            NSNotificationCenter.defaultCenter().postNotification(notification)
            return
        }

        // Construct the request
        let registrationRequest: NSMutableURLRequest
        do {
            registrationRequest = try self.constructRegistrationRequest(receiptData)
        } catch {
            let notification = NSNotification(name: RegistrationStatusNotification.failed.rawValue, object: nil, userInfo: nil)
            NSNotificationCenter.defaultCenter().postNotification(notification)
            return
        }

        self.sendRegistrationRequest(registrationRequest, transaction: transaction)
    }

    func sendRegistrationRequest(registrationRequest: NSURLRequest, transaction: SKPaymentTransaction?) {
        let registrationRequestTask = self.registrationSession.dataTaskWithRequest(registrationRequest, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in

            guard error == nil else {
                let notification = NSNotification(name: RegistrationStatusNotification.unknown.rawValue, object: nil, userInfo: [kUserInfoErrorKey: error!])
                NSNotificationCenter.defaultCenter().postNotification(notification)
                return
            }

            guard let httpResponse = response as? NSHTTPURLResponse else {
                let notification = NSNotification(name: RegistrationStatusNotification.unknown.rawValue, object: nil, userInfo: nil)
                NSNotificationCenter.defaultCenter().postNotification(notification)
                return
            }

            guard let responseData = data else {
                let notification = NSNotification(name: RegistrationStatusNotification.unknown.rawValue, object: nil, userInfo: nil)
                NSNotificationCenter.defaultCenter().postNotification(notification)
                return
            }

            switch httpResponse.statusCode {
            case 200...299:
                self.processRegistrationResponse(responseData, transaction: transaction)

            case 400:
                let notification = NSNotification(name: RegistrationStatusNotification.registrationRequestError.rawValue, object: nil, userInfo: nil)
                NSNotificationCenter.defaultCenter().postNotification(notification)

            case 401:
                let notification = NSNotification(name: RegistrationStatusNotification.registrationCredentialError.rawValue, object: nil, userInfo: nil)
                NSNotificationCenter.defaultCenter().postNotification(notification)

            case 404, 500:
                let notification = NSNotification(name: RegistrationStatusNotification.communicationError.rawValue, object: nil, userInfo: nil)
                NSNotificationCenter.defaultCenter().postNotification(notification)

            default:
                let notification = NSNotification(name: RegistrationStatusNotification.unknown.rawValue, object: nil, userInfo: nil)
                NSNotificationCenter.defaultCenter().postNotification(notification)

            }
        })

        registrationRequestTask.resume()

    }

    func processRegistrationResponse(responeData: NSData, transaction: SKPaymentTransaction?) -> Void {
        do {
            guard let JSONObject = try NSJSONSerialization.JSONObjectWithData(responeData, options: NSJSONReadingOptions.init(rawValue: 0)) as? NSDictionary else { return }

            guard let success = JSONObject.objectForKey("success") where (success as? NSNumber)!.boolValue == true else {
                /*
                TODO: Import Error Handling
                There is error handling elsewhere that will manage the codes returned from the server.
                */
                
                let notification = NSNotification(name: RegistrationStatusNotification.registrationCredentialError.rawValue, object: nil, userInfo: nil)
                NSNotificationCenter.defaultCenter().postNotification(notification)
                return
            }

            guard let subscription = (JSONObject.objectForKey("payload") as? NSDictionary)!.objectForKey("subscription") as? NSDictionary else {
                let notification = NSNotification(name: RegistrationStatusNotification.registrationResponseError.rawValue, object: nil, userInfo: nil)
                NSNotificationCenter.defaultCenter().postNotification(notification)
                return
            }

            try Account.processAccountPayload(subscription)

        } catch {
            let notification = NSNotification(name: RegistrationStatusNotification.registrationResponseError.rawValue, object: nil, userInfo: nil)
            NSNotificationCenter.defaultCenter().postNotification(notification)
            return

        }

        if transaction != nil {
            (UIApplication.sharedApplication().delegate as? AppDelegate)?.transactionProcessor.completeTransaction(transaction!)
        }

    }


}