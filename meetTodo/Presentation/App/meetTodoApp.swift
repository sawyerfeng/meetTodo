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
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Item.self)
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // 预加载输入法配置并确保会话ID有效
        let _ = UITextInputMode.activeInputModes
        return true
    }
}
