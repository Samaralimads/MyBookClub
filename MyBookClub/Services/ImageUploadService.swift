//
//  ImageUploadService.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import Foundation
import UIKit
import Supabase

final class ImageUploadService {
    static let shared = ImageUploadService()
    private init() {}

    enum UploadBucket: String {
        case clubCovers = "club-covers"
        case avatars    = "avatars"
    }

    // MARK: - Upload

    func uploadImage(_ image: UIImage, bucket: UploadBucket, path: String) async throws -> String {
        
        let normalized = image.normalizedForUpload()

        guard let compressed = compress(image: normalized, maxKB: 900) else {
            throw AppError("Failed to compress image")
        }

        let storage = SupabaseService.shared.client.storage.from(bucket.rawValue)
        try await storage.upload(
            path,
            data: compressed,
            options: FileOptions(contentType: "image/jpeg", upsert: true)
        )

        let publicURL = try storage.getPublicURL(path: path)
        return publicURL.absoluteString
    }

    func uploadClubCover(_ image: UIImage, clubId: UUID) async throws -> String {
        let path = "\(clubId.uuidString)/cover.jpg"
        return try await uploadImage(image, bucket: .clubCovers, path: path)
    }

    func uploadAvatar(_ image: UIImage) async throws -> String {
        let uid = try await SupabaseService.shared.currentUserID
        let path = "\(uid.uuidString)/avatar.jpg"
        return try await uploadImage(image, bucket: .avatars, path: path)
    }

    // MARK: - Compression

    private func compress(image: UIImage, maxKB: Int) -> Data? {
        // Guard against zero or invalid dimensions
        guard image.size.width > 0, image.size.height > 0 else { return nil }

        let maxDimension: CGFloat = 1024
        let size = image.size
        let scale = min(maxDimension / max(size.width, size.height), 1.0)

        // Round up to avoid a zero dimension after scaling very small images.
        let newSize = CGSize(
            width: (size.width * scale).rounded(.up),
            height: (size.height * scale).rounded(.up)
        )

        guard newSize.width > 0, newSize.height > 0 else { return nil }

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        var quality: CGFloat = 0.85
        while quality > 0.1 {
            if let data = resized.jpegData(compressionQuality: quality),
               data.count <= maxKB * 1024 {
                return data
            }
            quality -= 0.1
        }
        return resized.jpegData(compressionQuality: 0.1)
    }
}

// MARK: - UIImage + Normalization

private extension UIImage {
    func normalizedForUpload() -> UIImage {
        guard size.width > 0, size.height > 0 else { return self }
        // If already upright and fully decoded, skip the redraw.
        guard imageOrientation != .up else { return self }

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
