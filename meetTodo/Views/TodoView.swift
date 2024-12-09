import SwiftUI
import SwiftData

struct TodoView: View {
    @StateObject private var viewModel: TodoViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    init(modelContext: ModelContext) {
        self._viewModel = StateObject(wrappedValue: TodoViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            List {
                // 今日待办
                if !viewModel.todayItems.isEmpty {
                    Section("今日待办") {
                        ForEach(viewModel.todayItems) { item in
                            NavigationLink(destination: CompanyDetailView(item: item.item)) {
                                TodoItemRow(item: item)
                            }
                        }
                    }
                }
                
                // 未来安排
                if !viewModel.futureItems.isEmpty {
                    Section("未来安排") {
                        ForEach(viewModel.futureItems) { item in
                            NavigationLink(destination: CompanyDetailView(item: item.item)) {
                                TodoItemRow(item: item)
                            }
                        }
                    }
                }
                
                // 无待办提示
                if viewModel.todayItems.isEmpty && viewModel.futureItems.isEmpty {
                    Section {
                        Text("暂无待办事项")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .listRowBackground(Color.clear)
                    }
                }
            }
            .navigationTitle("待办事项")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.fetchItems()
            }
        }
    }
}

struct TodoItemRow: View {
    let item: TodoItem
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: item.date)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: item.date)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 时间和日期显示
            VStack(alignment: .center, spacing: 2) {
                Text(formattedTime)
                    .font(.title2.bold())
                    .foregroundColor(.blue)
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80)
            
            // 公司图标
            if let iconData = item.item.iconData,
               let uiImage = UIImage(data: iconData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: item.item.companyIcon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // 公司名称和阶段
                HStack {
                    Text(item.item.companyName)
                        .font(.headline)
                    Text(item.item.currentStage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 地点信息（如果有）
                if let location = item.location {
                    HStack {
                        Image(systemName: location.type == .online ? "link" : "mappin.and.ellipse")
                            .foregroundColor(.blue)
                        Text(location.address)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
} 