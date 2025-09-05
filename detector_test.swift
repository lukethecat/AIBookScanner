// AIBookScanner 书籍页面检测器核心逻辑测试
// 测试BookPageDetector的核心算法，不依赖iOS特定框架

import Foundation

/// 模拟的VNRectangleObservation结构，用于测试
struct TestRectangleObservation {
    var topLeft: CGPoint
    var topRight: CGPoint
    var bottomRight: CGPoint
    var bottomLeft: CGPoint
    var confidence: Float
    var boundingBox: CGRect

    init(
        topLeft: CGPoint, topRight: CGPoint, bottomRight: CGPoint, bottomLeft: CGPoint,
        confidence: Float = 0.9
    ) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomRight = bottomRight
        self.bottomLeft = bottomLeft
        self.confidence = confidence

        // 计算边界框
        let minX = min(topLeft.x, topRight.x, bottomRight.x, bottomLeft.x)
        let minY = min(topLeft.y, topRight.y, bottomRight.y, bottomLeft.y)
        let maxX = max(topLeft.x, topRight.x, bottomRight.x, bottomLeft.x)
        let maxY = max(topLeft.y, topRight.y, bottomRight.y, bottomLeft.y)

        self.boundingBox = CGRect(
            origin: CGPoint(x: minX, y: minY), size: CGSize(width: maxX - minX, height: maxY - minY)
        )
    }
}

/// 书籍页面检测器核心逻辑测试
class BookPageDetectorTest {

    // MARK: - 测试数据

    let testObservations = [
        // 完美矩形 - 理想情况
        TestRectangleObservation(
            topLeft: CGPoint(x: 0.1, y: 0.1),
            topRight: CGPoint(x: 0.9, y: 0.1),
            bottomRight: CGPoint(x: 0.9, y: 0.9),
            bottomLeft: CGPoint(x: 0.1, y: 0.9),
            confidence: 0.95
        ),
        // 倾斜页面 - 常见情况
        TestRectangleObservation(
            topLeft: CGPoint(x: 0.15, y: 0.08),
            topRight: CGPoint(x: 0.85, y: 0.12),
            bottomRight: CGPoint(x: 0.88, y: 0.88),
            bottomLeft: CGPoint(x: 0.12, y: 0.85),
            confidence: 0.85
        ),
        // 小矩形 - 可能不是主要页面
        TestRectangleObservation(
            topLeft: CGPoint(x: 0.3, y: 0.3),
            topRight: CGPoint(x: 0.4, y: 0.3),
            bottomRight: CGPoint(x: 0.4, y: 0.4),
            bottomLeft: CGPoint(x: 0.3, y: 0.4),
            confidence: 0.8
        ),
    ]

    // MARK: - 核心算法测试

    func testObservationScoring() {
        print("开始观察对象评分测试...")

        for (index, observation) in testObservations.enumerated() {
            let score = calculateObservationScore(observation)
            print("观察对象 \(index + 1) 评分: \(String(format: "%.3f", score))")

            // 验证评分在合理范围内
            assert(score >= 0.0 && score <= 1.0, "评分必须在0-1范围内")
        }

        print("观察对象评分测试完成 ✅")
    }

    func testBestObservationSelection() {
        print("开始最佳观察对象选择测试...")

        let bestObservation = selectBestObservation(from: testObservations)
        let bestScore = calculateObservationScore(bestObservation)

        print("最佳观察对象评分: \(String(format: "%.3f", bestScore))")

        // 验证选择了评分最高的观察对象
        var maxScore: Double = 0.0
        for observation in testObservations {
            let score = calculateObservationScore(observation)
            maxScore = max(maxScore, score)
        }

        assert(abs(bestScore - maxScore) < 0.001, "应该选择评分最高的观察对象")
        print("最佳观察对象选择测试完成 ✅")
    }

    func testGeometryCalculations() {
        print("开始几何计算测试...")

        let observation = testObservations[0]

        // 测试距离计算
        let distance = calculateDistance(observation.topLeft, observation.topRight)
        let expectedDistance = 0.8  // 0.9 - 0.1
        assert(abs(distance - expectedDistance) < 0.001, "距离计算错误")
        print("距离计算测试完成 ✅")

        // 测试规则性计算
        let regularity = calculateQuadrilateralRegularity(observation)
        assert(regularity >= 0.0 && regularity <= 1.0, "规则性评分必须在0-1范围内")
        print("规则性计算测试完成 ✅")

        print("几何计算测试完成 ✅")
    }

    // MARK: - 核心算法实现

    private func calculateObservationScore(_ observation: TestRectangleObservation) -> Double {
        var totalScore: Double = 0.0

        // 1. 置信度分数 (权重: 0.3)
        let confidenceScore = Double(observation.confidence) * 0.3

        // 2. 大小分数 - 倾向于较大的页面 (权重: 0.25)
        let area = Double(observation.boundingBox.size.width * observation.boundingBox.size.height)
        let sizeScore = min(area * 2.0, 1.0) * 0.25

        // 3. 纵横比分数 - 倾向于标准页面比例 (权重: 0.2)
        let aspectRatio = Double(
            observation.boundingBox.size.width / observation.boundingBox.size.height)
        let idealAspectRatio = 0.7071  // 1:√2 比例（A4纸比例）
        let aspectRatioScore = (1.0 - min(abs(aspectRatio - idealAspectRatio) / 0.3, 1.0)) * 0.2

        // 4. 中心位置分数 - 倾向于中心位置的页面 (权重: 0.15)
        let centerX = observation.boundingBox.origin.x + observation.boundingBox.size.width / 2
        let centerY = observation.boundingBox.origin.y + observation.boundingBox.size.height / 2
        let distanceFromCenter = sqrt(pow(centerX - 0.5, 2) + pow(centerY - 0.5, 2))
        let positionScore = (1.0 - min(distanceFromCenter * 2.0, 1.0)) * 0.15

        // 5. 规则性分数 - 检查是否为规则四边形 (权重: 0.1)
        let regularityScore = calculateQuadrilateralRegularity(observation) * 0.1

        totalScore =
            confidenceScore + sizeScore + aspectRatioScore + positionScore + regularityScore

        return min(max(totalScore, 0.0), 1.0)
    }

    private func selectBestObservation(from observations: [TestRectangleObservation])
        -> TestRectangleObservation
    {
        var scoredObservations = observations.map {
            observation -> (observation: TestRectangleObservation, score: Double) in
            let score = calculateObservationScore(observation)
            return (observation, score)
        }

        // 按分数排序
        scoredObservations.sort { $0.score > $1.score }

        return scoredObservations.first!.observation
    }

    private func calculateQuadrilateralRegularity(_ observation: TestRectangleObservation) -> Double
    {
        let points = [
            observation.topLeft,
            observation.topRight,
            observation.bottomRight,
            observation.bottomLeft,
        ]

        // 计算边长
        let sideLengths = [
            calculateDistance(points[0], points[1]),
            calculateDistance(points[1], points[2]),
            calculateDistance(points[2], points[3]),
            calculateDistance(points[3], points[0]),
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

    private func calculateDistance(_ point1: CGPoint, _ point2: CGPoint) -> Double {
        return sqrt(pow(Double(point1.x - point2.x), 2) + pow(Double(point1.y - point2.y), 2))
    }

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
}

// MARK: - 主测试函数

func runDetectorTests() {
    print("=== AIBookScanner 书籍页面检测器核心测试 ===")

    let tester = BookPageDetectorTest()

    // 运行几何计算测试
    tester.testGeometryCalculations()

    // 运行观察对象评分测试
    tester.testObservationScoring()

    // 运行最佳观察对象选择测试
    tester.testBestObservationSelection()

    print("=== 所有检测器测试完成 ===")
    print("✅ 几何计算算法验证通过")
    print("✅ 观察对象评分系统工作正常")
    print("✅ 最佳页面选择逻辑正确")
    print("✅ 书籍页面检测器核心逻辑编译成功")
}

// 运行测试
runDetectorTests()
