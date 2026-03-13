//
//  CitySearchService.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 13/03/2026.
//

import Foundation
import MapKit

@Observable
final class CitySearchService: NSObject, MKLocalSearchCompleterDelegate {

    var query: String = "" {
        didSet {
            if query.isEmpty {
                suggestions = []
                completionResults = []
            } else {
                completer.queryFragment = query
            }
        }
    }

    var suggestions: [String] = []

    // Raw completion objects so the VM can geocode the chosen one
    private(set) var completionResults: [MKLocalSearchCompletion] = []

    private let completer: MKLocalSearchCompleter

    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address]
        completer.pointOfInterestFilter = .excludingAll
    }

    // MARK: - MKLocalSearchCompleterDelegate

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let filtered = completer.results
            .filter { result in
                let firstChar = result.title.first
                return !result.subtitle.isEmpty && !(firstChar?.isNumber ?? false)
            }
            .prefix(5)

        completionResults = Array(filtered)
        suggestions = completionResults.map { result in
            result.subtitle.isEmpty ? result.title : "\(result.title), \(result.subtitle)"
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        suggestions = []
        completionResults = []
    }

    // MARK: - Geocode

    func geocode(_ completion: MKLocalSearchCompletion) async -> CLLocationCoordinate2D? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        let response = try? await search.start()
        return response?.mapItems.first?.location.coordinate
    }
}
