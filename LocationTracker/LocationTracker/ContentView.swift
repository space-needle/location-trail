import SwiftUI
import MapKit

struct ContentView: View {
    @EnvironmentObject var dataController: DataController
    @StateObject private var locationManager = LocationManager()

    @State private var selectedDate = Date()
    @State private var locations: [Location] = []
    @State private var showingConfig = false

    // A region for the map, centered on a default location
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default: San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    var body: some View {
        NavigationView {
            VStack {
                Map(coordinateRegion: $region, annotationItems: locations) { location in
                    MapPin(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude), tint: .red)
                }
                .onAppear(perform: setupLocationManager)

                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .padding()
                    .onChange(of: selectedDate) { _ in
                        fetchLocationsForSelectedDate()
                    }

                Text("Showing locations for: \(selectedDate, formatter: itemFormatter)")
            }
            .navigationTitle("Location Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingConfig = true
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingConfig) {
                ConfigView(locationManager: locationManager)
            }
            .onAppear(perform: fetchLocationsForSelectedDate)
        }
    }

    private func setupLocationManager() {
        locationManager.didUpdateLocation = { clLocation in
            dataController.saveLocation(location: clLocation)
            // If the new location is on the currently selected date, update the map
            if Calendar.current.isDate(clLocation.timestamp, inSameDayAs: selectedDate) {
                fetchLocationsForSelectedDate()
            }
            // Update region to center on the new location
            region.center = clLocation.coordinate
        }
    }

    private func fetchLocationsForSelectedDate() {
        locations = dataController.fetchLocations(for: selectedDate)
        // If there are locations, center the map on the first one
        if let firstLocation = locations.first {
            region.center = CLLocationCoordinate2D(latitude: firstLocation.latitude, longitude: firstLocation.longitude)
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    formatter.timeStyle = .none
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(DataController())
    }
}
