//
//  ContentItemJSONObjectConditioner.swift
//

import Foundation
import CoreData

class ContentItemJSONObjectConditioner: JSONObjectConditioner {

    static let entityName = "ContentItem"

    func condition(object: Dictionary<NSObject, AnyObject>) -> Dictionary<NSObject, AnyObject>? {
        // This object will take in the JSON of a ContentItem and change the genres array to an array of dictionaries with the necessary keys. Otherwise it will just return the given object.
        guard let genresArray = (object as NSDictionary).objectForKey("genres") as? Array<String> else { return object }
        let mutableObject = NSMutableDictionary(dictionary: object)
        let mutableGenreArray = NSMutableArray()
        for genre: String in genresArray {
            let genreDictionary = NSMutableDictionary()
            genreDictionary.setObject(genre, forKey: "name")
            mutableGenreArray.addObject(genreDictionary)
        }
        mutableObject.setObject(mutableGenreArray, forKey: "genres")
        return mutableObject as Dictionary<NSObject, AnyObject>
    }
}