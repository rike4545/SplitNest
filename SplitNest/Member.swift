//
//  Member.swift
//  SplitNest
//
//  Created by Bryan on 12/2/25.
//

// HouseholdModels.swift

import Foundation

struct Member: Identifiable, Hashable {
    let id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

// MARK: - Recurrence

enum RecurrenceFrequency: String, CaseIterable, Identifiable {
    case none
    case weekly
    case monthly
    case customDays

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none:       return "Doesn’t repeat"
        case .weekly:     return "Every week"
        case .monthly:    return "Every month"
        case .customDays: return "Custom days"
        }
    }

    /// Rough default interval in days (for chores rotation).
    var defaultIntervalDays: Int? {
        switch self {
        case .none:
            return nil
        case .weekly:
            return 7
        case .monthly:
            return 30
        case .customDays:
            return nil
        }
    }
}

// MARK: - Expense

enum ExpenseCategory: String, CaseIterable, Identifiable {
    case rent
    case utilities
    case groceries
    case diningOut
    case entertainment
    case pets
    case transport
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .rent:          return "Rent"
        case .utilities:     return "Utilities"
        case .groceries:     return "Groceries"
        case .diningOut:     return "Dining Out"
        case .entertainment: return "Entertainment"
        case .pets:          return "Pets"
        case .transport:     return "Transport"
        case .other:         return "Other"
        }
    }
}

struct Expense: Identifiable {
    let id: UUID
    var title: String
    var amount: Double
    var paidBy: Member.ID
    var participants: [Member.ID]
    var category: ExpenseCategory
    /// When the expense was added/recorded.
    var date: Date
    /// Optional due date for bills (used for reminders).
    var dueDate: Date?
    /// Optional recurrence for bills like rent, internet, etc.
    var recurrenceFrequency: RecurrenceFrequency
    /// Interval in days when `recurrenceFrequency == .customDays`.
    var customIntervalDays: Int?

    init(
        id: UUID = UUID(),
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
        self.id = id
        self.title = title
        self.amount = amount
        self.paidBy = paidBy
        self.participants = participants
        self.category = category
        self.date = date
        self.dueDate = dueDate
        self.recurrenceFrequency = recurrenceFrequency
        self.customIntervalDays = customIntervalDays
    }
}

// MARK: - Chore

struct Chore: Identifiable {
    let id: UUID
    var title: String
    var assignedTo: Member.ID?
    var dueDate: Date?
    var isCompleted: Bool

    /// Recurrence info for chores like trash / cleaning.
    var recurrenceFrequency: RecurrenceFrequency
    var customIntervalDays: Int?
    /// If true, the assignee rotates between household members on each repeat.
    var rotatesBetweenMembers: Bool

    init(
        id: UUID = UUID(),
        title: String,
        assignedTo: Member.ID?,
        dueDate: Date?,
        isCompleted: Bool = false,
        recurrenceFrequency: RecurrenceFrequency = .none,
        customIntervalDays: Int? = nil,
        rotatesBetweenMembers: Bool = false
    ) {
        self.id = id
        self.title = title
        self.assignedTo = assignedTo
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.recurrenceFrequency = recurrenceFrequency
        self.customIntervalDays = customIntervalDays
        self.rotatesBetweenMembers = rotatesBetweenMembers
    }
}

// MARK: - Lists

struct ListItem: Identifiable {
    let id: UUID
    var text: String
    var isCompleted: Bool

    init(id: UUID = UUID(), text: String, isCompleted: Bool = false) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
    }
}

struct SharedList: Identifiable {
    let id: UUID
    var title: String
    var items: [ListItem]

    init(id: UUID = UUID(), title: String, items: [ListItem] = []) {
        self.id = id
        self.title = title
        self.items = items
    }
}
