//
//  MonthlyBudgetView.swift
//  SplitNest
//
//  Created by Bryan on 12/3/25.
//

import SwiftUI

struct MonthlyBudgetView: View {
    @EnvironmentObject private var household: HouseholdStore
    @State private var showingBudgetEditor = false

    var body: some View {
        List {
            if household.monthlyExpenseSummaries.isEmpty {
                SplitNestCard {
                    VStack(spacing: 8) {
                        Text("No expenses yet")
                            .font(SplitNestTheme.sectionFont())
                        Text("Add some shared expenses to see monthly totals here.")
                            .font(SplitNestTheme.bodyFont())
                            .foregroundColor(SplitNestTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(household.monthlyExpenseSummaries) { summary in
                    SplitNestCard {
                        VStack(alignment: .leading, spacing: 10) {
                            headerRow(for: summary)
                            categoryBreakdown(for: summary)
                        }
                    }
                    .padding(.vertical, 6)
#if os(iOS)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
#endif
                }
            }
        }
        .listStyle(.insetGrouped)
#if os(iOS)
        .scrollContentBackground(.hidden)
#endif
        .navigationTitle("Budget by Month")
        .toolbar {
            Button("Edit Budgets", systemImage: "slider.horizontal.3") {
                showingBudgetEditor = true
            }
        }
        .sheet(isPresented: $showingBudgetEditor) {
            NavigationStack { BudgetEditorView() }
        }
    }

    // MARK: - Rows

    private func headerRow(for summary: MonthlyExpenseSummary) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(summary.monthLabel)
                    .font(SplitNestTheme.sectionFont())
                    .foregroundColor(SplitNestTheme.textPrimary)

                if household.members.count > 0 {
                    let perPerson = summary.total / Double(household.members.count)
                    Text(L10n.format("≈ %@ per person", perPerson.formatted(.currency(code: household.currencyCode))))
                        .font(SplitNestTheme.captionFont())
                        .foregroundColor(SplitNestTheme.textSecondary)
                }
            }

            Spacer()

            Text(
                summary.total,
                format: .currency(code: household.currencyCode)
            )
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundColor(SplitNestTheme.primary)
        }
    }

    private struct CategoryRow: Identifiable {
        let id = UUID()
        let category: ExpenseCategory
        let spent: Double
        let budget: Double?

        var progress: Double? {
            guard let budget, budget > 0 else { return nil }
            return min(spent / budget, 1.0)
        }

        var overBudget: Bool {
            if let budget, budget > 0 {
                return spent > budget
            }
            return false
        }
    }

    private func categoryBreakdown(for summary: MonthlyExpenseSummary) -> some View {
        let totals = household.categoryTotals(forYear: summary.year, month: summary.month)
        let budgets = household.categoryBudgets

        let rows: [CategoryRow] = totals
            .map { (category, spent) in
                CategoryRow(
                    category: category,
                    spent: spent,
                    budget: budgets[category]
                )
            }
            .sorted { $0.spent > $1.spent }

        if rows.isEmpty {
            return AnyView(
                Text("No category breakdown for this month.")
                    .font(.caption)
                    .foregroundColor(SplitNestTheme.textSecondary)
            )
        }

        return AnyView(
            VStack(spacing: 8) {
                ForEach(rows) { row in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(row.category.label)
                                .font(SplitNestTheme.captionFont())
                                .foregroundColor(SplitNestTheme.textPrimary)

                            Spacer()

                            if let budget = row.budget {
                                Text("\(row.spent, format: .currency(code: household.currencyCode)) / \(budget, format: .currency(code: household.currencyCode))")
                                    .font(SplitNestTheme.captionFont())
                                    .foregroundColor(row.overBudget ? .red : SplitNestTheme.textSecondary)
                            } else {
                                Text(row.spent, format: .currency(code: household.currencyCode))
                                    .font(SplitNestTheme.captionFont())
                                    .foregroundColor(SplitNestTheme.textSecondary)
                            }
                        }

                        if let progress = row.progress {
                            ProgressView(value: progress)
                                .progressViewStyle(.linear)
                                .tint(row.overBudget ? .red : SplitNestTheme.primary)
                        }
                    }
                }
            }
        )
    }
}

private struct BudgetEditorView: View {
    @EnvironmentObject private var household: HouseholdStore
    @Environment(\.dismiss) private var dismiss
    @State private var drafts: [ExpenseCategory: String] = [:]
    @State private var invalid = false

    var body: some View {
        Form {
            Section {
                ForEach(ExpenseCategory.allCases) { category in
                    TextField(category.label, text: Binding(
                        get: { drafts[category] ?? "" },
                        set: { drafts[category] = $0 }
                    ))
                    .keyboardType(.decimalPad)
                }
            } footer: {
                Text(L10n.format("Monthly limits in %@. Enter 0 to remove a limit.", household.currencyCode))
            }
        }
        .navigationTitle("Category Budgets")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    let values = ExpenseCategory.allCases.map {
                        HouseholdStore.parseAmount(drafts[$0] ?? "") ?? ((drafts[$0] ?? "") == "0" ? 0 : -1)
                    }
                    guard values.allSatisfy({ $0 >= 0 }) else { invalid = true; return }
                    for (index, category) in ExpenseCategory.allCases.enumerated() {
                        household.setBudget(values[index], for: category)
                    }
                    dismiss()
                }
            }
        }
        .alert("Invalid budget", isPresented: $invalid) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Enter a nonnegative amount for each category.")
        }
        .onAppear {
            for category in ExpenseCategory.allCases {
                drafts[category] = (household.categoryBudgets[category] ?? 0)
                    .formatted(.number.precision(.fractionLength(0...2)))
            }
        }
    }
}

