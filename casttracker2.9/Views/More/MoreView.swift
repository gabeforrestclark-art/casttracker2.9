import SwiftUI

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Coming Soon") {
                    comingSoonRow(icon: "megaphone.fill", title: "Social", subtitle: "Multi-platform publishing & scheduling", color: .blue)
                    comingSoonRow(icon: "star.fill", title: "Sponsors", subtitle: "Sponsorship tracking & management", color: .yellow)
                    comingSoonRow(icon: "dollarsign.circle.fill", title: "Fundraising", subtitle: "GoFundMe & Patreon integration", color: .green)
                    comingSoonRow(icon: "photo.stack.fill", title: "Media Campaign", subtitle: "Campaign assets & media library", color: .purple)
                    comingSoonRow(icon: "map.fill", title: "Roadmap", subtitle: "4-year journey timeline & milestones", color: AppTheme.primary)
                }

                Section("App") {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(AppTheme.primary)
                        Text("Cast Tracker v2.9")
                        Spacer()
                        Text("Season 1 — 2026")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle("More")
        }
    }

    private func comingSoonRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("Soon")
                .font(.caption2)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(color.opacity(0.15))
                .foregroundStyle(color)
                .cornerRadius(8)
        }
        .listRowBackground(AppTheme.cardBackground)
    }
}

#Preview {
    MoreView()
}
