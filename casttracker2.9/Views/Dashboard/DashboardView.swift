import SwiftUI
import CoreData

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDTrip.date, ascending: false)],
        predicate: NSPredicate(format: "status == %@", "completed"),
        animation: .default
    ) private var completedTrips: FetchedResults<CDTrip>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDTrip.date, ascending: true)],
        predicate: NSPredicate(format: "status == %@", "planned"),
        animation: .default
    ) private var plannedTrips: FetchedResults<CDTrip>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDCatch.date, ascending: false)]
    ) private var allCatches: FetchedResults<CDCatch>

    private let launchDate: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 4
        components.day = 7
        components.hour = 5
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone(identifier: "America/Chicago")
        return Calendar.current.date(from: components)!
    }()

    private let totalSites = 70

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    seasonBadge
                    countdownCard
                    journeyProgress
                    statsGrid
                    nextTripCard
                    recentTripsSection
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("Dashboard")
        }
    }

    // MARK: - Season Badge

    private var seasonBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(AppTheme.primary)
                .frame(width: 8, height: 8)
                .shadow(color: AppTheme.primary.opacity(0.8), radius: 4)

            Text("SEASON 1 — 2026")
                .font(.caption)
                .fontWeight(.bold)
                .tracking(2)
                .foregroundStyle(AppTheme.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AppTheme.primary.opacity(0.15))
        .cornerRadius(20)
    }

    // MARK: - Countdown

    private var countdownCard: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            let isLaunched = now >= launchDate

            VStack(spacing: 12) {
                if isLaunched {
                    let daysSince = Calendar.current.dateComponents([.day], from: launchDate, to: now).day ?? 0
                    Text("DAY \(daysSince)")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.primary)
                    Text("OF THE JOURNEY")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .tracking(2)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    Text("LAUNCH COUNTDOWN")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .tracking(2)
                        .foregroundStyle(AppTheme.secondaryText)

                    let components = Calendar.current.dateComponents(
                        [.day, .hour, .minute, .second],
                        from: now, to: launchDate
                    )
                    HStack(spacing: 16) {
                        countdownUnit(value: components.day ?? 0, label: "DAYS")
                        countdownUnit(value: components.hour ?? 0, label: "HRS")
                        countdownUnit(value: components.minute ?? 0, label: "MIN")
                        countdownUnit(value: components.second ?? 0, label: "SEC")
                    }

                    Text("April 7, 2026 · 5:00 AM CDT")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.tertiaryText)
                }
            }
            .frame(maxWidth: .infinity)
            .cardStyle()
        }
    }

    private func countdownUnit(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.tertiaryText)
        }
    }

    // MARK: - Journey Progress

    private var journeyProgress: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Journey Progress")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(completedTrips.count) / \(totalSites)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.primary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.primary, AppTheme.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(0, geo.size.width * CGFloat(completedTrips.count) / CGFloat(totalSites)),
                            height: 12
                        )
                }
            }
            .frame(height: 12)

            Text("\(Int(Double(completedTrips.count) / Double(totalSites) * 100))% Complete")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .cardStyle()
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard(
                icon: "fish.fill",
                title: "Total Fish",
                value: "\(allCatches.count)",
                color: AppTheme.primary
            )
            statCard(
                icon: "leaf.fill",
                title: "Species",
                value: "\(uniqueSpeciesCount)",
                color: .green
            )
            statCard(
                icon: "ruler.fill",
                title: "Biggest",
                value: biggestCatchString,
                color: AppTheme.accent
            )
            statCard(
                icon: "flag.checkered",
                title: "Trips Done",
                value: "\(completedTrips.count)",
                color: .purple
            )
        }
    }

    private func statCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .statCardStyle()
    }

    // MARK: - Next Trip

    private var nextTripCard: some View {
        Group {
            if let nextTrip = plannedTrips.first {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundStyle(AppTheme.accent)
                        Text("NEXT TRIP")
                            .font(.caption)
                            .fontWeight(.bold)
                            .tracking(1)
                            .foregroundStyle(AppTheme.accent)
                    }

                    Text(nextTrip.name ?? "Unknown Location")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    if let date = nextTrip.date {
                        Text(date, style: .date)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    if let waterType = nextTrip.waterType {
                        Text(waterType)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.primary.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundStyle(AppTheme.primary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
            }
        }
    }

    // MARK: - Recent Trips

    private var recentTripsSection: some View {
        Group {
            if !completedTrips.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Trips")
                        .font(.headline)
                        .foregroundStyle(.white)

                    ForEach(completedTrips.prefix(3)) { trip in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(trip.name ?? "Unknown")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white)
                                if let date = trip.date {
                                    Text(date, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                            }
                            Spacer()
                            let catchCount = (trip.catches as? Set<CDCatch>)?.count ?? 0
                            Text("\(catchCount) fish")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.primary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .cardStyle()
            }
        }
    }

    // MARK: - Computed

    private var uniqueSpeciesCount: Int {
        Set(allCatches.compactMap(\.species)).count
    }

    private var biggestCatchString: String {
        guard let biggest = allCatches.max(by: { ($0.lengthInches) < ($1.lengthInches) }),
              biggest.lengthInches > 0 else {
            return "—"
        }
        return String(format: "%.1f\"", biggest.lengthInches)
    }
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
