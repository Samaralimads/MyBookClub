//
//  SupabaseService.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import Foundation
import Supabase

final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private let iso8601 = ISO8601DateFormatter()

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: Config.supabaseURL)!,
            supabaseKey: Config.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }

    // MARK: - Auth helpers

    var currentUserID: UUID? {
        client.auth.currentUser?.id
    }

    // MARK: - Decoder

    private var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    // MARK: - User Profile

    func fetchCurrentUser() async throws -> AppUser {
        guard let uid = currentUserID else { throw AppError("Not signed in") }
        return try await client
            .from("users")
            .select()
            .eq("id", value: uid.uuidString)
            .single()
            .execute()
            .value
    }

    func upsertUser(_ user: AppUser) async throws {
        try await client.from("users").upsert(user).execute()
    }

    func updateAPNSToken(_ token: String) async throws {
        guard let uid = currentUserID else { return }
        try await client
            .from("users")
            .update(["apns_token": token])
            .eq("id", value: uid.uuidString)
            .execute()
    }

    // MARK: - Club Discovery

    func fetchNearbyClubs(
        lat: Double,
        lng: Double,
        radiusM: Double,
        genres: [String],
        query: String?
    ) async throws -> [Club] {
        var params: [String: AnyJSON] = [
            "p_lat": .double(lat),
            "p_lng": .double(lng),
            "radius_m": .double(radiusM),
        ]
        if !genres.isEmpty {
            params["genres"] = .array(genres.map { .string($0) })
        }
        if let q = query, !q.isEmpty {
            params["search_query"] = .string(q)
        }
        return try await client
            .rpc("nearby_clubs", params: params)
            .execute()
            .value
    }

    func fetchClub(id: UUID) async throws -> Club {
        var club: Club = try await client
            .from("clubs")
            .select("*, books(*)")
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value

        let count: Int = try await client
            .from("club_members")
            .select("*", count: .exact)
            .eq("club_id", value: id.uuidString)
            .eq("status", value: "active")
            .execute()
            .count ?? 0

        club.memberCount = count
        return club
    }
    
    func fetchMyClubs() async throws -> [Club] {
        guard let uid = currentUserID else { return [] }
        
        // 1. Fetch the clubs this user belongs to
        var clubs: [Club] = try await client
            .from("clubs")
            .select("*, books(*), club_members!inner(user_id)")
            .eq("club_members.user_id", value: uid.uuidString)
            .execute()
            .value

        // 2. For each club, fetch the active member count
        for i in clubs.indices {
            let count: Int = try await client
                .from("club_members")
                .select("*", count: .exact)
                .eq("club_id", value: clubs[i].id.uuidString)
                .eq("status", value: "active")
                .execute()
                .count ?? 0
            clubs[i].memberCount = count
        }

        return clubs
    }

    // MARK: - Club Membership
    
    func fetchClubMembers(clubId: UUID) async throws -> [AppUser] {
        struct MemberRow: Decodable {
            let users: AppUser
        }
        let rows: [MemberRow] = try await client
            .from("club_members")
            .select("users(*)")
            .eq("club_id", value: clubId.uuidString)
            .eq("status", value: "active")
            .execute()
            .value
        return rows.map(\.users)
    }

    func membershipStatus(clubId: UUID) async throws -> MemberStatus? {
        guard let uid = currentUserID else { return nil }
        let rows: [ClubMember] = try await client
            .from("club_members")
            .select()
            .eq("club_id", value: clubId.uuidString)
            .eq("user_id", value: uid.uuidString)
            .execute()
            .value
        return rows.first?.status
    }

    func myRole(clubId: UUID) async throws -> MemberRole? {
        guard let uid = currentUserID else { return nil }
        let rows: [ClubMember] = try await client
            .from("club_members")
            .select()
            .eq("club_id", value: clubId.uuidString)
            .eq("user_id", value: uid.uuidString)
            .execute()
            .value
        return rows.first?.role
    }

    func joinClub(clubId: UUID, isPublic: Bool) async throws {
        guard let uid = currentUserID else { return }
        let status = isPublic ? "active" : "pending"
        try await client.from("club_members").insert([
            "club_id": clubId.uuidString,
            "user_id": uid.uuidString,
            "role": "member",
            "status": status,
        ]).execute()
    }

    func leaveClub(clubId: UUID) async throws {
        guard let uid = currentUserID else { return }
        try await client
            .from("club_members")
            .delete()
            .eq("club_id", value: clubId.uuidString)
            .eq("user_id", value: uid.uuidString)
            .execute()
    }

    func removeMember(clubId: UUID, userId: UUID) async throws {
        try await client
            .from("club_members")
            .delete()
            .eq("club_id", value: clubId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    // MARK: - Club Creation

    func createClub(
        name: String,
        description: String?,
        genreTags: [String],
        lat: Double,
        lng: Double,
        cityLabel: String,
        isPublic: Bool,
        memberCap: Int,
        coverImageURL: String?,
        recurringDay: String?,
        recurringTime: String?
    ) async throws -> Club {
        guard let uid = currentUserID else { throw AppError("Not signed in") }

        // Round to 2dp for GDPR (~1km precision)
        let roundedLat = (lat * 100).rounded() / 100
        let roundedLng = (lng * 100).rounded() / 100

        // Supabase accepts PostGIS WKT for geography inserts
        let locationWKT = "SRID=4326;POINT(\(roundedLng) \(roundedLat))"

        struct ClubInsert: Encodable {
            let organiser_id: String
            let name: String
            let description: String?
            let genre_tags: [String]
            let location: String
            let city_label: String
            let is_public: Bool
            let member_cap: Int
            let cover_image_url: String?
            let recurring_day: String?
            let recurring_time: String?
        }

        let insert = ClubInsert(
            organiser_id: uid.uuidString,
            name: name,
            description: description,
            genre_tags: genreTags,
            location: locationWKT,
            city_label: cityLabel,
            is_public: isPublic,
            member_cap: memberCap,
            cover_image_url: coverImageURL,
            recurring_day: recurringDay,
            recurring_time: recurringTime
        )

        let club: Club = try await client
            .from("clubs")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        // Add organiser as first member
        try await client.from("club_members").insert([
            "club_id": club.id.uuidString,
            "user_id": uid.uuidString,
            "role": "organiser",
            "status": "active",
        ]).execute()

        return club
    }

    // MARK: - Club cover image

    func updateClubCover(clubId: UUID, coverImageURL: String) async throws {
        try await client
            .from("clubs")
            .update(["cover_image_url": coverImageURL])
            .eq("id", value: clubId.uuidString)
            .execute()
    }
    
    // MARK: - Club Update (organiser only)
  
     func updateClub(
         clubId: UUID,
         name: String,
         description: String?,
         genreTags: [String],
         lat: Double,
         lng: Double,
         cityLabel: String,
         isPublic: Bool,
         memberCap: Int,
         coverImageURL: String?,
         recurringDay: String?,
         recurringTime: String?
     ) async throws -> Club {
         // Round to 2dp for GDPR (~1km precision)
         let roundedLat = (lat * 100).rounded() / 100
         let roundedLng = (lng * 100).rounded() / 100
         let locationWKT = "SRID=4326;POINT(\(roundedLng) \(roundedLat))"
  
         struct ClubUpdate: Encodable {
             let name: String
             let description: String?
             let genre_tags: [String]
             let location: String
             let city_label: String
             let is_public: Bool
             let member_cap: Int
             let cover_image_url: String?
             let recurring_day: String?
             let recurring_time: String?
         }
  
         let update = ClubUpdate(
             name: name,
             description: description,
             genre_tags: genreTags,
             location: locationWKT,
             city_label: cityLabel,
             is_public: isPublic,
             member_cap: memberCap,
             cover_image_url: coverImageURL,
             recurring_day: recurringDay,
             recurring_time: recurringTime
         )
  
         return try await client
             .from("clubs")
             .update(update)
             .eq("id", value: clubId.uuidString)
             .select("*, books(*)")
             .single()
             .execute()
             .value
     }
  
     // MARK: - Club Delete (organiser only)
  
     func deleteClub(clubId: UUID) async throws {
         try await client
             .from("clubs")
             .delete()
             .eq("id", value: clubId.uuidString)
             .execute()
     }
  

    // MARK: - Meetings

    func fetchMeetings(clubId: UUID) async throws -> [Meeting] {
        try await client
            .from("meetings")
            .select()
            .eq("club_id", value: clubId.uuidString)
            .order("scheduled_at", ascending: true)
            .execute()
            .value
    }

    func fetchUpcomingMeetingsForUser() async throws -> [Meeting] {
        guard let uid = currentUserID else { return [] }
        return try await client
            .rpc("get_user_meetings", params: ["p_user_id": uid.uuidString])
            .execute()
            .value
    }

    func createMeeting(
        clubId: UUID,
        title: String,
        scheduledAt: Date,
        fromChapter: Int?,
        toChapter: Int?,
        chapterTitles: [String]?,
        notes: String?,
        address: String?,
        isFinal: Bool
    ) async throws -> Meeting {
        struct MeetingInsert: Encodable {
            let club_id: String
            let title: String
            let scheduled_at: String
            let from_chapter: Int?
            let to_chapter: Int?
            let chapter_titles: [String]?
            let notes: String?
            let address: String?
            let is_final: Bool
        }

        let insert = MeetingInsert(
            club_id: clubId.uuidString,
            title: title,
            scheduled_at: iso8601.string(from: scheduledAt),
            from_chapter: fromChapter,
            to_chapter: toChapter,
            chapter_titles: chapterTitles,
            notes: notes,
            address: address,
            is_final: isFinal
        )

        return try await client
            .from("meetings")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
    }

    // MARK: - Book archive

    // Returns the meeting flagged as final for this club, if one exists.
    func fetchFinalMeeting(clubId: UUID) async throws -> Meeting? {
        let rows: [Meeting] = try await client
            .from("meetings")
            .select()
            .eq("club_id", value: clubId.uuidString)
            .eq("is_final", value: true)
            .order("scheduled_at", ascending: false)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    // Writes the book to club_book_history and clears current_book_id on the club.
    func archiveBook(clubId: UUID, bookId: UUID) async throws {
        struct HistoryInsert: Encodable {
            let club_id: String
            let book_id: String
        }
        
        try await client
            .from("club_book_history")
            .upsert(
                HistoryInsert(
                    club_id: clubId.uuidString,
                    book_id: bookId.uuidString
                ),
                onConflict: "club_id,book_id"
            )
            .execute()
        
        let clearBook: [String: AnyJSON] = ["current_book_id": .null]

        try await client
            .from("clubs")
            .update(clearBook)
            .eq("id", value: clubId.uuidString)
            .execute()
    }

    // MARK: - Reading Progress

    func fetchReadingProgress(clubId: UUID, bookId: UUID) async throws -> ReadingProgress? {
        guard let uid = currentUserID else { return nil }
        let rows: [ReadingProgress] = try await client
            .from("reading_progress")
            .select()
            .eq("club_id", value: clubId.uuidString)
            .eq("user_id", value: uid.uuidString)
            .eq("book_id", value: bookId.uuidString)
            .execute()
            .value
        return rows.first
    }

    func upsertReadingProgress(clubId: UUID, bookId: UUID, completedChapters: [Int]) async throws {
        guard let uid = currentUserID else { return }
        struct ProgressUpsert: Encodable {
            let club_id: String
            let user_id: String
            let book_id: String
            let completed_chapters: [Int]
            let updated_at: String
        }
        let payload = ProgressUpsert(
            club_id: clubId.uuidString,
            user_id: uid.uuidString,
            book_id: bookId.uuidString,
            completed_chapters: completedChapters,
            updated_at: iso8601.string(from: .now)
        )
        try await client.from("reading_progress").upsert(payload).execute()
    }

    // MARK: - Posts (Board)

    func fetchPosts(clubId: UUID) async throws -> [Post] {
        try await client
            .from("posts")
            .select("*, users(id, display_name, avatar_url)")
            .eq("club_id", value: clubId.uuidString)
            .is("parent_post_id", value: nil)   // top-level announcements only
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func fetchComments(parentPostId: UUID) async throws -> [Post] {
        try await client
            .from("posts")
            .select("*, users(id, display_name, avatar_url)")
            .eq("parent_post_id", value: parentPostId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    func createPost(
        clubId: UUID,
        content: String,
        postType: PostType,
        parentPostId: UUID?,
        isSpoiler: Bool
    ) async throws -> Post {
        guard let uid = currentUserID else { throw AppError("Not signed in") }
        struct PostInsert: Encodable {
            let club_id: String
            let user_id: String
            let post_type: String
            let parent_post_id: String?
            let content: String
            let is_spoiler: Bool
        }
        let insert = PostInsert(
            club_id: clubId.uuidString,
            user_id: uid.uuidString,
            post_type: postType.rawValue,
            parent_post_id: parentPostId?.uuidString,
            content: content,
            is_spoiler: isSpoiler
        )
        return try await client
            .from("posts")
            .insert(insert)
            .select("*, users(id, display_name, avatar_url)")
            .single()
            .execute()
            .value
    }

    func deletePost(id: UUID) async throws {
        try await client.from("posts").delete().eq("id", value: id.uuidString).execute()
    }

    func addReaction(postId: UUID, emoji: String) async throws {
        let post: Post = try await client
            .from("posts")
            .select("reactions")
            .eq("id", value: postId.uuidString)
            .single()
            .execute()
            .value
        var reactions = post.reactions
        reactions[emoji, default: 0] += 1
        try await client
            .from("posts")
            .update(["reactions": reactions])
            .eq("id", value: postId.uuidString)
            .execute()
    }

    // MARK: - Voting

    func fetchActiveVoteSession(clubId: UUID) async throws -> VoteSession? {
        let rows: [VoteSession] = try await client
            .from("vote_sessions")
            .select()
            .eq("club_id", value: clubId.uuidString)
            .eq("status", value: "open")
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func openVoteSession(clubId: UUID, deadline: Date?) async throws -> VoteSession {
        struct VoteSessionInsert: Encodable {
            let club_id: String
            let deadline: String?
        }
        let insert = VoteSessionInsert(
            club_id: clubId.uuidString,
            deadline: deadline.map { iso8601.string(from: $0) }
        )
        return try await client
            .from("vote_sessions")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
    }

    func castVote(voteSessionId: UUID, bookId: UUID, clubId: UUID) async throws {
        guard let uid = currentUserID else { throw AppError("Not signed in") }
        try await client.from("votes").insert([
            "vote_session_id": voteSessionId.uuidString,
            "club_id":         clubId.uuidString,
            "book_id":         bookId.uuidString,
            "user_id":         uid.uuidString,
        ]).execute()
    }

    func closeVoteSession(voteSessionId: UUID, winnerBookId: UUID, clubId: UUID) async throws {
        try await client
            .from("vote_sessions")
            .update([
                "status": "closed",
                "winner_book_id": winnerBookId.uuidString,
            ])
            .eq("id", value: voteSessionId.uuidString)
            .execute()

        try await client
            .from("clubs")
            .update(["current_book_id": winnerBookId.uuidString])
            .eq("id", value: clubId.uuidString)
            .execute()
    }
    
    // Vote Suggestions

    func fetchSuggestions(sessionId: UUID) async throws -> [BookSuggestion] {
        guard let uid = currentUserID else { return [] }

        struct SuggestionRow: Decodable {
            let id: UUID
            let books: Book
            let voteCount: Int
            let hasVoted: Bool

            enum CodingKeys: String, CodingKey {
                case id
                case books
                case voteCount = "vote_count"
                case hasVoted  = "has_voted"
            }
        }

        // Fetch suggestions with vote counts
        let rows: [SuggestionRow] = try await client
            .rpc("get_vote_suggestions", params: [
                "p_session_id": AnyJSON.string(sessionId.uuidString),
                "p_user_id":    AnyJSON.string(uid.uuidString)
            ])
            .execute()
            .value

        return rows.map {
            BookSuggestion(
                id: $0.id,
                book: $0.books,
                voteCount: $0.voteCount,
                hasVoted: $0.hasVoted
            )
        }
    }

    func suggestBook(voteSessionId: UUID, bookId: UUID, clubId: UUID) async throws {
        guard let uid = currentUserID else { throw AppError("Not signed in") }
        try await client.from("vote_suggestions").insert([
            "vote_session_id": voteSessionId.uuidString,
            "book_id":         bookId.uuidString,
            "club_id":         clubId.uuidString,
            "suggested_by":    uid.uuidString,
        ]).execute()
    }

    func removeVote(voteSessionId: UUID, bookId: UUID) async throws {
        guard let uid = currentUserID else { return }
        try await client
            .from("votes")
            .delete()
            .eq("vote_session_id", value: voteSessionId.uuidString)
            .eq("book_id",         value: bookId.uuidString)
            .eq("user_id",         value: uid.uuidString)
            .execute()
    }

    // MARK: - Books

    func cacheBook(_ book: Book) async throws -> Book {
        return try await client
            .from("books")
            .upsert(book, onConflict: "google_books_id")
            .select()
            .single()
            .execute()
            .value
    }

    func setCurrentBook(clubId: UUID, book: Book) async throws {
        let saved = try await cacheBook(book)
        try await client
            .from("clubs")
            .update(["current_book_id": saved.id.uuidString])
            .eq("id", value: clubId.uuidString)
            .execute()
    }

    // MARK: - Book History
 
    func fetchBookHistory(clubId: UUID) async throws -> [ClubBookHistory] {
        try await client
            .from("club_book_history")
            .select("*, books(*)")
            .eq("club_id", value: clubId.uuidString)
            .order("finished_at", ascending: false)
            .execute()
            .value
    }
 
    // MARK: - Reports
 
    func reportPost(postId: UUID, reason: String?) async throws {
        guard let uid = currentUserID else { throw AppError("Not signed in") }
        try await client.from("reports").insert([
            "post_id":     postId.uuidString,
            "reporter_id": uid.uuidString,
            "reason":      reason ?? "",
        ]).execute()
    }
}
 
