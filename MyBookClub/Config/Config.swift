//
//  Config.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import Foundation

enum Config {
    // ── Supabase ────────────────────────────────────────────────
    static let supabaseURL     = secret("SUPABASE_URL")
    static let supabaseAnonKey = secret("SUPABASE_ANON_KEY")

    // ── Google Books ────────────────────────────────────────────
    static let googleBooksKey  = secret("GOOGLE_BOOKS_KEY")

    // ── TelemetryDeck ───────────────────────────────────────────
    static let telemetryDeckID = secret("TELEMETRY_DECK_ID")

    // ── App ─────────────────────────────────────────────────────
    static let privacyPolicyURL  = "https://samaralimads.github.io/mybookclub-legal"
    static let termsURL          = "https://samaralimads.github.io/mybookclub-legal/#terms"
    static let supportEmail      = "app.mybookclub@gmail.com"
   
    static let appStoreReviewURL = "https://apps.apple.com/app/id6762190250?action=write-review"
    // MARK: - Internal helper
    private static func secret(_ key: String) -> String {
        guard let value = Bundle.main.infoDictionary?[key] as? String,
              !value.isEmpty,
              !value.hasPrefix("$(")   // catch un-substituted xcconfig variables
        else {
            // During development this will crash loudly so you can't forget to fill in keys.
            // Remove the fatalError and return "" if you want silent fallback instead.
            fatalError("Missing required config key: \(key). Add it to Secrets.xcconfig.")
        }
        return value
    }
}
