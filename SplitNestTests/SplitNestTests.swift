import Foundation
import Testing
@testable import SplitNest

struct SplitNestTests {
    @Test func householdSurvivesRestart() {
        let suite = "SplitNestTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = HouseholdStore(defaults: defaults)
        store.renameHousehold(to: "Maple House")
        store.setCurrency("EUR")
        store.addMember(name: "Alex")
        store.addMember(name: "Sam")
        store.addExpense(title: "Utilities", amount: 41.25,
                         paidBy: store.members[0].id,
                         participants: store.members.map(\.id),
                         category: .utilities)
        store.addChore(title: "Trash", assignedTo: store.members[1].id, dueDate: nil)
        store.addList(title: "Groceries")
        store.addListItem(to: store.lists[0], text: "Milk")

        let restored = HouseholdStore(defaults: defaults)
        #expect(restored.householdName == "Maple House")
        #expect(restored.currencyCode == "EUR")
        #expect(restored.members.map(\.id) == store.members.map(\.id))
        #expect(restored.expenses.first?.amount == 41.25)
        #expect(restored.chores.first?.title == "Trash")
        #expect(restored.lists.first?.items.first?.text == "Milk")
    }

    @Test func localizedAmountParsing() {
        #expect(HouseholdStore.parseAmount("1,234.50", locale: Locale(identifier: "en_US")) == 1234.50)
        #expect(HouseholdStore.parseAmount("1.234,50", locale: Locale(identifier: "de_DE")) == 1234.50)
        #expect(HouseholdStore.parseAmount("1,5", locale: Locale(identifier: "en_US")) == nil)
        #expect(HouseholdStore.parseAmount("-12", locale: Locale(identifier: "en_US")) == nil)
    }

    @Test func settlementsPreserveEveryCent() {
        let suite = "SplitNestTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = HouseholdStore(defaults: defaults)
        ["Alex", "Sam", "Lee"].forEach { store.addMember(name: $0) }
        store.addExpense(title: "Shared", amount: 10.00,
                         paidBy: store.members[0].id,
                         participants: store.members.map(\.id),
                         category: .groceries)
        #expect(store.suggestedSettlements.reduce(0) { $0 + $1.cents } == Int((store.netBalances[store.members[0].id]! * 100).rounded()))
        #expect(Int((store.netBalances.values.reduce(0, +) * 100).rounded()) == 0)
    }
}
