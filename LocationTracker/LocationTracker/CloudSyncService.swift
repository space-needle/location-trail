import Foundation

// A struct representing the final "place" object to be uploaded, matching the API specification.
struct VisitedPlace: Codable {
    let userId: String
    let place: PlaceCoordinates
    let placeAddress: String?
    let placeName: String?
    let placeAliases: [String]?
    let startTime: Date
    let endTime: Date

    // Maps the Swift struct properties to the snake_case JSON keys.
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case place
        case placeAddress = "place_address"
        case placeName = "place_name"
        case placeAliases = "place_aliases"
        case startTime = "start_time"
        case endTime = "end_time"
    }
}

// A helper struct for the nested coordinate object.
struct PlaceCoordinates: Codable {
    let longitude: Double
    let latitude: Double
}


class CloudSyncService {

    // A placeholder URL for the mock service endpoint.
    private let mockServiceURL = URL(string: "https://api.mockservice.io/v1/places")!

    // Asynchronously uploads a VisitedPlace object to the cloud service.
    func uploadVisitedPlace(_ place: VisitedPlace) async {
        print("Uploading place: \(place.placeName ?? "Unknown") for user \(place.userId)")

        // 1. Prepare the URLRequest
        var request = URLRequest(url: mockServiceURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // In a real application, an authentication token would be added here.
        // For example: request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        // 2. Encode the VisitedPlace object into JSON data.
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601 // A standard format for dates.
        do {
            request.httpBody = try encoder.encode(place)
        } catch {
            print("Error: Failed to encode VisitedPlace object: \(error.localizedDescription)")
            return
        }

        // 3. Perform the network request using URLSession.
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Error: Did not receive a valid HTTP response.")
                return
            }

            if (200...299).contains(httpResponse.statusCode) {
                print("Successfully uploaded place. Server responded with status code: \(httpResponse.statusCode)")
                // Here you could optionally decode a success response from the server if needed.
            } else {
                print("Error: The server responded with a failure status code: \(httpResponse.statusCode)")
                // For debugging, print the response body.
                if let responseBody = String(data: data, encoding: .utf8) {
                    print("Server response body: \(responseBody)")
                }
            }
        } catch {
            print("Error: The network request failed: \(error.localizedDescription)")
        }
    }
}
