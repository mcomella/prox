/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Firebase
import CoreLocation

private let PROVIDERS_PATH = "providers/"
private let YELP_PATH = PROVIDERS_PATH + "yelp"
private let TRIP_ADVISOR_PATH = PROVIDERS_PATH + "tripAdvisor"

class Place: Hashable {

    var hashValue : Int {
        get {
            return id.hashValue
        }
    }

    private let transitTypes: [MKDirectionsTransportType] = [.automobile, .walking]

    let id: String

    let name: String
    let latLong: CLLocationCoordinate2D

    let photoURLs: [String]

    // Optional values.
    let categories: [String]?
    let url: String?

    let address: String?

    let yelpProvider: ReviewProvider
    let tripAdvisorProvider: ReviewProvider?

    let hours: OpenHours? // if nil, there are no listed hours for this place

    var lastTravelTime: TravelTimes?

    let wikiDescription: String?
    let yelpDescription: String?

    init(id: String, name: String, wikiDescription: String? = nil, yelpDescription: String? = nil,
         latLong: CLLocationCoordinate2D, categories: [String]? = nil, url: String? = nil,
         address: String? = nil, yelpProvider: ReviewProvider,
         tripAdvisorProvider: ReviewProvider? = nil, photoURLs: [String] = [], hours: OpenHours? = nil) {
        self.id = id
        self.name = name
        self.wikiDescription = wikiDescription
        self.yelpDescription = yelpDescription
        self.latLong = latLong
        self.categories = categories
        self.url = url
        self.address = address
        self.yelpProvider = yelpProvider
        self.tripAdvisorProvider = tripAdvisorProvider
        self.photoURLs = photoURLs
        self.hours = hours
    }

    convenience init?(fromFirebaseSnapshot data: FIRDataSnapshot) {
        guard data.exists(), data.hasChildren(),
                let value = data.value as? NSDictionary,
                let id = value["id"] as? String,
                let name = value["name"] as? String,
                let coords = value["coordinates"] as? [String:Double],
                let lat = coords["lat"], let lng = coords["lng"] else {
            print("lol dropping place: missing data, id, name, or coords")
            return nil
        }

        // TODO: #38: we need to decide whether to handle having a rating OR a review. If so, don't
        // forget to update the UI.
        guard let yelpProvider = ReviewProvider(fromFirebaseSnapshot: data.childSnapshot(forPath: YELP_PATH)),
                (yelpProvider.rating != nil && yelpProvider.totalReviewCount != nil) else {
            print("lol unable to init yelp provider for place: \(id)")
            return nil
        }

        // TODO:
        // * validate incoming data
        // * b/c ^, tests
        let (wikiDescription, yelpDescription) = Place.getDescriptions(fromFirebaseValue: value)
        let categoryNames = (value["categories"] as? [[String:String]])?.flatMap { $0["text"] }
        let photoURLs = (value["images"] as? [[String:String]])?.flatMap { $0["src"] } ?? []

        guard photoURLs.count > 0 else {
            // Photo json format may also be incorrect (we default to []) but only log this to keep it simple.
            print("lol dropped place \"\(id)\": no photos")
            return nil
        }

        let hours: OpenHours?
        if value["hours"] == nil {
            hours = nil // no listed hours
        } else {
            if let hoursDictFromServer = value["hours"] as? [String : [[String]]],
                    let hoursFromServer = OpenHours.fromFirebaseValue(hoursDictFromServer) {
                hours = hoursFromServer
            } else {
                return nil // malformed hours object: fail to make the Place
            }
        }

        self.init(id: id,
                  name: name,
                  wikiDescription: wikiDescription,
                  yelpDescription: yelpDescription,
                  latLong: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                  categories: categoryNames,
                  url: value["url"] as? String,
                  address: (value["address"] as? [String])?.joined(separator: " "),
                  yelpProvider: yelpProvider,
                  tripAdvisorProvider: ReviewProvider(fromFirebaseSnapshot: data.childSnapshot(forPath: TRIP_ADVISOR_PATH)),
                  photoURLs: photoURLs,
                  hours: hours)
    }

    static func ==(lhs: Place, rhs: Place) -> Bool {
        return lhs.id == rhs.id
    }

    private static func getDescriptions(fromFirebaseValue value: NSDictionary) -> (wiki: String?, yelp: String?) {
        var wikiDescription: String?
        var yelpDescription: String?
        if let descArr = value["description"] as? [[String:String]] {
            for providerDict in descArr {
                if let provider = providerDict["provider"],
                        let text = providerDict["text"] {
                    switch provider {
                    case "yelp":
                        yelpDescription = text
                    case "wikipedia":
                        wikiDescription = text
                    default:
                        break
                    }
                }
            }
        }

        return (wiki: wikiDescription, yelp: yelpDescription)
    }

    func travelTimes(fromLocation location: CLLocation, withCallback callback: @escaping ((TravelTimes?) -> ())) {
        TravelTimesProvider.travelTime(fromLocation: location.coordinate, toLocation: latLong) { travelTimes in
            self.lastTravelTime = travelTimes
            DispatchQueue.main.async {
                callback(travelTimes)
            }
        }
    }

}

enum DayOfWeek: String {
    case monday
    case tuesday, wednesday, thursday, friday
    case saturday, sunday

    private static let Cal: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US")  // necessary for Calendar.weekdaySymbols to return long symbols.
        return cal
    }()

    static func forDate(_ date: Date) -> DayOfWeek {
        let weekdayInt = Cal.component(.weekday, from: date)
        let weekdayStr = Cal.weekdaySymbols[weekdayInt - 1]
        return DayOfWeek(rawValue: weekdayStr.lowercased())!
    }
}

struct OpenHours {

    private static let TimeInDay: TimeInterval = 60 * 60 * 24 // specified in seconds.

    /* Notes:
     *   - An entry for DayOfWeek is missing if a location is not open that day.
     *   - For simplicity, we just use the last open interval for a day.
     *   - For simplicity, dates are normalized by a single day, allowing comparison but preventing
     *     the stored dates from being correct (e.g. if today is Mon Nov 7, the stored date for Tues
     *     isn't Nov 8).
     *
     * TODO:
     *   - Use all open intervals
     *   - Use accurate days of week in Date (maybe? It adds complexity for little gain).
     */
    let hours: [DayOfWeek : (open: Date, close: Date)]

    private static let inputFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private static let outputFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short // Time will appear in users' clock config: 12hr or 24hr.
        return formatter
    }()

    /*
     * Expected format: {"monday": [ ["7:00", "14:00"], ... ] }
     * Notes:
     *   - Times are 24hr, e.g. "14:00" for 2pm
     *   - Times are in the timezone of the place
     *   - "end" < "start" if a location is open overnight
     *   - An entry for DayOfWeek will be missing if a location is not open that day
     *
     * Returns nil if data format is unexpected in any way.
     * TODO: return nil ^ or just remove the days that are malformed?
     */
    static func fromFirebaseValue(_ hoursDict: [String : [[String]]]) -> OpenHours? {
        var out = [DayOfWeek : (open: Date, close: Date)]()

        // Note: we don't check if a day is missing because if it is,
        // it's closed for the day and we're supposed to omit it anyway.
        for dayFromServer in hoursDict.keys {
            guard let day = DayOfWeek(rawValue: dayFromServer) else {
                print("lol unknown day of week from server: \(dayFromServer)")
                return nil
            }

            let hoursArr = hoursDict[dayFromServer]! // force unwrap: we're iterating over the keys.
            guard let lastInterval = hoursArr.last else {
                print("lol hours array for \(dayFromServer) unexpectedly empty")
                return nil
            }

            guard lastInterval.count == 2 else {
                print("lol last opening interval unexpectedly has \(lastInterval.count) entries")
                return nil
            }

            guard let openTime = getDate(fromServerStr: lastInterval[0]),
                    var closeTime = getDate(fromServerStr: lastInterval[1]) else {
                print("lol unable to convert date str, \(lastInterval[0]) & \(lastInterval[1]), to Date")
                return nil
            }

            if closeTime < openTime { // i.e. open overnight.
                closeTime.addTimeInterval(TimeInDay) // Date defaults to today – this happens tomorrow.
            }

            out[day] = (open: openTime, close: closeTime)
        }

        return OpenHours(hours: out)
    }

    private static func getDate(fromServerStr serverStr: String) -> Date? {
        guard serverStr.characters.count != 4 || serverStr.characters.count != 5 else { // "1:00" or "10:00"
            return nil // the calling function logs.
        }

        return inputFormatter.date(from: serverStr)
    }

    func isOpen(onDate date: Date) -> Bool {
        return hours[DayOfWeek.forDate(date)] != nil
    }

    // Note: always call isOpen(onDate) or check if day exists in dict before calling.
    func getOpenTimeString(forDate date: Date) -> String {
        return getTimeString(forDate: date) { (interval: (open: Date, close: Date)) in interval.open }
    }

    // Note: always call isOpen(onDate) or check if day exists in dict before calling.
    func getCloseTimeString(forDate date: Date) -> String {
        return getTimeString(forDate: date) { (interval: (open: Date, close: Date)) in interval.close }
    }

    private func getTimeString(forDate date: Date,
                               forIntervalDateGetter dateGetter: ((open: Date, close: Date)) -> Date) -> String {
        let openInterval = hours[DayOfWeek.forDate(date)]! // force unwrap: expect isOpen to be called.
        let desiredTime = dateGetter(openInterval)
        return OpenHours.outputFormatter.string(from: desiredTime)
    }
}
