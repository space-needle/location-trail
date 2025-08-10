import Foundation
import CoreLocation

// Structs for parsing the Google Maps Geocoding API response
struct GeocodingResponse: Codable {
    let results: [GeocodingResult]
    let status: String
}

struct GeocodingResult: Codable {
    let formattedAddress: String

    enum CodingKeys: String, CodingKey {
        case formattedAddress = "formatted_address"
    }
}

// A struct to represent a detected place before it's enriched with address info.
struct DetectedPlace {
    let coordinate: CLLocationCoordinate2D
    let startTime: Date
    let endTime: Date
    let locationSamples: [Location] // The raw location points that make up this place
}

class PlaceDetectionService {

    // The main function where the user will add their custom algorithm.
    // It takes an array of sorted location objects and returns an array of detected places.
    func detectPlaces(from locations: [Location]) -> [DetectedPlace] {
        print("Starting place detection with \(locations.count) locations...")

        // --- SKELETON LOGIC ---
        // This is where the user's custom algorithm will go.
        // The basic idea is to iterate through the locations and identify
        // "clusters" of points that are close to each other in space and time.

        // For now, this is a placeholder. It does not contain any real logic.
        // It simply returns an empty array.
        var detectedPlaces: [DetectedPlace] = []

        // Example of how one might create a DetectedPlace once a cluster is found:
        /*
        if !cluster.isEmpty {
            let place = DetectedPlace(
                coordinate: calculateCenterOf(cluster),
                startTime: cluster.first!.timestamp!,
                endTime: cluster.last!.timestamp!,
                locationSamples: cluster
            )
            detectedPlaces.append(place)
        }
        */

        print("Finished place detection. Found \(detectedPlaces.count) places.")
        return detectedPlaces
    }

    // --- HELPER FUNCTION EXAMPLE ---
    // A helper function to calculate the center of a cluster of locations.
    private func calculateCenterOf(_ locations: [Location]) -> CLLocationCoordinate2D {
        guard !locations.isEmpty else {
            // In a real app, you might want to handle this error more gracefully.
            return kCLLocationCoordinate2DInvalid
        }

        let totalLatitude = locations.reduce(0.0) { $0 + $1.latitude }
        let totalLongitude = locations.reduce(0.0) { $0 + $1.longitude }

        let averageLatitude = totalLatitude / Double(locations.count)
        let averageLongitude = totalLongitude / Double(locations.count)

        return CLLocationCoordinate2D(latitude: averageLatitude, longitude: averageLongitude)
    }

    // Function to get an address from coordinates using Google Maps API
    func getAddressFromCoordinates(apiKey: String, coordinates: CLLocationCoordinate2D) async -> String? {
        // 1. Construct the URL
        var components = URLComponents(string: "https://maps.googleapis.com/maps/api/geocode/json")
        components?.queryItems = [
            URLQueryItem(name: "latlng", value: "\(coordinates.latitude),\(coordinates.longitude)"),
            URLQueryItem(name: "key", value: apiKey)
        ]

        guard let url = components?.url else {
            print("Error: Could not create URL for Google Maps API.")
            return nil
        }

        // 2. Make the network request
        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Error: Invalid response from Google Maps API.")
                return nil
            }

            // 3. Decode the JSON response
            let decoder = JSONDecoder()
            let geocodingResponse = try decoder.decode(GeocodingResponse.self, from: data)

            // 4. Return the first formatted address
            if geocodingResponse.status == "OK", let firstResult = geocodingResponse.results.first {
                return firstResult.formattedAddress
            } else {
                print("Error: Google Maps API returned status: \(geocodingResponse.status)")
                return nil
            }

        } catch {
            print("Error during Google Maps API call: \(error.localizedDescription)")
            return nil
        }
    }
}
