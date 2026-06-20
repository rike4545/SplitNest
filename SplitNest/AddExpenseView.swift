//
//  AddExpenseView.swift
//  SplitNest
//
//  Created by Bryan on 12/2/25.
//

import SwiftUI

struct AddExpenseView: View {
    @EnvironmentObject private var household: HouseholdStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var amountText: String = ""
    @State private var selectedPayer: Member?
    @State private var selectedParticipants: Set<Member.ID> = []
    @State private var selectedCategory: ExpenseCategory = .groceries
    @State private var showValidationError = false

    // Due + recurrence
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date()
    @State private var recurrenceFrequency: RecurrenceFrequency = .none
    @State private var customIntervalText: String = ""

    var body: some View {
        Form {
            Section("Details") {
                TextField("Title", text: $title)

                TextField("Amount", text: $amountText)
                    .keyboardType(.decimalPad)

                Picker("Category", selection: $selectedCategory) {
                    ForEach(ExpenseCategory.allCases) { category in
                        Text(category.label).tag(category)
                    }
                }
            }

            Section("Payer") {
                Picker("Paid by", selection: Binding(
                    get: { selectedPayer ?? household.members.first },
                    set: { selectedPayer = $0 }
                )) {
                    ForEach(household.members) { member in
                        Text(member.name).tag(Optional(member))
                    }
                }
            }

            Section("Participants") {
                ForEach(household.members) { member in
                    Toggle(isOn: Binding(
                        get: { selectedParticipants.contains(member.id) },
                        set: { isOn in
                            if isOn {
                                selectedParticipants.insert(member.id)
                            } else {
                                selectedParticipants.remove(member.id)
                            }
                        }
                    )) {
                        Text(member.name)
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
        .navigationTitle("Add Expense")
        .navigationBarTitleDisplayMode(.inline)
#if os(iOS)
        .scrollContentBackground(.hidden)
#endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .foregroundColor(SplitNestTheme.primary)
            }
        }
        .onAppear {
            if selectedPayer == nil {
                selectedPayer = household.members.first
            }
            if selectedParticipants.isEmpty {
                selectedParticipants = Set(household.members.map(\.id))
            }
        }
        .alert("Please fill in all fields", isPresented: $showValidationError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Make sure you’ve entered a title, amount, payer, and at least one participant.")
        }
    }

    private func save() {
        guard
            !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")),
            amount > 0,
            let payer = selectedPayer,
            !selectedParticipants.isEmpty
        else {
            showValidationError = true
            return
        }

        let due = hasDueDate ? dueDate : nil
        let customInterval: Int? = {
            guard recurrenceFrequency == .customDays else { return nil }
            let trimmed = customIntervalText.trimmingCharacters(in: .whitespacesAndNewlines)
            return Int(trimmed)
        }()

        household.addExpense(
            title: title,
            amount: amount,
            paidBy: payer.id,
            participants: Array(selectedParticipants),
            category: selectedCategory,
            date: Date(),
            dueDate: due,
            recurrenceFrequency: recurrenceFrequency,
            customIntervalDays: customInterval
        )

        dismiss()
    }
}
