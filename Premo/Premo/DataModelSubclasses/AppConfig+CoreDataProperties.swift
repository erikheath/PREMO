//
//  AppConfig+CoreDataProperties.swift
//  Premo
//
//  Created by ERIKHEATH A THOMAS on 1/12/16.
//  Copyright © 2016 Premo Network. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension AppConfig {

    @NSManaged var catalogFeed: String?
    @NSManaged var catalogFeedURL: NSObject?
    @NSManaged var transientRoot: String?
    @NSManaged var catalogSources: NSSet?
    @NSManaged var categories: NSOrderedSet?
    @NSManaged var genres: NSSet?

}
