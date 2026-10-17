import Foundation
import MapKit

protocol CategoriesService: Sendable {
    func categories() -> [POICategory]
}

struct MapKitCategoriesService: CategoriesService {
    func categories() -> [POICategory] {
        Self.categoryMappings.map { mapping in
            POICategory(
                id: mapping.id,
                mapkitValue: mapping.category.rawValue
            )
        }
    }

    private static let categoryMappings: [(id: String, category: MKPointOfInterestCategory)] = [
        ("airport", .airport),
        ("amusement_park", .amusementPark),
        ("aquarium", .aquarium),
        ("atm", .atm),
        ("bakery", .bakery),
        ("bank", .bank),
        ("beach", .beach),
        ("brewery", .brewery),
        ("cafe", .cafe),
        ("campground", .campground),
        ("car_rental", .carRental),
        ("ev_charger", .evCharger),
        ("fire_station", .fireStation),
        ("fitness_center", .fitnessCenter),
        ("food_market", .foodMarket),
        ("gas_station", .gasStation),
        ("hospital", .hospital),
        ("hotel", .hotel),
        ("laundry", .laundry),
        ("library", .library),
        ("marina", .marina),
        ("movie_theater", .movieTheater),
        ("museum", .museum),
        ("national_park", .nationalPark),
        ("nightlife", .nightlife),
        ("park", .park),
        ("parking", .parking),
        ("pharmacy", .pharmacy),
        ("police", .police),
        ("post_office", .postOffice),
        ("public_transport", .publicTransport),
        ("restaurant", .restaurant),
        ("restroom", .restroom),
        ("school", .school),
        ("stadium", .stadium),
        ("store", .store),
        ("theater", .theater),
        ("university", .university),
        ("winery", .winery),
        ("zoo", .zoo)
    ]
}
