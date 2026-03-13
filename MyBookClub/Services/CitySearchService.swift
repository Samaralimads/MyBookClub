//
//  CitySearchService.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 13/03/2026.
//

import Foundation
import MapKit
import Combine

@Observable
final class CitySearchService: NSObject, MKLocalSearchCompleterDelegate {

    var query: String = "" {
        didSet {
            if query.isEmpty {
                suggestions = []
            } else {
                completer.queryFragment = query
            }
        }
    }

    var suggestions: [String] = []

    private let completer: MKLocalSearchCompleter

    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        // Only return cities, neighbourhoods, and points of interest — no street addresses
        completer.resultTypes = [.address]
        completer.pointOfInterestFilter = .excludingAll
    }

    // MARK: - MKLocalSearchCompleterDelegate

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = completer.results
            .filter { result in
                // Keep results that have a subtitle (city/country info)
                // and exclude results that look like full street addresses
                // (they typically have numbers at the start of the title)
                let title = result.title
                let firstChar = title.first
                return !result.subtitle.isEmpty
                    && !(firstChar?.isNumber ?? false)
            }
            .map { result in
                // Combine title + subtitle for display: "Le Marais, Paris, France"
                result.subtitle.isEmpty ? result.title : "\(result.title), \(result.subtitle)"
            }
            .prefix(5)
            .map { $0 }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        suggestions = []
    }
}
