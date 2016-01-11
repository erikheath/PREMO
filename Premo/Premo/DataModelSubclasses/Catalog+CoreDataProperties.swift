//
//  Catalog+CoreDataProperties.swift
//  Premo
//
//  Created by ERIKHEATH A THOMAS on 1/10/16.
//  Copyright © 2016 Premo Network. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Catalog {

    @NSManaged var catalogPcode: String?
    @NSManaged var catalogSource: String?
    @NSManaged var appConfig: AppConfig?

}
