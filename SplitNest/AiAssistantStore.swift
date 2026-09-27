import Foundation
import Combine

@MainActor
final class AiAssistantStore: ObservableObject {
    @Published var messages: [ChatMessage] = []

    init() { clearConversation() }

    func send(_ text: String, household: HouseholdStore) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        messages.append(ChatMessage(text: trimmed, sender: .user))
        messages.append(ChatMessage(text: response(to: trimmed, household: household),
                                    sender: .assistant))
    }

    func clearConversation() {
        messages = [ChatMessage(
            text: "I can summarize your balances, upcoming bills, open chores, and this month's spending. All answers stay on this device.",
            sender: .assistant)]
    }

    private func response(to text: String, household: HouseholdStore) -> String {
        let query = text.lowercased()
        let money: (Double) -> String = {
            $0.formatted(.currency(code: household.currencyCode))
        }
        if query.contains("owe") || query.contains("settle") || query.contains("balance") {
            let transfers = household.suggestedSettlements
            guard !transfers.isEmpty else { return "Everyone is settled." }
            return transfers.map { "\($0.from.name) pays \($0.to.name) \(money($0.amount))." }
                .joined(separator: "\n")
        }
        if query.contains("bill") || query.contains("due") || query.contains("remind") {
            let bills = household.upcomingExpenses(withinDays: 30).prefix(5)
            guard !bills.isEmpty else { return "No bills are due in the next 30 days." }
            return bills.map {
                let due = household.nextBillDate(for: $0)!.formatted(date: .abbreviated, time: .omitted)
                return "\($0.title): \(money($0.amount)), due \(due)."
            }.joined(separator: "\n")
        }
        if query.contains("chore") || query.contains("task") {
            let open = household.chores.filter { !$0.isCompleted }
            guard !open.isEmpty else { return "There are no open chores." }
            return open.prefix(5).map {
                let name = $0.assignedTo.flatMap { household.member(for: $0)?.name } ?? "Unassigned"
                return "\($0.title) — \(name)."
            }.joined(separator: "\n")
        }
        if query.contains("spend") || query.contains("budget") || query.contains("expense") {
            let parts = Calendar.current.dateComponents([.year, .month], from: Date())
            let totals = household.categoryTotals(forYear: parts.year!, month: parts.month!)
            let total = totals.values.reduce(0, +)
            let over = totals.keys.filter { totals[$0, default: 0] >
                household.categoryBudgets[$0, default: 0] && household.categoryBudgets[$0, default: 0] > 0 }
            let detail = over.isEmpty ? "No categories are over budget." :
                "Over budget: " + over.map(\.label).sorted().joined(separator: ", ") + "."
            return "This month: \(money(total)). \(detail)"
        }
        return "Try asking: Who owes whom? What bills are due? What chores are open? How much did we spend this month?"
    }
}
