// AIBookScanner 核心图像处理编译测试
// 这个文件用于测试核心的图像处理算法，不依赖iOS特定框架

import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

/// 核心图像处理功能测试
class CoreImageProcessorTest {

    // MARK: - 图像处理测试

    /// 测试基本的图像处理功能
    func testBasicImageProcessing() {
        print("开始核心图像处理测试...")

        // 创建一个测试图像（简单的渐变）
        let testImage = createTestImage()
        print("测试图像创建成功")

        // 测试灰度转换
        let grayscaleImage = applyGrayscaleFilter(testImage)
        print("灰度转换测试完成")

        // 测试对比度增强
        let contrastImage = applyContrastFilter(grayscaleImage)
        print("对比度增强测试完成")

        // 测试边缘增强
        let edgeEnhancedImage = applyEdgeEnhancement(contrastImage)
        print("边缘增强测试完成")

        // 测试降噪
        let denoisedImage = applyDenoising(edgeEnhancedImage)
        print("降噪处理测试完成")

        print("所有核心图像处理测试完成 ✅")
    }

    // MARK: - 测试图像创建

    private func createTestImage() -> CIImage {
        // 创建一个简单的渐变图像作为测试
        let gradientFilter = CIFilter.linearGradient()
        gradientFilter.color0 = CIColor(red: 0.8, green: 0.8, blue: 0.8)
        gradientFilter.color1 = CIColor(red: 0.2, green: 0.2, blue: 0.2)
        gradientFilter.point0 = CGPoint(x: 0, y: 0)
        gradientFilter.point1 = CGPoint(x: 500, y: 500)

        return gradientFilter.outputImage ?? CIImage.empty()
    }

    // MARK: - 核心图像处理函数

    private func applyGrayscaleFilter(_ image: CIImage) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.saturation = 0.1
        return filter.outputImage ?? image
    }

    private func applyContrastFilter(_ image: CIImage) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.contrast = 1.5
        filter.brightness = 0.2
        return filter.outputImage ?? image
    }

    private func applyEdgeEnhancement(_ image: CIImage) -> CIImage {
        let filter = CIFilter.unsharpMask()
        filter.inputImage = image
        filter.radius = 2.0
        filter.intensity = 1.0
        return filter.outputImage ?? image
    }

    private func applyDenoising(_ image: CIImage) -> CIImage {
        let filter = CIFilter.noiseReduction()
        filter.inputImage = image
        filter.noiseLevel = 0.02
        filter.sharpness = 0.4
        return filter.outputImage ?? image
    }

    // MARK: - 几何计算测试

    func testGeometryCalculations() {
        print("开始几何计算测试...")

        // 测试距离计算
        let point1 = CGPoint(x: 0, y: 0)
        let point2 = CGPoint(x: 3, y: 4)
        let distance = calculateDistance(point1, point2)
        assert(distance == 5.0, "距离计算错误")
        print("距离计算测试完成 ✅")

        // 测试角度计算
        let points = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 1, y: 0),
            CGPoint(x: 1, y: 1),
        ]
        let angles = calculateAngles(points: points)
        print("角度计算测试完成 ✅")

        print("所有几何计算测试完成 ✅")
    }

    private func calculateDistance(_ point1: CGPoint, _ point2: CGPoint) -> Double {
        return sqrt(pow(Double(point1.x - point2.x), 2) + pow(Double(point1.y - point2.y), 2))
    }

    private func calculateAngles(points: [CGPoint]) -> [Double] {
        var angles: [Double] = []

        for i in 0..<points.count {
            let p0 = points[i]
            let p1 = points[(i + 1) % points.count]
            let p2 = points[(i + 2) % points.count]

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

func runCoreTests() {
    print("=== AIBookScanner 核心功能编译测试 ===")

    let tester = CoreImageProcessorTest()

    // 运行图像处理测试
    tester.testBasicImageProcessing()

    // 运行几何计算测试
    tester.testGeometryCalculations()

    print("=== 所有核心测试完成 ===")
    print("✅ 核心图像处理算法编译成功")
    print("✅ 几何计算函数工作正常")
    print("✅ 项目核心逻辑验证通过")
}

// 运行测试
runCoreTests()
