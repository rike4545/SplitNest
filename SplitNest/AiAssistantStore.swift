import Foundation
import Combine

@MainActor
final class AiAssistantStore: ObservableObject {
    enum Topic: String, CaseIterable, Identifiable {
        case balances, bills, chores, budget
        var id: String { rawValue }

        var title: String {
            switch self {
            case .balances: String(localized: "Balances")
            case .bills: String(localized: "Upcoming Bills")
            case .chores: String(localized: "Open Chores")
            case .budget: String(localized: "Budget")
            }
        }

        static func matching(_ text: String) -> Topic? {
            let query = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            let words: [(Topic, [String])] = [
                (.balances, ["owe", "settle", "balance", "debe", "saldo", "saldar", "doit", "doivent", "solde", "schuldet", "ausgleich", "quem deve", "acertar", "残高", "精算", "誰が", "誰に"]),
                (.budget, ["spend", "spent", "budget", "expense", "presupuesto", "gast", "depens", "ausgab", "ausgegeben", "orcamento", "despesa", "予算", "支出", "使った"]),
                (.bills, ["bill", "due", "remind", "factur", "venc", "echeance", "rechnung", "fallig", "conta", "請求", "期限"]),
                (.chores, ["chore", "task", "tarea", "tache", "aufgabe", "taref", "家事", "掃除"])
            ]
            return words.first { _, keywords in keywords.contains { query.contains($0) } }?.0
        }
    }

    @Published var messages: [ChatMessage] = []
    init() { clearConversation() }

    func send(_ text: String, household: HouseholdStore) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        messages.append(ChatMessage(text: trimmed, sender: .user))
        let reply = Topic.matching(trimmed).map { response(for: $0, household: household) }
            ?? String(localized: "Try asking: Who owes whom? What bills are due? What chores are open? How much did we spend this month?")
        messages.append(ChatMessage(text: reply, sender: .assistant))
    }

    func send(_ topic: Topic, household: HouseholdStore) {
        messages.append(ChatMessage(text: topic.title, sender: .user))
        messages.append(ChatMessage(text: response(for: topic, household: household), sender: .assistant))
    }

    func clearConversation() {
        messages = [ChatMessage(
            text: String(localized: "I can summarize your balances, upcoming bills, open chores, and this month's spending. All answers stay on this device."),
            sender: .assistant)]
    }

    private func response(for topic: Topic, household: HouseholdStore) -> String {
        let money: (Double) -> String = { $0.formatted(.currency(code: household.currencyCode)) }
        switch topic {
        case .balances:
            let transfers = household.suggestedSettlements
            guard !transfers.isEmpty else { return String(localized: "Everyone is settled.") }
            return transfers.map { L10n.format("%@ pays %@ %@.", $0.from.name, $0.to.name, money($0.amount)) }
                .joined(separator: "\n")
        case .bills:
            let bills = household.upcomingExpenses(withinDays: 30).prefix(5)
            guard !bills.isEmpty else { return String(localized: "No bills are due in the next 30 days.") }
            return bills.compactMap { expense -> String? in
                guard let due = household.nextBillDate(for: expense) else { return nil }
                return L10n.format("%@: %@, due %@.", expense.title, money(expense.amount),
                                   due.formatted(date: .abbreviated, time: .omitted))
            }.joined(separator: "\n")
        case .chores:
            let open = household.chores.filter { !$0.isCompleted }
            guard !open.isEmpty else { return String(localized: "There are no open chores.") }
            return open.prefix(5).map {
                let name = $0.assignedTo.flatMap { household.member(for: $0)?.name } ?? String(localized: "Unassigned")
                return "\($0.title) — \(name)"
            }.joined(separator: "\n")
        case .budget:
            let parts = Calendar.current.dateComponents([.year, .month], from: Date())
            let totals = household.categoryTotals(forYear: parts.year!, month: parts.month!)
            let over = totals.keys.filter { totals[$0, default: 0] > household.categoryBudgets[$0, default: 0]
                && household.categoryBudgets[$0, default: 0] > 0 }
            let detail = over.isEmpty ? String(localized: "No categories are over budget.") :
                L10n.format("Over budget: %@.", over.map(\.label).sorted().joined(separator: ", "))
            return L10n.format("This month: %@. %@", money(totals.values.reduce(0, +)), detail)
        }
    }
}

