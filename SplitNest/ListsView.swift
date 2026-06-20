// ListsView.swift

import SwiftUI

struct ListsView: View {
    @EnvironmentObject private var household: HouseholdStore

    /// Track the selected list by its ID.
    @State private var selectedListID: SharedList.ID?
    @State private var newItemText: String = ""

    // List management state
    @State private var isShowingNewListSheet = false
    @State private var newListTitle: String = ""

    @State private var isShowingRenameSheet = false
    @State private var renameTitle: String = ""

    @State private var isShowingDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            if household.lists.isEmpty {
                emptyState
                Spacer()

                Button {
                    startCreateList()
                } label: {
                    Label("Add List", systemImage: "plus.circle.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding()
            } else {
                // Selection binding for the Picker, based on list ID
                let selectionBinding = Binding<SharedList.ID>(
                    get: {
                        if let id = selectedListID,
                           household.lists.contains(where: { $0.id == id }) {
                            return id
                        } else if let first = household.lists.first {
                            return first.id
                        } else {
                            // Guarded by `isEmpty` above; should never happen.
                            return UUID()
                        }
                    },
                    set: { newValue in
                        selectedListID = newValue
                    }
                )

                SplitNestCard {
                    HStack {
                        Picker("List", selection: selectionBinding) {
                            ForEach(household.lists) { list in
                                Text(list.title).tag(list.id)
                            }
                        }
                        .pickerStyle(.segmented)

                        Button {
                            startCreateList()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(SplitNestTheme.primary)
                        }
                        .padding(.leading, 8)
                        .accessibilityLabel("Create new list")
                    }
                }
                .padding()

                if let currentList = currentList {
                    List {
                        ForEach(currentList.items) { item in
                            Button {
                                household.toggleListItem(item, in: currentList)
                            } label: {
                                SplitNestCard {
                                    HStack {
                                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(item.isCompleted ? .green : SplitNestTheme.primary)

                                        Text(item.text)
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .strikethrough(item.isCompleted, color: .secondary)
                                            .foregroundColor(item.isCompleted ? .secondary : SplitNestTheme.textPrimary)

                                        Spacer()
                                    }
                                }
                            }
                            .buttonStyle(.plain)
#if os(iOS)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
#endif
#if os(iOS)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteItem(item, in: currentList)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
#endif
                        }
                        .onDelete { offsets in
                            deleteItems(at: offsets, in: currentList)
                        }
                    }
                    .listStyle(.inset)
#if os(iOS)
                    .scrollContentBackground(.hidden)
#endif

                    SplitNestCard {
                        HStack {
                            TextField("Add item…", text: $newItemText)
                                .textFieldStyle(.roundedBorder)

                            Button {
                                addItem(to: currentList)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                            }
                            .tint(SplitNestTheme.primary)
                            .disabled(newItemText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Lists")
        .toolbar {
            if currentList != nil {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        startRenameList()
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .accessibilityLabel("Rename list")

                    Button(role: .destructive) {
                        isShowingDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("Delete current list")
                }
            }
        }
        .confirmationDialog(
            "Delete this list?",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete List", role: .destructive) {
                deleteCurrentList()
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $isShowingNewListSheet) {
            NavigationStack {
                Form {
                    Section(header: Text("List Title")) {
                        TextField("e.g. Groceries", text: $newListTitle)
                    }
                }
                .navigationTitle("New List")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { cancelNewList() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Create") { createList() }
                            .disabled(newListTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingRenameSheet) {
            NavigationStack {
                Form {
                    Section(header: Text("List Title")) {
                        TextField("Title", text: $renameTitle)
                    }
                }
                .navigationTitle("Rename List")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { isShowingRenameSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { renameCurrentList() }
                            .disabled(renameTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .onAppear {
            // Initialize selectedListID on first appear if needed
            if selectedListID == nil {
                selectedListID = household.lists.first?.id
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        SplitNestCard {
            VStack(spacing: 10) {
                Text("No shared lists yet")
                    .font(SplitNestTheme.sectionFont())
                Text("Create a shared shopping list or house to-do list to get started.")
                    .font(SplitNestTheme.bodyFont())
                    .foregroundColor(SplitNestTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }

    // MARK: - Current List

    /// Convenience: current list based on selectedListID, falling back to first list.
    private var currentList: SharedList? {
        guard !household.lists.isEmpty else { return nil }

        if let id = selectedListID,
           let list = household.lists.first(where: { $0.id == id }) {
            return list
        }

        return household.lists.first
    }

    // MARK: - Items

    private func addItem(to list: SharedList) {
        let trimmed = newItemText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        household.addListItem(to: list, text: trimmed)
        newItemText = ""
    }

    private func deleteItems(at offsets: IndexSet, in list: SharedList) {
        guard let listIndex = household.lists.firstIndex(where: { $0.id == list.id }) else { return }
        household.lists[listIndex].items.remove(atOffsets: offsets)
    }

    private func deleteItem(_ item: ListItem, in list: SharedList) {
        guard let listIndex = household.lists.firstIndex(where: { $0.id == list.id }) else { return }
        household.lists[listIndex].items.removeAll { $0.id == item.id }
    }

    // MARK: - Lists (create / rename / delete)

    private func startCreateList() {
        newListTitle = ""
        isShowingNewListSheet = true
    }

    private func cancelNewList() {
        newListTitle = ""
        isShowingNewListSheet = false
    }

    private func createList() {
        let trimmed = newListTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let newList = SharedList(title: trimmed, items: [])
        household.lists.append(newList)
        selectedListID = newList.id

        cancelNewList()
    }

    private func startRenameList() {
        guard let current = currentList else { return }
        renameTitle = current.title
        isShowingRenameSheet = true
    }

    private func renameCurrentList() {
        let trimmed = renameTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let current = currentList,
              let index = household.lists.firstIndex(where: { $0.id == current.id }),
              !trimmed.isEmpty else {
            isShowingRenameSheet = false
            return
        }

        household.lists[index].title = trimmed
        isShowingRenameSheet = false
    }

    private func deleteCurrentList() {
        guard let current = currentList else { return }

        household.lists.removeAll { $0.id == current.id }

        if let first = household.lists.first {
            selectedListID = first.id
        } else {
            selectedListID = nil
        }
    }
}
