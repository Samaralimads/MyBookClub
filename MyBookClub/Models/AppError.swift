//
//  AppError.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import Foundation

struct AppError: LocalizedError, Identifiable {
    let id = UUID()
    let message: String

    var errorDescription: String? { message }

    init(_ message: String) {
        self.message = message
    }

    init(underlying error: Error) {
        self.message = error.localizedDescription
    }
}
