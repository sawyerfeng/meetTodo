//
//  ContentView.swift
//  meetTodo
//
//  Created by pygmalion on 2024/12/8.
//

import SwiftUI
import SwiftData

/// 主内容视图
/// 显示公司列表和统计信息
struct ContentView: View {
    // MARK: - 环境属性
    
    /// 环境中的模型上下文
    @Environment(\.modelContext) private var modelContext
    
    /// 数据查询
    @Query(
        filter: #Predicate<Item> { _ in true },
        sort: [.init(\Item.timestamp, order: .reverse)]
    ) private var items: [Item]
    
    // MARK: - 状态管理
    
    /// 视图模型
    @StateObject private var viewModel: ContentViewModel
    
    // MARK: - 初始化方法
    
    init() {
        _viewModel = StateObject(wrappedValue: ContentViewModel(modelContext: ModelContext(try! ModelContainer(for: Item.self))))
    }
    
    // MARK: - 视图构建
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 统计看板
                StatisticsBoard(
                    applicationCount: viewModel.getItems(for: .application).count,
                    writtenCount: viewModel.getWrittenCount(),
                    interviewCount: viewModel.getInterviewCount()
                )
                
                // 公司列表
                List {
                    ForEach(viewModel.getItems(for: .application)) { item in
                        companyRow(for: item)
                    }
                }
            }
            .navigationTitle("面试记录")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    addButton
                }
            }
            .sheet(isPresented: $viewModel.showingAddSheet) {
                AddCompanyView()
            }
            .onChange(of: items) { _, _ in
                viewModel.fetchItems()
            }
        }
    }
    
    // MARK: - 私有视图
    
    @ViewBuilder
    private func companyRow(for item: Item) -> some View {
        NavigationLink {
            CompanyDetailView(item: item)
        } label: {
            CompanyRow(item: item)
        }
        .swipeActions(edge: .leading) {
            Button {
                viewModel.togglePin(item)
            } label: {
                Label(item.isPinned ? "取消置顶" : "置顶",
                      systemImage: item.isPinned ? "pin.slash" : "pin")
            }
            .tint(.orange)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.deleteItem(item)
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }
    
    private var addButton: some View {
        Button {
            viewModel.showingAddSheet = true
        } label: {
            Image(systemName: "plus")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Item.self, configurations: config)
    
    let item1 = Item(companyName: "阿里巴巴",
                    companyIcon: "building.2.fill",
                    processType: .application,
                    currentStage: "投递",
                    status: .resume,
                    nextStageDate: Date().addingTimeInterval(86400),
                    isPinned: true)
    
    container.mainContext.insert(item1)
    
    return ContentView()
        .modelContainer(container)
}
