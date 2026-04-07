import SwiftUI
import CoreData
import MapKit

struct TripDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var trip: CDTrip
    @State private var showingCatchForm = false
    @State private var showingYouTubeChapters = false

    private var catches: [CDCatch] {
        let set = trip.catches as? Set<CDCatch> ?? []
        return set.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }

    private var checklistItems: [CDChecklistItem] {
        let set = trip.checklist as? Set<CDChecklistItem> ?? []
        return set.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                tripHeader
                if trip.latitude != 0 && trip.longitude != 0 {
                    mapSnippet
                }
                if trip.status == "planned" {
                    checklistSection
                }
                statsRow
                catchesList
            }
            .padding()
        }
        .background(AppTheme.background)
        .navigationTitle(trip.name ?? "Trip")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { ensureChecklist() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingCatchForm = true }) {
                    Label("Log Catch", systemImage: "fish.fill")
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                Menu {
                    if trip.status == "planned" {
                        Button("Mark Completed") {
                            trip.status = "completed"
                            try? viewContext.save()
                        }
                    } else {
                        Button("Mark Planned") {
                            trip.status = "planned"
                            try? viewContext.save()
                        }
                    }

                    Divider()

                    Button {
                        showingYouTubeChapters = true
                    } label: {
                        Label("YouTube Chapters", systemImage: "play.rectangle.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingCatchForm) {
            CatchFormView(trip: trip)
        }
        .sheet(isPresented: $showingYouTubeChapters) {
            YouTubeChaptersView(trip: trip)
                .presentationDetents([.large])
        }
    }

    // MARK: - Trip Header

    private var tripHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(trip.status == "completed" ? "COMPLETED" : "PLANNED")
                    .font(.caption)
                    .fontWeight(.bold)
                    .tracking(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(trip.status == "completed" ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                    .foregroundStyle(trip.status == "completed" ? .green : .orange)
                    .cornerRadius(8)

                Spacer()

                if let season = trip.season {
                    Text(season)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            if let date = trip.date {
                Text(date, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            if let waterType = trip.waterType {
                HStack(spacing: 4) {
                    Image(systemName: "drop.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.primary)
                    Text(waterType)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            if let notes = trip.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(AppTheme.tertiaryText)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Map

    private var mapSnippet: some View {
        let coordinate = CLLocationCoordinate2D(latitude: trip.latitude, longitude: trip.longitude)
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))

        return Map(initialPosition: .region(region)) {
            Marker(trip.name ?? "Trip", coordinate: coordinate)
                .tint(trip.status == "completed" ? .green : .orange)
        }
        .frame(height: 180)
        .cornerRadius(12)
        .allowsHitTesting(false)
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 12) {
            miniStat(value: "\(catches.count)", label: "Fish", icon: "fish.fill")
            if let biggest = catches.max(by: { $0.lengthInches < $1.lengthInches }), biggest.lengthInches > 0 {
                miniStat(value: String(format: "%.1f\"", biggest.lengthInches), label: "Biggest", icon: "ruler")
            }
            let speciesCount = Set(catches.compactMap(\.species)).count
            miniStat(value: "\(speciesCount)", label: "Species", icon: "leaf.fill")
        }
    }

    private func miniStat(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(AppTheme.primary)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .statCardStyle()
    }

    // MARK: - Checklist

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checklist")
                    .foregroundStyle(AppTheme.accent)
                Text("Pre-Trip Checklist")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                let done = checklistItems.filter(\.isCompleted).count
                Text("\(done)/\(checklistItems.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(done == checklistItems.count && !checklistItems.isEmpty ? .green : AppTheme.secondaryText)
            }

            if checklistItems.isEmpty {
                Text("Loading checklist...")
                    .font(.caption)
                    .foregroundStyle(AppTheme.tertiaryText)
            } else {
                ForEach(checklistItems) { item in
                    Button {
                        item.isCompleted.toggle()
                        try? viewContext.save()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(item.isCompleted ? .green : AppTheme.tertiaryText)
                                .font(.body)
                            Text(item.name ?? "")
                                .font(.subheadline)
                                .foregroundStyle(item.isCompleted ? AppTheme.tertiaryText : .white)
                                .strikethrough(item.isCompleted)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    private func ensureChecklist() {
        let existing = trip.checklist as? Set<CDChecklistItem> ?? []
        guard existing.isEmpty, trip.status == "planned" else { return }

        for (i, name) in DefaultChecklist.items.enumerated() {
            let item = CDChecklistItem(context: viewContext)
            item.id = UUID()
            item.name = name
            item.sortOrder = Int32(i)
            item.isCompleted = false
            item.trip = trip
        }
        try? viewContext.save()
    }

    // MARK: - Catches

    private var catchesList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Catches")
                .font(.headline)
                .foregroundStyle(.white)

            if catches.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "fish")
                        .font(.largeTitle)
                        .foregroundStyle(AppTheme.tertiaryText)
                    Text("No catches logged yet")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                    Button("Log a Catch") { showingCatchForm = true }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(catches) { c in
                    CatchRow(catchEntry: c)
                }
            }
        }
        .cardStyle()
    }
}

struct CatchRow: View {
    let catchEntry: CDCatch

    var body: some View {
        HStack(spacing: 12) {
            if let photoData = catchEntry.photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.primary.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "fish.fill")
                            .foregroundStyle(AppTheme.primary)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(catchEntry.species ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)

                HStack(spacing: 8) {
                    if catchEntry.lengthInches > 0 {
                        Text(String(format: "%.1f\"", catchEntry.lengthInches))
                            .font(.caption)
                            .foregroundStyle(AppTheme.primary)
                    }
                    if catchEntry.weightLbs > 0 {
                        Text(String(format: "%.1f lbs", catchEntry.weightLbs))
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    if let bait = catchEntry.baitLure, !bait.isEmpty {
                        Text(bait)
                            .font(.caption2)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(AppTheme.accent.opacity(0.2))
                            .cornerRadius(4)
                            .foregroundStyle(AppTheme.accent)
                    }
                    if let weather = catchEntry.weatherConditions {
                        if let condition = WeatherCondition(rawValue: weather) {
                            Image(systemName: condition.icon)
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                }

                if catchEntry.isKept {
                    Text("Kept")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                } else {
                    Text("Released")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            if let date = catchEntry.date {
                Text(date, style: .time)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.tertiaryText)
            }
        }
        .padding(.vertical, 4)
    }
}
