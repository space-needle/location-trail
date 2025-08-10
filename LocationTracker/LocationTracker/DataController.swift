import Foundation
import CoreData
import CoreLocation

class DataController: ObservableObject {
    let container = NSPersistentContainer(name: "LocationTracker")

    init() {
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }

    func saveLocation(location: CLLocation) {
        let newLocation = Location(context: container.viewContext)
        newLocation.latitude = location.coordinate.latitude
        newLocation.longitude = location.coordinate.longitude
        newLocation.timestamp = location.timestamp

        saveContext()
    }

    func fetchLocations(for date: Date) -> [Location] {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: date)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!

        let request: NSFetchRequest<Location> = Location.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Location.timestamp, ascending: true)]

        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Failed to fetch locations: \(error.localizedDescription)")
            return []
        }
    }

    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

// In a real Xcode project, the following code would be in auto-generated files.
// (e.g., Location+CoreDataClass.swift and Location+CoreDataProperties.swift)
// It's included here for completeness.

@objc(Location)
public class Location: NSManagedObject {

}

extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var timestamp: Date?

}

extension Location : Identifiable {

}
