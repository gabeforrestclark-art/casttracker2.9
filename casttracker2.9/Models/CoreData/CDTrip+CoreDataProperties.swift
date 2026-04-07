import Foundation
import CoreData

extension CDTrip {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDTrip> {
        return NSFetchRequest<CDTrip>(entityName: "CDTrip")
    }

    @NSManaged public var date: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var name: String?
    @NSManaged public var notes: String?
    @NSManaged public var season: String?
    @NSManaged public var siteNumber: Int32
    @NSManaged public var status: String?
    @NSManaged public var waterType: String?
    @NSManaged public var catches: NSSet?
    @NSManaged public var checklist: NSSet?
    @NSManaged public var site: CDFishingSite?

}

extension CDTrip {

    @objc(addCatchesObject:)
    @NSManaged public func addToCatches(_ value: CDCatch)

    @objc(removeCatchesObject:)
    @NSManaged public func removeFromCatches(_ value: CDCatch)

    @objc(addCatches:)
    @NSManaged public func addToCatches(_ values: NSSet)

    @objc(removeCatches:)
    @NSManaged public func removeFromCatches(_ values: NSSet)

}

extension CDTrip {

    @objc(addChecklistObject:)
    @NSManaged public func addToChecklist(_ value: CDChecklistItem)

    @objc(removeChecklistObject:)
    @NSManaged public func removeFromChecklist(_ value: CDChecklistItem)

    @objc(addChecklist:)
    @NSManaged public func addToChecklist(_ values: NSSet)

    @objc(removeChecklist:)
    @NSManaged public func removeFromChecklist(_ values: NSSet)

}
