//
//  meetTodoApp.swift
//  meetTodo
//
//  Created by pygmalion on 2024/12/8.
//

import SwiftUI
import SwiftData
import UserNotifications
import UIKit
import ObjectiveC

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // 预加载输入法配置并确保会话ID有效
        let _ = UITextInputMode.activeInputModes
        
        // 设置输入系统客户端
        if let clientClass = NSClassFromString("RTIInputSystemClient") {
            let selector = NSSelectorFromString("enableInputMethodPrewarming")
            let methodIMP = class_getClassMethod(clientClass, selector)
            if methodIMP != nil {
                typealias FunctionType = @convention(c) (AnyClass, Selector) -> Void
                let method = unsafeBitCast(method_getImplementation(methodIMP!), to: FunctionType.self)
                method(clientClass, selector)
            }
        }
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // 当应用变为活动状态时重新初始化输入法会话
        let _ = UITextInputMode.activeInputModes
    }
}

@main
struct meetTodoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    let container: ModelContainer
    
    init() {
        // 禁用Metal调试工具，避免警告
        UserDefaults.standard.set(false, forKey: "MTL_DEBUG_LAYER")
        
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
