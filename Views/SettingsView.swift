import SwiftUI

struct SettingsView: View {
    @AppStorage("theme") private var theme = "system"
    @AppStorage("fontSize") private var fontSize: Double = 18
    @AppStorage("autoBackup") private var autoBackup = false
    @State private var showingBackupAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section(header: Text("显示")) {
                Picker("主题", selection: $theme) {
                    Text("跟随系统").tag("system")
                    Text("浅色").tag("light")
                    Text("深色").tag("dark")
                }
                
                VStack(alignment: .leading) {
                    Text("默认字体大小")
                    Slider(value: $fontSize, in: 12...24, step: 1) {
                        Text("\(Int(fontSize))")
                    }
                }
            }
            
            Section(header: Text("备份")) {
                Toggle("自动备份", isOn: $autoBackup)
                
                Button("立即备份") {
                    backup()
                }
                
                Button("恢复备份") {
                    restore()
                }
            }
            
            Section(header: Text("缓存")) {
                Button("清除缓存") {
                    clearCache()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("设置")
        .alert("提示", isPresented: $showingBackupAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func backup() {
        Task {
            do {
                try await BackupManager.shared.backup()
                alertMessage = "备份成功"
            } catch {
                alertMessage = "备份失败：\(error.localizedDescription)"
            }
            showingBackupAlert = true
        }
    }
    
    private func restore() {
        Task {
            do {
                try await BackupManager.shared.restore()
                alertMessage = "恢复成功"
            } catch {
                alertMessage = "恢复失败：\(error.localizedDescription)"
            }
            showingBackupAlert = true
        }
    }
    
    private func clearCache() {
        CacheManager.shared.clearCache()
        alertMessage = "缓存已清除"
        showingBackupAlert = true
    }
} 