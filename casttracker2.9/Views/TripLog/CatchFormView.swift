import SwiftUI
import PhotosUI
import CoreData

struct CatchFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let trip: CDTrip?

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDTrip.date, ascending: false)]
    ) private var allTrips: FetchedResults<CDTrip>

    @State private var selectedTrip: CDTrip?
    @State private var species: FishSpecies = .walleye
    @State private var lengthText = ""
    @State private var weightText = ""
    @State private var weather: WeatherCondition = .partlyCloudy
    @State private var waterClarity: WaterClarity = .clear
    @State private var waterTempText = ""
    @State private var baitLure: BaitLure = .jig
    @State private var isKept = false
    @State private var notes = ""
    @State private var date = Date()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip") {
                    if trip != nil {
                        Text(trip?.name ?? "Unknown Trip")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Select Trip", selection: $selectedTrip) {
                            Text("None").tag(nil as CDTrip?)
                            ForEach(allTrips) { t in
                                Text(t.name ?? "Unknown").tag(t as CDTrip?)
                            }
                        }
                    }
                }

                Section("Catch Details") {
                    Picker("Species", selection: $species) {
                        ForEach(FishSpecies.allCases) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }

                    DatePicker("Date & Time", selection: $date)

                    HStack {
                        Text("Length")
                        Spacer()
                        TextField("inches", text: $lengthText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("in")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("lbs", text: $weightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("lbs")
                            .foregroundStyle(.secondary)
                    }

                    Picker("Bait / Lure", selection: $baitLure) {
                        ForEach(BaitLure.allCases) { b in
                            Text(b.rawValue).tag(b)
                        }
                    }

                    Toggle("Kept", isOn: $isKept)
                }

                Section("Conditions") {
                    Picker("Weather", selection: $weather) {
                        ForEach(WeatherCondition.allCases) { w in
                            Label(w.rawValue, systemImage: w.icon).tag(w)
                        }
                    }

                    Picker("Water Clarity", selection: $waterClarity) {
                        ForEach(WaterClarity.allCases) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }

                    HStack {
                        Text("Water Temp")
                        Spacer()
                        TextField("°F", text: $waterTempText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("°F")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Photo") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        if let photoData, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(8)
                        } else {
                            Label("Add Photo", systemImage: "camera.fill")
                        }
                    }
                    .onChange(of: selectedPhoto) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data),
                               let compressed = image.jpegData(compressionQuality: 0.7) {
                                photoData = compressed
                            }
                        }
                    }

                    if photoData != nil {
                        Button("Remove Photo", role: .destructive) {
                            photoData = nil
                            selectedPhoto = nil
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }
            }
            .navigationTitle("Log Catch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveCatch() }
                }
            }
        }
        .onAppear {
            selectedTrip = trip
        }
    }

    private func saveCatch() {
        let catchEntry = CDCatch(context: viewContext)
        catchEntry.id = UUID()
        catchEntry.species = species.rawValue
        catchEntry.date = date
        catchEntry.lengthInches = Double(lengthText) ?? 0
        catchEntry.weightLbs = Double(weightText) ?? 0
        catchEntry.weatherConditions = weather.rawValue
        catchEntry.waterClarity = waterClarity.rawValue
        catchEntry.waterTemp = Double(waterTempText) ?? 0
        catchEntry.baitLure = baitLure.rawValue
        catchEntry.isKept = isKept
        catchEntry.notes = notes
        catchEntry.photoData = photoData

        let targetTrip = trip ?? selectedTrip
        catchEntry.trip = targetTrip

        if targetTrip?.status == "planned" {
            targetTrip?.status = "completed"
        }

        try? viewContext.save()
        dismiss()
    }
}

#Preview {
    CatchFormView(trip: nil)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
