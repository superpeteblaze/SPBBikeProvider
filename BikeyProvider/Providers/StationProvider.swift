//
//  StationProvider.swift
//  BikeyGo
//
//  Created by Pete Smith on 31/05/2016.
//  Copyright © 2016 Pete Smith. All rights reserved.
//

import Foundation
import CoreLocation

/**
 *  Fetches stations
 */
public struct StationProvider {
    
    /// The delimiter to use for formatting our station name
    static var delimiter: String?
    
    /**
     Get a cities stations
     
     - parameter href:    The city-specific url suffix
     - parameter success: Success closure
     - parameter failure: Failure closure
     */
    static public func getStations(href: String, success: (([Station]) -> Void), failure: (() -> Void)) -> Void {
        
        let url = Constants.API.baseURL+href+Constants.API.requestOptions
        
        APIClient.get(url){ (resultSuccess, result) in
            if resultSuccess {
                
                if let json = result, network = json["network"] as? [String: AnyObject], stations = network["stations"] as? [[String: AnyObject]] {
                    
                    var stationCollection = [Station]()
                    
                    for station in stations {
                        if let stationId = station["id"] as? String {
                            
                            if let lastUpdated = station["timestamp"] as? String, latitude = station["latitude"] as? Double,
                                longitude = station["longitude"] as? Double, name = station["name"] as? String {
                                
                                // These are failable, so keep them out of conditional binding
                                let bikes = station["free_bikes"] as? Int ?? 0
                                let slots = station["empty_slots"] as? Int ?? 0
                                
                                var installed = true, sellsTickets = true
                                
                                if let extra = station["extra"] as? [String:AnyObject] {
                                    
                                    if let active = extra["installed"] as? Bool {
                                        installed = active
                                    }
                                    
                                    if let banking = extra["banking"] as? Bool {
                                        sellsTickets = banking
                                    }
                                }
                                
                                // Only add bike stations that are 'Installed' - i.e that are actually present and active
                                if installed {
                                    
                                    let location = CLLocation(latitude: latitude, longitude: longitude)
                                    let station = Station(id: stationId, name: name, bikes: bikes, spaces: slots, location: location, lastUpdated: lastUpdated, sellsTickets: sellsTickets)
                                    
                                    // Add to stations collection
                                    stationCollection.append(station)
                                }
                            }
                        }
                    }
                    
                    success(stationCollection)
                } else {
                    failure()
                }
                
            } else {
                failure()
            }
        }
    }
    
    /**
     Parse a returned station name to get a better formatted display name
     
     - parameter name: Station name
     
     - returns: Formatted station name
     */
    static func stationDisplayName(name: String) -> String {
        
        var formattedName = name

        if name.containsString("- ") {
            delimiter = "- "
        } else if name.containsString("-") {
            delimiter = "-"
        } else if name.containsString(" : ") {
            delimiter = " : "
        }
        
        if let delimiter = delimiter {
            let splitString = name.componentsSeparatedByString(delimiter)
            let formattedSlice = splitString.dropFirst()
            
            if formattedSlice.count > 1 {
                formattedName =  formattedSlice.reduce("") { $0 + " " + $1 }
            } else if let name = formattedSlice.first {
                formattedName =  name
            }
            
            
            guard formattedName != "" && formattedName != " " else {
                return name
            }
            
            return formattedName
        }
        return name
    }
}
