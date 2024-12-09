import SwiftUI
import SwiftData

/// 添加公司的视图
/// 提供添加新公司的用户界面
struct AddCompanyView: View {
    // MARK: - 环境属性
    
    /// 环境中的模型上下文
    @Environment(\.modelContext) private var modelContext
    
    /// 环境中的 dismiss 动作
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - 状态管理
    
    /// 视图模型
    @StateObject private var viewModel: AddCompanyViewModel
    
    // MARK: - 初始化方法
    
    init() {
        _viewModel = StateObject(wrappedValue: AddCompanyViewModel(modelContext: ModelContext(try! ModelContainer(for: Item.self))))
    }
    
    // MARK: - 视图构建
    
    var body: some View {
        NavigationStack {
            Form {
                // 公司信息部分
                Section {
                    // 公司图标选择器
                    HStack {
                        Text("公司图标")
                        Spacer()
                        Button {
                            viewModel.showingIconPicker = true
                        } label: {
                            Image(systemName: viewModel.companyIcon)
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // 公司名称输入框
                    TextField("公司名称", text: $viewModel.companyName)
                        .textFieldStyle(.roundedBorder)
                }
                
                // 流程类型选择
                Section {
                    Picker("流程类型", selection: $viewModel.selectedType) {
                        Text("投递简历").tag(ProcessType.application)
                        Text("笔试").tag(ProcessType.written)
                        Text("面试").tag(ProcessType.interview)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("添加公司")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 取消按钮
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                // 添加按钮
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        if viewModel.addCompany() {
                            dismiss()
                        }
                    }
                    .disabled(viewModel.companyName.isEmpty)
                }
            }
            .sheet(isPresented: $viewModel.showingIconPicker) {
                IconPickerView(selectedIcon: viewModel.companyIcon) { icon in
                    viewModel.updateIcon(icon)
                }
            }
        }
    }
} 