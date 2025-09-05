import AVFoundation
import SwiftUI

/// 主界面视图，包含应用的主要导航结构
struct ContentView: View {
    // 环境对象
    @EnvironmentObject private var appState: AppState

    // 状态管理
    @State private var selectedTab = 0
    @State private var showCameraPermissionAlert = false
    @State private var showProcessingSheet = false

    var body: some View {
        TabView(selection: $selectedTab) {
            // 扫描标签页
            ScanView()
                .tabItem {
                    Label("扫描", systemImage: "camera.viewfinder")
                }
                .tag(0)

            // 图库标签页
            LibraryView()
                .tabItem {
                    Label("图库", systemImage: "photo.on.rectangle")
                }
                .tag(1)

            // 设置标签页
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
                .tag(2)
        }
        .accentColor(.blue)  // 主色调
        .onAppear {
            checkCameraPermission()
        }
        .alert("相机权限被拒绝", isPresented: $showCameraPermissionAlert) {
            Button("设置", role: .none) {
                openAppSettings()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("AIBookScanner需要相机权限来扫描书籍。请在设置中启用相机权限。")
        }
        .sheet(isPresented: $showProcessingSheet) {
            ProcessingView()
        }
    }

    /// 检查相机权限状态
    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            appState.hasCameraPermission = true
        case .notDetermined:
            requestCameraPermission()
        case .denied, .restricted:
            showCameraPermissionAlert = true
        @unknown default:
            break
        }
    }

    /// 请求相机权限
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                appState.hasCameraPermission = granted
                if !granted {
                    showCameraPermissionAlert = true
                }
            }
        }
    }

    /// 打开应用设置
    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

/// 扫描视图
struct ScanView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isShowingCamera = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 相机图标
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .padding(.top, 50)

                // 标题
                Text("AI书籍扫描仪")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // 描述
                Text("使用AI技术将手机拍摄的书籍页面转换为清晰的数字文档")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                Spacer()

                // 开始扫描按钮
                Button(action: {
                    if appState.hasCameraPermission {
                        isShowingCamera = true
                    }
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("开始扫描")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(appState.hasCameraPermission ? Color.blue : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(!appState.hasCameraPermission)
                .padding(.horizontal)

                // 隐私保护提示
                VStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.green)
                    Text("所有处理均在设备本地完成\n确保您的隐私安全")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationBarTitle("扫描", displayMode: .inline)
            .sheet(isPresented: $isShowingCamera) {
                CameraView()
            }
        }
    }
}

/// 图库视图
struct LibraryView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("扫描历史")
                    .font(.title2)
                    .padding()

                // 占位内容
                VStack(spacing: 20) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("暂无扫描记录")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("开始扫描书籍页面来创建您的数字图书馆")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                }
                .padding(.top, 100)

                Spacer()
            }
            .navigationBarTitle("图库", displayMode: .inline)
        }
    }
}

/// 设置视图
struct SettingsView: View {
    @AppStorage("enableAutoEnhancement") private var enableAutoEnhancement = true
    @AppStorage("enableEdgeDetection") private var enableEdgeDetection = true
    @AppStorage("saveToPhotos") private var saveToPhotos = false

    var body: some View {
        NavigationView {
            Form {
                // 处理设置
                Section(header: Text("处理设置")) {
                    Toggle("自动图像增强", isOn: $enableAutoEnhancement)
                    Toggle("边缘检测", isOn: $enableEdgeDetection)
                    Toggle("保存到相册", isOn: $saveToPhotos)
                }

                // 关于
                Section(header: Text("关于")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("隐私保护")
                        Spacer()
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green)
                    }

                    Link("用户协议", destination: URL(string: "https://example.com/terms")!)
                    Link("隐私政策", destination: URL(string: "https://example.com/privacy")!)
                }

                // 技术支持
                Section(header: Text("技术支持")) {
                    Button("发送反馈") {
                        // 反馈功能
                    }

                    Button("评分应用") {
                        // 评分功能
                    }
                }
            }
            .navigationBarTitle("设置", displayMode: .inline)
        }
    }
}

/// 处理中视图
struct ProcessingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(2.0)
                .padding()

            Text("正在处理中...")
                .font(.headline)

            Text("AI正在优化您的书籍页面")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// 预览
#Preview {
    ContentView()
        .environmentObject(AppState())
}
