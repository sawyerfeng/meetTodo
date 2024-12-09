import SwiftUI

struct CompanyRow: View {
    @State private var viewModel: CompanyRowViewModel
    
    init(item: Item) {
        self._viewModel = State(wrappedValue: CompanyRowViewModel(item: item))
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // 公司图标
            viewModel.icon
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // 公司信息
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.companyName)
                    .font(.headline)
                
                HStack {
                    Text(viewModel.currentStage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let dateString = viewModel.formattedDate {
                        Text(dateString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 进度条
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)
                            .cornerRadius(2)
                        
                        Rectangle()
                            .fill(viewModel.statusColor)
                            .frame(width: geometry.size.width * viewModel.progressPercentage, height: 4)
                            .cornerRadius(2)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(.vertical, 8)
    }
} 