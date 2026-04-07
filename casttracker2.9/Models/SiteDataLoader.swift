import Foundation
import CoreData

struct SiteJSON: Codable {
    let siteNumber: Int
    let name: String
    let waterBody: String
    let waterType: String
    let latitude: Double
    let longitude: Double
    let zone: String
    let targetSpecies: String
    let recommendedBait: String
    let lore: String
    let easterEgg: String
    let youtubeIdea: String
    let baitShopInfo: String
}

enum SiteDataLoader {
    static func preloadSitesIfNeeded(context: NSManagedObjectContext) {
        let request: NSFetchRequest<CDFishingSite> = CDFishingSite.fetchRequest()
        let count = (try? context.count(for: request)) ?? 0
        guard count == 0 else { return }

        guard let url = Bundle.main.url(forResource: "fishing_sites", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let sites = try? JSONDecoder().decode([SiteJSON].self, from: data) else {
            return
        }

        for siteJSON in sites {
            let site = CDFishingSite(context: context)
            site.id = UUID()
            site.siteNumber = Int32(siteJSON.siteNumber)
            site.name = siteJSON.name
            site.waterBody = siteJSON.waterBody
            site.waterType = siteJSON.waterType
            site.latitude = siteJSON.latitude
            site.longitude = siteJSON.longitude
            site.zone = siteJSON.zone
            site.targetSpecies = siteJSON.targetSpecies
            site.recommendedBait = siteJSON.recommendedBait
            site.lore = siteJSON.lore
            site.easterEgg = siteJSON.easterEgg
            site.youtubeIdea = siteJSON.youtubeIdea
            site.baitShopInfo = siteJSON.baitShopInfo
            site.county = ""

            // Also create a planned trip for each site
            let trip = CDTrip(context: context)
            trip.id = UUID()
            trip.name = siteJSON.name
            trip.siteNumber = Int32(siteJSON.siteNumber)
            trip.latitude = siteJSON.latitude
            trip.longitude = siteJSON.longitude
            trip.waterType = siteJSON.waterType
            trip.status = "planned"
            trip.season = "Spring"
            trip.site = site
        }

        try? context.save()
    }
}
