//
//  ViewModels.swift
//  purs
//
//  Created by Kim Thuy Ha on 6/7/24.
//

import Foundation
import SwiftUI


//===== Models
struct Location: Decodable {
    var location_name: String = ""
    var hours: [OpeningHours] = []
    init(dataString: String) throws {
        let jsonData = dataString.data(using: .utf8)!
        let decoder = JSONDecoder()
        self = try decoder.decode(Location.self, from: jsonData)
    }
    // Custom initializer to fetch and decode data
    static func fromUrl(fromURL urlString: String, completion: @escaping (Result<Location, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -1, userInfo: nil)))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let location = try decoder.decode(Location.self, from: data)
                completion(.success(location))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

struct OpeningHours: Decodable {
    let day_of_week: String
    let start_local_time: String
    var end_local_time: String
}

// For the status message
enum OpenHoursStatus {
    case openUntil(closingTime: String)
    case reopeningSoon(closingTime: String, nextOpeningTime: String)
    case openAgain(time: String)
    case openLater(day: String, time: String)
    case closed
    
    // Function to determine the status based on current time and hours data
    static func getCurrentStatus(openingHours: [OpeningHours]) -> OpenHoursStatus {
        if openingHours.count == 0 {
            return .closed
        }
        // Get current time and day of the week
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let currentTimeString = formatter.string(from: now)
        
        let calendar = Calendar.current
        let weekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
        let currentDayString = weekdays[calendar.component(.weekday, from: now)-1]
        var start = 0
        
        // Loop till there is an opening time for today
        let currentDayIndex = dayIndex(for: currentDayString)
        while start < openingHours.count && dayIndex(for: openingHours[start].day_of_week) < currentDayIndex {
            start += 1
        }
        if start >= openingHours.count {
            start = 0
        }
        
        // Check if now is within any of today's range
        let count = openingHours.count
        while start < count && openingHours[start].day_of_week == currentDayString && currentTimeString >= openingHours[start].start_local_time{
            // if within check if within an hour of closing
            if currentTimeString < openingHours[start].end_local_time {
                var endRange = openingHours[start]
                var curr = start
                // handle the case where close == 24:00:00 and open == 00:00:00 on multiple day
                for i in 1...count {
                    let nextInd = (start + i)%count
                    if !(openingHours[curr].end_local_time == "24:00:00" && openingHours[nextInd].start_local_time == "00:00:00") {
                        endRange = openingHours[curr]
                        break
                    }
                    curr = nextInd
                }
                // check hou much time until closing
                let dist = timeFromNowTill(nextRange:endRange, start: false)
                if dist != nil && dist! > 3600 {
                    return .openUntil(closingTime: endRange.end_local_time)
                } else {
                    let nextRange = openingHours[(curr+1)%count]
                    return .reopeningSoon(closingTime: endRange.end_local_time, nextOpeningTime: nextRange.start_local_time)
                }
                
                
            }
            start += 1
        }
        
        // If not open, find the next opening time
        let nextRange = openingHours[(start) % openingHours.count]
        let dist = timeFromNowTill(nextRange:nextRange,start: true)
        if dist != nil && dist! <= 86400 {
            return .openAgain(time: nextRange.start_local_time)
        } else {
            return .openLater(day: nextRange.day_of_week, time: nextRange.start_local_time)
        }
    }
    
    
    
    // Function to format the message based on the enum case
    func formatMessage() -> String {
        switch self {
        case .openUntil(let closingTime):
            return "Open until \(convertTo12HourFormat(closingTime))"
        case .reopeningSoon(let closingTime, let nextOpeningTime):
            return "Open until \(convertTo12HourFormat(closingTime)), reopen at \(convertTo12HourFormat(nextOpeningTime))"
        case .openAgain(let time):
            return "Open again at \(convertTo12HourFormat(time))"
        case .openLater(let day, let time):
            let weekdaysFullNames = ["SUN": "Sunday", "MON": "Monday", "TUE": "Tuesday", "WED": "Wednesday", "THU": "Thursday", "FRI": "Friday", "SAT": "Saturday"]
            return "Open \(weekdaysFullNames[day]!) \(convertTo12HourFormat(time))"
        case .closed:
            return "Closed"
        }
    }
    
    // Function to get the color based on the enum case
    func getColor() -> Color { // Renamed for clarity
        switch self {
        case .openUntil: // Assuming this is for "Open Until" without specific time
            return Color(hex: "#4AA548") // Green
        case .reopeningSoon:
            return Color.yellow
        default:
            return Color.red
        }
    }
}


//=== Utility functions

// Convert from 23:30:00 to 11:30PM
func convertTo12HourFormat(_ timeString: String) -> String {
    // Edge case for "24:00:00"
    if timeString == "24:00:00" {
        return "12AM"
    }
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    
    let date = formatter.date(from: timeString)!
    
    let calendar = Calendar.current
    let components = calendar.dateComponents([.minute], from: date)
    
    let minute = components.minute!
    
    if minute == 0 {
        formatter.dateFormat = "ha"
    } else {
        formatter.dateFormat = "h:mma"
    }
    
    formatter.amSymbol = "AM"
    formatter.pmSymbol = "PM"
    
    return formatter.string(from: date)
    
}


// For scenarios where SUN is the first day of the week
func dayIndex(for day: String) -> Int {
    let weekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    return weekdays.firstIndex(of: day) ?? 0
}

// check #seconds from now until a time, either use open or close time of nextRange, controlled by start
func timeFromNowTill(nextRange: OpeningHours, start: Bool) -> TimeInterval? {
    let calendar = Calendar.current
    let now = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    let currentTimeString = formatter.string(from: now)
    
    // check how many days until target day
    var daysToAdd = (dayIndex(for: nextRange.day_of_week) - (calendar.component(.weekday, from: now)-1) + 7) % 7
    
    // if current time is not within the range and daysToAdd == 0, it's a week from now
    if daysToAdd == 0 && currentTimeString > nextRange.end_local_time {
        daysToAdd = 7
    }
    // Create date components for adding days
    var nextDate = Calendar.current.date(byAdding: DateComponents(day:daysToAdd), to: now)!
    // Combine the new date with the start local time
    formatter.dateFormat = "yyyy MM dd HH:mm:ss"
    let combinedDateString: String
    
    // set the time to use
    if start {
        combinedDateString = formatter.string(from: nextDate).prefix(10) + " " + nextRange.start_local_time
    } else if nextRange.end_local_time != "24:00:00"{
        combinedDateString = formatter.string(from: nextDate).prefix(10) + " " + nextRange.end_local_time
    } else {
        nextDate = Calendar.current.date(byAdding: DateComponents(day:daysToAdd+1), to: now)!
        combinedDateString = formatter.string(from: nextDate).prefix(10) + " " + "00:00:00"
    }

    // Convert the combined date string to a Date object
    guard let combinedDate = formatter.date(from: combinedDateString) else {
        fatalError("Failed to parse the combined date string.")
    }
    return combinedDate.timeIntervalSince(now)
}

//===== View Models
class LocationDetailsViewModel: ObservableObject {
    @Published var isExpanded: Bool = false
    private(set) var openingHours: [OpeningHours] = []
    @Published var locationName: String = ""
    // i = days of the week with i = 0 -> Monday and so on. formattedHours[i] = list of opening hours on that day
    @Published var formattedHours: [[String]] = Array(repeating: [], count: 7)
    @Published var msg : OpenHoursStatus = .closed
    init() {
        self.fetchData()
//        self.fromJson() // use this for testing without calling the endpoint
    }
    
    
    // Merge
    private func sortMergeTimeRanges() {
        openingHours.sort {
            if $0.day_of_week != $1.day_of_week {
                return dayIndex(for: $0.day_of_week) < dayIndex(for: $1.day_of_week)
            } else {
                return $0.start_local_time < $1.start_local_time
            }
        }

        var mergedRanges: [OpeningHours] = []
        var currentRange = openingHours[0]
        for range in openingHours {
            if range.start_local_time <= currentRange.end_local_time && range.day_of_week == currentRange.day_of_week {
                // Overlapping or consecutive ranges, merge them
                currentRange.end_local_time = max(currentRange.end_local_time, range.end_local_time)
            } else {
                // No overlap, add the current range to the merged list and start a new range
                mergedRanges.append(currentRange)
                currentRange = range
            }
            
        }
        mergedRanges.append(currentRange)
        
        openingHours = mergedRanges
    }
    
    
    // From a list of opening hours, update the formattedHours array. If consecutive overnight, merge the two ranges
    // and save it to the previous day
    func formatHours() {
        // Format the merged ranges
        for (ind, range) in openingHours.enumerated() {
            let dayIndex = (dayIndex(for: range.day_of_week) + 6) % 7
            let start = convertTo12HourFormat(range.start_local_time)
            var end = convertTo12HourFormat(range.end_local_time)
            if start == end && start == "12AM" {
                formattedHours[dayIndex].append("24 hours")
            } else if start == "12AM" && ((ind > 0 && openingHours[ind-1].end_local_time == "24:00:00" && openingHours[ind-1].start_local_time != "00:00:00") || (ind == 0 && openingHours.last!.end_local_time == "24:00:00" && openingHours.last!.start_local_time != "00:00:00")) { // if consecutive overnight and the previous is not 24 hours
                // already included in the next case
                continue
            } else if end == "12AM" && openingHours[(ind+1)%openingHours.count].start_local_time == "00:00:00" {
                // if two ranges are executive overnight
                end = convertTo12HourFormat(openingHours[(ind+1)%openingHours.count].end_local_time)
                formattedHours[dayIndex].append("\(start) - \(end)")
            }
            else {
                formattedHours[dayIndex].append("\(start) - \(end)")
            }
            
        }
    
}
    
    // Check if times are valid
    private func isValidTimeString(_ timeString: String) -> Bool {
        if timeString == "24:00:00" {
            return true
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        
        // Attempt to parse the time string
        if let _ = formatter.date(from: timeString) {
            // Parsing successful, time string is valid
            return true
        } else {
            // Parsing failed, time string is invalid
            return false
        }
    }
    
    // for testing
    func fromJson() {
        do {
            let location = try Location(dataString: jsonDataString)
            self.locationName = location.location_name
            for range in location.hours {
                if self.isValidTimeString(range.start_local_time) && self.isValidTimeString(range.end_local_time) {
                    self.openingHours.append(range)
                }
            }
            self.sortMergeTimeRanges()
            self.formatHours()
            self.msg = OpenHoursStatus.getCurrentStatus(openingHours: self.openingHours)
        } catch {
            print(error)
        }
    }
    
    
    // Call the endpoint and process the data
    func fetchData() {
        let urlString = "https://purs-demo-bucket-test.s3.us-west-2.amazonaws.com/location.json"
        
        Location.fromUrl(fromURL: urlString) { result in
            switch result {
            case .success(let location):
                DispatchQueue.main.async {
                    self.locationName = location.location_name
                    for range in location.hours {
                        if self.isValidTimeString(range.start_local_time) && self.isValidTimeString(range.end_local_time) {
                            self.openingHours.append(range)
                        }
                    }
                    self.sortMergeTimeRanges()
                    self.formatHours()
                    self.msg = OpenHoursStatus.getCurrentStatus(openingHours: self.openingHours)
                }
                
            case .failure(let error):
                print("Error fetching data: \(error)")
            }
        }
    }
}

//========== For testing
// JSON data as a String (replace with your actual JSON data)
let jsonDataString = """
{
  "location_name": "BEASTRO by Marshawn Lynch",
  "hours": [

    {
      "day_of_week": "MON",
      "start_local_time": "14:00:00",
      "end_local_time": "24:00:00"
    },
    {
      "day_of_week": "TUE",
      "start_local_time": "11:00:00",
      "end_local_time": "12:30:00"
    },
    {
      "day_of_week": "FRI",
      "start_local_time": "19:00:00",
      "end_local_time": "24:00:00"
    },
    {
      "day_of_week": "SAT",
      "start_local_time": "15:00:00",
      "end_local_time": "24:00:00"
    },
    {
      "day_of_week": "SUN",
      "start_local_time": "00:00:00",
      "end_local_time": "02:00:00"
    }
    
  ]
}
"""
    
    
