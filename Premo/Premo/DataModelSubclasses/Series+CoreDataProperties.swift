//
//  Series+CoreDataProperties.swift

//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Series {

    @NSManaged var seriesIdentifier: String?
    @NSManaged var contentItems: NSSet?
    @NSManaged var genres: NSSet?
    @NSManaged var seasons: NSSet?

}
