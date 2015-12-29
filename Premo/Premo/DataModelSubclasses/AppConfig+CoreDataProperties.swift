//
//  AppConfig+CoreDataProperties.swift
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension AppConfig {

    @NSManaged var catalogFeed: String?
    @NSManaged var catalogFeedURL: NSObject?
    @NSManaged var catalogSources: NSSet?

}
