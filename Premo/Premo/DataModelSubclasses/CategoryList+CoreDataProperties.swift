//
//  CategoryList+CoreDataProperties.swift

//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension CategoryList {

    @NSManaged var categoryFeedURL: NSObject?
    @NSManaged var categoryIcon: String?
    @NSManaged var categoryName: String?
    @NSManaged var categoryNameDisplayColor: String?
    @NSManaged var lastRemoteUpdate: NSDate?
    @NSManaged var remoteOrderPosition: NSDate?
    @NSManaged var remoteUpdateExpiration: NSDate?
    @NSManaged var appConfig: AppConfig?
    @NSManaged var carousel: NSOrderedSet?
    @NSManaged var contentItems: NSOrderedSet?

}
