//
//  ClubBoardViewModel.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 07/04/2026.
//

import SwiftUI

@Observable
final class ClubBoardViewModel {

    // MARK: - State

    var posts: [Post] = []
    var likeCounts: [UUID: Int] = [:]
    var likedPostIds: Set<UUID> = []
    var isLoading = false
    var isSending = false
    var error: AppError?

    // Compose
    var newAnnouncementText = ""
    var isSpoiler = false

    // MARK: - Load

    func load(clubId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let fetchedPosts = SupabaseService.shared.fetchBoardPosts(clubId: clubId)
            async let fetchedLikedIds = SupabaseService.shared.fetchMyLikedPostIds()

            var (loadedPosts, liked) = try await (fetchedPosts, fetchedLikedIds)
            likedPostIds = liked

            var counts: [UUID: Int] = [:]
            for i in loadedPosts.indices {
                let comments = try await SupabaseService.shared.fetchComments(parentPostId: loadedPosts[i].id)
                let count = try await SupabaseService.shared.fetchLikeCount(postId: loadedPosts[i].id)
                loadedPosts[i].comments = comments
                counts[loadedPosts[i].id] = count
            }

            posts = loadedPosts
            likeCounts = counts
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    // MARK: - Like toggle (optimistic)

    func toggleLike(postId: UUID) async {
        let wasLiked = likedPostIds.contains(postId)

        if wasLiked {
            likedPostIds.remove(postId)
            likeCounts[postId] = max(0, (likeCounts[postId] ?? 1) - 1)
        } else {
            likedPostIds.insert(postId)
            likeCounts[postId] = (likeCounts[postId] ?? 0) + 1
        }

        do {
            if wasLiked {
                try await SupabaseService.shared.unlikePost(postId: postId)
            } else {
                try await SupabaseService.shared.likePost(postId: postId)
            }
        } catch {
            if wasLiked {
                likedPostIds.insert(postId)
                likeCounts[postId] = (likeCounts[postId] ?? 0) + 1
            } else {
                likedPostIds.remove(postId)
                likeCounts[postId] = max(0, (likeCounts[postId] ?? 1) - 1)
            }
            self.error = AppError(underlying: error)
        }
    }

    // MARK: - Post announcement (organiser only)

    func postAnnouncement(clubId: UUID) async {
        let text = newAnnouncementText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isSending = true
        defer { isSending = false }

        do {
            try await SupabaseService.shared.createPost(
                clubId: clubId,
                content: text,
                postType: .announcement,
                parentPostId: nil,
                isSpoiler: isSpoiler
            )
            newAnnouncementText = ""
            isSpoiler = false
            await load(clubId: clubId)
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    // MARK: - Post comment

    func postComment(text: String, parentId: UUID, clubId: UUID) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            try await SupabaseService.shared.createPost(
                clubId: clubId,
                content: trimmed,
                postType: .comment,
                parentPostId: parentId,
                isSpoiler: false
            )
            await load(clubId: clubId)
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    // MARK: - Pin toggle (organiser only)

    func togglePin(post: Post, clubId: UUID) async {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        let newPinned = !(post.isPinned ?? false)
        posts[index].isPinned = newPinned

        do {
            try await SupabaseService.shared.pinPost(postId: post.id, pinned: newPinned)
            await load(clubId: clubId)
        } catch {
            posts[index].isPinned = post.isPinned
            self.error = AppError(underlying: error)
        }
    }

    // MARK: - Delete post (organiser only)

    func deletePost(post: Post, clubId: UUID) async {
        posts.removeAll { $0.id == post.id }
        do {
            try await SupabaseService.shared.deletePost(id: post.id)
        } catch {
            self.error = AppError(underlying: error)
        }
    }
}
