import SwiftUI
import Charts
import CoreData

struct AnalyticsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDCatch.date, ascending: true)]
    ) private var allCatches: FetchedResults<CDCatch>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDTrip.date, ascending: true)],
        predicate: NSPredicate(format: "status == %@", "completed")
    ) private var completedTrips: FetchedResults<CDTrip>

    var body: some View {
        NavigationStack {
            ScrollView {
                if allCatches.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 16) {
                        summaryCards
                        speciesChart
                        monthlyCatchChart
                        personalRecords
                    }
                    .padding()
                }
            }
            .background(AppTheme.background)
            .navigationTitle("Analytics")
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.tertiaryText)
            Text("No Data Yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
            Text("Log your first catch to see analytics")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            summaryCard(value: "\(allCatches.count)", label: "Total Fish", color: AppTheme.primary)
            summaryCard(value: String(format: "%.1f", averageLength), label: "Avg Length\"", color: .green)
            summaryCard(value: String(format: "%.1f", fishPerTrip), label: "Fish/Trip", color: AppTheme.accent)
        }
    }

    private func summaryCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .statCardStyle()
    }

    // MARK: - Species Chart

    private var speciesChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Species Breakdown")
                .font(.headline)
                .foregroundStyle(.white)

            Chart(speciesData, id: \.species) { item in
                BarMark(
                    x: .value("Count", item.count),
                    y: .value("Species", item.species)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primary.opacity(0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(4)
                .annotation(position: .trailing, alignment: .leading, spacing: 4) {
                    Text("\(item.count)")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.white)
                }
            }
            .frame(height: CGFloat(speciesData.count) * 36)
        }
        .cardStyle()
    }

    // MARK: - Monthly Catch Chart

    private var monthlyCatchChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Catches")
                .font(.headline)
                .foregroundStyle(.white)

            Chart(monthlyCatchData, id: \.month) { item in
                LineMark(
                    x: .value("Month", item.month),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(AppTheme.primary)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Month", item.month),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.primary.opacity(0.3), AppTheme.primary.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Month", item.month),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(AppTheme.primary)
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.white.opacity(0.1))
                    AxisValueLabel()
                        .foregroundStyle(Color.white.opacity(0.6))
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.white.opacity(0.6))
                }
            }
            .frame(height: 200)
        }
        .cardStyle()
    }

    // MARK: - Leaderboard / Personal Records

    private var personalRecords: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
                Text("Catch Leaderboard")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            if topCatchBySpecies.isEmpty {
                Text("Log catches with sizes to see your leaderboard")
                    .font(.caption)
                    .foregroundStyle(AppTheme.tertiaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(topCatchBySpecies.enumerated()), id: \.element.species) { index, record in
                    HStack(spacing: 12) {
                        // Rank medal
                        ZStack {
                            Circle()
                                .fill(rankColor(index).opacity(0.2))
                                .frame(width: 32, height: 32)
                            if index < 3 {
                                Image(systemName: "medal.fill")
                                    .font(.caption)
                                    .foregroundStyle(rankColor(index))
                            } else {
                                Text("#\(index + 1)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.species)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            HStack(spacing: 6) {
                                if let date = record.date {
                                    Text(date, style: .date)
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.tertiaryText)
                                }
                                if let bait = record.bait, !bait.isEmpty {
                                    Text("on \(bait)")
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.accent)
                                }
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.1f\"", record.length))
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(AppTheme.primary)
                            if record.weight > 0 {
                                Text(String(format: "%.1f lbs", record.weight))
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                        }
                    }
                    .padding(.vertical, 6)

                    if index < topCatchBySpecies.count - 1 {
                        Divider().overlay(AppTheme.cardBorder)
                    }
                }
            }

            // Catch & release stats
            if !allCatches.isEmpty {
                Divider().overlay(AppTheme.cardBorder)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Released")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.secondaryText)
                        Text("\(releasedCount)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                    Spacer()
                    VStack(alignment: .center, spacing: 2) {
                        Text("Kept")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.secondaryText)
                        Text("\(keptCount)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Top Bait")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.secondaryText)
                        Text(topBait)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(AppTheme.accent)
                    }
                }
                .padding(.top, 4)
            }
        }
        .cardStyle()
    }

    private func rankColor(_ index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return Color(white: 0.75)
        case 2: return .brown
        default: return AppTheme.tertiaryText
        }
    }

    // MARK: - Computed Data

    private var speciesData: [(species: String, count: Int)] {
        var counts: [String: Int] = [:]
        for c in allCatches {
            let s = c.species ?? "Unknown"
            counts[s, default: 0] += 1
        }
        return counts.map { (species: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    private var monthlyCatchData: [(month: String, count: Int)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        var counts: [String: Int] = [:]
        let monthOrder = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

        for c in allCatches {
            guard let date = c.date else { continue }
            let month = formatter.string(from: date)
            counts[month, default: 0] += 1
        }

        return monthOrder.compactMap { month in
            guard let count = counts[month] else { return nil }
            return (month: month, count: count)
        }
    }

    private var averageLength: Double {
        let validCatches = allCatches.filter { $0.lengthInches > 0 }
        guard !validCatches.isEmpty else { return 0 }
        return validCatches.reduce(0.0) { $0 + $1.lengthInches } / Double(validCatches.count)
    }

    private var fishPerTrip: Double {
        guard !completedTrips.isEmpty else { return 0 }
        return Double(allCatches.count) / Double(completedTrips.count)
    }

    struct SpeciesRecord {
        let species: String
        let length: Double
        let weight: Double
        let date: Date?
        let bait: String?
    }

    private var topCatchBySpecies: [SpeciesRecord] {
        var records: [String: CDCatch] = [:]
        for c in allCatches where c.lengthInches > 0 {
            let species = c.species ?? "Unknown"
            if let existing = records[species] {
                if c.lengthInches > existing.lengthInches {
                    records[species] = c
                }
            } else {
                records[species] = c
            }
        }
        return records.map {
            SpeciesRecord(
                species: $0.key,
                length: $0.value.lengthInches,
                weight: $0.value.weightLbs,
                date: $0.value.date,
                bait: $0.value.baitLure
            )
        }
        .sorted { $0.length > $1.length }
    }

    private var keptCount: Int {
        allCatches.filter(\.isKept).count
    }

    private var releasedCount: Int {
        allCatches.count - keptCount
    }

    private var topBait: String {
        var counts: [String: Int] = [:]
        for c in allCatches {
            guard let bait = c.baitLure, !bait.isEmpty else { continue }
            counts[bait, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key ?? "—"
    }
}

#Preview {
    AnalyticsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
