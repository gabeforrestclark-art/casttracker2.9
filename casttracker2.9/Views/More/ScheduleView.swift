import SwiftUI
import CoreData

struct ScheduleView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDTrip.siteNumber, ascending: true)]
    ) private var trips: FetchedResults<CDTrip>

    @State private var filterYear: Int? = nil
    @State private var showCompletedOnly = false

    private let schedule = ScheduleData.all

    private var years: [Int] { [2026, 2027, 2028] }

    private var filteredSchedule: [ScheduleEntry] {
        schedule.filter { entry in
            let yearMatch = filterYear == nil || Calendar.current.component(.year, from: entry.date) == filterYear
            let completedMatch = !showCompletedOnly || tripStatus(for: entry.tripNumber) == "completed"
            return yearMatch && completedMatch
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    filterBar
                    List {
                        ForEach(groupedByYear, id: \.year) { group in
                            Section(header: Text(String(group.year))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(AppTheme.primary)
                                .tracking(1)
                            ) {
                                ForEach(group.entries) { entry in
                                    ScheduleRow(entry: entry, status: tripStatus(for: entry.tripNumber))
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCompletedOnly.toggle()
                    } label: {
                        Image(systemName: showCompletedOnly ? "checkmark.circle.fill" : "checkmark.circle")
                            .foregroundStyle(showCompletedOnly ? .green : AppTheme.secondaryText)
                    }
                }
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: filterYear == nil) { filterYear = nil }
                ForEach(years, id: \.self) { year in
                    FilterChip(title: String(year), isSelected: filterYear == year) { filterYear = year }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(AppTheme.background)
    }

    private var groupedByYear: [(year: Int, entries: [ScheduleEntry])] {
        let grouped = Dictionary(grouping: filteredSchedule) {
            Calendar.current.component(.year, from: $0.date)
        }
        return grouped.keys.sorted().map { year in
            (year: year, entries: grouped[year]!.sorted { $0.tripNumber < $1.tripNumber })
        }
    }

    private func tripStatus(for tripNumber: Int) -> String {
        // Match by siteNumber for weekly local trips, or by name for grand journey
        let entry = schedule.first { $0.tripNumber == tripNumber }
        guard let entry else { return "planned" }

        // Check if any trip with matching name is completed
        let match = trips.first { trip in
            trip.name == entry.location || trip.siteNumber == Int32(entry.tripNumber)
        }
        return match?.status ?? "planned"
    }
}

struct ScheduleRow: View {
    let entry: ScheduleEntry
    let status: String

    private var isCompleted: Bool { status == "completed" }
    private var isPast: Bool { entry.date < Date() }

    var body: some View {
        HStack(spacing: 12) {
            // Trip number badge
            Text("\(entry.tripNumber)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(isCompleted ? .black : AppTheme.tertiaryText)
                .frame(width: 28, height: 28)
                .background(isCompleted ? Color.green : AppTheme.cardBackground)
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.location)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(isCompleted ? AppTheme.secondaryText : .white)
                    .strikethrough(isCompleted)

                HStack(spacing: 8) {
                    Text(entry.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(isPast && !isCompleted ? AppTheme.accent : AppTheme.secondaryText)

                    Text(entry.type == .weekly ? "Local" : "Journey")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(entry.type == .weekly ? Color.blue.opacity(0.15) : AppTheme.accent.opacity(0.15))
                        .foregroundStyle(entry.type == .weekly ? .blue : AppTheme.accent)
                        .cornerRadius(4)

                    Text(entry.drive)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.tertiaryText)
                }
            }

            Spacer()

            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
            } else if isPast {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(AppTheme.accent)
                    .font(.caption)
            }
        }
        .listRowBackground(AppTheme.cardBackground)
        .opacity(isCompleted ? 0.7 : 1.0)
    }
}

// MARK: - Schedule Data

enum TripType { case weekly, biWeekly }

struct ScheduleEntry: Identifiable {
    let id = UUID()
    let tripNumber: Int
    let date: Date
    let type: TripType
    let location: String
    let drive: String
}

struct ScheduleData {
    static func makeDate(_ month: Int, _ day: Int, _ year: Int) -> Date {
        var c = DateComponents()
        c.year = year; c.month = month; c.day = day
        return Calendar.current.date(from: c)!
    }

    static let all: [ScheduleEntry] = [
        .init(tripNumber: 1,   date: makeDate(4,  4,  2026), type: .weekly,   location: "Moorhead Riverside Park Access",             drive: "2m"),
        .init(tripNumber: 2,   date: makeDate(4,  11, 2026), type: .biWeekly, location: "Red Lake River — Crookston Access",           drive: "1h 14m"),
        .init(tripNumber: 3,   date: makeDate(4,  18, 2026), type: .weekly,   location: "Felton Prairie / Buffalo River State Park",   drive: "16m"),
        .init(tripNumber: 4,   date: makeDate(4,  25, 2026), type: .biWeekly, location: "Otter Tail Lake Public Access",               drive: "1h 15m"),
        .init(tripNumber: 5,   date: makeDate(5,  2,  2026), type: .weekly,   location: "Barnesville City Park Access",                drive: "25m"),
        .init(tripNumber: 6,   date: makeDate(5,  9,  2026), type: .biWeekly, location: "Pelican Lake Public Access",                  drive: "1h 33m"),
        .init(tripNumber: 7,   date: makeDate(5,  16, 2026), type: .weekly,   location: "Detroit Lakes — Long Lake Access",            drive: "50m"),
        .init(tripNumber: 8,   date: makeDate(5,  23, 2026), type: .biWeekly, location: "Thief River Falls — Thief River Access",      drive: "1h 46m"),
        .init(tripNumber: 9,   date: makeDate(5,  30, 2026), type: .weekly,   location: "Lake Lida Public Access",                    drive: "51m"),
        .init(tripNumber: 10,  date: makeDate(6,  6,  2026), type: .biWeekly, location: "Lake Miltona Public Access",                  drive: "1h 59m"),
        .init(tripNumber: 11,  date: makeDate(6,  13, 2026), type: .weekly,   location: "Lake Melissa Public Access",                  drive: "52m"),
        .init(tripNumber: 12,  date: makeDate(6,  20, 2026), type: .biWeekly, location: "Lake Carlos State Park Access",               drive: "2h 1m"),
        .init(tripNumber: 13,  date: makeDate(6,  27, 2026), type: .weekly,   location: "Lake Sallie Public Access",                   drive: "53m"),
        .init(tripNumber: 14,  date: makeDate(7,  4,  2026), type: .biWeekly, location: "Alexandria — Lake Agnes Access",              drive: "2h 2m"),
        .init(tripNumber: 15,  date: makeDate(7,  11, 2026), type: .weekly,   location: "Otter Tail River — Fergus Falls Access",      drive: "59m"),
        .init(tripNumber: 16,  date: makeDate(7,  18, 2026), type: .biWeekly, location: "Pomme de Terre River — Morris Access",        drive: "2h 6m"),
        .init(tripNumber: 17,  date: makeDate(7,  25, 2026), type: .weekly,   location: "Moorhead Riverside Park Access",             drive: "2m"),
        .init(tripNumber: 18,  date: makeDate(8,  1,  2026), type: .biWeekly, location: "Mississippi River — Bemidji Access",          drive: "2h 17m"),
        .init(tripNumber: 19,  date: makeDate(8,  8,  2026), type: .weekly,   location: "Felton Prairie / Buffalo River State Park",   drive: "16m"),
        .init(tripNumber: 20,  date: makeDate(8,  15, 2026), type: .biWeekly, location: "Lake Bemidji State Park Access",              drive: "2h 17m"),
        .init(tripNumber: 21,  date: makeDate(8,  22, 2026), type: .weekly,   location: "Barnesville City Park Access",                drive: "25m"),
        .init(tripNumber: 22,  date: makeDate(8,  29, 2026), type: .biWeekly, location: "Big Stone Lake Public Access",                drive: "2h 21m"),
        .init(tripNumber: 23,  date: makeDate(9,  5,  2026), type: .weekly,   location: "Detroit Lakes — Long Lake Access",            drive: "50m"),
        .init(tripNumber: 24,  date: makeDate(9,  12, 2026), type: .biWeekly, location: "Long Prairie River — Long Prairie Access",    drive: "2h 22m"),
        .init(tripNumber: 25,  date: makeDate(9,  19, 2026), type: .weekly,   location: "Lake Lida Public Access",                    drive: "51m"),
        .init(tripNumber: 26,  date: makeDate(9,  26, 2026), type: .biWeekly, location: "Lake Minnewaska Public Access",               drive: "2h 23m"),
        .init(tripNumber: 27,  date: makeDate(10, 3,  2026), type: .weekly,   location: "Lake Melissa Public Access",                  drive: "52m"),
        .init(tripNumber: 28,  date: makeDate(10, 10, 2026), type: .biWeekly, location: "Leech Lake — Walker Bay Access",              drive: "2h 25m"),
        .init(tripNumber: 29,  date: makeDate(10, 17, 2026), type: .weekly,   location: "Lake Sallie Public Access",                   drive: "53m"),
        .init(tripNumber: 30,  date: makeDate(10, 24, 2026), type: .biWeekly, location: "Crow Wing River — Motley Access",             drive: "2h 32m"),
        .init(tripNumber: 31,  date: makeDate(10, 31, 2026), type: .weekly,   location: "Otter Tail River — Fergus Falls Access",      drive: "59m"),
        .init(tripNumber: 32,  date: makeDate(11, 7,  2026), type: .biWeekly, location: "Lower Red Lake — Redby Access",               drive: "2h 36m"),
        .init(tripNumber: 33,  date: makeDate(11, 14, 2026), type: .weekly,   location: "Moorhead Riverside Park Access",             drive: "2m"),
        .init(tripNumber: 34,  date: makeDate(11, 21, 2026), type: .biWeekly, location: "Pine River State Water Trail Access",         drive: "2h 37m"),
        .init(tripNumber: 35,  date: makeDate(11, 28, 2026), type: .weekly,   location: "Felton Prairie / Buffalo River State Park",   drive: "16m"),
        .init(tripNumber: 36,  date: makeDate(12, 5,  2026), type: .biWeekly, location: "Gull Lake — Brainerd Area Access",            drive: "2h 43m"),
        .init(tripNumber: 37,  date: makeDate(12, 12, 2026), type: .weekly,   location: "Barnesville City Park Access",                drive: "25m"),
        .init(tripNumber: 38,  date: makeDate(12, 19, 2026), type: .biWeekly, location: "Lac Qui Parle Lake — Watson Access",          drive: "2h 45m"),
        .init(tripNumber: 39,  date: makeDate(12, 26, 2026), type: .weekly,   location: "Detroit Lakes — Long Lake Access",            drive: "50m"),
        .init(tripNumber: 40,  date: makeDate(1,  2,  2027), type: .biWeekly, location: "Crow Wing River — Brainerd Access",           drive: "2h 57m"),
        .init(tripNumber: 41,  date: makeDate(1,  9,  2027), type: .weekly,   location: "Lake Lida Public Access",                    drive: "51m"),
        .init(tripNumber: 42,  date: makeDate(1,  16, 2027), type: .biWeekly, location: "Upper Red Lake — Waskish Access",             drive: "2h 59m"),
        .init(tripNumber: 43,  date: makeDate(1,  23, 2027), type: .weekly,   location: "Lake Melissa Public Access",                  drive: "52m"),
        .init(tripNumber: 44,  date: makeDate(1,  30, 2027), type: .biWeekly, location: "Lake Winnibigoshish — Federal Dam Access",    drive: "3h 4m"),
        .init(tripNumber: 45,  date: makeDate(2,  6,  2027), type: .weekly,   location: "Lake Sallie Public Access",                   drive: "53m"),
        .init(tripNumber: 46,  date: makeDate(2,  13, 2027), type: .biWeekly, location: "Chippewa River — Montevideo Access",          drive: "3h 4m"),
        .init(tripNumber: 47,  date: makeDate(2,  20, 2027), type: .weekly,   location: "Otter Tail River — Fergus Falls Access",      drive: "59m"),
        .init(tripNumber: 48,  date: makeDate(2,  27, 2027), type: .biWeekly, location: "Mille Lacs Lake — Garrison Access",           drive: "3h 8m"),
        .init(tripNumber: 49,  date: makeDate(3,  6,  2027), type: .weekly,   location: "Moorhead Riverside Park Access",             drive: "2m"),
        .init(tripNumber: 50,  date: makeDate(3,  13, 2027), type: .biWeekly, location: "Sauk River — St. Cloud Area Access",          drive: "3h 19m"),
        .init(tripNumber: 51,  date: makeDate(3,  20, 2027), type: .weekly,   location: "Felton Prairie / Buffalo River State Park",   drive: "16m"),
        .init(tripNumber: 52,  date: makeDate(3,  27, 2027), type: .biWeekly, location: "Mississippi River — St. Cloud Access",        drive: "3h 19m"),
        .init(tripNumber: 53,  date: makeDate(4,  3,  2027), type: .weekly,   location: "Barnesville City Park Access",                drive: "25m"),
        .init(tripNumber: 54,  date: makeDate(4,  10, 2027), type: .biWeekly, location: "Minnesota River — Granite Falls Access",      drive: "3h 19m"),
        .init(tripNumber: 55,  date: makeDate(4,  17, 2027), type: .weekly,   location: "Detroit Lakes — Long Lake Access",            drive: "50m"),
        .init(tripNumber: 56,  date: makeDate(4,  24, 2027), type: .biWeekly, location: "Redwood River — Marshall Access",             drive: "3h 45m"),
        .init(tripNumber: 57,  date: makeDate(5,  1,  2027), type: .weekly,   location: "Lake Lida Public Access",                    drive: "51m"),
        .init(tripNumber: 58,  date: makeDate(5,  8,  2027), type: .biWeekly, location: "Rum River — Princeton Access",                drive: "3h 49m"),
        .init(tripNumber: 59,  date: makeDate(5,  15, 2027), type: .weekly,   location: "Lake Melissa Public Access",                  drive: "52m"),
        .init(tripNumber: 60,  date: makeDate(5,  22, 2027), type: .biWeekly, location: "North Fork Crow River — Rockford Access",     drive: "4h 6m"),
        .init(tripNumber: 61,  date: makeDate(5,  29, 2027), type: .weekly,   location: "Lake Sallie Public Access",                   drive: "53m"),
        .init(tripNumber: 62,  date: makeDate(6,  5,  2027), type: .biWeekly, location: "Kettle River — Sandstone Access",             drive: "4h 10m"),
        .init(tripNumber: 63,  date: makeDate(6,  12, 2027), type: .weekly,   location: "Otter Tail River — Fergus Falls Access",      drive: "59m"),
        .init(tripNumber: 64,  date: makeDate(6,  19, 2027), type: .biWeekly, location: "Lake of the Woods — Baudette Access",         drive: "4h 11m"),
        .init(tripNumber: 65,  date: makeDate(6,  26, 2027), type: .weekly,   location: "Moorhead Riverside Park Access",             drive: "2m"),
        .init(tripNumber: 66,  date: makeDate(7,  3,  2027), type: .biWeekly, location: "Snake River — Pine City Access",              drive: "4h 13m"),
        .init(tripNumber: 67,  date: makeDate(7,  10, 2027), type: .weekly,   location: "Felton Prairie / Buffalo River State Park",   drive: "16m"),
        .init(tripNumber: 68,  date: makeDate(7,  17, 2027), type: .biWeekly, location: "Big Fork River — Big Falls Access",           drive: "4h 15m"),
        .init(tripNumber: 69,  date: makeDate(7,  24, 2027), type: .weekly,   location: "Barnesville City Park Access",                drive: "25m"),
        .init(tripNumber: 70,  date: makeDate(7,  31, 2027), type: .biWeekly, location: "Mississippi River — Anoka Access",            drive: "4h 36m"),
        .init(tripNumber: 71,  date: makeDate(8,  7,  2027), type: .weekly,   location: "Detroit Lakes — Long Lake Access",            drive: "50m"),
        .init(tripNumber: 72,  date: makeDate(8,  14, 2027), type: .biWeekly, location: "Lake Waconia Public Access",                  drive: "4h 38m"),
        .init(tripNumber: 73,  date: makeDate(8,  21, 2027), type: .weekly,   location: "Lake Lida Public Access",                    drive: "51m"),
        .init(tripNumber: 74,  date: makeDate(8,  28, 2027), type: .biWeekly, location: "Little Fork River — Little Fork Access",      drive: "4h 40m"),
        .init(tripNumber: 75,  date: makeDate(9,  4,  2027), type: .weekly,   location: "Lake Melissa Public Access",                  drive: "52m"),
        .init(tripNumber: 76,  date: makeDate(9,  11, 2027), type: .biWeekly, location: "Cottonwood River — New Ulm Access",           drive: "4h 41m"),
        .init(tripNumber: 77,  date: makeDate(9,  18, 2027), type: .weekly,   location: "Lake Sallie Public Access",                   drive: "53m"),
        .init(tripNumber: 78,  date: makeDate(9,  25, 2027), type: .biWeekly, location: "Lake Minnetonka — Wayzata Access",            drive: "4h 44m"),
        .init(tripNumber: 79,  date: makeDate(10, 2,  2027), type: .weekly,   location: "Otter Tail River — Fergus Falls Access",      drive: "59m"),
        .init(tripNumber: 80,  date: makeDate(10, 9,  2027), type: .biWeekly, location: "Des Moines River — Windom Access",            drive: "4h 47m"),
        .init(tripNumber: 81,  date: makeDate(10, 16, 2027), type: .weekly,   location: "Moorhead Riverside Park Access",             drive: "2m"),
        .init(tripNumber: 82,  date: makeDate(10, 23, 2027), type: .biWeekly, location: "Rainy Lake — International Falls Access",     drive: "5h 1m"),
        .init(tripNumber: 83,  date: makeDate(10, 30, 2027), type: .weekly,   location: "Felton Prairie / Buffalo River State Park",   drive: "16m"),
        .init(tripNumber: 84,  date: makeDate(11, 6,  2027), type: .biWeekly, location: "Watonwan River — St. James Access",           drive: "5h 1m"),
        .init(tripNumber: 85,  date: makeDate(11, 13, 2027), type: .weekly,   location: "Barnesville City Park Access",                drive: "25m"),
        .init(tripNumber: 86,  date: makeDate(11, 20, 2027), type: .biWeekly, location: "Minnesota River — Mankato Access",            drive: "5h 9m"),
        .init(tripNumber: 87,  date: makeDate(11, 27, 2027), type: .weekly,   location: "Detroit Lakes — Long Lake Access",            drive: "50m"),
        .init(tripNumber: 88,  date: makeDate(12, 4,  2027), type: .biWeekly, location: "Blue Earth River — Mankato Area Access",      drive: "5h 9m"),
        .init(tripNumber: 89,  date: makeDate(12, 11, 2027), type: .weekly,   location: "Lake Lida Public Access",                    drive: "51m"),
        .init(tripNumber: 90,  date: makeDate(12, 18, 2027), type: .biWeekly, location: "Cloquet River — Cloquet Access",              drive: "5h 11m"),
        .init(tripNumber: 91,  date: makeDate(12, 25, 2027), type: .weekly,   location: "Lake Melissa Public Access",                  drive: "52m"),
        .init(tripNumber: 92,  date: makeDate(1,  1,  2028), type: .biWeekly, location: "Kabetogama Lake — Voyageurs NP Access",       drive: "5h 15m"),
        .init(tripNumber: 93,  date: makeDate(1,  8,  2028), type: .weekly,   location: "Lake Sallie Public Access",                   drive: "53m"),
        .init(tripNumber: 94,  date: makeDate(1,  15, 2028), type: .biWeekly, location: "St. Croix River — Stillwater Access",         drive: "5h 16m"),
        .init(tripNumber: 95,  date: makeDate(1,  22, 2028), type: .weekly,   location: "Otter Tail River — Fergus Falls Access",      drive: "59m"),
        .init(tripNumber: 96,  date: makeDate(1,  29, 2028), type: .biWeekly, location: "Lake Vermilion — Tower Access",               drive: "5h 24m"),
        .init(tripNumber: 97,  date: makeDate(2,  5,  2028), type: .weekly,   location: "Moorhead Riverside Park Access",             drive: "2m"),
        .init(tripNumber: 98,  date: makeDate(2,  12, 2028), type: .biWeekly, location: "Cannon River — Northfield Access",            drive: "5h 24m"),
        .init(tripNumber: 99,  date: makeDate(2,  19, 2028), type: .weekly,   location: "Felton Prairie / Buffalo River State Park",   drive: "16m"),
        .init(tripNumber: 100, date: makeDate(2,  26, 2028), type: .biWeekly, location: "Namakan Lake — Voyageurs NP Access",          drive: "5h 26m"),
        .init(tripNumber: 101, date: makeDate(3,  4,  2028), type: .weekly,   location: "Barnesville City Park Access",                drive: "25m"),
        .init(tripNumber: 102, date: makeDate(3,  11, 2028), type: .biWeekly, location: "St. Louis River — Duluth Access",             drive: "5h 32m"),
        .init(tripNumber: 103, date: makeDate(3,  18, 2028), type: .weekly,   location: "Detroit Lakes — Long Lake Access",            drive: "50m"),
        .init(tripNumber: 104, date: makeDate(3,  25, 2028), type: .biWeekly, location: "Lake Superior — Duluth Canal Park Access",    drive: "5h 38m"),
        .init(tripNumber: 105, date: makeDate(4,  1,  2028), type: .weekly,   location: "Lake Lida Public Access",                    drive: "51m"),
        .init(tripNumber: 106, date: makeDate(4,  8,  2028), type: .biWeekly, location: "Crane Lake — BWCA Entry Point #4",            drive: "5h 40m"),
        .init(tripNumber: 107, date: makeDate(4,  15, 2028), type: .weekly,   location: "Lake Melissa Public Access",                  drive: "52m"),
        .init(tripNumber: 108, date: makeDate(4,  22, 2028), type: .biWeekly, location: "Straight River — Owatonna Access",            drive: "5h 46m"),
        .init(tripNumber: 109, date: makeDate(4,  29, 2028), type: .weekly,   location: "Lake Sallie Public Access",                   drive: "53m"),
        .init(tripNumber: 110, date: makeDate(5,  6,  2028), type: .biWeekly, location: "Lake Pepin — Lake City Access",               drive: "6h 9m"),
        .init(tripNumber: 111, date: makeDate(5,  13, 2028), type: .weekly,   location: "Otter Tail River — Fergus Falls Access",      drive: "59m"),
        .init(tripNumber: 112, date: makeDate(5,  20, 2028), type: .biWeekly, location: "Ely — BWCA Entry (Fall Lake)",                drive: "6h 10m"),
        .init(tripNumber: 113, date: makeDate(5,  27, 2028), type: .weekly,   location: "Moorhead Riverside Park Access",             drive: "2m"),
        .init(tripNumber: 114, date: makeDate(6,  3,  2028), type: .biWeekly, location: "Shell Rock River — Albert Lea Access",        drive: "6h 13m"),
        .init(tripNumber: 115, date: makeDate(6,  10, 2028), type: .weekly,   location: "Felton Prairie / Buffalo River State Park",   drive: "16m"),
        .init(tripNumber: 116, date: makeDate(6,  17, 2028), type: .biWeekly, location: "Zumbro River — Rochester Access",             drive: "6h 26m"),
        .init(tripNumber: 117, date: makeDate(6,  24, 2028), type: .weekly,   location: "Barnesville City Park Access",                drive: "25m"),
        .init(tripNumber: 118, date: makeDate(7,  1,  2028), type: .biWeekly, location: "Cedar River — Austin Access",                 drive: "6h 27m"),
        .init(tripNumber: 119, date: makeDate(7,  8,  2028), type: .weekly,   location: "Detroit Lakes — Long Lake Access",            drive: "50m"),
        .init(tripNumber: 120, date: makeDate(7,  15, 2028), type: .biWeekly, location: "Whitewater River — Elba Access",              drive: "6h 51m"),
        .init(tripNumber: 121, date: makeDate(7,  22, 2028), type: .weekly,   location: "Lake Lida Public Access",                    drive: "51m"),
        .init(tripNumber: 122, date: makeDate(7,  29, 2028), type: .biWeekly, location: "Mississippi River — Winona Access",           drive: "7h 4m"),
        .init(tripNumber: 123, date: makeDate(8,  5,  2028), type: .weekly,   location: "Lake Melissa Public Access",                  drive: "52m"),
        .init(tripNumber: 124, date: makeDate(8,  12, 2028), type: .biWeekly, location: "Root River — Lanesboro Access",               drive: "7h 10m"),
    ]
}
