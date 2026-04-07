import SwiftUI
import CoreData

struct TripLogView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDTrip.date, ascending: false)],
        animation: .default
    ) private var trips: FetchedResults<CDTrip>

    @State private var showingNewTrip = false
    @State private var showingNewCatch = false
    @State private var searchText = ""
    @State private var filterStatus: String? = nil

    private var filteredTrips: [CDTrip] {
        trips.filter { trip in
            let matchesSearch = searchText.isEmpty ||
                (trip.name ?? "").localizedCaseInsensitiveContains(searchText)
            let matchesFilter = filterStatus == nil || trip.status == filterStatus
            return matchesSearch && matchesFilter
        }
    }

    private var completedTrips: [CDTrip] {
        filteredTrips.filter { $0.status == "completed" }
    }

    private var plannedTrips: [CDTrip] {
        filteredTrips.filter { $0.status == "planned" }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                List {
                    filterPicker

                    if !completedTrips.isEmpty {
                        Section("Completed") {
                            ForEach(completedTrips) { trip in
                                NavigationLink(destination: TripDetailView(trip: trip)) {
                                    TripRow(trip: trip)
                                }
                            }
                            .onDelete { offsets in
                                deleteTrips(offsets, from: completedTrips)
                            }
                        }
                    }

                    if !plannedTrips.isEmpty {
                        Section("Planned") {
                            ForEach(plannedTrips) { trip in
                                NavigationLink(destination: TripDetailView(trip: trip)) {
                                    TripRow(trip: trip)
                                }
                            }
                            .onDelete { offsets in
                                deleteTrips(offsets, from: plannedTrips)
                            }
                        }
                    }

                    if filteredTrips.isEmpty {
                        if #available(iOS 17.0, *) {
                            ContentUnavailableView(
                                "No Trips Yet",
                                systemImage: "fish",
                                description: Text("Tap + to create your first trip")
                            )
                        } else {
                            // Fallback on earlier versions
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .searchable(text: $searchText, prompt: "Search trips")
            }
            .navigationTitle("Trips")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { showingNewTrip = true }) {
                            Label("New Trip", systemImage: "plus")
                        }
                        Button(action: { showingNewCatch = true }) {
                            Label("Log Catch", systemImage: "fish.fill")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingNewTrip) {
                NewTripSheet()
            }
            .sheet(isPresented: $showingNewCatch) {
                CatchFormView(trip: nil)
            }
        }
    }

    private var filterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: filterStatus == nil) {
                    filterStatus = nil
                }
                FilterChip(title: "Completed", isSelected: filterStatus == "completed") {
                    filterStatus = "completed"
                }
                FilterChip(title: "Planned", isSelected: filterStatus == "planned") {
                    filterStatus = "planned"
                }
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }

    private func deleteTrips(_ offsets: IndexSet, from list: [CDTrip]) {
        withAnimation {
            offsets.map { list[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? AppTheme.primary : AppTheme.cardBackground)
                .foregroundStyle(isSelected ? .black : .white)
                .cornerRadius(16)
        }
    }
}

struct TripRow: View {
    let trip: CDTrip

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(trip.status == "completed" ? Color.green : Color.gray.opacity(0.4))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text(trip.name ?? "Unknown Trip")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    if let date = trip.date {
                        Text(date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let waterType = trip.waterType {
                        Text(waterType)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.primary.opacity(0.2))
                            .cornerRadius(4)
                            .foregroundStyle(AppTheme.primary)
                    }
                }
            }

            Spacer()

            let catchCount = (trip.catches as? Set<CDCatch>)?.count ?? 0
            if catchCount > 0 {
                Text("\(catchCount)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.primary)
                Image(systemName: "fish.fill")
                    .font(.caption)
                    .foregroundStyle(AppTheme.primary)
            }
        }
        .listRowBackground(AppTheme.cardBackground)
    }
}

// MARK: - New Trip Sheet

struct NewTripSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var date = Date()
    @State private var waterType = "Lake"
    @State private var season = "Spring"
    @State private var notes = ""

    private let waterTypes = ["Lake", "River", "Stream", "Pond", "Reservoir"]
    private let seasons = ["Spring", "Summer", "Fall", "Winter"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Info") {
                    TextField("Location Name", text: $name)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Picker("Water Type", selection: $waterType) {
                        ForEach(waterTypes, id: \.self) { Text($0) }
                    }
                    Picker("Season", selection: $season) {
                        ForEach(seasons, id: \.self) { Text($0) }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveTrip() }
                        .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveTrip() {
        let trip = CDTrip(context: viewContext)
        trip.id = UUID()
        trip.name = name
        trip.date = date
        trip.waterType = waterType
        trip.season = season
        trip.status = "planned"
        trip.notes = notes
        try? viewContext.save()
        dismiss()
    }
}

#Preview {
    TripLogView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
