//
//  ClubBoardTab.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 10/03/2026.
//

import SwiftUI

struct ClubBoardTab: View {
    let club: Club
    let isOrganiser: Bool
    let isMember: Bool
    
    @State private var vm = ClubBoardViewModel()
    @State private var showBanner = true
    @State private var showCompose = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            if !isMember {
                membersOnlyBanner
            } else {
                boardContent
            }
        }
        .padding(.bottom, Spacing.xxl)
        .task { await vm.load(clubId: club.id) }
    }
    
    // MARK: - Members only
    
    private var membersOnlyBanner: some View {
        EmptyStateView(
            icon: "lock.fill",
            title: "Members Only",
            description: "Join this club to read announcements and join the discussion."
        )
    }
    
    // MARK: - Board content
    
    private var boardContent: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            if showBanner {
                infoBanner
            }
            
            if isOrganiser {
                Button { showCompose = true } label: {
                    Label("New Announcement", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())            }
            
            if vm.isLoading {
                ProgressView()
                    .tint(.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xxl)
            } else if vm.posts.isEmpty {
                EmptyStateView(
                    icon: "megaphone",
                    title: "No posts",
                    description: "The organiser hasn't posted any announcements yet."
                )
            } else {
                VStack(spacing: Spacing.md) {
                    ForEach(vm.posts) { post in
                        AnnouncementCard(
                            post: post,
                            isOrganiser: isOrganiser,
                            likeCount: vm.likeCounts[post.id, default: 0],
                            isLiked: vm.likedPostIds.contains(post.id),
                            onLike: {
                                Task { await vm.toggleLike(postId: post.id) }
                            },
                            onPin: {
                                Task { await vm.togglePin(post: post, clubId: club.id) }
                            },
                            onDelete: {
                                Task { await vm.deletePost(post: post, clubId: club.id) }
                            },
                            onComment: { text in
                                Task { await vm.postComment(text: text, parentId: post.id, clubId: club.id) }
                            }
                        )
                    }
                }
            }
            
            if let error = vm.error {
                Text(error.message)
                    .font(.appCaption)
                    .foregroundStyle(.red)
            }
        }
        .sheet(isPresented: $showCompose) {
            ComposeAnnouncementSheet(vm: vm) {
                await vm.postAnnouncement(clubId: club.id)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Info banner
    
    private var infoBanner: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Club Bulletin Board")
                    .font(.appBody.weight(.semibold))
                    .foregroundStyle(.inkPrimary)
                Text("Only organizers can post updates. Members can comment below each post.")
                    .font(.appCaption)
                    .foregroundStyle(.inkSecondary)
            }
            Spacer()
            Button {
                withAnimation(Animations.standard) { showBanner = false }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.inkTertiary)
            }
        }
        .padding(Spacing.md)
        .background(Color.cardBackground)
        .clipShape(.rect(cornerRadius: CornerRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .stroke(Color.border, lineWidth: 1)
        }
    }
}

// MARK: - Announcement Card

struct AnnouncementCard: View {
    let post: Post
    let isOrganiser: Bool
    let likeCount: Int
    let isLiked: Bool
    let onLike: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void
    let onComment: (String) -> Void
    
    @State private var commentText = ""
    @State private var spoilerRevealed = false
    @State private var commentsExpanded = false
    
    private let collapsedCommentLimit = 2
    private var commentCount: Int { post.comments?.count ?? 0 }
    private var isPinned: Bool { post.isPinned ?? false }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            postHeader
            postBody
            reactionsRow
            Divider().background(Color.border)
            commentsSection
        }
        .background(Color.cardBackground)
        .clipShape(.rect(cornerRadius: CornerRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .stroke(isPinned ? Color.accent.opacity(0.4) : Color.border, lineWidth: isPinned ? 1.5 : 1)
        }
    }
    
    // MARK: - Header
    
    private var postHeader: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            AvatarView(user: post.author, size: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xs) {
                    Text(post.author?.displayName ?? "Organiser")
                        .font(.appBody.weight(.semibold))
                        .foregroundStyle(.inkPrimary)
                    Spacer()
                    
                    Text("organiser")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.accent)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.accentSubtle)
                        .clipShape(.rect(cornerRadius: 20))
                }
                Text(post.createdAt.formatted(.relative(presentation: .named)))
                    .font(.appCaption)
                    .foregroundStyle(.inkTertiary)
            }
            
            Spacer()
            
            HStack(spacing: Spacing.sm) {
                if isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.accent)
                }
                if isOrganiser {
                    Menu {
                        Button {
                            onPin()
                        } label: {
                            Label(isPinned ? "Unpin" : "Pin Post", systemImage: isPinned ? "pin.slash" : "pin")
                        }
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Delete Post", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16))
                            .foregroundStyle(.inkTertiary)
                            .padding(Spacing.xs)
                    }
                }
            }
        }
        .padding(Spacing.md)
    }
    
    // MARK: Body
    
    @ViewBuilder
    private var postBody: some View {
        if post.isSpoiler && !spoilerRevealed {
            Button {
                withAnimation(Animations.standard) { spoilerRevealed = true }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 14))
                    Text("Spoiler — tap to reveal")
                        .font(.appCaption)
                }
                .foregroundStyle(.inkTertiary)
                .frame(maxWidth: .infinity)
                .padding(Spacing.md)
                .background(Color.border.opacity(0.3))
                .clipShape(.rect(cornerRadius: CornerRadius.badge))
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.badge)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                        .foregroundStyle(Color.inkTertiary.opacity(0.4))
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.md)
        } else {
            Text(post.content)
                .font(.appBody)
                .foregroundStyle(.inkPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.md)
        }
    }
    
    // MARK: Reactions
    
    private var reactionsRow: some View {
        HStack(spacing: Spacing.lg) {
            Button(action: onLike) {
                HStack(spacing: 5) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 17))
                        .foregroundStyle(isLiked ? Color.red : Color.inkSecondary)
                    Text("\(likeCount)")
                        .font(.appCaption)
                        .foregroundStyle(.inkSecondary)
                }
            }
            .animation(Animations.standard, value: isLiked)
            
            HStack(spacing: 5) {
                Image(systemName: "bubble.right")
                    .font(.system(size: 17))
                    .foregroundStyle(.inkSecondary)
                Text("\(commentCount)")
                    .font(.appCaption)
                    .foregroundStyle(.inkSecondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.md)
    }
    
    // MARK: Comments
    
    private var commentsSection: some View {
        VStack(spacing: 0) {
            if let comments = post.comments, !comments.isEmpty {
                let visibleComments = commentsExpanded ? comments : Array(comments.prefix(collapsedCommentLimit))
                let hiddenCount = comments.count - collapsedCommentLimit

                VStack(spacing: 0) {
                    ForEach(visibleComments) { comment in
                        CommentRow(comment: comment)
                        if comment.id != visibleComments.last?.id {
                            Divider()
                                .background(Color.border)
                                .padding(.leading, 52)
                        }
                    }
                }

                if !commentsExpanded && hiddenCount > 0 {
                    Divider().background(Color.border).padding(.leading, 52)
                    Button {
                        withAnimation(Animations.standard) { commentsExpanded = true }
                    } label: {
                        Text("View \(hiddenCount) more comment\(hiddenCount == 1 ? "" : "s")")
                            .font(.appCaption.weight(.medium))
                            .foregroundStyle(.accent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                    }
                } else if commentsExpanded && comments.count > collapsedCommentLimit {
                    Divider().background(Color.border).padding(.leading, 52)
                    Button {
                        withAnimation(Animations.standard) { commentsExpanded = false }
                    } label: {
                        Text("Show less")
                            .font(.appCaption.weight(.medium))
                            .foregroundStyle(.inkTertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                    }
                }
            }
            replyInput
        }
        .background(Color.background.opacity(0.5))
    }
    
    private var replyInput: some View {
        HStack(spacing: Spacing.sm) {
            TextField("Add a comment…", text: $commentText)
                .font(.appBody)
                .foregroundStyle(.inkPrimary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.cardBackground)
                .clipShape(.rect(cornerRadius: 50))
                .overlay {
                    RoundedRectangle(cornerRadius: 50)
                        .stroke(Color.border, lineWidth: 1)
                }
                .submitLabel(.send)
                .onSubmit { submitComment() }
            
            Button(action: submitComment) {
                Image(systemName: "paperplane")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(commentText.isEmpty ? .inkTertiary : .accent)
                    .frame(width: 36, height: 36)
                    .background(Color.cardBackground)
                    .clipShape(.rect(cornerRadius: CornerRadius.avatar))
                    .overlay {
                        RoundedRectangle(cornerRadius: CornerRadius.avatar)
                            .stroke(Color.border, lineWidth: 1)
                    }
            }
            .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(Spacing.md)
    }
    
    private func submitComment() {
        let text = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        commentText = ""
        onComment(text)
    }
}

// MARK: - Comment Row

struct CommentRow: View {
    let comment: Post
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            AvatarView(user: comment.author, size: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xs) {
                    Text(comment.author?.displayName ?? "Member")
                        .font(.appCaptionBold)
                        .foregroundStyle(.inkPrimary)
                    Text("·")
                        .foregroundStyle(.inkTertiary)
                    Text(comment.createdAt.formatted(.relative(presentation: .named)))
                        .font(.appCaption)
                        .foregroundStyle(.inkTertiary)
                }
                Text(comment.content)
                    .font(.appCaption)
                    .foregroundStyle(.inkPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Compose Announcement Sheet

struct ComposeAnnouncementSheet: View {
    @Bindable var vm: ClubBoardViewModel
    let onPost: () async -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                TextField("Write an announcement…", text: $vm.newAnnouncementText, axis: .vertical)
                    .font(.appBody)
                    .foregroundStyle(.inkPrimary)
                    .lineLimit(5...)
                    .padding(Spacing.md)
                    .background(Color.cardBackground)
                    .clipShape(.rect(cornerRadius: CornerRadius.card))
                    .overlay {
                        RoundedRectangle(cornerRadius: CornerRadius.card)
                            .stroke(Color.border, lineWidth: 1)
                    }
                
                Toggle(isOn: $vm.isSpoiler) {
                    Label("Mark as spoiler", systemImage: "eye.slash")
                        .font(.appBody)
                        .foregroundStyle(.inkPrimary)
                }
                .tint(.accent)
                
                Spacer()
                
                if let error = vm.error {
                    Text(error.message)
                        .font(.appCaption)
                        .foregroundStyle(.red)
                }
            }
            .padding(Spacing.lg)
            .background(Color.background.ignoresSafeArea())
            .navigationTitle("New Announcement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await onPost()
                            dismiss()
                        }
                    } label: {
                        if vm.isSending {
                            ProgressView().tint(.accent)
                        } else {
                            Text("Post")
                                .font(.appBody.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, 6)
                                .background(Color.accent)
                                .clipShape(.rect(cornerRadius: CornerRadius.button))
                        }
                    }
                    .disabled(vm.newAnnouncementText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isSending)
                }
            }
        }
    }
}
