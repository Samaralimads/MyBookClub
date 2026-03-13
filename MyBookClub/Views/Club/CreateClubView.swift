//
//  CreateClubView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 11/03/2026.
//

import SwiftUI
import PhotosUI

struct CreateClubView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var vm = CreateClubViewModel()
    @State private var locationSvc = LocationService()
    @State private var citySearch  = CitySearchService()
    @State private var showSuccess = false

    var onClubCreated: ((Club) -> Void)?

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {

                    coverImageSection
                    clubNameSection
                    categorySection
                    descriptionSection
                    citySection
                    meetingScheduleSection
                    maxMembersSection
                    visibilitySection

                    if let error = vm.error {
                        Text(error.message)
                            .font(.appCaption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        Task { await handleCreate() }
                    } label: {
                        Text("Create Club")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!vm.canCreate || vm.isLoading)
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, Spacing.xxl)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)
            }
            .scrollIndicators(.hidden)

            if vm.isLoading { LoadingOverlay() }
        }
        .navigationTitle("Create a Club")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(.accent)
            }
        }
        .alert("Club Created! 🎉", isPresented: $showSuccess) {
            Button("Let's go!") {
                if let club = vm.createdClub { onClubCreated?(club) }
                dismiss()
            }
        } message: {
            Text("\"\(vm.createdClub?.name ?? "")\" is live. You can verify it in Supabase.")
        }
    }

    // MARK: - Cover Image

    private var coverImageSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionLabel("Cover Image")
            PhotosPicker(
                selection: $vm.selectedPhotoItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                ZStack {
                    if let image = vm.coverImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 140)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                            .overlay(alignment: .bottomTrailing) {
                                Label("Change", systemImage: "pencil")
                                    .font(.appCaption.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, Spacing.md)
                                    .padding(.vertical, Spacing.xs)
                                    .background(.black.opacity(0.45))
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.badge))
                                    .padding(Spacing.sm)
                            }
                    } else {
                        VStack(spacing: Spacing.md) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 28))
                                .foregroundStyle(.accent)
                            Text("Upload cover image")
                                .font(.appBody.weight(.medium))
                                .foregroundStyle(.inkPrimary)
                            Text("Recommended: 1200×400px")
                                .font(.appCaption)
                                .foregroundStyle(.inkSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                        .background(Color.accentSubtle.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                        .overlay {
                            RoundedRectangle(cornerRadius: CornerRadius.card)
                                .strokeBorder(
                                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                                )
                                .foregroundStyle(Color.accentColor.opacity(0.5))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Club Name

    private var clubNameSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionLabel("Club Name *")
            AppTextField(placeholder: "e.g., Downtown Fiction Readers", text: $vm.name)
        }
    }

    // MARK: - Category

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionLabel("Category *")
            Menu {
                Button("Select a category") { vm.selectedGenre = nil }
                Divider()
                ForEach(Genre.allCases, id: \.rawValue) { genre in
                    Button {
                        vm.selectedGenre = genre
                    } label: {
                        if vm.selectedGenre == genre {
                            Label(genre.label, systemImage: "checkmark")
                        } else {
                            Text(genre.label)
                        }
                    }
                }
            } label: {
                HStack {
                    Text(vm.selectedGenre?.label ?? "Select a category")
                        .font(.appBody)
                        .foregroundStyle(vm.selectedGenre == nil ? .inkTertiary : .inkPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.inkSecondary)
                }
                .padding(.horizontal, Spacing.md)
                .frame(height: 50)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.card)
                        .stroke(Color.border, lineWidth: 1)
                }
            }
        }
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionLabel("Description *")
            TextField(
                "Tell people what makes your book club special...",
                text: $vm.description,
                axis: .vertical
            )
            .lineLimit(4...)
            .font(.appBody)
            .foregroundStyle(.inkPrimary)
            .padding(Spacing.md)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .stroke(Color.border, lineWidth: 1)
            }
        }
    }

    // MARK: - City (with autocomplete)

    private var citySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionLabel("City / Neighbourhood *")

            VStack(alignment: .leading, spacing: 0) {
                // Text field
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "mappin")
                        .font(.system(size: 15))
                        .foregroundStyle(.inkSecondary)
                    TextField("e.g., Le Marais, Paris", text: $vm.cityLabel)
                        .font(.appBody)
                        .foregroundStyle(.inkPrimary)
                        .onChange(of: vm.cityLabel) { _, newValue in
                            citySearch.query = newValue
                        }
                }
                .padding(.horizontal, Spacing.md)
                .frame(height: 50)
                .background(Color.cardBackground)
                .clipShape(
                    citySearch.suggestions.isEmpty
                        ? AnyShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                        : AnyShape(UnevenRoundedRectangle(
                            topLeadingRadius: CornerRadius.card,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: CornerRadius.card
                        ))
                )
                .overlay {
                    AnyShape(UnevenRoundedRectangle(
                        topLeadingRadius: CornerRadius.card,
                        bottomLeadingRadius: citySearch.suggestions.isEmpty ? CornerRadius.card : 0,
                        bottomTrailingRadius: citySearch.suggestions.isEmpty ? CornerRadius.card : 0,
                        topTrailingRadius: CornerRadius.card
                    ))
                    .stroke(Color.border, lineWidth: 1)
                }

                // Suggestions dropdown
                if !citySearch.suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(citySearch.suggestions.enumerated()), id: \.element) { index, suggestion in
                            Button {
                                vm.cityLabel = suggestion
                                vm.selectSuggestion(citySearch.completionResults[index], citySearch: citySearch)
                                citySearch.query = ""
                            } label: {
                                HStack(spacing: Spacing.sm) {
                                    Image(systemName: "mappin.circle")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.accent)
                                    Text(suggestion)
                                        .font(.appBody)
                                        .foregroundStyle(.inkPrimary)
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .padding(.horizontal, Spacing.md)
                                .frame(height: 44)
                                .background(Color.cardBackground)
                            }
                            if index < citySearch.suggestions.count - 1 {
                                Divider()
                                    .padding(.leading, Spacing.xl + Spacing.md)
                            }
                        }
                    }
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: CornerRadius.card,
                            bottomTrailingRadius: CornerRadius.card,
                            topTrailingRadius: 0
                        )
                    )
                    .overlay {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: CornerRadius.card,
                            bottomTrailingRadius: CornerRadius.card,
                            topTrailingRadius: 0
                        )
                        .stroke(Color.border, lineWidth: 1)
                    }
                }
            }
        }
    }

    // MARK: - Meeting Schedule

    private var meetingScheduleSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionLabel("Meeting Schedule")

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("How often?")
                    .font(.appCaption)
                    .foregroundStyle(.inkSecondary)
                Menu {
                    Button("Select frequency") { vm.frequency = nil }
                    Divider()
                    ForEach(MeetingFrequency.allCases, id: \.rawValue) { freq in
                        Button {
                            vm.frequency = freq
                        } label: {
                            if vm.frequency == freq {
                                Label(freq.label, systemImage: "checkmark")
                            } else {
                                Text(freq.label)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(vm.frequency?.label ?? "Select frequency")
                            .font(.appBody)
                            .foregroundStyle(vm.frequency == nil ? .inkTertiary : .inkPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.inkSecondary)
                    }
                    .padding(.horizontal, Spacing.md)
                    .frame(height: 50)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                    .overlay {
                        RoundedRectangle(cornerRadius: CornerRadius.card)
                            .stroke(
                                vm.frequency != nil ? Color.accentColor : Color.border,
                                lineWidth: vm.frequency != nil ? 1.5 : 1
                            )
                    }
                }
            }

            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Day")
                        .font(.appCaption)
                        .foregroundStyle(.inkSecondary)
                    Menu {
                        Button("No specific day") { vm.recurringDay = nil }
                        Divider()
                        ForEach(
                            ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"],
                            id: \.self
                        ) { day in
                            Button {
                                vm.recurringDay = day
                            } label: {
                                if vm.recurringDay == day {
                                    Label(day, systemImage: "checkmark")
                                } else {
                                    Text(day)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "calendar")
                                .font(.system(size: 15))
                                .foregroundStyle(.inkSecondary)
                            Text(vm.recurringDay ?? "Saturday")
                                .font(.appBody)
                                .foregroundStyle(vm.recurringDay == nil ? .inkTertiary : .inkPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, Spacing.md)
                        .frame(height: 50)
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                        .overlay {
                            RoundedRectangle(cornerRadius: CornerRadius.card)
                                .stroke(Color.border, lineWidth: 1)
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Time")
                        .font(.appCaption)
                        .foregroundStyle(.inkSecondary)
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "clock")
                            .font(.system(size: 15))
                            .foregroundStyle(.inkSecondary)
                        DatePicker(
                            "",
                            selection: $vm.recurringTime,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .tint(.accent)
                    }
                    .padding(.horizontal, Spacing.md)
                    .frame(height: 50)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                    .overlay {
                        RoundedRectangle(cornerRadius: CornerRadius.card)
                            .stroke(Color.border, lineWidth: 1)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Max Members

    private var maxMembersSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                SectionLabel("Maximum Members")
                Text("(optional)")
                    .font(.appCaption)
                    .foregroundStyle(.inkTertiary)
            }
            HStack(spacing: Spacing.md) {
                Image(systemName: "person.2")
                    .font(.system(size: 16))
                    .foregroundStyle(.inkSecondary)
                TextField("e.g., 20", text: $vm.memberCapText)
                    .font(.appBody)
                    .foregroundStyle(.inkPrimary)
                    .keyboardType(.numberPad)
            }
            .padding(.horizontal, Spacing.md)
            .frame(height: 50)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .stroke(Color.border, lineWidth: 1)
            }
        }
    }

    // MARK: - Visibility

    private var visibilitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionLabel("Visibility")
            VStack(spacing: Spacing.sm) {
                VisibilityOption(
                    title: "Public",
                    subtitle: "Anyone can find and join",
                    icon: "globe",
                    isSelected: vm.isPublic
                ) { vm.isPublic = true }

                VisibilityOption(
                    title: "Private",
                    subtitle: "Members join by request only",
                    icon: "lock.fill",
                    isSelected: !vm.isPublic
                ) { vm.isPublic = false }
            }
        }
    }

    // MARK: - Actions

    private func handleCreate() async {
        await vm.createClub(locationService: locationSvc)
        if vm.createdClub != nil { showSuccess = true }
    }
}

// MARK: - Shared Sub-views

private struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.appBody.weight(.semibold))
            .foregroundStyle(.inkPrimary)
    }
}

private struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    var body: some View {
        TextField(placeholder, text: $text)
            .font(.appBody)
            .foregroundStyle(.inkPrimary)
            .padding(.horizontal, Spacing.md)
            .frame(height: 50)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .stroke(Color.border, lineWidth: 1)
            }
    }
}

private struct VisibilityOption: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? .accent : .inkSecondary)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.appBody.weight(.medium))
                        .foregroundStyle(.inkPrimary)
                    Text(subtitle)
                        .font(.appCaption)
                        .foregroundStyle(.inkSecondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .accent : .border)
                    .font(.system(size: 20))
            }
            .padding(Spacing.md)
            .background(isSelected ? Color.accentSubtle : Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .stroke(isSelected ? Color.accentColor : Color.border, lineWidth: 1.5)
            }
            .animation(Animations.standard, value: isSelected)
        }
    }
}

#Preview {
    NavigationStack {
        CreateClubView()
    }
}
