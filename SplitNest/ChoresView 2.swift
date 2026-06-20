import SwiftUI

struct ChoresView: View {
    @EnvironmentObject private var household: HouseholdStore
    @Environment(\.colorScheme) private var scheme

    // Sheet state
    @State private var isShowingChoreSheet = false
    @State private var isEditing = false
    @State private var choreBeingEdited: Chore?

    // Form fields (used for both Add + Edit)
    @State private var newChoreTitle: String = ""
    @State private var selectedAssigneeId: Member.ID?
    @State private var dueDate: Date = Date()
    @State private var hasDueDate: Bool = false

    // Recurrence
    @State private var recurrenceFrequency: RecurrenceFrequency = .none
    @State private var customIntervalText: String = ""
    @State private var rotatesBetweenMembers: Bool = false

    // Toast
    @State private var showChoreToast: Bool = false
    @State private var choreToastText: String = ""
    @State private var lastToastChoreID: UUID?

    /// Nearest upcoming (incomplete) chore with a due date within a few days.
    private var nextDueChore: Chore? {
        household.upcomingChores(withinDays: 5).first
    }

    var body: some View {
        VStack {
            if household.chores.isEmpty {
                emptyState
                Spacer()
            } else {
                VStack(spacing: 12) {
                    if let upcoming = nextDueChore {
                        nextDueCard(upcoming)
                    }

                    List {
                        ForEach(household.chores) { chore in
                            choreRow(chore)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    startEditing(chore)
                                }
#if os(iOS)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
#endif
#if os(iOS)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteChore(chore)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button {
                                        startEditing(chore)
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                }
#endif
                        }
                        .onDelete(perform: deleteChores)
                    }
                    .listStyle(.inset)
#if os(iOS)
                    .scrollContentBackground(.hidden)
#endif
                }
            }

            Button {
                startAddChore()
            } label: {
                Label("Add Chore", systemImage: "plus.circle.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding()
        }
        .navigationTitle("Chores")
        .sheet(isPresented: $isShowingChoreSheet) {
            choreSheet
        }
        // Toast inset so it doesn't cover the first row.
        .safeAreaInset(edge: .top) {
            if showChoreToast {
                ChoreReminderToast(
                    title: "Upcoming chore",
                    message: choreToastText,
                    scheme: scheme
                )
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            refreshChoreToast()
        }
        .onChange(of: household.chores.count) {
            refreshChoreToast()
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        SplitNestCard {
            VStack(spacing: 10) {
                Text("No chores yet")
                    .font(SplitNestTheme.sectionFont())
                Text("Create simple recurring tasks like trash, dishes, or cleaning.")
                    .font(SplitNestTheme.bodyFont())
                    .foregroundColor(SplitNestTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }

    private func choreRow(_ chore: Chore) -> some View {
        SplitNestCard {
            HStack {
                Button {
                    household.toggleChoreCompletion(chore)
                    refreshChoreToast()
                } label: {
                    Image(systemName: chore.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(chore.isCompleted ? .green : SplitNestTheme.primary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 6) {
                    Text(chore.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .strikethrough(chore.isCompleted, color: .secondary)

                    HStack(spacing: 6) {
                        if let assignedId = chore.assignedTo,
                           let member = household.member(for: assignedId) {
                            Text(member.name)
                                .font(SplitNestTheme.captionFont())
                                .foregroundColor(SplitNestTheme.textSecondary)
                        }

                        if let due = chore.dueDate {
                            Text("Due \(due, style: .date)")
                                .font(SplitNestTheme.captionFont())
                                .foregroundColor(SplitNestTheme.textSecondary)
                        }

                        if chore.recurrenceFrequency != .none {
                            Text(chore.recurrenceFrequency.label)
                                .font(SplitNestTheme.captionFont())
                                .foregroundColor(SplitNestTheme.primary)
                        }
                    }
                }

                Spacer()
            }
        }
        .padding(.vertical, 4)
    }

    private func nextDueCard(_ chore: Chore) -> some View {
        SplitNestCard {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(SplitNestTheme.accent.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: "clock.badge.checkmark")
                        .foregroundColor(SplitNestTheme.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Next up")
                        .font(SplitNestTheme.captionFont())
                        .foregroundColor(SplitNestTheme.textSecondary)
                    Text(chore.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    if let due = chore.dueDate {
                        Text("Due \(due, style: .date)")
                            .font(SplitNestTheme.captionFont())
                            .foregroundColor(SplitNestTheme.textSecondary)
                    }
                }

                Spacer()

                if let due = chore.dueDate {
                    Text(daysUntil(due))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(SplitNestTheme.primary)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Sheet

    private var choreSheet: some View {
        NavigationStack {
            Form {
                Section("Chore") {
                    TextField("Title", text: $newChoreTitle)
                }

                Section("Assigned To") {
                    Picker("Assigned to", selection: $selectedAssigneeId) {
                        Text("Unassigned").tag(Member.ID?.none)
                        ForEach(household.members) { member in
                            Text(member.name).tag(Member.ID?.some(member.id))
                        }
                    }
                }

                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker(
                            "Due date",
                            selection: $dueDate,
                            displayedComponents: .date
                        )
                    }
                }

                Section("Repeat") {
                    Picker("Frequency", selection: $recurrenceFrequency) {
                        ForEach(RecurrenceFrequency.allCases) { frequency in
                            Text(frequency.label).tag(frequency)
                        }
                    }

                    if recurrenceFrequency == .customDays {
                        TextField("Every X days", text: $customIntervalText)
                            .keyboardType(.numberPad)
                    }

                    Toggle("Rotate between roommates", isOn: $rotatesBetweenMembers)
                        .tint(SplitNestTheme.primary)
                }
            }
            .navigationTitle(isEditing ? "Edit Chore" : "Add Chore")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        cancelChoreSheet()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChore()
                    }
                    .disabled(newChoreTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    // MARK: - Actions

    private func startAddChore() {
        isEditing = false
        choreBeingEdited = nil
        newChoreTitle = ""
        selectedAssigneeId = household.members.first?.id
        dueDate = Date()
        hasDueDate = false
        recurrenceFrequency = .none
        customIntervalText = ""
        rotatesBetweenMembers = false
        isShowingChoreSheet = true
    }

    private func startEditing(_ chore: Chore) {
        isEditing = true
        choreBeingEdited = chore
        newChoreTitle = chore.title
        selectedAssigneeId = chore.assignedTo
        dueDate = chore.dueDate ?? Date()
        hasDueDate = chore.dueDate != nil
        recurrenceFrequency = chore.recurrenceFrequency
        if let customDays = chore.customIntervalDays {
            customIntervalText = String(customDays)
        } else {
            customIntervalText = ""
        }
        rotatesBetweenMembers = chore.rotatesBetweenMembers
        isShowingChoreSheet = true
    }

    private func cancelChoreSheet() {
        isShowingChoreSheet = false
        isEditing = false
        choreBeingEdited = nil
        newChoreTitle = ""
        customIntervalText = ""
        hasDueDate = false
        recurrenceFrequency = .none
        rotatesBetweenMembers = false
    }

    private func saveChore() {
        let trimmedTitle = newChoreTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let due = hasDueDate ? dueDate : nil
        let customInterval: Int? = {
            guard recurrenceFrequency == .customDays else { return nil }
            let trimmed = customIntervalText.trimmingCharacters(in: .whitespacesAndNewlines)
            return Int(trimmed)
        }()

        if isEditing, var chore = choreBeingEdited {
            chore.title = trimmedTitle
            chore.assignedTo = selectedAssigneeId
            chore.dueDate = due
            chore.recurrenceFrequency = recurrenceFrequency
            chore.customIntervalDays = customInterval
            chore.rotatesBetweenMembers = rotatesBetweenMembers

            if let index = household.chores.firstIndex(where: { $0.id == chore.id }) {
                household.chores[index] = chore
            }
        } else {
            household.addChore(
                title: trimmedTitle,
                assignedTo: selectedAssigneeId,
                dueDate: due,
                recurrenceFrequency: recurrenceFrequency,
                customIntervalDays: customInterval,
                rotatesBetweenMembers: rotatesBetweenMembers
            )
        }

        isShowingChoreSheet = false
        refreshChoreToast()
    }

    private func deleteChores(at offsets: IndexSet) {
        for index in offsets {
            let chore = household.chores[index]
            deleteChore(chore)
        }
    }

    private func deleteChore(_ chore: Chore) {
        household.deleteChore(chore)
        refreshChoreToast()
    }

    private func daysUntil(_ date: Date) -> String {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0

        switch days {
        case ..<0:
            return "Past due"
        case 0:
            return "Today"
        case 1:
            return "In 1 day"
        default:
            return "In \(days) days"
        }
    }

    // MARK: - Toast Logic

    private func refreshChoreToast() {
        guard let upcoming = nextDueChore else {
            withAnimation {
                showChoreToast = false
            }
            return
        }

        if lastToastChoreID == upcoming.id, showChoreToast {
            return
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        var parts: [String] = []

        if let assignedId = upcoming.assignedTo,
           let member = household.member(for: assignedId) {
            parts.append(member.name)
        }

        if let due = upcoming.dueDate {
            let dateText = formatter.string(from: due)
            parts.append("due \(dateText)")
        }

        let suffix = parts.joined(separator: " · ")
        if suffix.isEmpty {
            choreToastText = upcoming.title
        } else {
            choreToastText = "\(upcoming.title) – \(suffix)"
        }

        lastToastChoreID = upcoming.id

        withAnimation {
            showChoreToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation {
                showChoreToast = false
            }
        }
    }
}

// MARK: - Toast View

private struct ChoreReminderToast: View {
    let title: String
    let message: String
    let scheme: ColorScheme

    private var backgroundColor: Color {
        scheme == .dark
        ? Color.black.opacity(0.75)
        : Color(.systemBackground).opacity(0.95)
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "bell.badge")
                .font(.subheadline)
                .foregroundColor(SplitNestTheme.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(SplitNestTheme.textPrimary)

                Text(message)
                    .font(.caption2)
                    .foregroundColor(SplitNestTheme.textSecondary)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(backgroundColor)
                .shadow(radius: 4)
        )
    }
}
