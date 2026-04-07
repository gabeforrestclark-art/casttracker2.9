import Foundation
import CoreData

extension CDFishingSite {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDFishingSite> {
        return NSFetchRequest<CDFishingSite>(entityName: "CDFishingSite")
    }

    @NSManaged public var baitShopInfo: String?
    @NSManaged public var county: String?
    @NSManaged public var easterEgg: String?
    @NSManaged public var id: UUID?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var lore: String?
    @NSManaged public var name: String?
    @NSManaged public var notes: String?
    @NSManaged public var recommendedBait: String?
    @NSManaged public var siteNumber: Int32
    @NSManaged public var targetSpecies: String?
    @NSManaged public var waterBody: String?
    @NSManaged public var waterType: String?
    @NSManaged public var youtubeIdea: String?
    @NSManaged public var zone: String?
    @NSManaged public var trips: NSSet?

}

extension CDFishingSite {

    @objc(addTripsObject:)
    @NSManaged public func addToTrips(_ value: CDTrip)

    @objc(removeTripsObject:)
    @NSManaged public func removeFromTrips(_ value: CDTrip)

    @objc(addTrips:)
    @NSManaged public func addToTrips(_ values: NSSet)

    @objc(removeTrips:)
    @NSManaged public func removeFromTrips(_ values: NSSet)

}
