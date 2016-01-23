//
//  Genre+CoreDataProperties.swift
//  Premo
//
//  Created by ERIKHEATH A THOMAS on 1/21/16.
//  Copyright © 2016 Premo Network. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Genre {

    @NSManaged var genreColor: String?
    @NSManaged var genreName: String?
    @NSManaged var appConfig: AppConfig?
    @NSManaged var contentItems: NSSet?
    @NSManaged var seriesMembers: NSSet?

}
