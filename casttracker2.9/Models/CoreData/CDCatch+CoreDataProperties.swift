import Foundation
import CoreData

extension CDCatch {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDCatch> {
        return NSFetchRequest<CDCatch>(entityName: "CDCatch")
    }

    @NSManaged public var date: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var lengthInches: Double
    @NSManaged public var notes: String?
    @NSManaged public var photoData: Data?
    @NSManaged public var species: String?
    @NSManaged public var waterClarity: String?
    @NSManaged public var waterTemp: Double
    @NSManaged public var baitLure: String?
    @NSManaged public var isKept: Bool
    @NSManaged public var weatherConditions: String?
    @NSManaged public var weightLbs: Double
    @NSManaged public var trip: CDTrip?

}
