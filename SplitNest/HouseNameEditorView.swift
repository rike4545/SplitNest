//
//  HouseNameEditorView.swift
//  SplitNest
//
//  Created by Bryan on 12/3/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct HouseNameEditorView: View {
    @EnvironmentObject private var household: HouseholdStore
    @Environment(\.dismiss) private var dismiss

    @State private var draftName: String = ""
    @State private var backup: HouseholdBackupDocument?
    @State private var exporting = false
    @State private var importing = false
    @State private var pendingImport: Data?
    @State private var confirmingRestore = false
    @State private var backupError: String?

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

            Section("Backup") {
                Button("Export JSON Backup", systemImage: "square.and.arrow.up") {
                    do {
                        backup = HouseholdBackupDocument(data: try household.exportBackup())
                        exporting = true
                    } catch { backupError = error.localizedDescription }
                }
                Button("Restore JSON Backup", systemImage: "square.and.arrow.down") {
                    importing = true
                }
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
        .navigationTitle("Household Settings")
        .fileExporter(isPresented: $exporting, document: backup,
                      contentType: .json, defaultFilename: "SplitNest-Backup") { result in
            if case let .failure(error) = result { backupError = error.localizedDescription }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get()
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                pendingImport = try Data(contentsOf: url)
                confirmingRestore = true
            } catch {
                backupError = error.localizedDescription
            }
        }
        .confirmationDialog("Replace this household with the backup?",
                            isPresented: $confirmingRestore) {
            Button("Restore Backup", role: .destructive) {
                guard let pendingImport else { return }
                do { try household.importBackup(pendingImport); draftName = household.householdName }
                catch { backupError = "This is not a valid SplitNest backup." }
                self.pendingImport = nil
            }
        } message: {
            Text("Current household data will be replaced.")
        }
        .alert("Backup Error", isPresented: Binding(
            get: { backupError != nil },
            set: { if !$0 { backupError = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(backupError ?? "")
        }
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

private struct HouseholdBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
