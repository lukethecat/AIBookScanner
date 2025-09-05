import SwiftUI

@main
struct AIBookScannerApp: App {
    // 应用状态管理器
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    // 应用启动时初始化必要的服务
                    initializeAppServices()
                }
        }
    }

    /// 初始化应用服务
    private func initializeAppServices() {
        // 初始化Metal设备（如果可用）
        if MTLCreateSystemDefaultDevice() != nil {
            print("Metal设备初始化成功")
        } else {
            print("警告：当前设备不支持Metal")
        }

        // 检查相机权限状态
        checkCameraPermission()

        // 初始化Core Data上下文
        CoreDataManager.shared.initialize()
    }

    /// 检查相机权限
    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            print("相机权限已授权")
        case .notDetermined:
            print("相机权限未确定，需要请求")
        case .denied, .restricted:
            print("相机权限被拒绝或受限")
        @unknown default:
            print("未知的权限状态")
        }
    }
}

/// 应用状态管理类
class AppState: ObservableObject {
    // 网络连接状态监控（用于隐私保护）
    @Published var isNetworkConnected: Bool = false
    @Published var isProcessing: Bool = false
    @Published var hasCameraPermission: Bool = false

    // 隐私保护监控器
    private var networkMonitor: NetworkMonitor?

    init() {
        setupNetworkMonitoring()
    }

    /// 设置网络连接监控
    private func setupNetworkMonitoring() {
        networkMonitor = NetworkMonitor()
        networkMonitor?.onStatusChange = { [weak self] isConnected in
            DispatchQueue.main.async {
                self?.isNetworkConnected = isConnected
                if isConnected {
                    print("警告：检测到网络连接，确保所有处理在本地进行")
                }
            }
        }
        networkMonitor?.startMonitoring()
    }
}

/// 网络连接监控器（隐私保护）
class NetworkMonitor {
    private let monitor = NWPathMonitor()
    var onStatusChange: ((Bool) -> Void)?

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            let isConnected = path.status == .satisfied
            self?.onStatusChange?(isConnected)
        }
        monitor.start(queue: DispatchQueue.global(qos: .background))
    }

    func stopMonitoring() {
        monitor.cancel()
    }
}
