//
//  ContentView.swift
//  meetTodo
//
//  Created by pygmalion on 2024/12/8.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [
//        SortDescriptor<Item>(\.isPinned, order: .reverse),
        SortDescriptor<Item>(\.timestamp, order: .reverse)
    ], animation: .default) private var items: [Item]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // 顶部看板
                HStack(spacing: 12) {
                    ProcessTypeCard(type: .application, 
                                  count: items.filter { $0.processType == .application }.count)
                    ProcessTypeCard(type: .interview,
                                  count: items.filter { $0.processType == .interview }.count)
                    ProcessTypeCard(type: .written,
                                  count: items.filter { $0.processType == .written }.count)
                }
                .padding(.horizontal)
                
                // 公司列表
                List {
                    ForEach(items) { item in
                        NavigationLink {
                            CompanyDetailView(item: item)
                        } label: {
                            CompanyRow(item: item)
                        }
                        .swipeActions(edge: .trailing) {
                            // 删除按钮
                            Button(role: .destructive) {
                                withAnimation {
                                    modelContext.delete(item)
                                }
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                            
                            // 置顶按钮
                            Button {
                                withAnimation {
                                    item.isPinned.toggle()
                                }
                            } label: {
                                Label("置顶", systemImage: item.isPinned ? "pin.slash.fill" : "pin.fill")
                            }
                            .tint(.orange)
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .navigationTitle("求职进度")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("添加公司", systemImage: "plus")
                    }
                }
            }
        }
        .task {
            // 预加载数据
            _ = items.count
        }
    }
    
    private func addItem() {
        withAnimation {
            let newItem = Item(companyName: "示例公司",
                             processType: .application,
                             currentStage: "简历投递")
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

// 进度类型卡片
struct ProcessTypeCard: View {
    let type: ProcessType
    let count: Int
    
    var backgroundColor: Color {
        switch type {
        case .application: return .blue
        case .interview: return .green
        case .written: return .orange
        }
    }
    
    var body: some View {
        VStack {
            Text(type.rawValue)
                .font(.subheadline)
            Text("\(count)")
                .font(.title.bold())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(backgroundColor.opacity(0.1))
        .foregroundColor(backgroundColor)
        .cornerRadius(12)
    }
}

// 公司行
struct CompanyRow: View {
    let item: Item
    
    var progressColor: Color {
        item.status.color
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 公司图标
            ZStack {
                Image(systemName: item.companyIcon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                
                if item.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .offset(x: 15, y: -15)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.companyName)
                    .font(.headline)
                Text(item.currentStage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let nextDate = item.nextStageDate {
                Text(nextDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(progressColor.opacity(0.15))
                        .frame(width: geometry.size.width * CGFloat(item.status.percentage) / 100)
                    Rectangle()
                        .fill(Color.gray.opacity(0.05))
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Item.self, configurations: config)
    
    let item1 = Item(companyName: "阿里巴巴",
                    companyIcon: "building.2.fill",
                    processType: .application,
                    currentStage: "简历投递",
                    status: .resume,
                    nextStageDate: Date().addingTimeInterval(86400),
                    isPinned: true)
    
    container.mainContext.insert(item1)
    
    return ContentView()
        .modelContainer(container)
}
