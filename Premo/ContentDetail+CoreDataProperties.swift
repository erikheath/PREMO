//
//  ContentDetail+CoreDataProperties.swift
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

extension ContentDetail {

    @NSManaged var contentDescription: String?
    @NSManaged var contentDetailDisplayTitle: String?
    @NSManaged var contentDisplayHeader: String?
    @NSManaged var contentDisplaySubheader: String?
    @NSManaged var contentSynopsis: String?
    @NSManaged var contentItem: ContentItem?

}
