//
//  ContentView.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink {
                    AllowRemoteFileAccessView()
                } label: {
                    Label("Grant Remote File Access", systemImage: "shield.checkered")
                }
                
                NavigationLink {
                    ScreenSharingView()
                } label: {
                    Label("Screen Sharing", systemImage: "rectangle.on.rectangle")
                }
                
                NavigationLink {
                    RemoteManagementView()
                } label: {
                    Label("Remote Management", systemImage: "desktopcomputer")
                }
                
                NavigationLink {
                    SSHView()
                } label: {
                    Label("SSH Access", systemImage: "terminal.fill")
                }
                
                NavigationLink {
                    TSSView()
                } label: {
                    Label("TSS", systemImage: "checkmark.seal.fill")
                }
                
                NavigationLink {
                    LocationView()
                } label: {
                    Label("Location", systemImage: "location.fill")
                }
                
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar {
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
