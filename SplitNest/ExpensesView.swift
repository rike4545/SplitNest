import SwiftUI

struct ExpensesView: View {
    @EnvironmentObject private var household: HouseholdStore
    @Environment(\.colorScheme) private var scheme

    @State private var showAddExpense = false
    @State private var expenseToEdit: Expense?
    @State private var showRoommatesEditor = false

    // Toast state
    @State private var showExpenseToast = false
    @State private var expenseToastText: String = ""
    @State private var lastToastExpenseID: UUID?

    // Use static formatter so it's not recreated every render
    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()

    /// Nearest upcoming bill (within the next 5 days).
    private var nextDueExpense: Expense? {
        household.upcomingExpenses(withinDays: 5).first
    }

    var body: some View {
        let sortedExpenses = household.expenses.sorted { $0.date > $1.date }

        VStack {
            if sortedExpenses.isEmpty {
                emptyState
                Spacer()
            } else {
                VStack(spacing: 12) {
                    if let upcoming = nextDueExpense {
                        nextDueCard(upcoming)
                    }

                    List {
                        if !household.suggestedSettlements.isEmpty {
                            Section("Settle up") {
                                ForEach(household.suggestedSettlements) { settlement in
                                    HStack {
                                        Text("\(settlement.from.name) → \(settlement.to.name)")
                                        Spacer()
                                        Text(settlement.amount, format: .currency(code: household.currencyCode))
                                            .fontWeight(.semibold)
                                    }
                                    .accessibilityElement(children: .combine)
                                }
                            }
                        }
                        Section("Expenses") {
                        ForEach(sortedExpenses) { expense in
                            expenseRow(expense)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    expenseToEdit = expense
                                }
#if os(iOS)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
#endif
#if os(iOS)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        household.deleteExpense(expense)
                                        refreshExpenseToast()
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button {
                                        expenseToEdit = expense
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                }
#endif
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                let expense = sortedExpenses[index]
                                household.deleteExpense(expense)
                            }
                            refreshExpenseToast()
                        }
                        }
                    }
#if os(iOS)
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
#else
                    .listStyle(.inset)
#endif
                }
            }

#if os(iOS)
            addButton
                .padding()
#endif
        }
        .background(Color.clear)
        .navigationTitle("Expenses")
        .toolbar {
#if os(macOS)
            ToolbarItem {
                addButton
            }
#endif
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showRoommatesEditor = true
                } label: {
                    Label("Roommates", systemImage: "person.3")
                }
            }
        }
        // Add new expense
        .sheet(isPresented: $showAddExpense) {
            NavigationStack {
                AddExpenseView()
            }
        }
        // Edit existing expense
        .sheet(item: $expenseToEdit) { expense in
            NavigationStack {
                EditExpenseView(expense: expense)
            }
        }
        // Edit roommates
        .sheet(isPresented: $showRoommatesEditor) {
            NavigationStack {
                RoommatesEditorView()
            }
        }
        // Toast: use safeAreaInset so it doesn't cover the first card
        .safeAreaInset(edge: .top) {
            if showExpenseToast {
                ExpenseReminderToast(
                    title: "Upcoming bill",
                    message: expenseToastText,
                    scheme: scheme
                )
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            refreshExpenseToast()
        }
        .onChange(of: household.expenses.count) {
            refreshExpenseToast()
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        SplitNestCard {
            VStack(spacing: 10) {
                Text("No expenses yet")
                    .font(SplitNestTheme.sectionFont())
                Text("Tap the button below to add your first shared bill or purchase.")
                    .font(SplitNestTheme.bodyFont())
                    .foregroundColor(SplitNestTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }

    private var addButton: some View {
        Button {
            showAddExpense = true
        } label: {
            Label("Add Expense", systemImage: "plus.circle.fill")
        }
        .buttonStyle(PrimaryButtonStyle())
    }

    private func nextDueCard(_ expense: Expense) -> some View {
        SplitNestCard {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(SplitNestTheme.primary.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: "bell.badge.fill")
                        .foregroundColor(SplitNestTheme.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Next up")
                        .font(SplitNestTheme.captionFont())
                        .foregroundColor(SplitNestTheme.textSecondary)
                    Text(expense.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    if let due = expense.dueDate {
                        Text("Due \(due, style: .date)")
                            .font(SplitNestTheme.captionFont())
                            .foregroundColor(SplitNestTheme.textSecondary)
                    }
                }

                Spacer()

                Text(
                    expense.amount,
                    format: .currency(code: household.currencyCode)
                )
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(SplitNestTheme.primary)
            }
        }
        .padding(.horizontal)
    }

    private func expenseRow(_ expense: Expense) -> some View {
        SplitNestCard {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(SplitNestTheme.primary.opacity(0.18))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(expense.category.label.prefix(1)))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(SplitNestTheme.primary)
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(expense.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))

                    if let payer = household.member(for: expense.paidBy) {
                        Text("Paid by \(payer.name)")
                            .font(SplitNestTheme.captionFont())
                            .foregroundColor(SplitNestTheme.textSecondary)
                    }

                    HStack(spacing: 6) {
                        Text(ExpensesView.dateFormatter.string(from: expense.date))
                        if let due = expense.dueDate {
                            Text("· Due \(due, style: .date)")
                        }
                    }
                    .font(SplitNestTheme.captionFont())
                    .foregroundColor(SplitNestTheme.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 10) {
                    Text(
                        expense.amount,
                        format: .currency(code: household.currencyCode)
                    )
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(SplitNestTheme.primary)

                    Menu {
                        Button {
                            expenseToEdit = expense
                        } label: {
                            Label("Edit Expense", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            household.deleteExpense(expense)
                            refreshExpenseToast()
                        } label: {
                            Label("Delete Expense", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(SplitNestTheme.textSecondary)
                            .frame(width: 32, height: 32)
                    }
                    .accessibilityLabel("Expense actions")
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Toast Logic

    private func refreshExpenseToast() {
        guard let upcoming = nextDueExpense else {
            withAnimation {
                showExpenseToast = false
            }
            return
        }

        // Don't constantly re-show the same bill
        if lastToastExpenseID == upcoming.id, showExpenseToast {
            return
        }

        let df = DateFormatter()
        df.dateStyle = .medium

        if let due = upcoming.dueDate {
            expenseToastText = "\(upcoming.title) · due \(df.string(from: due))"
        } else {
            expenseToastText = upcoming.title
        }

        lastToastExpenseID = upcoming.id

        withAnimation {
            showExpenseToast = true
        }

        // Auto-hide after a few seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation {
                showExpenseToast = false
            }
        }
    }
}

// MARK: - Toast View

private struct ExpenseReminderToast: View {
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
