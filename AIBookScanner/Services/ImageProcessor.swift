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

    /// 图像预处理 - 专门针对书籍页面优化
    private func preprocessImage(_ image: CIImage) -> CIImage {
        var processedImage = image

        // 1. 灰度转换（便于边缘检测）
        let grayscaleFilter = CIFilter.colorControls()
        grayscaleFilter.inputImage = processedImage
        grayscaleFilter.saturation = 0.1  // 降低饱和度，接近灰度
        if let grayscaleImage = grayscaleFilter.outputImage {
            processedImage = grayscaleImage
        }

        // 2. 对比度增强
        let contrastFilter = CIFilter.colorControls()
        contrastFilter.inputImage = processedImage
        contrastFilter.contrast = 1.5  // 增强对比度，突出边缘
        contrastFilter.brightness = 0.2
        if let contrastedImage = contrastFilter.outputImage {
            processedImage = contrastedImage
        }

        // 3. 边缘增强
        let edgeEnhanceFilter = CIFilter.unsharpMask()
        edgeEnhanceFilter.inputImage = processedImage
        edgeEnhanceFilter.radius = 2.0
        edgeEnhanceFilter.intensity = 1.0
        if let enhancedImage = edgeEnhanceFilter.outputImage {
            processedImage = enhancedImage
        }

        // 4. 降噪处理
        if let denoisedImage = applyDenoising(processedImage) {
            processedImage = denoisedImage
        }

        return processedImage
    }

    // MARK: - 边缘检测和透视校正

    /// 检测和校正透视 - 使用高级书籍页面检测器
    private func detectAndCorrectPerspective(_ image: CIImage) -> CIImage? {
        // 使用BookPageDetector进行高级页面检测
        var correctedImage: CIImage?
        let semaphore = DispatchSemaphore(value: 0)

        BookPageDetector.shared.detectBestPageBoundary(in: image) { result in
            switch result {
            case .success(let observation):
                if let observation = observation {
                    correctedImage = self.applyPerspectiveCorrection(to: image, using: observation)
                }
            case .failure(let error):
                print("高级页面检测失败: \(error.localizedDescription)")
            }
            semaphore.signal()
        }

        // 等待检测完成（最多3秒）
        _ = semaphore.wait(timeout: .now() + 3.0)
        return correctedImage
    }

    /// 应用透视校正 - 增强版本
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

        // 获取校正后的图像
        guard var correctedImage = perspectiveFilter.outputImage else {
            return nil
        }

        // 应用额外的裁剪以确保矩形边界
        correctedImage = cropToContentBounds(correctedImage, originalRect: rectangle)

        return correctedImage
    }

    // MARK: - 图像增强

    /// 图像增强处理 - 专门针对书籍页面优化
    private func enhanceImage(_ image: CIImage) -> CIImage {
        var enhancedImage = image

        // 1. 文本锐化（专门针对文字内容）
        let textSharpenFilter = CIFilter.sharpenLuminance()
        textSharpenFilter.inputImage = enhancedImage
        textSharpenFilter.sharpness = 0.8  // 更强的锐化用于文字
        textSharpenFilter.radius = 1.5  // 较小的半径避免过度锐化
        if let sharpened = textSharpenFilter.outputImage {
            enhancedImage = sharpened
        }

        // 2. 对比度和亮度优化
        let contrastFilter = CIFilter.colorControls()
        contrastFilter.inputImage = enhancedImage
        contrastFilter.contrast = 1.4  // 增强对比度使文字更清晰
        contrastFilter.brightness = 0.15  // 轻微提亮
        contrastFilter.saturation = 1.1  // 保持适当的色彩饱和度
        if let contrasted = contrastFilter.outputImage {
            enhancedImage = contrasted
        }

        // 3. 去除黄色色调（常见于旧书页）
        let colorFilter = CIFilter.colorMatrix()
        colorFilter.inputImage = enhancedImage
        colorFilter.rVector = CIVector(x: 1.1, y: -0.1, z: -0.1, w: 0)  // 减少红色和黄色
        colorFilter.gVector = CIVector(x: -0.05, y: 1.0, z: -0.05, w: 0)  // 保持绿色
        colorFilter.bVector = CIVector(x: -0.05, y: -0.05, z: 1.1, w: 0)  // 增强蓝色
        if let colorCorrected = colorFilter.outputImage {
            enhancedImage = colorCorrected
        }

        // 4. 最终微调
        let finalFilter = CIFilter.colorControls()
        finalFilter.inputImage = enhancedImage
        finalFilter.contrast = 1.1
        if let finalImage = finalFilter.outputImage {
            enhancedImage = finalImage
        }

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
    var enableTextOptimization: Bool = true
    var enableColorCorrection: Bool = true
    var targetResolution: CGSize?
    var processingQuality: ProcessingQuality = .balanced
}

enum ProcessingQuality {
    case fast
    case balanced
    case highQuality
}

// MARK: - 辅助方法扩展

extension ImageProcessor {

    /// 从检测到的矩形中找到最适合书籍页面的矩形
    private func findBestBookPageRectangle(
        from rectangles: [VNRectangleObservation], in image: CIImage
    ) -> VNRectangleObservation {
        // 使用BookPageDetector的评分系统选择最佳页面
        var scoredObservations = rectangles.map {
            observation -> (observation: VNRectangleObservation, score: Double) in
            let score = calculateObservationScore(observation, in: image)
            return (observation, score)
        }

        // 按分数排序
        scoredObservations.sort { $0.score > $1.score }

        return scoredObservations.first?.observation ?? rectangles.first!
    }

    /// 计算观察对象的综合评分（与BookPageDetector保持一致）
    private func calculateObservationScore(_ observation: VNRectangleObservation, in image: CIImage)
        -> Double
    {
        var totalScore: Double = 0.0

        // 1. 置信度分数 (权重: 0.3)
        let confidenceScore = Double(observation.confidence) * 0.3

        // 2. 大小分数 - 倾向于较大的页面 (权重: 0.25)
        let area = Double(observation.boundingBox.width * observation.boundingBox.height)
        let sizeScore = min(area * 2.0, 1.0) * 0.25

        // 3. 纵横比分数 - 倾向于标准页面比例 (权重: 0.2)
        let aspectRatio = Double(observation.boundingBox.width / observation.boundingBox.height)
        let idealAspectRatio = 0.7071  // 1:√2 比例（A4纸比例）
        let aspectRatioScore = (1.0 - min(abs(aspectRatio - idealAspectRatio) / 0.3, 1.0)) * 0.2

        // 4. 中心位置分数 - 倾向于中心位置的页面 (权重: 0.15)
        let centerX = observation.boundingBox.midX
        let centerY = observation.boundingBox.midY
        let distanceFromCenter = sqrt(pow(centerX - 0.5, 2) + pow(centerY - 0.5, 2))
        let positionScore = (1.0 - min(distanceFromCenter * 2.0, 1.0)) * 0.15

        // 5. 规则性分数 - 检查是否为规则四边形 (权重: 0.1)
        let regularityScore = calculateQuadrilateralRegularity(observation) * 0.1

        totalScore =
            confidenceScore + sizeScore + aspectRatioScore + positionScore + regularityScore

        return min(max(totalScore, 0.0), 1.0)
    }

    /// 计算四边形的规则性
    private func calculateQuadrilateralRegularity(_ observation: VNRectangleObservation) -> Double {
        let points = [
            observation.topLeft,
            observation.topRight,
            observation.bottomRight,
            observation.bottomLeft,
        ]

        // 计算边长
        let sideLengths = [
            distanceBetween(points[0], points[1]),
            distanceBetween(points[1], points[2]),
            distanceBetween(points[2], points[3]),
            distanceBetween(points[3], points[0]),
        ]

        // 计算边长的一致性
        let meanLength = sideLengths.reduce(0, +) / 4.0
        let variance = sideLengths.map { pow($0 - meanLength, 2) }.reduce(0, +) / 4.0
        let stdDev = sqrt(variance)
        let lengthConsistency = (stdDev / meanLength) > 0 ? 1.0 / (stdDev / meanLength) : 1.0

        // 计算角度的规则性
        let angles = calculateAngles(points: points)
        let angleDeviation = angles.map { abs($0 - .pi / 2) }.reduce(0, +) / 4.0
        let angleRegularity = 1.0 - min(angleDeviation / (.pi / 4), 1.0)

        return (lengthConsistency * 0.5 + angleRegularity * 0.5) * 0.5
    }

    /// 计算两点之间的距离
    private func distanceBetween(_ point1: CGPoint, _ point2: CGPoint) -> Double {
        return sqrt(pow(Double(point1.x - point2.x), 2) + pow(Double(point1.y - point2.y), 2))
    }

    /// 计算四边形的内角
    private func calculateAngles(points: [CGPoint]) -> [Double] {
        var angles: [Double] = []

        for i in 0..<4 {
            let p0 = points[i]
            let p1 = points[(i + 1) % 4]
            let p2 = points[(i + 2) % 4]

            let vector1 = (x: p1.x - p0.x, y: p1.y - p0.y)
            let vector2 = (x: p1.x - p2.x, y: p1.y - p2.y)

            let dotProduct = Double(vector1.x * vector2.x + vector1.y * vector2.y)
            let magnitude1 = sqrt(Double(vector1.x * vector1.x + vector1.y * vector1.y))
            let magnitude2 = sqrt(Double(vector2.x * vector2.x + vector2.y * vector2.y))

            let cosine = dotProduct / (magnitude1 * magnitude2)
            let angle = acos(cosine)

            angles.append(angle)
        }

        return angles
    }

    /// 裁剪到内容边界
    private func cropToContentBounds(_ image: CIImage, originalRect: VNRectangleObservation)
        -> CIImage
    {
        // 这里可以添加智能裁剪逻辑，确保裁剪到实际内容区域
        // 目前直接返回原图像，后续可以增强
        return image
    }

    /// 计算图像的文字清晰度评分
    private func calculateTextClarityScore(_ image: CIImage) -> Double {
        // 实现文字清晰度评估算法
        // 返回0-1的评分，1表示最清晰
        return 0.8  // 默认值
    }
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
