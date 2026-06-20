//
//  HouseholdStore.swift
//  SplitNest
//

import Foundation
import Combine

final class HouseholdStore: ObservableObject {

    // MARK: - Published State

    @Published var householdName: String
    @Published var members: [Member]
    @Published var expenses: [Expense]
    @Published var chores: [Chore]
    @Published var lists: [SharedList]

    // MARK: - Init

    init() {
        self.householdName = "The Nest"
        self.members = []
        self.expenses = []
        self.chores = []
        self.lists = []
    }

    // MARK: - Household

    func renameHousehold(to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        householdName = trimmed
    }

    // MARK: - Members

    func addMember(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        members.append(Member(name: trimmed))
    }

    func updateMember(_ member: Member) {
        guard let index = members.firstIndex(where: { $0.id == member.id }) else { return }
        members[index] = member
    }

    func removeMember(_ member: Member) {
        members.removeAll { $0.id == member.id }

        // Also clean up references in expenses / chores / lists.
        for index in expenses.indices {
            expenses[index].participants.removeAll { $0 == member.id }
            if expenses[index].paidBy == member.id,
               let fallback = members.first?.id {
                expenses[index].paidBy = fallback
            }
        }

        for index in chores.indices {
            if chores[index].assignedTo == member.id {
                chores[index].assignedTo = members.first?.id
            }
        }
    }

    func member(for id: Member.ID) -> Member? {
        members.first(where: { $0.id == id })
    }

    // MARK: - Expenses

    func addExpense(
        title: String,
        amount: Double,
        paidBy: Member.ID,
        participants: [Member.ID],
        category: ExpenseCategory,
        date: Date = Date(),
        dueDate: Date? = nil,
        recurrenceFrequency: RecurrenceFrequency = .none,
        customIntervalDays: Int? = nil
    ) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let new = Expense(
            title: trimmedTitle,
            amount: amount,
            paidBy: paidBy,
            participants: participants,
            category: category,
            date: date,
            dueDate: dueDate,
            recurrenceFrequency: recurrenceFrequency,
            customIntervalDays: customIntervalDays
        )
        expenses.insert(new, at: 0)
    }

    /// Replace an existing expense by matching its id.
    func updateExpense(_ updated: Expense) {
        guard let index = expenses.firstIndex(where: { $0.id == updated.id }) else { return }
        expenses[index] = updated
    }

    /// Delete a specific expense.
    func deleteExpense(_ expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
    }

    /// Upcoming expenses (by dueDate) within a window of days.
    func upcomingExpenses(withinDays days: Int) -> [Expense] {
        let now = Date()
        let calendar = Calendar.current
        let horizon = calendar.date(byAdding: .day, value: days, to: now) ?? now

        return expenses
            .compactMap { expense -> Expense? in
                guard let due = expense.dueDate else { return nil }
                guard due >= now && due <= horizon else { return nil }
                return expense
            }
            .sorted { ($0.dueDate ?? now) < ($1.dueDate ?? now) }
    }

    // MARK: - Chores

    func addChore(
        title: String,
        assignedTo: Member.ID?,
        dueDate: Date?,
        recurrenceFrequency: RecurrenceFrequency = .none,
        customIntervalDays: Int? = nil,
        rotatesBetweenMembers: Bool = false
    ) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let chore = Chore(
            title: trimmedTitle,
            assignedTo: assignedTo,
            dueDate: dueDate,
            isCompleted: false,
            recurrenceFrequency: recurrenceFrequency,
            customIntervalDays: customIntervalDays,
            rotatesBetweenMembers: rotatesBetweenMembers
        )
        chores.insert(chore, at: 0)
    }

    func toggleChoreCompletion(_ chore: Chore) {
        guard let index = chores.firstIndex(where: { $0.id == chore.id }) else { return }
        chores[index].isCompleted.toggle()
        let updated = chores[index]

        // If this is a recurring chore and we just marked it complete, create the next one.
        if updated.isCompleted,
           updated.recurrenceFrequency != .none,
           let nextDue = nextDueDate(for: updated) {

            let nextAssignee = updated.rotatesBetweenMembers
                ? nextAssignee(after: updated.assignedTo)
                : updated.assignedTo

            let nextChore = Chore(
                title: updated.title,
                assignedTo: nextAssignee,
                dueDate: nextDue,
                isCompleted: false,
                recurrenceFrequency: updated.recurrenceFrequency,
                customIntervalDays: updated.customIntervalDays,
                rotatesBetweenMembers: updated.rotatesBetweenMembers
            )
            chores.insert(nextChore, at: 0)
        }
    }

    func deleteChore(_ chore: Chore) {
        chores.removeAll { $0.id == chore.id }
    }

    func upcomingChores(withinDays days: Int) -> [Chore] {
        let now = Date()
        let calendar = Calendar.current
        let horizon = calendar.date(byAdding: .day, value: days, to: now) ?? now

        return chores
            .filter { !$0.isCompleted }
            .compactMap { chore -> Chore? in
                guard let due = chore.dueDate else { return nil }
                guard due >= now && due <= horizon else { return nil }
                return chore
            }
            .sorted { ($0.dueDate ?? now) < ($1.dueDate ?? now) }
    }

    private func nextDueDate(for chore: Chore) -> Date? {
        let calendar = Calendar.current
        let base = chore.dueDate ?? Date()

        switch chore.recurrenceFrequency {
        case .none:
            return nil
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: base)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: base)
        case .customDays:
            let days = (chore.customIntervalDays ?? 0)
            guard days > 0 else { return nil }
            return calendar.date(byAdding: .day, value: days, to: base)
        }
    }

    private func nextAssignee(after current: Member.ID?) -> Member.ID? {
        guard !members.isEmpty else { return nil }
        let sortedMembers = members.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        if let current = current,
           let index = sortedMembers.firstIndex(where: { $0.id == current }) {
            let nextIndex = (index + 1) % sortedMembers.count
            return sortedMembers[nextIndex].id
        } else {
            return sortedMembers.first?.id
        }
    }

    // MARK: - Lists

    func addListItem(to list: SharedList, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        guard let index = lists.firstIndex(where: { $0.id == list.id }) else { return }
        let item = ListItem(text: trimmed)
        lists[index].items.append(item)
    }

    func toggleListItem(_ item: ListItem, in list: SharedList) {
        guard let listIndex = lists.firstIndex(where: { $0.id == list.id }) else { return }
        guard let itemIndex = lists[listIndex].items.firstIndex(where: { $0.id == item.id }) else { return }
        lists[listIndex].items[itemIndex].isCompleted.toggle()
    }

    func deleteListItem(_ item: ListItem, in list: SharedList) {
        guard let listIndex = lists.firstIndex(where: { $0.id == list.id }) else { return }
        lists[listIndex].items.removeAll { $0.id == item.id }
    }

    func addList(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        lists.append(SharedList(title: trimmed))
    }

    func renameList(_ list: SharedList, to newTitle: String) {
        guard let index = lists.firstIndex(where: { $0.id == list.id }) else { return }
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        lists[index].title = trimmed
    }

    func deleteList(_ list: SharedList) {
        lists.removeAll { $0.id == list.id }
    }

    // MARK: - Balances

    /// Very simple net balance calculation: positive = others owe them.
    var netBalances: [Member.ID: Double] {
        var balances: [Member.ID: Double] = [:]
        for member in members {
            balances[member.id] = 0
        }

        for expense in expenses {
            guard !expense.participants.isEmpty else { continue }
            let share = expense.amount / Double(expense.participants.count)

            // Participants owe their share
            for participant in expense.participants {
                balances[participant, default: 0] -= share
            }

            // Payer fronted the full amount
            balances[expense.paidBy, default: 0] += expense.amount
        }

        return balances
    }

    // MARK: - Monthly Expense Summary (for Budget by Month)

    /// Roll up all expenses into month-level totals (by expense.date),
    /// sorted with the most recent month first.
    var monthlyExpenseSummaries: [MonthlyExpenseSummary] {
        let calendar = Calendar.current
        var buckets: [YearMonth: Double] = [:]

        for expense in expenses {
            let comps = calendar.dateComponents([.year, .month], from: expense.date)
            guard let year = comps.year, let month = comps.month else { continue }
            let key = YearMonth(year: year, month: month)
            buckets[key, default: 0] += expense.amount
        }

        var results: [MonthlyExpenseSummary] = []
        for (key, total) in buckets {
            results.append(
                MonthlyExpenseSummary(
                    year: key.year,
                    month: key.month,
                    total: total
                )
            )
        }

        return results.sorted {
            if $0.year == $1.year {
                return $0.month > $1.month
            } else {
                return $0.year > $1.year
            }
        }
    }

    // MARK: - Category Budgets & Totals

    /// Simple per-category monthly budgets (can be made editable later).
    var categoryBudgets: [ExpenseCategory: Double] {
        [
            .rent:          2500,
            .utilities:     300,
            .groceries:     600,
            .diningOut:     300,
            .entertainment: 200,
            .pets:          150,
            .transport:     200,
            .other:         250
        ]
    }

    /// Per-category totals for a given year/month (by expense.date).
    func categoryTotals(forYear year: Int, month: Int) -> [ExpenseCategory: Double] {
        let calendar = Calendar.current
        var totals: [ExpenseCategory: Double] = [:]

        for expense in expenses {
            let comps = calendar.dateComponents([.year, .month], from: expense.date)
            guard comps.year == year, comps.month == month else { continue }
            totals[expense.category, default: 0] += expense.amount
        }

        return totals
    }
}

// MARK: - Supporting Types for Monthly Summary

/// Simple hashable key for (year, month) used in bucketing.
private struct YearMonth: Hashable {
    let year: Int
    let month: Int
}

/// A single month's total expenses.
struct MonthlyExpenseSummary: Identifiable {
    let id = UUID()
    let year: Int
    let month: Int
    let total: Double

    /// e.g. "January 2026"
    var monthLabel: String {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        let calendar = Calendar.current
        let date = calendar.date(from: comps) ?? Date()

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}
