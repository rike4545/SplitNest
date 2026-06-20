//
//  EditExpenseView.swift
//  SplitNest
//
//  Created by Bryan on 12/3/25.
//

import SwiftUI

struct EditExpenseView: View {
    @EnvironmentObject private var household: HouseholdStore
    @Environment(\.dismiss) private var dismiss

    /// The original expense we’re editing (used for id/date + fallback values)
    private let originalExpense: Expense

    // Editable fields
    @State private var title: String
    @State private var amountText: String
    @State private var paidBy: Member.ID
    @State private var selectedParticipants: Set<Member.ID>
    @State private var category: ExpenseCategory

    // Due + recurrence
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var recurrenceFrequency: RecurrenceFrequency
    @State private var customIntervalText: String
    @State private var showingDeleteConfirmation = false

    // MARK: - Init

    init(expense: Expense) {
        self.originalExpense = expense
        _title = State(initialValue: expense.title)
        _amountText = State(initialValue: String(format: "%.2f", expense.amount))
        _paidBy = State(initialValue: expense.paidBy)
        _selectedParticipants = State(initialValue: Set(expense.participants))
        _category = State(initialValue: expense.category)

        let hasDue = expense.dueDate != nil
        _hasDueDate = State(initialValue: hasDue)
        _dueDate = State(initialValue: expense.dueDate ?? expense.date)
        _recurrenceFrequency = State(initialValue: expense.recurrenceFrequency)
        if let customDays = expense.customIntervalDays {
            _customIntervalText = State(initialValue: String(customDays))
        } else {
            _customIntervalText = State(initialValue: "")
        }
    }

    // MARK: - Body

    var body: some View {
        Form {
            Section(header: Text("Details")) {
                TextField("Title", text: $title)

                TextField("Amount", text: $amountText)
                    .multilineTextAlignment(.trailing)

                // Optional read-only date display
                HStack {
                    Text("Created")
                    Spacer()
                    Text(originalExpense.date, style: .date)
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("Category")) {
                Picker("Category", selection: $category) {
                    ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                        Text(cat.label)
                            .tag(cat)
                    }
                }
            }

            Section(header: Text("Paid by")) {
                Picker("Paid by", selection: $paidBy) {
                    ForEach(household.members) { member in
                        Text(member.name).tag(member.id)
                    }
                }
            }

            Section(header: Text("Shared with")) {
                if household.members.isEmpty {
                    Text("No roommates configured yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(household.members) { member in
                        Toggle(isOn: participantBinding(for: member)) {
                            Text(member.name)
                        }
                    }
                }
            }

            Section("Due & Repeat") {
                Toggle("Set due date", isOn: $hasDueDate)

                if hasDueDate {
                    DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                }

                Picker("Repeat", selection: $recurrenceFrequency) {
                    ForEach(RecurrenceFrequency.allCases) { frequency in
                        Text(frequency.label).tag(frequency)
                    }
                }

                if recurrenceFrequency == .customDays {
                    TextField("Every X days", text: $customIntervalText)
                        .keyboardType(.numberPad)
                }
            }
        }
        .navigationTitle("Edit Expense")
        .navigationBarTitleDisplayMode(.inline)
#if os(iOS)
        .scrollContentBackground(.hidden)
#endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .bottomBar) {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete Expense", systemImage: "trash")
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .foregroundColor(SplitNestTheme.primary)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .confirmationDialog(
            "Delete this expense?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Expense", role: .destructive) {
                household.deleteExpense(originalExpense)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes the expense from balances and monthly totals.")
        }
    }

    // MARK: - Helpers

    private func participantBinding(for member: Member) -> Binding<Bool> {
        Binding(
            get: { selectedParticipants.contains(member.id) },
            set: { isSelected in
                if isSelected {
                    selectedParticipants.insert(member.id)
                } else {
                    selectedParticipants.remove(member.id)
                }
            }
        )
    }

    private func save() {
        var updated = originalExpense

        // Title
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)

        // Amount: strip out non-numeric chars, fallback to original if parse fails
        let cleanedString = amountText
            .replacingOccurrences(of: ",", with: ".")
            .filter { "0123456789.".contains($0) }

        let parsedAmount = Double(cleanedString) ?? originalExpense.amount
        updated.amount = parsedAmount

        // Payer
        updated.paidBy = paidBy

        // Category
        updated.category = category

        // Participants – ensure at least the payer is included
        var participants = Array(selectedParticipants)
        if participants.isEmpty {
            participants = [paidBy]
        }
        updated.participants = participants

        // Due + recurrence
        updated.dueDate = hasDueDate ? dueDate : nil
        if recurrenceFrequency == .none {
            updated.recurrenceFrequency = .none
            updated.customIntervalDays = nil
        } else {
            updated.recurrenceFrequency = recurrenceFrequency
            let trimmed = customIntervalText.trimmingCharacters(in: .whitespacesAndNewlines)
            if recurrenceFrequency == .customDays {
                updated.customIntervalDays = Int(trimmed)
            } else {
                updated.customIntervalDays = nil
            }
        }

        household.updateExpense(updated)
        dismiss()
    }
}
