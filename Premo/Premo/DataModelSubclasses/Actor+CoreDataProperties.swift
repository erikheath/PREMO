//
//  Actor+CoreDataProperties.swift
//  Premo
//
//  Created by ERIKHEATH A THOMAS on 1/13/16.
//  Copyright © 2016 Premo Network. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Actor {

    @NSManaged var creditedName: String?
    @NSManaged var creditedRole: String?
    @NSManaged var contentItems: NSSet?

}
