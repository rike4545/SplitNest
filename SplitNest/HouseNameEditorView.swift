//
//  HouseNameEditorView.swift
//  SplitNest
//
//  Created by Bryan on 12/3/25.
//

import SwiftUI

struct HouseNameEditorView: View {
    @EnvironmentObject private var household: HouseholdStore
    @Environment(\.dismiss) private var dismiss

    @State private var draftName: String = ""

    var body: some View {
        Form {
            Section(
                header: Text("Household Name"),
                footer: Text("Pick anything – “The Loft”, “Nerd Nest”, “Room 237”…")
                    .foregroundColor(.secondary)
            ) {
                TextField("House name", text: $draftName)
                    .textInputAutocapitalization(.words)
            }

            Section("Currency") {
                Picker("Household currency", selection: Binding(
                    get: { household.currencyCode },
                    set: { household.setCurrency($0) }
                )) {
                    ForEach(Locale.commonISOCurrencyCodes.sorted(), id: \.self) { code in
                        Text("\(code) · \(Locale.current.localizedString(forCurrencyCode: code) ?? code)")
                            .tag(code)
                    }
                }
                Text("Changing the currency changes labels only. Existing amounts are not converted.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Rename House")
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
                    // This matches the method in the regenerated HouseholdStore
                    household.renameHousehold(to: draftName)
                    dismiss()
                }
                .disabled(draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear {
            draftName = household.householdName
        }
    }
}
