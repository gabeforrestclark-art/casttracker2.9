import SwiftUI
import CoreData

struct YouTubeChaptersView: View {
    let trip: CDTrip
    @State private var introLength: Int = 30
    @State private var catchClipLength: Int = 120
    @State private var includeOutro: Bool = true
    @State private var copied = false

    private var catches: [CDCatch] {
        let set = trip.catches as? Set<CDCatch> ?? []
        return set.sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    settingsSection
                    previewSection
                    copyButton
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("YouTube Chapters")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Chapter Settings")
                .font(.headline)
                .foregroundStyle(.white)

            HStack {
                Text("Intro length")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                Spacer()
                Stepper("\(introLength)s", value: $introLength, in: 10...120, step: 10)
                    .font(.subheadline)
            }

            HStack {
                Text("Per-catch clip")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                Spacer()
                Stepper("\(catchClipLength)s", value: $catchClipLength, in: 30...300, step: 30)
                    .font(.subheadline)
            }

            Toggle("Include outro", isOn: $includeOutro)
                .font(.subheadline)
        }
        .cardStyle()
    }

    // MARK: - Preview

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "play.rectangle.fill")
                    .foregroundStyle(.red)
                Text("Chapter Preview")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            if catches.isEmpty {
                Text("No catches logged — chapters need at least one catch")
                    .font(.caption)
                    .foregroundStyle(AppTheme.tertiaryText)
                    .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(generatedChapters.enumerated()), id: \.offset) { _, chapter in
                        HStack(alignment: .top, spacing: 8) {
                            Text(chapter.timestamp)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(AppTheme.primary)
                                .frame(width: 50, alignment: .leading)

                            Text(chapter.title)
                                .font(.subheadline)
                                .foregroundStyle(.white)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)

                Text("Estimated video length: \(formattedDuration(totalSeconds))")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .cardStyle()
    }

    // MARK: - Copy Button

    private var copyButton: some View {
        Button {
            UIPasteboard.general.string = chaptersText
            copied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
        } label: {
            HStack {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                Text(copied ? "Copied!" : "Copy Chapters to Clipboard")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(copied ? Color.green : AppTheme.primary)
            .foregroundStyle(copied ? .white : .black)
            .cornerRadius(12)
        }
        .disabled(catches.isEmpty)
    }

    // MARK: - Chapter Generation

    struct Chapter {
        let timestamp: String
        let title: String
    }

    private var generatedChapters: [Chapter] {
        var chapters: [Chapter] = []
        var currentSecond = 0

        // Intro
        let tripName = trip.name ?? "Fishing Trip"
        let dateStr: String
        if let date = trip.date {
            let f = DateFormatter()
            f.dateStyle = .medium
            dateStr = f.string(from: date)
        } else {
            dateStr = ""
        }
        chapters.append(Chapter(
            timestamp: formatTimestamp(currentSecond),
            title: "Intro — \(tripName) \(dateStr)"
        ))
        currentSecond += introLength

        // Setup / arrival
        chapters.append(Chapter(
            timestamp: formatTimestamp(currentSecond),
            title: "Arrival & Setup"
        ))
        currentSecond += 60

        // Each catch
        for (i, c) in catches.enumerated() {
            let species = c.species ?? "Fish"
            var title = "Catch #\(i + 1) — \(species)"

            if c.lengthInches > 0 {
                title += String(format: " (%.1f\"", c.lengthInches)
                if c.weightLbs > 0 {
                    title += String(format: ", %.1f lbs", c.weightLbs)
                }
                title += ")"
            }

            if let bait = c.baitLure, !bait.isEmpty {
                title += " on \(bait)"
            }

            chapters.append(Chapter(
                timestamp: formatTimestamp(currentSecond),
                title: title
            ))
            currentSecond += catchClipLength
        }

        // Wrap-up
        chapters.append(Chapter(
            timestamp: formatTimestamp(currentSecond),
            title: "Trip Recap & Stats"
        ))
        currentSecond += 60

        // Outro
        if includeOutro {
            chapters.append(Chapter(
                timestamp: formatTimestamp(currentSecond),
                title: "Outro — Like, Subscribe & Support"
            ))
            currentSecond += 30
        }

        return chapters
    }

    private var totalSeconds: Int {
        introLength + 60 + (catches.count * catchClipLength) + 60 + (includeOutro ? 30 : 0)
    }

    private var chaptersText: String {
        generatedChapters.map { "\($0.timestamp) \($0.title)" }.joined(separator: "\n")
    }

    private func formatTimestamp(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }

    private func formattedDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        if m >= 60 {
            return String(format: "%dh %dm", m / 60, m % 60)
        }
        return String(format: "%dm %ds", m, s)
    }
}
