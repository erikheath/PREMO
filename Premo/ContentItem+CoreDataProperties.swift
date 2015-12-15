//
//  ContentItem+CoreDataProperties.swift
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

extension ContentItem {

    @NSManaged var contentCaptionsURL: String?
    @NSManaged var contentCopyright: String?
    @NSManaged var contentCountry: String?
    @NSManaged var contentDistributor: String?
    @NSManaged var contentExpires: NSDate?
    @NSManaged var contentFormat: String?
    @NSManaged var contentHasCaptions: NSNumber?
    @NSManaged var contentLanguage: String?
    @NSManaged var contentRating: String?
    @NSManaged var contentRatingSystem: String?
    @NSManaged var contentReleaseYear: String?
    @NSManaged var contentRuntime: NSNumber?
    @NSManaged var contentSource: String?
    @NSManaged var contentSourceID: String?
    @NSManaged var contentType: String?
    @NSManaged var contentURL: String?
    @NSManaged var credits: Credit?
    @NSManaged var details: ContentDetail?
    @NSManaged var seasonMembership: Season?
    @NSManaged var seriesMembership: Series?
    @NSManaged var genres: NSSet?
    @NSManaged var categories: NSSet?
    @NSManaged var trailers: NSSet?
    @NSManaged var artwork: NSSet?

}
