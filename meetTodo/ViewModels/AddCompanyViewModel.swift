import SwiftUI
import SwiftData

class AddCompanyViewModel: ObservableObject {
    // MARK: - 属性
    
    /// 数据上下文
    private let modelContext: ModelContext
    
    /// 公司名称
    @Published var companyName: String = ""
    
    /// 公司图标
    @Published var companyIcon: String = "building.2"
    
    /// 是否显示图标选择器
    @Published var showingIconPicker = false
    
    /// 选中的流程类型
    @Published var selectedType: ProcessType = .application
    
    // MARK: - 初始化方法
    
    /// 初始化方法
    /// - Parameter modelContext: 数据上下文
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - 公共方法
    
    /// 添加公司
    /// - Returns: 是否添加成功
    func addCompany() -> Bool {
        guard !companyName.isEmpty else { return false }
        
        let item = Item(
            companyName: companyName,
            companyIcon: companyIcon,
            processType: selectedType,
            currentStage: "未开始"
        )
        
        modelContext.insert(item)
        return true
    }
    
    /// 更新图标
    /// - Parameter icon: 新图标
    func updateIcon(_ icon: String) {
        companyIcon = icon
    }
} 