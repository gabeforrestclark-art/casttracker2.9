import SwiftUI
import CoreData

struct SiteDetailSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    let site: CDFishingSite

    private var siteTrips: [CDTrip] {
        let set = (site.trips as? Set<CDTrip>) ?? []
        return set.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }

    private var isCompleted: Bool {
        siteTrips.contains { $0.status == "completed" }
    }

    private var totalCatches: Int {
        siteTrips.reduce(0) { sum, trip in
            sum + ((trip.catches as? Set<CDCatch>)?.count ?? 0)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerSection
                    detailsCard
                    targetSpeciesSection
                    recommendedBaitSection

                    if isCompleted {
                        statsSection
                    }

                    loreSection
                    easterEggSection
                    youtubeSection
                    baitShopSection
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle(site.name ?? "Site")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isCompleted ? .green : .orange)
            Text(isCompleted ? "Completed" : "Planned")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(isCompleted ? .green : .orange)

            Spacer()

            if let zone = site.siteZone, !zone.isEmpty {
                Text(zone)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(zone == "Local Circuit" ? Color.blue.opacity(0.2) : AppTheme.accent.opacity(0.2))
                    .foregroundStyle(zone == "Local Circuit" ? .blue : AppTheme.accent)
                    .cornerRadius(8)
            }

            if site.siteNumber > 0 {
                Text("#\(site.siteNumber)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.primary.opacity(0.2))
                    .cornerRadius(8)
                    .foregroundStyle(AppTheme.primary)
            }
        }
    }

    // MARK: - Details

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let waterBody = site.waterBody, !waterBody.isEmpty {
                DetailRow(icon: "water.waves", label: "Water Body", value: waterBody)
            }
            if let waterType = site.waterType {
                DetailRow(icon: "drop.fill", label: "Water Type", value: waterType)
            }
            DetailRow(
                icon: "location.fill",
                label: "Coordinates",
                value: String(format: "%.4f, %.4f", site.latitude, site.longitude)
            )
        }
        .cardStyle()
    }

    // MARK: - Target Species

    private var targetSpeciesSection: some View {
        Group {
            if let species = site.targetSpecies, !species.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "fish.fill")
                            .foregroundStyle(AppTheme.primary)
                        Text("Target Species")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }

                    let speciesList = species.components(separatedBy: ", ")
                    FlowLayout(spacing: 6) {
                        ForEach(speciesList, id: \.self) { sp in
                            Text(sp)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(AppTheme.primary.opacity(0.15))
                                .foregroundStyle(AppTheme.primary)
                                .cornerRadius(12)
                        }
                    }
                }
                .cardStyle()
            }
        }
    }

    // MARK: - Recommended Bait

    private var recommendedBaitSection: some View {
        Group {
            if let bait = site.recommendedBait, !bait.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "fishhook")
                            .foregroundStyle(AppTheme.accent)
                        Text("Recommended Bait & Lures")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }

                    let baits = bait.components(separatedBy: ", ")
                    ForEach(baits, id: \.self) { b in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(AppTheme.accent)
                                .frame(width: 5, height: 5)
                                .padding(.top, 6)
                            Text(b)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                }
                .cardStyle()
            }
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 16) {
            VStack {
                Text("\(siteTrips.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Text("Trips")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)

            VStack {
                Text("\(totalCatches)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.primary)
                Text("Fish")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
        }
        .statCardStyle()
    }

    // MARK: - Lore

    private var loreSection: some View {
        Group {
            if let lore = site.lore, !lore.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "book.fill")
                            .foregroundStyle(.purple)
                        Text("Local Lore")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    Text(lore)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .cardStyle()
            }
        }
    }

    // MARK: - Easter Egg

    private var easterEggSection: some View {
        Group {
            if let egg = site.easterEgg, !egg.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.yellow)
                        Text("Hidden Gem")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    Text(egg)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                        .italic()
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.yellow.opacity(0.08), Color.orange.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - YouTube

    private var youtubeSection: some View {
        Group {
            if let idea = site.youtubeIdea, !idea.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.rectangle.fill")
                            .foregroundStyle(.red)
                        Text("Content Idea")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    Text(idea)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .cardStyle()
            }
        }
    }

    // MARK: - Bait Shop

    private var baitShopSection: some View {
        Group {
            if let shop = site.baitShopInfo, !shop.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "storefront.fill")
                            .foregroundStyle(.green)
                        Text("Bait & Tackle Shop")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    Text(shop)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .cardStyle()
            }
        }
    }
}

// MARK: - Flow Layout for species tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(AppTheme.primary)
                .frame(width: 20)
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
    }
}
