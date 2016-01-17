//
//  TransactionProcessor.swift
//  Premo
//
//  Created by ERIKHEATH A THOMAS on 1/16/16.
//  Copyright © 2016 Premo Network. All rights reserved.
//

import Foundation
import StoreKit


class TransactionProcessor: NSObject, SKPaymentTransactionObserver {

    /**
     This enumeration provides the keys for transaction status notifications dispatched by a TransactionProcessor object.
     */
    enum TransactionStatusNotification: String {
        case purchasing = "PurchaseProcessingNotification"
        case purchased = "PurchaseCompleteNotification"
        case deferred = "PurchaseDeferredNotification"
        case failed = "PurchaseFailedNotification"
        case restored = "PurchaseRestoredNotification"
        case receiptError = "ReceiptProcessingErrorNotification"
    }

    //MARK: - OBJECT LIFECYCLE

    /**
    Designated initializer for the Transaction Processor.
    */
    override init() {
        super.init()
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    }

    // MARK: - PURCHASE MANAGEMENT

    /**
    Implements the required method of the SKPaymentTransactionObserver protocol. This method dispatches notifications to the application regarding transaction status. See the TransactionStatusNotification enumeration for possible values.
    */
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {

            case SKPaymentTransactionState.Purchasing:
                let notification = NSNotification(name: TransactionStatusNotification.purchasing.rawValue, object: transaction, userInfo: nil)
                NSNotificationCenter.defaultCenter().postNotification(notification)

            case SKPaymentTransactionState.Deferred:
                let notification = NSNotification(name: TransactionStatusNotification.deferred.rawValue, object: transaction, userInfo: nil)
                NSNotificationCenter.defaultCenter().postNotification(notification)

            case SKPaymentTransactionState.Failed:
                let notification = NSNotification(name: TransactionStatusNotification.failed.rawValue, object: transaction, userInfo: nil)
                NSNotificationCenter.defaultCenter().postNotification(notification)

            case SKPaymentTransactionState.Purchased:
                let notification = NSNotification(name: TransactionStatusNotification.purchased.rawValue, object: transaction, userInfo: nil)
                NSNotificationCenter.defaultCenter().postNotification(notification)

            case SKPaymentTransactionState.Restored:
                let notification = NSNotification(name: TransactionStatusNotification.restored.rawValue, object: transaction, userInfo: nil)
                NSNotificationCenter.defaultCenter().postNotification(notification)
                
            }
        }
    }

    /**
     When a transaction has been completed (i.e. registered with the PREMO server) call this method to close the transaction with StoreKit. It is an error to not call this method on a completed transaction, and can result in sending the transaction multiple times to the PREMO server.
     */
    func completeTransaction(transaction: SKPaymentTransaction) -> Void {
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }


}