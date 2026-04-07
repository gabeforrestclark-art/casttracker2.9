import SwiftUI
import CoreData

struct RoadmapView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "status == %@", "completed")
    ) private var completedTrips: FetchedResults<CDTrip>

    @State private var selectedMilestone: RoadmapMilestone? = nil

    private var completedCount: Int { completedTrips.count }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 0) {
                        progressHeader
                        Divider().background(Color.white.opacity(0.1))
                        milestoneList
                    }
                }
            }
            .navigationTitle("Roadmap")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedMilestone) { milestone in
                MilestoneDetailSheet(milestone: milestone)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WORKING MAN'S WATERS")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .tracking(2)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text("4-Year Journey")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("April 2026 — August 2028")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 6)
                        .frame(width: 64, height: 64)
                    Circle()
                        .trim(from: 0, to: CGFloat(completedCount) / 124.0)
                        .stroke(
                            LinearGradient(colors: [AppTheme.primary, AppTheme.accent], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 64, height: 64)
                    VStack(spacing: 0) {
                        Text("\(completedCount)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("/ 124")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(AppTheme.tertiaryText)
                    }
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
    }

    // MARK: - Milestone List

    private var milestoneList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(RoadmapMilestone.all.enumerated()), id: \.element.id) { index, milestone in
                let isReached = completedCount >= milestone.tripNumber
                let isNext = !isReached && (index == 0 || completedCount >= RoadmapMilestone.all[index - 1].tripNumber)

                Button {
                    selectedMilestone = milestone
                } label: {
                    MilestoneRow(milestone: milestone, isReached: isReached, isNext: isNext)
                }

                if index < RoadmapMilestone.all.count - 1 {
                    HStack {
                        Spacer().frame(width: 48)
                        Rectangle()
                            .fill(isReached ? AppTheme.primary.opacity(0.4) : Color.white.opacity(0.08))
                            .frame(width: 2, height: 28)
                        Spacer()
                    }
                    .padding(.leading, 16)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Milestone Row

struct MilestoneRow: View {
    let milestone: RoadmapMilestone
    let isReached: Bool
    let isNext: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Icon node
            ZStack {
                Circle()
                    .fill(isReached ? milestone.color : Color.white.opacity(0.06))
                    .frame(width: 44, height: 44)
                if isReached {
                    Image(systemName: milestone.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: milestone.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(isNext ? milestone.color : Color.white.opacity(0.25))
                }
                if isNext {
                    Circle()
                        .stroke(milestone.color, lineWidth: 2)
                        .frame(width: 44, height: 44)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(milestone.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(isReached ? .white : isNext ? .white : Color.white.opacity(0.5))
                    if isNext {
                        Text("NEXT")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(milestone.color.opacity(0.2))
                            .foregroundStyle(milestone.color)
                            .cornerRadius(4)
                    }
                }
                Text(milestone.subtitle)
                    .font(.caption)
                    .foregroundStyle(isReached ? AppTheme.secondaryText : Color.white.opacity(0.3))
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Trip \(milestone.tripNumber)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(isReached ? milestone.color : Color.white.opacity(0.25))
                Text(milestone.date, style: .date)
                    .font(.system(size: 9))
                    .foregroundStyle(Color.white.opacity(0.25))
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(Color.white.opacity(0.2))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Milestone Detail Sheet

struct MilestoneDetailSheet: View {
    let milestone: RoadmapMilestone
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(milestone.color.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: milestone.icon)
                        .font(.system(size: 32))
                        .foregroundStyle(milestone.color)
                }
                .padding(.top, 24)

                Text(milestone.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text(milestone.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("Trip #")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                        Text("\(milestone.tripNumber)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(milestone.color)
                    }
                    Divider().frame(height: 32).background(Color.white.opacity(0.1))
                    VStack(spacing: 4) {
                        Text("Date")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                        Text(milestone.date, style: .date)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                }
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(12)
                .padding(.horizontal)

                Text(milestone.description)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer()
            }
        }
    }
}

// MARK: - Data Model

struct RoadmapMilestone: Identifiable {
    let id = UUID()
    let tripNumber: Int
    let date: Date
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let color: Color

    static func makeDate(_ month: Int, _ day: Int, _ year: Int) -> Date {
        var c = DateComponents()
        c.year = year; c.month = month; c.day = day
        return Calendar.current.date(from: c)!
    }

    static let all: [RoadmapMilestone] = [
        .init(tripNumber: 1,   date: makeDate(4,  4,  2026), title: "Journey Begins",       subtitle: "First paddle on the Red River",           description: "The journey starts right in your backyard — the Red River of the North. 123 more to go.",                                    icon: "flag.fill",              color: AppTheme.primary),
        .init(tripNumber: 2,   date: makeDate(4,  11, 2026), title: "1-Hour Barrier",        subtitle: "Red Lake River, Crookston",               description: "First trip beyond 1 hour from Moorhead. The Red Lake River State Water Trail opens up northwest Minnesota.",                   icon: "car.fill",               color: .blue),
        .init(tripNumber: 10,  date: makeDate(6,  6,  2026), title: "2-Hour Barrier",        subtitle: "Lake Miltona, Douglas County",            description: "Pushing into Central Minnesota for the first time. Lake Miltona is a clear, deep walleye lake.",                              icon: "arrow.right.circle.fill", color: .cyan),
        .init(tripNumber: 28,  date: makeDate(10, 10, 2026), title: "Leech Lake",            subtitle: "Minnesota's 3rd largest lake",            description: "World-class walleye and muskie fishing. Plan a full weekend — this is one of the great ones.",                               icon: "fish.fill",              color: .green),
        .init(tripNumber: 42,  date: makeDate(1,  16, 2027), title: "Upper Red Lake",        subtitle: "One of MN's best walleye lakes",         description: "World-class walleye fishing in the heart of the Beltrami Island State Forest. A bucket list lake.",                           icon: "star.fill",              color: .yellow),
        .init(tripNumber: 48,  date: makeDate(2,  27, 2027), title: "Mille Lacs Lake",       subtitle: "Minnesota's premier walleye fishery",     description: "The crown jewel of Minnesota walleye fishing. Multiple DNR public accesses and legendary productivity.",                      icon: "crown.fill",             color: AppTheme.accent),
        .init(tripNumber: 64,  date: makeDate(6,  19, 2027), title: "Lake of the Woods",    subtitle: "World-class walleye on the Canadian border", description: "Massive lake straddling the MN/Canada border. World-class walleye and sauger. Plan a full weekend.",                    icon: "globe.americas.fill",    color: .teal),
        .init(tripNumber: 92,  date: makeDate(1,  1,  2028), title: "Voyageurs NP",          subtitle: "Kabetogama Lake wilderness fishing",      description: "Voyageurs National Park. Remote wilderness fishing on one of Minnesota's most beautiful lakes. Overnight recommended.",       icon: "tent.fill",              color: .indigo),
        .init(tripNumber: 96,  date: makeDate(1,  29, 2028), title: "Lake Vermilion",        subtitle: "One of MN's most beautiful lakes",       description: "Lake Vermilion near Tower — legendary for walleye and smallmouth bass. One of the most scenic lakes in the state.",           icon: "sparkles",               color: .purple),
        .init(tripNumber: 104, date: makeDate(3,  25, 2028), title: "Lake Superior",         subtitle: "The Great Lake — big-water kayak fishing", description: "Lake Superior at Duluth Canal Park. Unique big-water kayak fishing for lake trout and salmon. Overnight recommended.",    icon: "water.waves",            color: .blue),
        .init(tripNumber: 106, date: makeDate(4,  8,  2028), title: "BWCA Entry",            subtitle: "Crane Lake — Boundary Waters gateway",   description: "Gateway to the Boundary Waters Canoe Area Wilderness. Remote walleye and lake trout fishing. Overnight recommended.",        icon: "leaf.fill",              color: .green),
        .init(tripNumber: 112, date: makeDate(5,  20, 2028), title: "Ely / BWCA",           subtitle: "World-class wilderness fishing",          description: "Ely is the gateway to the BWCA. Fall Lake entry offers world-class wilderness fishing for walleye, smallmouth, and lake trout.", icon: "mountain.2.fill",        color: .mint),
        .init(tripNumber: 124, date: makeDate(8,  12, 2028), title: "THE FINAL DESTINATION", subtitle: "Root River — Lanesboro, Fillmore County", description: "The furthest point in Minnesota — over 7 hours from Moorhead. Root River State Water Trail. Trout, smallmouth, and walleye. The end of the Working Man's Waters journey.", icon: "trophy.fill", color: AppTheme.accent),
    ]
}
