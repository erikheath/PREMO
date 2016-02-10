//
//  RequestValidationCondition.swift
//

import Foundation

public struct RequestValidationCondition: OperationCondition {
    static let name = "Request Validation"
    static let isMutuallyExclusive = false

    func dependencyForOperation(operation: Operation) -> NSOperation? {

        return nil
    }

    func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {

    }
    
}
