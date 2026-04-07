import Foundation

enum FishSpecies: String, CaseIterable, Identifiable {
    case walleye = "Walleye"
    case northernPike = "Northern Pike"
    case largemouthBass = "Largemouth Bass"
    case smallmouthBass = "Smallmouth Bass"
    case crappie = "Crappie"
    case bluegill = "Bluegill"
    case catfish = "Catfish"
    case muskie = "Muskie"
    case perch = "Perch"
    case trout = "Trout"
    case sunfish = "Sunfish"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .walleye: return "🐟"
        case .northernPike: return "🐊"
        case .largemouthBass, .smallmouthBass: return "🐟"
        case .crappie: return "🐟"
        case .bluegill, .sunfish: return "🐠"
        case .catfish: return "🐱"
        case .muskie: return "🦈"
        case .perch: return "🐟"
        case .trout: return "🐟"
        case .other: return "🎣"
        }
    }
}

enum WeatherCondition: String, CaseIterable, Identifiable {
    case sunny = "Sunny"
    case partlyCloudy = "Partly Cloudy"
    case cloudy = "Cloudy"
    case overcast = "Overcast"
    case rainy = "Rainy"
    case stormy = "Stormy"
    case windy = "Windy"
    case snowy = "Snowy"
    case foggy = "Foggy"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .overcast: return "smoke.fill"
        case .rainy: return "cloud.rain.fill"
        case .stormy: return "cloud.bolt.rain.fill"
        case .windy: return "wind"
        case .snowy: return "cloud.snow.fill"
        case .foggy: return "cloud.fog.fill"
        }
    }
}

enum WaterClarity: String, CaseIterable, Identifiable {
    case clear = "Clear"
    case slightlyStained = "Slightly Stained"
    case stained = "Stained"
    case murky = "Murky"
    case muddy = "Muddy"

    var id: String { rawValue }
}

enum BaitLure: String, CaseIterable, Identifiable {
    case liveMinow = "Live Minnow"
    case leech = "Leech"
    case nightcrawler = "Nightcrawler"
    case crankbait = "Crankbait"
    case jig = "Jig"
    case spinnerbait = "Spinnerbait"
    case spoon = "Spoon"
    case softPlastic = "Soft Plastic"
    case topwater = "Topwater"
    case swimbait = "Swimbait"
    case jerkbait = "Jerkbait"
    case fly = "Fly"
    case inlineSpinner = "Inline Spinner"
    case liplessCrank = "Lipless Crankbait"
    case dropShot = "Drop Shot"
    case other = "Other"

    var id: String { rawValue }

    var category: String {
        switch self {
        case .liveMinow, .leech, .nightcrawler: return "Live Bait"
        case .fly: return "Fly"
        default: return "Artificial"
        }
    }
}

struct DefaultChecklist {
    static let items = [
        "Kayak loaded & strapped down",
        "Paddle & backup paddle",
        "PFD / life jacket",
        "Fishing license on person",
        "Rod & reel (primary)",
        "Rod & reel (backup)",
        "Tackle box — jigs, crankbaits, spinnerbaits",
        "Live bait (minnows / leeches / crawlers)",
        "Steel leaders (pike/muskie water)",
        "Pliers, line cutter & hook remover",
        "Net",
        "Measuring tape & digital scale",
        "Sunscreen, sunglasses & hat",
        "Water & snacks",
        "Phone charger / battery pack",
        "GoPro / camera charged & mounted",
        "SD card cleared / storage check",
        "Dry bag for electronics",
        "First aid kit",
        "Weather-appropriate layers",
        "Anchor / drift sock",
        "Headlamp (early launch)",
        "Check weather & wind forecast",
        "Tell someone your float plan"
    ]
}
