import SwiftUI

struct ConfigView: View {
    @ObservedObject var locationManager: LocationManager
    @Environment(\.presentationMode) var presentationMode

    @State private var trackingEnabled: Bool
    @State private var trackingInterval: Double = 5.0 // in minutes

    private let intervals = [1.0, 5.0, 15.0, 30.0, 60.0]

    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        _trackingEnabled = State(initialValue: locationManager.isTracking)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Location Tracking")) {
                    Toggle("Enable Tracking", isOn: $trackingEnabled)
                        .onChange(of: trackingEnabled) { value in
                            if value {
                                locationManager.startTracking()
                            } else {
                                locationManager.stopTracking()
                            }
                        }
                }

                Section(header: Text("Tracking Frequency")) {
                    Picker("Update every", selection: $trackingInterval) {
                        ForEach(intervals, id: \.self) { interval in
                            Text("\(Int(interval)) minute(s)")
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(!trackingEnabled)
                    .onChange(of: trackingInterval) { value in
                        locationManager.setFrequency(minutes: value)
                    }
                }

                Section {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("Configuration")
        }
    }
}

struct ConfigView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigView(locationManager: LocationManager())
    }
}
