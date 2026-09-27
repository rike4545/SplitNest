import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var household: HouseholdStore
    @State private var showingRenameHouse = false
    @State private var showingAssistant = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                summaryRow

                settleUpSection

                upcomingBillsSection

                upcomingChoresSection

                BannerAdContainerView()
            }
            .padding()
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showingAssistant = true
                } label: {
                    Label("Assistant", systemImage: "sparkles")
                }

                Button {
                    showingRenameHouse = true
                } label: {
                    Label("Rename house", systemImage: "pencil.circle")
                }
            }
        }
        .sheet(isPresented: $showingRenameHouse) {
            NavigationStack {
                HouseNameEditorView()
            }
        }
        .sheet(isPresented: $showingAssistant) {
            NavigationStack {
                AssistantView()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(SplitNestTheme.heroGradient)
                .frame(minHeight: 160)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "house.lodge.fill")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                    Text("SplitNest")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .opacity(0.9)
                }
                .foregroundColor(.white.opacity(0.95))

                Text(household.householdName)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Shared expenses, chores, and lists with zero awkwardness.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))

                HStack(spacing: 8) {
                    PillTag(text: "Household")
                    PillTag(text: "\(household.members.count) roommates")
                }
            }
            .padding(20)
        }
        .shadow(color: SplitNestTheme.primary.opacity(0.18), radius: 12, x: 0, y: 6)
    }

    // MARK: - Summary

    private var summaryRow: some View {
        let unsettledCount = household.netBalances.values.filter { abs($0) > 0.01 }.count
        let openChores = household.chores.filter { !$0.isCompleted }.count

        let columns = [GridItem(.adaptive(minimum: 110), spacing: 12)]

        return LazyVGrid(columns: columns, spacing: 12) {
            summaryCard(
                title: "Roommates",
                value: "\(household.members.count)",
                subtitle: "people in this household",
                icon: "person.3.fill",
                accent: SplitNestTheme.accent
            )

            summaryCard(
                title: "Balances",
                value: "\(unsettledCount)",
                subtitle: unsettledCount == 1 ? "person unsettled" : "people unsettled",
                icon: "scale.3d",
                accent: SplitNestTheme.primary
            )

            summaryCard(
                title: "Open Chores",
                value: "\(openChores)",
                subtitle: "waiting to be done",
                icon: "checkmark.seal.fill",
                accent: SplitNestTheme.ink
            )

            summaryCard(
                title: "Settle Up",
                value: settlementSummaryValue,
                subtitle: settlementSummarySubtitle,
                icon: "arrow.left.arrow.right.circle.fill",
                accent: SplitNestTheme.accent
            )
        }
    }

    private func summaryCard(title: String, value: String, subtitle: String, icon: String, accent: Color) -> some View {
        SplitNestCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(accent)
                    Spacer()
                    Text(title)
                        .font(SplitNestTheme.captionFont())
                        .foregroundColor(SplitNestTheme.textSecondary)
                }

                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(SplitNestTheme.textPrimary)

                Text(subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(SplitNestTheme.textSecondary)
            }
        }
    }

    // MARK: - Settle Up

    private var settleUpSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SplitNestSectionHeader("Settle Up", subtitle: "The fewest payments to even things out.")

            if household.suggestedSettlements.isEmpty {
                SplitNestCard {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(SplitNestTheme.accent.opacity(0.18))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(SplitNestTheme.accent)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Everyone is settled")
                                .font(SplitNestTheme.sectionFont())
                            Text("No reimbursements are needed right now.")
                                .font(SplitNestTheme.captionFont())
                                .foregroundColor(SplitNestTheme.textSecondary)
                        }
                    }
                }
            } else {
                ForEach(household.suggestedSettlements) { suggestion in
                    SplitNestCard {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(SplitNestTheme.primary.opacity(0.16))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(SplitNestTheme.primary)
                                )

                            VStack(alignment: .leading, spacing: 5) {
                                Text("\(suggestion.from.name) pays \(suggestion.to.name)")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(SplitNestTheme.textPrimary)

                                Text("Balances after shared expenses")
                                    .font(SplitNestTheme.captionFont())
                                    .foregroundColor(SplitNestTheme.textSecondary)
                            }

                            Spacer()

                            Text(
                                suggestion.amount,
                                format: .currency(code: household.currencyCode)
                            )
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(SplitNestTheme.primary)
                        }
                    }
                }
            }
        }
    }

    private var settlementSummaryValue: String {
        guard let first = household.suggestedSettlements.first else { return 0.formatted(.currency(code: household.currencyCode)) }
        return first.amount.formatted(.currency(code: household.currencyCode))
    }

    private var settlementSummarySubtitle: String {
        switch household.suggestedSettlements.count {
        case 0:
            return "all balances even"
        case 1:
            return "one payment suggested"
        default:
            return "\(household.suggestedSettlements.count) payments suggested"
        }
    }

    // MARK: - Upcoming Bills

    private var upcomingBillsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SplitNestSectionHeader("Upcoming Bills", subtitle: "Keep an eye on what’s due next.")

            if upcomingBills.isEmpty {
                SplitNestCard {
                    HStack(spacing: 12) {
                        Image(systemName: "tray.fill")
                            .foregroundColor(SplitNestTheme.accent)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("No upcoming bills")
                                .font(SplitNestTheme.sectionFont())
                            Text("Add expenses in the Expenses tab to get reminders here.")
                                .font(SplitNestTheme.captionFont())
                                .foregroundColor(SplitNestTheme.textSecondary)
                        }
                    }
                }
            } else {
                ForEach(upcomingBills) { expense in
                    SplitNestCard {
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(SplitNestTheme.primary.opacity(0.15))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: "creditcard.fill")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(SplitNestTheme.primary)
                                )

                            VStack(alignment: .leading, spacing: 6) {
                                Text(expense.title)
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(SplitNestTheme.textPrimary)

                                HStack(spacing: 6) {
                                    if let payer = household.member(for: expense.paidBy) {
                                        Text("Paid by \(payer.name)")
                                    }
                                    Text(expense.date, style: .date)
                                }
                                .font(SplitNestTheme.captionFont())
                                .foregroundColor(SplitNestTheme.textSecondary)
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
                }
            }
        }
    }

    /// Choose up to 3 “upcoming” expenses.
    /// If none are in the future, show the 3 most recent instead.
    private var upcomingBills: [Expense] {
        let now = Date()

        let future = household.expenses
            .filter { $0.date >= now }
            .sorted(by: { $0.date < $1.date })

        if !future.isEmpty {
            return Array(future.prefix(3))
        }

        let recent = household.expenses.sorted(by: { $0.date > $1.date })
        return Array(recent.prefix(3))
    }

    // MARK: - Upcoming Chores & Deadlines

    private var upcomingChoresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SplitNestSectionHeader("Other Deadlines", subtitle: "Chores and reminders you don’t want to miss.")

            if upcomingChores.isEmpty {
                SplitNestCard {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.badge.checkmark")
                            .foregroundColor(SplitNestTheme.accent)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("No upcoming chore deadlines")
                                .font(SplitNestTheme.sectionFont())
                            Text("Add due dates in the Chores tab to stay ahead.")
                                .font(SplitNestTheme.captionFont())
                                .foregroundColor(SplitNestTheme.textSecondary)
                        }
                    }
                }
            } else {
                ForEach(upcomingChores) { chore in
                    SplitNestCard {
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(SplitNestTheme.accent.opacity(0.18))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(SplitNestTheme.accent)
                                )

                            VStack(alignment: .leading, spacing: 6) {
                                Text(chore.title)
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(SplitNestTheme.textPrimary)

                                HStack(spacing: 6) {
                                    if let assignedId = chore.assignedTo,
                                       let member = household.member(for: assignedId) {
                                        Text(member.name)
                                    }

                                    if let due = chore.dueDate {
                                        Text(due, style: .date)
                                    }
                                }
                                .font(SplitNestTheme.captionFont())
                                .foregroundColor(SplitNestTheme.textSecondary)
                            }

                            Spacer()

                            if let due = chore.dueDate {
                                Text(daysUntil(due))
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(SplitNestTheme.primary)
                            }
                        }
                    }
                }
            }
        }
    }

    /// Up to 3 upcoming (incomplete) chores with due dates in the future.
    private var upcomingChores: [Chore] {
        let now = Date()
        return household.chores
            .filter { !$0.isCompleted }
            .compactMap { chore -> Chore? in
                guard let due = chore.dueDate, due >= now else { return nil }
                return chore
            }
            .sorted { ($0.dueDate ?? now) < ($1.dueDate ?? now) }
            .prefix(3)
            .map { $0 }
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
}

