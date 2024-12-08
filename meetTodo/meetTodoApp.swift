//
//  meetTodoApp.swift
//  meetTodo
//
//  Created by pygmalion on 2024/12/8.
//

import SwiftUI
import SwiftData

@main
struct meetTodoApp: App {
    let container: ModelContainer
    
    init() {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            container = try ModelContainer(for: Item.self, configurations: config)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Label("列表", systemImage: "list.bullet")
                    }
                
                TodoView()
                    .tabItem {
                        Label("待办", systemImage: "checklist")
                    }
            }
            .modelContainer(container)
        }
    }
}
