//
//  PlaceSearchService.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 17/03/2026.
//

import Foundation
import MapKit

// Global place autocomplete — finds addresses, cafés, stores... no city or region restriction.
@Observable
final class PlaceSearchService: NSObject, MKLocalSearchCompleterDelegate {

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

    private(set) var suggestions: [String] = []
    private(set) var completionResults: [MKLocalSearchCompletion] = []

    private let completer: MKLocalSearchCompleter

    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    // MARK: - MKLocalSearchCompleterDelegate

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let top = completer.results.prefix(5)
        completionResults = Array(top)
        suggestions = completionResults.map { result in
            result.subtitle.isEmpty
                ? result.title
                : "\(result.title), \(result.subtitle)"
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        suggestions = []
        completionResults = []
    }

    // MARK: - Resolve

    /// Returns the display string for the selected completion.
    func displayString(for completion: MKLocalSearchCompletion) -> String {
        completion.subtitle.isEmpty
            ? completion.title
            : "\(completion.title), \(completion.subtitle)"
    }
}
