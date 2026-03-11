//
//  DistanceFormatter.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 10/03/2026.
//

import Foundation

enum DistanceFormatter {

    private static let formatter: MeasurementFormatter = {
        let f = MeasurementFormatter()
        f.unitOptions = .naturalScale
        f.numberFormatter.maximumFractionDigits = 1
        return f
    }()

    /// Format a distance in metres using the user's locale (mi or km automatically).
    static func string(fromMeters meters: Double) -> String {
        let measurement = Measurement(value: meters, unit: UnitLength.meters)
        return formatter.string(from: measurement)
    }

    /// Format a distance in kilometres using the user's locale.
    static func string(fromKm km: Double) -> String {
        string(fromMeters: km * 1000)
    }

    /// Label for the Distance filter chip menu options — locale-aware.
    static func menuLabel(forKm km: Double) -> String {
        string(fromKm: km)
    }
} 
