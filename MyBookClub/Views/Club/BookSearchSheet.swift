//
//  BookSearchSheet.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 13/03/2026.
//

import SwiftUI

struct BookSearchSheet: View {
    let onSelect: (Book) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchService = BookSearchService()
    @State private var query = ""
    @State private var searchField: BookSearchField = .title

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Search by", selection: $searchField) {
                    ForEach(BookSearchField.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)

                searchResults
            }
            .background(Color.background)
            .navigationTitle("Set Current Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.accent)
                }
            }
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: searchField == .title ? "Search by title" : "Search by author"
            )
        }
        .task(id: query + searchField.rawValue) {
            try? await Task.sleep(for: .milliseconds(350))
            await searchService.search(query: query, field: searchField)
        }
    }

    // MARK: - Results

    @ViewBuilder
    private var searchResults: some View {
        if searchService.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if query.isEmpty {
            ContentUnavailableView(
                "Search for a book",
                systemImage: "magnifyingglass",
                description: Text(
                    searchField == .title
                        ? "Type a book title above"
                        : "Type an author name above"
                )
            )
        } else if query.count < 3 {
            ContentUnavailableView(
                "Keep typing…",
                systemImage: "magnifyingglass",
                description: Text("Enter at least 3 characters to search")
            )
        } else if searchService.results.isEmpty {
            ContentUnavailableView.search(text: query)
        } else {
            List(searchService.results) { book in
                Button {
                    onSelect(book)
                    dismiss()
                } label: {
                    BookSearchRow(book: book)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.cardBackground)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}

// MARK: - Row

private struct BookSearchRow: View {
    let book: Book

    var body: some View {
        HStack(spacing: Spacing.md) {
            AsyncImage(url: book.displayCoverURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    coverPlaceholder
                }
            }
            .frame(width: 44, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.badge))

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(book.title)
                    .font(.appBody.weight(.semibold))
                    .foregroundStyle(.inkPrimary)
                    .lineLimit(2)
                Text(book.author)
                    .font(.appCaption)
                    .foregroundStyle(.inkSecondary)
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    private var coverPlaceholder: some View {
        Color.purpleTint
            .overlay {
                Image(systemName: "book.closed")
                    .foregroundStyle(.accent.opacity(0.5))
            }
    }
}
