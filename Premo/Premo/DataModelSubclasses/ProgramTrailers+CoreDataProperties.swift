//
//  ProgramTrailers+CoreDataProperties.swift

//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension ProgramTrailers {

    @NSManaged var trailerSource: String?
    @NSManaged var trailerSourceID: String?
    @NSManaged var contentItem: ContentItem?

}
