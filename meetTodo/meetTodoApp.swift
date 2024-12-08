//
//  meetTodoApp.swift
//  meetTodo
//
//  Created by pygmalion on 2024/12/8.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct meetTodoApp: App {
    let container: ModelContainer
    
    init() {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            container = try ModelContainer(for: Item.self, configurations: config)
            
            // 请求通知权限
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if granted {
                    print("通知权限已获取")
                }
            }
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
                
                SettingsView()
                    .tabItem {
                        Label("设置", systemImage: "gear")
                    }
            }
            .modelContainer(container)
        }
    }
}
