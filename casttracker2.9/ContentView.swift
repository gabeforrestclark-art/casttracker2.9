import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                
                }

            Group {
                if #available(iOS 17.0, *) {
                    JourneyMapView()
                } else {
                    Text("Map requires iOS 17")
                        .foregroundStyle(.secondary)
                }
            }
            .tabItem {
                Label("Map", systemImage: "map.fill")
            }

            TripLogView()
                .tabItem {
                    Label("Trips", systemImage: "list.bullet")
                }

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }

            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis")
                }
        }
        .tint(AppTheme.primary)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
