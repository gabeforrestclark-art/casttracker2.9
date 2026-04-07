import Foundation
import CoreData

extension CDChecklistItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDChecklistItem> {
        return NSFetchRequest<CDChecklistItem>(entityName: "CDChecklistItem")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var name: String?
    @NSManaged public var sortOrder: Int32
    @NSManaged public var trip: CDTrip?

}

extension CDChecklistItem: Identifiable {}
