//
//  CategoryList+CoreDataProperties.swift
//  Premo
//
//  Created by ERIKHEATH A THOMAS on 12/14/15.
//  Copyright © 2015 Premo Network. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension CategoryList {

    @NSManaged var categoryDisplayLevel: NSNumber?
    @NSManaged var categoryDisplayOrder: NSNumber?
    @NSManaged var categoryFeedURL: NSObject?
    @NSManaged var categoryIcon: String?
    @NSManaged var categoryName: String?
    @NSManaged var categoryNameDisplayColor: String?
    @NSManaged var contentItems: NSOrderedSet?

}
