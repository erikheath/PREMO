//
//  ContentItem+CoreDataProperties.swift
//  Premo
//
//  Created by ERIKHEATH A THOMAS on 1/12/16.
//  Copyright © 2016 Premo Network. All rights reserved.
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
    @NSManaged var contentDescription: String?
    @NSManaged var contentDetailDisplayTitle: String?
    @NSManaged var contentDisplayHeader: String?
    @NSManaged var contentDisplaySubheader: String?
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
    @NSManaged var contentSynopsis: String?
    @NSManaged var contentType: String?
    @NSManaged var contentURL: String?
    @NSManaged var remoteOrderPosition: NSDate?
    @NSManaged var actors: NSOrderedSet?
    @NSManaged var artwork: Artwork?
    @NSManaged var categoryMember: CategoryList?
    @NSManaged var directors: NSOrderedSet?
    @NSManaged var genres: NSOrderedSet?
    @NSManaged var producers: NSOrderedSet?
    @NSManaged var seasonMembership: Season?
    @NSManaged var seriesMembership: Series?
    @NSManaged var trailers: ProgramTrailers?

}
