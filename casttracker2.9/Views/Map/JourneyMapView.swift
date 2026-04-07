import SwiftUI
import MapKit
import CoreData

struct JourneyMapView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDFishingSite.siteNumber, ascending: true)]
    ) private var sites: FetchedResults<CDFishingSite>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDTrip.siteNumber, ascending: true)]
    ) private var trips: FetchedResults<CDTrip>

    @State private var selectedSite: CDFishingSite?
    @State private var filterStatus: String? = nil
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 46.7296, longitude: -94.6859),
            span: MKCoordinateSpan(latitudeDelta: 4.0, longitudeDelta: 4.0)
        )
    )

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Map(position: $cameraPosition) {
                    // Show sites if we have them
                    ForEach(filteredSites) { site in
                        Annotation(
                            site.name ?? "",
                            coordinate: CLLocationCoordinate2D(
                                latitude: site.latitude,
                                longitude: site.longitude
                            )
                        ) {
                            Button {
                                selectedSite = site
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(pinColor(for: site).opacity(0.3))
                                        .frame(width: 32, height: 32)
                                    Circle()
                                        .fill(pinColor(for: site))
                                        .frame(width: 16, height: 16)
                                    Image(systemName: "fish.fill")
                                        .font(.system(size: 8))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                    }

                    // Show trips without sites
                    ForEach(tripsWithoutSites) { trip in
                        if trip.latitude != 0 || trip.longitude != 0 {
                            Marker(
                                trip.name ?? "Trip",
                                coordinate: CLLocationCoordinate2D(
                                    latitude: trip.latitude,
                                    longitude: trip.longitude
                                )
                            )
                            .tint(trip.status == "completed" ? .green : .orange)
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))

                // Filter bar
                filterBar
                    .padding(.horizontal)
                    .padding(.top, 8)
            }
            .navigationTitle("Journey Map")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedSite) { site in
                SiteDetailSheet(site: site)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var filterBar: some View {
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

            Spacer()

            Text("\(filteredSites.count) sites")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
        }
    }

    private var filteredSites: [CDFishingSite] {
        guard let status = filterStatus else { return Array(sites) }
        return sites.filter { site in
            siteStatus(site) == status
        }
    }

    private var tripsWithoutSites: [CDTrip] {
        trips.filter { $0.site == nil }
    }

    private func siteStatus(_ site: CDFishingSite) -> String {
        let siteTrips = (site.trips as? Set<CDTrip>) ?? []
        if siteTrips.contains(where: { $0.status == "completed" }) {
            return "completed"
        }
        return "planned"
    }

    private func pinColor(for site: CDFishingSite) -> Color {
        let status = siteStatus(site)
        switch status {
        case "completed": return .green
        default: return .gray
        }
    }
}

#Preview {
    JourneyMapView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
