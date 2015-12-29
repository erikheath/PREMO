//
//  Producer+CoreDataProperties.swift
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Producer {

    @NSManaged var creditedName: String?
    @NSManaged var contentItems: NSSet?

}
