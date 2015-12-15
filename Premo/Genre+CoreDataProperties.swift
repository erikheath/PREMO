//
//  Genre+CoreDataProperties.swift
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

extension Genre {

    @NSManaged var genreColor: NSObject?
    @NSManaged var genreFeedURL: String?
    @NSManaged var genreIcon: String?
    @NSManaged var genreName: String?
    @NSManaged var genreSearchKey: String?
    @NSManaged var contentItems: NSSet?
    @NSManaged var seriesMembers: NSSet?

}
