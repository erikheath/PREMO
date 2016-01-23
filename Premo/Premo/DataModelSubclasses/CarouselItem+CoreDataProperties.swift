//
//  CarouselItem+CoreDataProperties.swift
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

extension CarouselItem {

    @NSManaged var contentSource: String?
    @NSManaged var contentSourceID: String?
    @NSManaged var remoteOrderPosition: NSDate?
    @NSManaged var category: CategoryList?

}
