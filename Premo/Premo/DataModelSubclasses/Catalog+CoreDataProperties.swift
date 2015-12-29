//
//  Catalog+CoreDataProperties.swift
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Catalog {

    @NSManaged var catalogSource: String?
    @NSManaged var catalogPcode: String?
    @NSManaged var appConfiguration: AppConfig?

}
