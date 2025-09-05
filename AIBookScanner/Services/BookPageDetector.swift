import AVFoundation
import CoreImage
import Vision

/// 书籍页面检测器服务 - 使用先进的计算机视觉算法检测和优化书籍页面
class BookPageDetector {

    // MARK: - 单例实例
    static let shared = BookPageDetector()

    // MARK: - 配置参数
    struct DetectionConfig {
        var minConfidence: Float = 0.8
        var minAspectRatio: Float = 0.5
        var maxAspectRatio: Float = 0.85
        var maxObservations: Int = 5
        var quadratureTolerance: Float = 15.0
    }

    // MARK: - 初始化
    private init() {}

    // MARK: - 主要检测方法

    /// 检测书籍页面边界
    /// - Parameters:
    ///   - image: 输入图像
    ///   - config: 检测配置
    ///   - completion: 完成回调，返回检测到的页面边界
    func detectPageBoundaries(
        in image: CIImage,
        config: DetectionConfig = DetectionConfig(),
        completion: @escaping (Result<[VNRectangleObservation], Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let observations = try self.performPageDetection(image: image, config: config)
                DispatchQueue.main.async {
                    completion(.success(observations))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    /// 检测并选择最佳页面边界
    /// - Parameters:
    ///   - image: 输入图像
    ///   - config: 检测配置
    ///   - completion: 完成回调，返回最佳页面边界
    func detectBestPageBoundary(
        in image: CIImage,
        config: DetectionConfig = DetectionConfig(),
        completion: @escaping (Result<VNRectangleObservation?, Error>) -> Void
    ) {
        detectPageBoundaries(in: image, config: config) { result in
            switch result {
            case .success(let observations):
                let bestObservation = self.selectBestPageObservation(from: observations, in: image)
                completion(.success(bestObservation))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - 核心检测逻辑

    /// 执行页面检测
    private func performPageDetection(image: CIImage, config: DetectionConfig) throws
        -> [VNRectangleObservation]
    {
        let request = VNDetectRectanglesRequest { request, error in
            if let error = error {
                print("页面检测错误: \(error.localizedDescription)")
            }
        }

        // 配置检测参数
        request.minimumConfidence = config.minConfidence
        request.minimumAspectRatio = config.minAspectRatio
        request.maximumAspectRatio = config.maxAspectRatio
        request.maximumObservations = config.maxObservations
        request.quadratureTolerance = config.quadratureTolerance

        // 执行检测
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        try handler.perform([request])

        guard let results = request.results as? [VNRectangleObservation] else {
            return []
        }

        return results
    }

    /// 从检测结果中选择最佳页面观察
    private func selectBestPageObservation(
        from observations: [VNRectangleObservation],
        in image: CIImage
    ) -> VNRectangleObservation? {
        guard !observations.isEmpty else { return nil }

        // 评分系统：综合考虑多个因素选择最佳页面
        var scoredObservations = observations.map {
            observation -> (observation: VNRectangleObservation, score: Double) in
            let score = calculateObservationScore(observation, in: image)
            return (observation, score)
        }

        // 按分数排序
        scoredObservations.sort { $0.score > $1.score }

        // 返回分数最高的观察
        return scoredObservations.first?.observation
    }

    /// 计算观察对象的综合评分
    private func calculateObservationScore(_ observation: VNRectangleObservation, in image: CIImage)
        -> Double
    {
        var totalScore: Double = 0.0

        // 1. 置信度分数 (权重: 0.3)
        let confidenceScore = Double(observation.confidence) * 0.3

        // 2. 大小分数 - 倾向于较大的页面 (权重: 0.25)
        let area = Double(observation.boundingBox.width * observation.boundingBox.height)
        let sizeScore = min(area * 2.0, 1.0) * 0.25  // 标准化到0-1范围

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

    /// 计算四边形的规则性（角度和边长的一致性）
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

        // 计算边长的一致性（变异系数的倒数）
        let meanLength = sideLengths.reduce(0, +) / 4.0
        let variance = sideLengths.map { pow($0 - meanLength, 2) }.reduce(0, +) / 4.0
        let stdDev = sqrt(variance)
        let lengthConsistency = (stdDev / meanLength) > 0 ? 1.0 / (stdDev / meanLength) : 1.0

        // 计算角度的规则性（检查是否接近90度）
        let angles = calculateAngles(points: points)
        let angleDeviation = angles.map { abs($0 - .pi / 2) }.reduce(0, +) / 4.0
        let angleRegularity = 1.0 - min(angleDeviation / (.pi / 4), 1.0)

        // 综合规则性评分
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

    // MARK: - 高级检测功能

    /// 多尺度检测 - 在不同尺度下检测页面
    func detectPageBoundariesMultiScale(
        in image: CIImage,
        scales: [Float] = [1.0, 0.75, 0.5],
        completion: @escaping (Result<[VNRectangleObservation], Error>) -> Void
    ) {
        var allObservations: [VNRectangleObservation] = []
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "com.aibookscanner.multiscale", attributes: .concurrent)

        for scale in scales {
            group.enter()
            queue.async {
                do {
                    let scaledImage = self.scaleImage(image, by: scale)
                    let observations = try self.performPageDetection(
                        image: scaledImage,
                        config: DetectionConfig()
                    )

                    // 将坐标转换回原始尺度
                    let scaledObservations = observations.map { observation in
                        self.scaleObservation(observation, from: scale, to: 1.0)
                    }

                    queue.async(flags: .barrier) {
                        allObservations.append(contentsOf: scaledObservations)
                        group.leave()
                    }
                } catch {
                    queue.async(flags: .barrier) {
                        group.leave()
                    }
                }
            }
        }

        group.notify(queue: .main) {
            // 去除重复的观察结果
            let uniqueObservations = self.removeDuplicateObservations(allObservations)
            completion(.success(uniqueObservations))
        }
    }

    /// 缩放图像
    private func scaleImage(_ image: CIImage, by scale: Float) -> CIImage {
        let filter = CIFilter.lanczosScaleTransform()
        filter.inputImage = image
        filter.scale = scale
        filter.aspectRatio = 1.0
        return filter.outputImage ?? image
    }

    /// 缩放观察结果坐标
    private func scaleObservation(
        _ observation: VNRectangleObservation, from fromScale: Float, to toScale: Float
    ) -> VNRectangleObservation {
        let scaleFactor = Double(toScale / fromScale)

        return VNRectangleObservation(
            topLeft: CGPoint(
                x: observation.topLeft.x * scaleFactor,
                y: observation.topLeft.y * scaleFactor
            ),
            topRight: CGPoint(
                x: observation.topRight.x * scaleFactor,
                y: observation.topRight.y * scaleFactor
            ),
            bottomRight: CGPoint(
                x: observation.bottomRight.x * scaleFactor,
                y: observation.bottomRight.y * scaleFactor
            ),
            bottomLeft: CGPoint(
                x: observation.bottomLeft.x * scaleFactor,
                y: observation.bottomLeft.y * scaleFactor
            )
        )
    }

    /// 去除重复的观察结果
    private func removeDuplicateObservations(_ observations: [VNRectangleObservation])
        -> [VNRectangleObservation]
    {
        var uniqueObservations: [VNRectangleObservation] = []
        let similarityThreshold: Double = 0.8

        for observation in observations {
            var isDuplicate = false

            for uniqueObservation in uniqueObservations {
                if calculateIOU(observation, uniqueObservation) > similarityThreshold {
                    isDuplicate = true
                    break
                }
            }

            if !isDuplicate {
                uniqueObservations.append(observation)
            }
        }

        return uniqueObservations
    }

    /// 计算两个矩形的交并比（IoU）
    private func calculateIOU(_ rect1: VNRectangleObservation, _ rect2: VNRectangleObservation)
        -> Double
    {
        // 简化的IoU计算（基于边界框）
        let intersection = calculateIntersectionArea(rect1.boundingBox, rect2.boundingBox)
        let union = calculateUnionArea(rect1.boundingBox, rect2.boundingBox)

        return union > 0 ? intersection / union : 0.0
    }

    /// 计算两个矩形的交集面积
    private func calculateIntersectionArea(_ rect1: CGRect, _ rect2: CGRect) -> Double {
        let intersectionRect = rect1.intersection(rect2)
        return Double(intersectionRect.width * intersectionRect.height)
    }

    /// 计算两个矩形的并集面积
    private func calculateUnionArea(_ rect1: CGRect, _ rect2: CGRect) -> Double {
        let area1 = Double(rect1.width * rect1.height)
        let area2 = Double(rect2.width * rect2.height)
        let intersection = calculateIntersectionArea(rect1, rect2)
        return area1 + area2 - intersection
    }
}

// MARK: - 错误类型

enum BookPageDetectionError: Error, LocalizedError {
    case detectionFailed
    case invalidInput
    case noPagesDetected

    var errorDescription: String? {
        switch self {
        case .detectionFailed:
            return "页面检测失败"
        case .invalidInput:
            return "输入图像无效"
        case .noPagesDetected:
            return "未检测到书籍页面"
        }
    }
}

// MARK: - 检测结果扩展

extension VNRectangleObservation {
    /// 获取边界框的中心点
    var center: CGPoint {
        return CGPoint(x: boundingBox.midX, y: boundingBox.midY)
    }

    /// 获取边界框的面积
    var area: Double {
        return Double(boundingBox.width * boundingBox.height)
    }

    /// 获取纵横比
    var aspectRatio: Double {
        return Double(boundingBox.width / boundingBox.height)
    }
}
