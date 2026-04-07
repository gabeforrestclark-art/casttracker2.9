import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        // Create sample trips
        for i in 1...5 {
            let trip = CDTrip(context: viewContext)
            trip.id = UUID()
            trip.name = "Trip \(i) — Sample Lake"
            trip.siteNumber = Int32(i)
            trip.date = Calendar.current.date(byAdding: .day, value: -i * 7, to: Date())
            trip.status = i <= 2 ? "completed" : "planned"
            trip.season = "Spring"
            trip.waterType = "Lake"
            trip.latitude = 46.0 + Double(i) * 0.5
            trip.longitude = -94.0 + Double(i) * 0.3

            if i <= 2 {
                let c = CDCatch(context: viewContext)
                c.id = UUID()
                c.species = ["Walleye", "Northern Pike"][i - 1]
                c.lengthInches = Double.random(in: 14...28)
                c.weightLbs = Double.random(in: 1.5...8.0)
                c.date = trip.date
                c.weatherConditions = "Partly Cloudy"
                c.trip = trip
            }
        }
        // Create sample sites
        let siteNames = ["Mille Lacs", "Lake Vermilion", "Leech Lake", "Red Lake", "Lake of the Woods"]
        for (i, name) in siteNames.enumerated() {
            let site = CDFishingSite(context: viewContext)
            site.id = UUID()
            site.siteNumber = Int32(i + 1)
            site.name = name
            site.latitude = 46.0 + Double(i) * 0.5
            site.longitude = -94.0 + Double(i) * 0.3
            site.waterType = "Lake"
            site.county = "Sample County"
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "casttracker2_9")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Preload 70 fishing sites on first launch
        if !inMemory {
            SiteDataLoader.preloadSitesIfNeeded(context: container.viewContext)
        }
    }
}
