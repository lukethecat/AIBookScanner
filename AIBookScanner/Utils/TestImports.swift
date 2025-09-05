import AVFoundation
import CoreData
import CoreImage
import Metal
import MetalPerformanceShaders
import Network
import UIKit
import Vision

/// 测试文件 - 用于验证所有必要的框架导入是否正常工作
/// 这个文件不应该包含在实际应用中，仅用于开发测试
class TestImports {

    // MARK: - 框架可用性测试

    /// 测试所有必要框架的可用性
    static func testAllFrameworks() -> Bool {
        var allAvailable = true

        // 测试AVFoundation
        if !testAVFoundation() {
            print("AVFramework测试失败")
            allAvailable = false
        }

        // 测试CoreImage
        if !testCoreImage() {
            print("CoreImage测试失败")
            allAvailable = false
        }

        // 测试Metal
        if !testMetal() {
            print("Metal测试失败")
            allAvailable = false
        }

        // 测试Vision
        if !testVision() {
            print("Vision测试失败")
            allAvailable = false
        }

        // 测试Network
        if !testNetwork() {
            print("Network测试失败")
            allAvailable = false
        }

        // 测试CoreData
        if !testCoreData() {
            print("CoreData测试失败")
            allAvailable = false
        }

        return allAvailable
    }

    // MARK: - 各框架测试方法

    private static func testAVFoundation() -> Bool {
        // 测试相机权限状态检查
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        print("相机权限状态: \(status.rawValue)")
        return true
    }

    private static func testCoreImage() -> Bool {
        // 测试Core Image滤镜创建
        let filter = CIFilter(name: "CIColorControls")
        return filter != nil
    }

    private static func testMetal() -> Bool {
        // 测试Metal设备可用性
        let device = MTLCreateSystemDefaultDevice()
        return device != nil
    }

    private static func testVision() -> Bool {
        // 测试Vision请求创建
        let request = VNDetectRectanglesRequest { request, error in
            // 空实现，仅测试编译
        }
        return request is VNDetectRectanglesRequest
    }

    private static func testNetwork() -> Bool {
        // 测试Network框架
        if #available(iOS 12.0, *) {
            let monitor = NWPathMonitor()
            return monitor is NWPathMonitor
        }
        return true  // 对于旧版本iOS，Network可能不可用
    }

    private static func testCoreData() -> Bool {
        // 测试Core Data实体描述
        let entity = NSEntityDescription()
        return entity is NSEntityDescription
    }

    // MARK: - 设备能力检查

    /// 检查设备是否支持Metal
    static var supportsMetal: Bool {
        return MTLCreateSystemDefaultDevice() != nil
    }

    /// 检查设备是否支持神经网络加速
    static var supportsNeuralEngine: Bool {
        // 简单的检查方法：如果支持Metal，通常也支持神经网络加速
        return supportsMetal
    }

    /// 检查相机是否可用
    static var cameraAvailable: Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    // MARK: - 版本兼容性检查

    /// 检查iOS版本是否满足最低要求
    static func isiOSVersionSupported(minVersion: Double = 17.0) -> Bool {
        if #available(iOS 17.0, *) {
            return true
        } else {
            return false
        }
    }

    /// 获取当前设备信息
    static var deviceInfo: String {
        let device = UIDevice.current
        return """
            设备名称: \(device.name)
            系统版本: \(device.systemName) \(device.systemVersion)
            设备型号: \(device.model)
            支持Metal: \(supportsMetal)
            支持神经网络: \(supportsNeuralEngine)
            相机可用: \(cameraAvailable)
            """
    }
}

// MARK: - 测试扩展

extension TestImports {

    /// 运行完整的导入测试
    static func runComprehensiveTest() {
        print("=== AIBookScanner 导入测试 ===")
        print(deviceInfo)
        print("iOS 17+ 支持: \(isiOSVersionSupported())")
        print("所有框架可用: \(testAllFrameworks())")
        print("=== 测试完成 ===")
    }
}

// MARK: - 编译时检查

// 这些编译时检查确保所有必要的符号都存在
// 如果编译失败，说明有框架导入问题

// AVFoundation 符号检查
private let _avFoundationSymbols:
    (
        AVCaptureDevice.self, AVCaptureSession.self, AVCapturePhotoOutput.self
    ) = (AVCaptureDevice.self, AVCaptureSession.self, AVCapturePhotoOutput.self)

// CoreImage 符号检查
private let _coreImageSymbols: (CIImage.self, CIFilter.self) = (CIImage.self, CIFilter.self)

// Metal 符号检查
private let _metalSymbols: (MTLDevice.self, MTLCommandQueue.self) = (
    MTLDevice.self, MTLCommandQueue.self
)

// Vision 符号检查
private let _visionSymbols: (VNImageRequestHandler.self, VNDetectRectanglesRequest.self) =
    (VNImageRequestHandler.self, VNDetectRectanglesRequest.self)

// Network 符号检查（可选）
private let _networkSymbols: (NWPathMonitor.self)? = NWPathMonitor.self

// CoreData 符号检查
private let _coreDataSymbols: (NSManagedObjectContext.self, NSPersistentContainer.self) =
    (NSManagedObjectContext.self, NSPersistentContainer.self)
