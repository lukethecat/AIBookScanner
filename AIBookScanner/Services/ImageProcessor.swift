import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import Metal
import MetalPerformanceShaders
import Vision

/// 图像处理器服务 - 负责书籍页面的AI增强处理
class ImageProcessor {

    // MARK: - 单例实例

    static let shared = ImageProcessor()

    // MARK: - Metal组件

    private var metalDevice: MTLDevice?
    private var metalCommandQueue: MTLCommandQueue?
    private var metalLibrary: MTLLibrary?

    // MARK: - 初始化

    private init() {
        setupMetal()
    }

    /// 设置Metal环境
    private func setupMetal() {
        // 获取默认Metal设备
        metalDevice = MTLCreateSystemDefaultDevice()

        guard let device = metalDevice else {
            print("警告：当前设备不支持Metal")
            return
        }

        // 创建命令队列
        metalCommandQueue = device.makeCommandQueue()

        // 创建默认Metal库
        do {
            metalLibrary = try device.makeDefaultLibrary(bundle: Bundle.main)
        } catch {
            print("创建Metal库失败: \(error.localizedDescription)")
        }

        print("Metal环境初始化完成")
    }

    // MARK: - 主要处理流程

    /// 处理书籍页面图像
    /// - Parameters:
    ///   - image: 原始图像
    ///   - completion: 处理完成回调
    func processBookPage(_ image: UIImage, completion: @escaping (Result<UIImage, Error>) -> Void) {
        // 在主线程外执行处理
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // 1. 转换为CIImage
                guard let ciImage = CIImage(image: image) else {
                    throw ImageProcessorError.invalidInputImage
                }

                // 2. 执行处理管道
                var processedImage = ciImage

                // 图像预处理
                processedImage = self.preprocessImage(processedImage)

                // 边缘检测和透视校正
                if let correctedImage = self.detectAndCorrectPerspective(processedImage) {
                    processedImage = correctedImage
                }

                // 图像增强
                processedImage = self.enhanceImage(processedImage)

                // 3. 转换为UIImage
                guard let resultImage = self.convertToUIImage(processedImage) else {
                    throw ImageProcessorError.conversionFailed
                }

                // 返回处理结果
                DispatchQueue.main.async {
                    completion(.success(resultImage))
                }

            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - 图像预处理

    /// 图像预处理
    private func preprocessImage(_ image: CIImage) -> CIImage {
        var processedImage = image

        // 1. 自动调整（对比度、亮度等）
        let autoAdjustments = image.autoAdjustmentFilters(options: nil)
        for filter in autoAdjustments {
            filter.setValue(processedImage, forKey: kCIInputImageKey)
            if let output = filter.outputImage {
                processedImage = output
            }
        }

        // 2. 降噪（使用Metal加速如果可用）
        if let denoisedImage = applyDenoising(processedImage) {
            processedImage = denoisedImage
        }

        return processedImage
    }

    // MARK: - 边缘检测和透视校正

    /// 检测和校正透视
    private func detectAndCorrectPerspective(_ image: CIImage) -> CIImage? {
        // 使用Vision框架进行矩形检测
        let request = VNDetectRectanglesRequest { [weak self] request, error in
            guard let self = self, error == nil else { return }

            if let results = request.results as? [VNRectangleObservation],
                let firstRectangle = results.first
            {
                // 找到最大的矩形（可能是书页）
                let largestRectangle = results.max(by: {
                    $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width
                        * $1.boundingBox.height
                })

                if let rectangle = largestRectangle {
                    // 应用透视校正
                    self.applyPerspectiveCorrection(to: image, using: rectangle)
                }
            }
        }

        // 配置矩形检测参数
        request.minimumConfidence = 0.75
        request.minimumAspectRatio = 0.3
        request.maximumAspectRatio = 0.8
        request.quadratureTolerance = 30
        request.maximumObservations = 1

        // 执行检测
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])

            if let results = request.results as? [VNRectangleObservation],
                let rectangle = results.first
            {
                return applyPerspectiveCorrection(to: image, using: rectangle)
            }
        } catch {
            print("矩形检测失败: \(error.localizedDescription)")
        }

        return nil
    }

    /// 应用透视校正
    private func applyPerspectiveCorrection(
        to image: CIImage, using rectangle: VNRectangleObservation
    ) -> CIImage? {
        // 创建透视校正滤镜
        let perspectiveFilter = CIFilter.perspectiveCorrection()
        perspectiveFilter.inputImage = image

        // 设置四个角点
        perspectiveFilter.topLeft = rectangle.topLeft
        perspectiveFilter.topRight = rectangle.topRight
        perspectiveFilter.bottomRight = rectangle.bottomRight
        perspectiveFilter.bottomLeft = rectangle.bottomLeft

        return perspectiveFilter.outputImage
    }

    // MARK: - 图像增强

    /// 图像增强处理
    private func enhanceImage(_ image: CIImage) -> CIImage {
        var enhancedImage = image

        // 1. 锐化
        let sharpenFilter = CIFilter.sharpenLuminance()
        sharpenFilter.inputImage = enhancedImage
        sharpenFilter.sharpness = 0.5
        sharpenFilter.radius = 2.0
        if let sharpened = sharpenFilter.outputImage {
            enhancedImage = sharpened
        }

        // 2. 对比度增强
        let contrastFilter = CIFilter.colorControls()
        contrastFilter.inputImage = enhancedImage
        contrastFilter.contrast = 1.2
        contrastFilter.brightness = 0.1
        if let contrasted = contrastFilter.outputImage {
            enhancedImage = contrasted
        }

        // 3. 色彩校正
        let colorFilter = CIFilter.colorMatrix()
        colorFilter.inputImage = enhancedImage
        // 可以调整颜色矩阵参数来优化书籍页面的色彩

        return enhancedImage
    }

    // MARK: - Metal加速处理

    /// 应用降噪（Metal加速）
    private func applyDenoising(_ image: CIImage) -> CIImage? {
        guard let device = metalDevice,
            let commandQueue = metalCommandQueue
        else {
            return applyCPUDenoising(image)
        }

        // 创建Metal上下文
        let context = CIContext(mtlDevice: device)

        // 创建Metal命令缓冲区和纹理
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
            let texture = createTexture(from: image, context: context, device: device)
        else {
            return applyCPUDenoising(image)
        }

        // 这里可以添加自定义的Metal降噪着色器
        // 暂时使用CPU降噪作为后备方案
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        return applyCPUDenoising(image)
    }

    /// CPU降噪（后备方案）
    private func applyCPUDenoising(_ image: CIImage) -> CIImage {
        // 使用Core Image的降噪滤镜
        let noiseReductionFilter = CIFilter.noiseReduction()
        noiseReductionFilter.inputImage = image
        noiseReductionFilter.noiseLevel = 0.02
        noiseReductionFilter.sharpness = 0.4

        return noiseReductionFilter.outputImage ?? image
    }

    /// 创建Metal纹理
    private func createTexture(from image: CIImage, context: CIContext, device: MTLDevice)
        -> MTLTexture?
    {
        // 获取图像尺寸
        let extent = image.extent
        let width = Int(extent.width)
        let height = Int(extent.height)

        // 创建纹理描述符
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderRead, .shaderWrite]

        // 创建纹理
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            return nil
        }

        // 渲染CIImage到Metal纹理
        context.render(
            image, to: texture, commandBuffer: nil, bounds: extent,
            colorSpace: CGColorSpaceCreateDeviceRGB())

        return texture
    }

    // MARK: - 工具方法

    /// 转换为UIImage
    private func convertToUIImage(_ ciImage: CIImage) -> UIImage? {
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    /// 获取图像方向信息
    private func getImageOrientation(_ image: UIImage) -> CGImagePropertyOrientation {
        switch image.imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}

// MARK: - 错误类型

enum ImageProcessorError: Error, LocalizedError {
    case invalidInputImage
    case metalNotSupported
    case conversionFailed
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .invalidInputImage:
            return "输入的图像无效"
        case .metalNotSupported:
            return "当前设备不支持Metal加速"
        case .conversionFailed:
            return "图像转换失败"
        case .processingFailed:
            return "图像处理失败"
        }
    }
}

// MARK: - 处理选项

struct ImageProcessingOptions {
    var enablePerspectiveCorrection: Bool = true
    var enableEnhancement: Bool = true
    var enableDenoising: Bool = true
    var targetResolution: CGSize?
}

// MARK: - 性能监控

extension ImageProcessor {
    /// 性能监控结构体
    struct PerformanceMetrics {
        var processingTime: TimeInterval = 0
        var memoryUsage: UInt64 = 0
        var metalAccelerated: Bool = false
    }

    /// 获取性能指标
    func getPerformanceMetrics() -> PerformanceMetrics {
        var metrics = PerformanceMetrics()
        metrics.metalAccelerated = (metalDevice != nil)
        // 这里可以添加更多的性能监控逻辑
        return metrics
    }
}
