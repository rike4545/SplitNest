//
//  RoommatesEditorView.swift
//  SplitNest
//
//  Created by Bryan on 12/3/25.
//


import SwiftUI

struct RoommatesEditorView: View {
    @EnvironmentObject private var household: HouseholdStore
    @Environment(\.dismiss) private var dismiss

    @State private var newMemberName: String = ""

    private var roommateCountText: String {
        let count = household.members.count
        switch count {
        case 0:
            return "No roommates yet"
        case 1:
            return "1 roommate"
        default:
            return "\(count) roommates"
        }
    }

    var body: some View {
        Form {
            Section(footer: Text("These names are used when splitting expenses, chores, and lists.")) {
                HStack {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(SplitNestTheme.primary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(roommateCountText)
                            .font(.headline)
                        Text("Add, rename, or remove roommates at any time.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("Current roommates")) {
                if household.members.isEmpty {
                    Text("No roommates yet. Add a name below to get started.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(household.members) { member in
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(SplitNestTheme.primary)

                            TextField("Name", text: binding(for: member))
                        }
                    }
                    .onDelete(perform: deleteMembers)
                }
            }

            Section(header: Text("Add roommate")) {
                HStack {
                    TextField("Name", text: $newMemberName)

                    Button {
                        addMember()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .disabled(newMemberName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel("Add roommate")
                }
            }
        }
        .navigationTitle("Roommates")
        .navigationBarTitleDisplayMode(.inline)
#if os(iOS)
        .scrollContentBackground(.hidden)
#endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    // MARK: - Helpers

    private func binding(for member: Member) -> Binding<String> {
        Binding(
            get: {
                household.members.first(where: { $0.id == member.id })?.name ?? ""
            },
            set: { newValue in
                if let index = household.members.firstIndex(where: { $0.id == member.id }) {
                    household.members[index].name = newValue
                }
            }
        )
    }

    private func deleteMembers(at offsets: IndexSet) {
        household.members.remove(atOffsets: offsets)
    }

    private func addMember() {
        let trimmed = newMemberName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let new = Member(name: trimmed)
        household.members.append(new)
        newMemberName = ""
    }
}
