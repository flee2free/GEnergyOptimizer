//
//  CDZone+CoreDataProperties.swift
//  GEnergyOptimizer
//
//  Created by Binay Budhthoki on 1/19/18.
//  Copyright © 2018 GeminiEnergyServices. All rights reserved.
//
//

import Foundation
import CoreData


extension CDZone {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDZone> {
        return NSFetchRequest<CDZone>(entityName: "CDZone")
    }

    @NSManaged public var createdAt: NSDate?
    @NSManaged public var name: String?
    @NSManaged public var objectId: String?
    @NSManaged public var syncStatus: Bool
    @NSManaged public var type: String?
    @NSManaged public var updatedAt: NSDate?
    @NSManaged public var uuid: String?
    @NSManaged public var belongsToAudit: CDAudit?
    @NSManaged public var hasFeature: NSSet?
    @NSManaged public var hasRoom: NSSet?

}

// MARK: Generated accessors for hasFeature
extension CDZone {

    @objc(addHasFeatureObject:)
    @NSManaged public func addToHasFeature(_ value: CDPreAudit)

    @objc(removeHasFeatureObject:)
    @NSManaged public func removeFromHasFeature(_ value: CDPreAudit)

    @objc(addHasFeature:)
    @NSManaged public func addToHasFeature(_ values: NSSet)

    @objc(removeHasFeature:)
    @NSManaged public func removeFromHasFeature(_ values: NSSet)

}

// MARK: Generated accessors for hasRoom
extension CDZone {

    @objc(addHasRoomObject:)
    @NSManaged public func addToHasRoom(_ value: CDRoom)

    @objc(removeHasRoomObject:)
    @NSManaged public func removeFromHasRoom(_ value: CDRoom)

    @objc(addHasRoom:)
    @NSManaged public func addToHasRoom(_ values: NSSet)

    @objc(removeHasRoom:)
    @NSManaged public func removeFromHasRoom(_ values: NSSet)

}
