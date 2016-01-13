//
//  JSONObjectConditioner.swift
//

import Foundation
import CoreData

// Implement this to create a method body.

protocol JSONObjectConditioner {

    func condition(object:Dictionary<NSObject, AnyObject>) -> Dictionary<NSObject, AnyObject>?
    
}