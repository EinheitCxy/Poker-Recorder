//
//  Poker_RecoderApp.swift
//  Poker Recoder
//
//  Created by cxy on 2025/11/17.
//

import SwiftUI
import SwiftData

@main
struct Poker_RecoderApp: App {
    // 配置SwiftData容器，注册Session和Hand模型
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Session.self,
            Hand.self,
            Player.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // 如果加载失败，删除旧数据库并重新创建
            print("⚠️ ModelContainer 创建失败，尝试删除旧数据库...")
            let url = modelConfiguration.url
            try? FileManager.default.removeItem(at: url)
            return try! ModelContainer(for: schema, configurations: [modelConfiguration])
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
