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
    
    var currentUserID: UUID {
        get async throws {
            try await client.auth.session.user.id
        }
    }
    
    // MARK: - Decoder
    
    private var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
    
    // MARK: - User Profile
    
    func fetchCurrentUser() async throws -> AppUser {
        let uid = try await currentUserID
        return try await client
            .from("users")
            .select()
            .eq("id", value: uid.uuidString)
            .single()
            .execute()
            .value
    }
    
    func fetchUser(id: UUID) async throws -> AppUser {
        try await client
            .from("users")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }
    
    func upsertUser(_ user: AppUser) async throws {
        try await client.from("users").upsert(user).execute()
    }
    
    func updateAPNSToken(_ token: String) async throws {
        guard let uid = try? await currentUserID else { return }
        try await client
            .from("users")
            .update(["apns_token": token])
            .eq("id", value: uid.uuidString)
            .execute()
    }
    
    func deleteCurrentUser() async throws {
        let uid = try await currentUserID
        try await client
            .from("users")
            .delete()
            .eq("id", value: uid.uuidString)
            .execute()
        try await client.auth.signOut()
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
                .select("*, books(*), lat:ST_Y(location::geometry), lng:ST_X(location::geometry)")
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
        guard let uid = try? await currentUserID else { return [] }
        
        var clubs: [Club] = try await client
            .from("clubs")
            .select("*, books(*), club_members!inner(user_id)")
            .eq("club_members.user_id", value: uid.uuidString)
            .execute()
            .value
        
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
        guard let uid = try? await currentUserID else { return nil }
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
        guard let uid = try? await currentUserID else { return nil }
        let rows: [ClubMember] = try await client
            .from("club_members")
            .select()
            .eq("club_id", value: clubId.uuidString)
            .eq("user_id", value: uid.uuidString)
            .execute()
            .value
        return rows.first?.role
    }
    
    func joinClub(clubId: UUID, isPublic: Bool, memberCap: Int) async throws {
        let uid = try await currentUserID
        
        if memberCap > 0 {
            let liveCount: Int = try await client
                .from("club_members")
                .select("*", count: .exact)
                .eq("club_id", value: clubId.uuidString)
                .eq("status", value: "active")
                .execute()
                .count ?? 0
            
            if liveCount >= memberCap {
                throw AppError("This club is full.")
            }
        }
        
        let status = isPublic ? "active" : "pending"
        try await client.from("club_members").insert([
            "club_id": clubId.uuidString,
            "user_id": uid.uuidString,
            "role": "member",
            "status": status,
        ]).execute()
    }
    
    func leaveClub(clubId: UUID) async throws {
        let uid = try await currentUserID
        try await client
            .from("club_members")
            .delete()
            .eq("club_id", value: clubId.uuidString)
            .eq("user_id", value: uid.uuidString)
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
        coverImageURL: String?
    ) async throws -> Club {
        let uid = try await currentUserID
        
        let roundedLat = (lat * 100).rounded() / 100
        let roundedLng = (lng * 100).rounded() / 100
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
            cover_image_url: coverImageURL
        )
        
        let club: Club = try await client
            .from("clubs")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
        
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
        coverImageURL: String?
    ) async throws -> Club {
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
        }
        
        let update = ClubUpdate(
            name: name,
            description: description,
            genre_tags: genreTags,
            location: locationWKT,
            city_label: cityLabel,
            is_public: isPublic,
            member_cap: memberCap,
            cover_image_url: coverImageURL
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
        let uid = try await currentUserID
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
    
    func updateMeeting(
        meetingId: UUID,
        title: String,
        scheduledAt: Date,
        fromChapter: Int?,
        toChapter: Int?,
        chapterTitles: [String]?,
        notes: String? = nil,
        address: String?,
        isFinal: Bool
    ) async throws -> Meeting {
        struct MeetingUpdate: Encodable {
            let title: String
            let scheduled_at: String
            let from_chapter: Int?
            let to_chapter: Int?
            let chapter_titles: [String]?
            let notes: String?
            let address: String?
            let is_final: Bool
        }
        
        let update = MeetingUpdate(
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
            .update(update)
            .eq("id", value: meetingId.uuidString)
            .select()
            .single()
            .execute()
            .value
    }
    
    // MARK: - Meeting RSVPs
    
    func fetchMyRSVP(meetingId: UUID) async throws -> MeetingRSVP? {
        let rows: [MeetingRSVP] = try await client
            .rpc("get_my_rsvp", params: ["p_meeting_id": AnyJSON.string(meetingId.uuidString)])
            .execute()
            .value
        return rows.first
    }
    
    @discardableResult
    func upsertRSVP(meetingId: UUID, clubId: UUID, status: RSVPStatus) async throws -> MeetingRSVP {
        let uid = try await currentUserID
        
        struct RSVPUpsert: Encodable {
            let meeting_id: String
            let club_id: String
            let user_id: String
            let status: String
        }
        
        let payload = RSVPUpsert(
            meeting_id: meetingId.uuidString,
            club_id: clubId.uuidString,
            user_id: uid.uuidString,
            status: status.rawValue
        )
        
        return try await client
            .from("meeting_rsvps")
            .upsert(payload, onConflict: "meeting_id,user_id")
            .select()
            .single()
            .execute()
            .value
    }
    
    func fetchRSVPMembers(meetingId: UUID) async throws -> [RSVPMember] {
        try await client
            .rpc("get_meeting_rsvps", params: ["p_meeting_id": AnyJSON.string(meetingId.uuidString)])
            .execute()
            .value
    }
    
    func fetchRSVPCounts(meetingId: UUID) async throws -> RSVPCounts {
        let rows: [RSVPCounts] = try await client
            .from("meeting_rsvp_counts")
            .select("going_count,not_going_count")
            .eq("meeting_id", value: meetingId.uuidString)
            .execute()
            .value
        return rows.first ?? RSVPCounts(goingCount: 0, notGoingCount: 0)
    }
    
    // MARK: - Book archive
    
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
        guard let uid = try? await currentUserID else { return nil }
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
        let uid = try await currentUserID
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
    
    func fetchBoardPosts(clubId: UUID) async throws -> [Post] {
        try await client
            .from("posts")
            .select("id, club_id, user_id, post_type, parent_post_id, content, is_spoiler, is_pinned, created_at, users:user_id(*)")
            .eq("club_id", value: clubId.uuidString)
            .is("parent_post_id", value: nil)
            .order("is_pinned", ascending: false)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    func fetchLikeCount(postId: UUID) async throws -> Int {
        try await client
            .from("post_likes")
            .select("*", count: .exact)
            .eq("post_id", value: postId.uuidString)
            .execute()
            .count ?? 0
    }
    
    func pinPost(postId: UUID, pinned: Bool) async throws {
        try await client
            .from("posts")
            .update(["is_pinned": pinned])
            .eq("id", value: postId.uuidString)
            .execute()
    }
    
    func fetchComments(parentPostId: UUID) async throws -> [Post] {
        try await client
            .from("posts")
            .select("id, club_id, user_id, post_type, parent_post_id, content, is_spoiler, is_pinned, created_at, users:user_id(*)")
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
    ) async throws {
        let uid = try await currentUserID
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
        try await client
            .from("posts")
            .insert(insert)
            .execute()
    }
    
    func deletePost(id: UUID) async throws {
        try await client.from("posts").delete().eq("id", value: id.uuidString).execute()
    }
    
    func likePost(postId: UUID) async throws {
        let uid = try await currentUserID
        struct LikeInsert: Encodable {
            let post_id: String
            let user_id: String
        }
        try await client
            .from("post_likes")
            .upsert(LikeInsert(post_id: postId.uuidString, user_id: uid.uuidString),
                    onConflict: "post_id,user_id")
            .execute()
    }
    
    func unlikePost(postId: UUID) async throws {
        let uid = try await currentUserID
        try await client
            .from("post_likes")
            .delete()
            .eq("post_id", value: postId.uuidString)
            .eq("user_id", value: uid.uuidString)
            .execute()
    }
    
    func fetchMyLikedPostIds() async throws -> Set<UUID> {
        let uid = try await currentUserID
        struct LikeRow: Decodable {
            let postId: UUID
            enum CodingKeys: String, CodingKey { case postId = "post_id" }
        }
        let rows: [LikeRow] = try await client
            .from("post_likes")
            .select("post_id")
            .eq("user_id", value: uid.uuidString)
            .execute()
            .value
        return Set(rows.map(\.postId))
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
        let uid = try await currentUserID
        try await client.from("votes").insert([
            "vote_session_id": voteSessionId.uuidString,
            "club_id": clubId.uuidString,
            "book_id": bookId.uuidString,
            "user_id": uid.uuidString,
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
    
    // MARK: - Vote Suggestions
    
    func fetchSuggestions(sessionId: UUID) async throws -> [BookSuggestion] {
        let uid = try await currentUserID
        
        struct SuggestionRow: Decodable {
            let id: UUID
            let books: Book
            let voteCount: Int
            let hasVoted: Bool
            let suggestedByName: String?
            
            enum CodingKeys: String, CodingKey {
                case id
                case books
                case voteCount       = "vote_count"
                case hasVoted        = "has_voted"
                case suggestedByName = "suggested_by_name"
            }
        }
        
        let rows: [SuggestionRow] = try await client
            .rpc("get_vote_suggestions", params: [
                "p_session_id": AnyJSON.string(sessionId.uuidString),
                "p_user_id": AnyJSON.string(uid.uuidString)
            ])
            .execute()
            .value
        
        return rows.map {
            BookSuggestion(
                id: $0.id,
                book: $0.books,
                voteCount: $0.voteCount,
                hasVoted: $0.hasVoted,
                suggestedByName: $0.suggestedByName
            )
        }
    }
    
    func suggestBook(voteSessionId: UUID, bookId: UUID, clubId: UUID) async throws {
        let uid = try await currentUserID
        try await client.from("vote_suggestions").insert([
            "vote_session_id": voteSessionId.uuidString,
            "book_id": bookId.uuidString,
            "club_id": clubId.uuidString,
            "suggested_by": uid.uuidString,
        ]).execute()
    }
    
    func removeVote(voteSessionId: UUID, bookId: UUID) async throws {
        let uid = try await currentUserID
        try await client
            .from("votes")
            .delete()
            .eq("vote_session_id", value: voteSessionId.uuidString)
            .eq("book_id", value: bookId.uuidString)
            .eq("user_id", value: uid.uuidString)
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
    
    func fetchBooksReadCount() async throws -> Int {
        guard let uid = try? await currentUserID else { return 0 }
        let response = try await client
            .rpc("count_books_read", params: ["p_user_id": uid.uuidString])
            .execute()
        return Int(String(data: response.data, encoding: .utf8) ?? "0") ?? 0
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
    
    // MARK: - Book Rating
    
    func fetchBookRating(clubId: UUID, bookId: UUID) async throws -> BookRating {
        let uid = try await currentUserID
        let rows: [BookRating] = try await client
            .rpc("get_book_ratings", params: [
                "p_club_id": AnyJSON.string(clubId.uuidString),
                "p_book_id": AnyJSON.string(bookId.uuidString),
                "p_user_id": AnyJSON.string(uid.uuidString)
            ])
            .execute()
            .value
        return rows.first ?? BookRating(myRating: nil, avgRating: nil, ratingCount: 0)
    }
    
    func upsertBookRating(clubId: UUID, bookId: UUID, rating: Double) async throws {
        let uid = try await currentUserID
        
        struct RatingUpsert: Encodable {
            let club_id: String
            let book_id: String
            let user_id: String
            let rating: Double
        }
        
        try await client
            .from("book_ratings")
            .upsert(
                RatingUpsert(
                    club_id: clubId.uuidString,
                    book_id: bookId.uuidString,
                    user_id: uid.uuidString,
                    rating: rating
                ),
                onConflict: "club_id,book_id,user_id"
            )
            .execute()
    }
    
    
    // MARK: - Pending Join Requests (organiser)
    
    func fetchPendingMembers(clubId: UUID) async throws -> [AppUser] {
        struct MemberRow: Decodable {
            let users: AppUser
        }
        let rows: [MemberRow] = try await client
            .from("club_members")
            .select("users(*)")
            .eq("club_id", value: clubId.uuidString)
            .eq("status", value: "pending")
            .execute()
            .value
        return rows.map(\.users)
    }
    
    func approveMember(clubId: UUID, userId: UUID) async throws {
        try await client
            .from("club_members")
            .update(["status": "active"])
            .eq("club_id", value: clubId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
    
    func rejectMember(clubId: UUID, userId: UUID) async throws {
        try await client
            .from("club_members")
            .delete()
            .eq("club_id", value: clubId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
    
}
