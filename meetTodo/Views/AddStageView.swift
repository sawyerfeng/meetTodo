import SwiftUI

/// 添加阶段视图
/// 提供添加新阶段的用户界面
struct AddStageView: View {
    // MARK: - 环境属性
    
    /// 环境中的 dismiss 动作
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - 状态管理
    
    /// 视图模型
    @StateObject private var viewModel: AddStageViewModel
    
    // MARK: - 初始化方法
    
    /// 初始化方法
    /// - Parameters:
    ///   - availableStages: 可选的阶段列表
    ///   - onComplete: 添加完成的回调
    init(availableStages: [InterviewStage], onComplete: @escaping (InterviewStage, Date, StageLocation?) -> Void) {
        _viewModel = StateObject(wrappedValue: AddStageViewModel(availableStages: availableStages, onComplete: onComplete))
    }
    
    // MARK: - 视图构建
    
    var body: some View {
        NavigationStack {
            Form {
                // 阶段选择部分
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.getStages()) { stage in
                                Button {
                                    viewModel.updateStage(stage)
                                } label: {
                                    VStack(spacing: 6) {
                                        Circle()
                                            .fill(viewModel.selectedStage == stage ? stage.color : Color.gray.opacity(0.1))
                                            .frame(width: 44, height: 44)
                                            .overlay {
                                                Image(systemName: stage.icon)
                                                    .foregroundColor(viewModel.selectedStage == stage ? .white : .gray)
                                            }
                                        Text(stage.rawValue)
                                            .font(.caption)
                                            .foregroundColor(viewModel.selectedStage == stage ? stage.color : .gray)
                                    }
                                    .frame(width: 60)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("选择阶段")
                }
                
                // 时间选择部分
                Section {
                    DatePicker("时间", 
                              selection: $viewModel.selectedDate,
                              displayedComponents: [.date, .hourAndMinute])
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                }
                
                // 地点选择部分（仅面试和笔试阶段显示）
                if viewModel.needsLocation {
                    Section {
                        VStack(spacing: 12) {
                            Picker("方式", selection: Binding(
                                get: { viewModel.locationType },
                                set: { viewModel.updateLocationType($0) }
                            )) {
                                ForEach(LocationType.allCases, id: \.self) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            HStack {
                                Image(systemName: viewModel.locationType == .online ? "link" : "mappin.and.ellipse")
                                    .foregroundColor(.blue)
                                TextField(viewModel.locationPlaceholder, text: $viewModel.address)
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    } header: {
                        Text(viewModel.selectedStage == .written ? "笔试方式" : "面试方式")
                    }
                }
            }
            .navigationTitle("添加阶段")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 取消按钮
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                // 保存按钮
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        viewModel.save()
                        dismiss()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }
} 