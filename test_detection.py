#!/usr/bin/env python3
"""
AIBookScanner 页面检测测试脚本
用于测试书籍页面检测算法的效果
"""

import cv2
import numpy as np
import argparse
import os
import sys
from pathlib import Path

def load_image(image_path):
    """加载测试图像"""
    if not os.path.exists(image_path):
        print(f"错误: 图像文件不存在 {image_path}")
        return None

    image = cv2.imread(image_path)
    if image is None:
        print(f"错误: 无法加载图像 {image_path}")
        return None

    return image

def create_test_images():
    """创建测试图像 - 模拟书籍页面"""
    test_dir = "test_images"
    os.makedirs(test_dir, exist_ok=True)

    # 创建不同角度的矩形测试图像
    test_cases = [
        {
            'name': 'perfect_rectangle',
            'points': np.array([[50, 50], [450, 50], [450, 650], [50, 650]]),
            'description': '完美矩形 - 理想情况'
        },
        {
            'name': 'tilted_page',
            'points': np.array([[100, 80], [400, 50], [420, 620], [80, 650]]),
            'description': '倾斜页面 - 常见情况'
        },
        {
            'name': 'perspective_distortion',
            'points': np.array([[150, 100], [350, 80], [380, 600], [120, 620]]),
            'description': '透视变形 - 挑战情况'
        }
    ]

    for i, test_case in enumerate(test_cases):
        # 创建空白图像
        img = np.ones((700, 500, 3), dtype=np.uint8) * 255

        # 绘制矩形
        points = test_case['points'].reshape((-1, 1, 2))
        cv2.polylines(img, [points], isClosed=True, color=(0, 0, 0), thickness=2)

        # 添加一些文本内容模拟书籍页面
        for j in range(5):
            y_pos = 150 + j * 100
            cv2.putText(img, f"书籍文本行 {j+1}", (100, y_pos),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 0), 2)

        # 保存测试图像
        filename = f"{test_dir}/test_case_{i+1}_{test_case['name']}.jpg"
        cv2.imwrite(filename, img)
        print(f"创建测试图像: {filename} - {test_case['description']}")

    return test_dir

def test_edge_detection(image_path):
    """测试边缘检测算法"""
    print(f"\n测试边缘检测: {image_path}")

    # 加载图像
    image = load_image(image_path)
    if image is None:
        return

    # 转换为灰度图
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # 应用高斯模糊
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)

    # Canny边缘检测
    edges = cv2.Canny(blurred, 50, 150)

    # 显示结果
    cv2.imshow('Original', image)
    cv2.imshow('Edges', edges)
    cv2.waitKey(0)
    cv2.destroyAllWindows()

    return edges

def test_contour_detection(image_path):
    """测试轮廓检测算法"""
    print(f"\n测试轮廓检测: {image_path}")

    # 加载图像
    image = load_image(image_path)
    if image is None:
        return

    # 边缘检测
    edges = test_edge_detection(image_path)
    if edges is None:
        return

    # 查找轮廓
    contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    # 绘制轮廓
    result = image.copy()
    cv2.drawContours(result, contours, -1, (0, 255, 0), 2)

    print(f"找到 {len(contours)} 个轮廓")

    # 显示结果
    cv2.imshow('Contours', result)
    cv2.waitKey(0)
    cv2.destroyAllWindows()

    return contours

def test_perspective_correction(image_path):
    """测试透视校正算法"""
    print(f"\n测试透视校正: {image_path}")

    # 加载图像
    image = load_image(image_path)
    if image is None:
        return

    # 这里可以添加实际的透视校正算法测试
    # 目前只是显示原始图像
    cv2.imshow('Perspective Test', image)
    cv2.waitKey(0)
    cv2.destroyAllWindows()

def run_comprehensive_test(test_image_dir):
    """运行全面的测试"""
    print("=" * 60)
    print("AIBookScanner 页面检测综合测试")
    print("=" * 60)

    # 获取所有测试图像
    test_images = list(Path(test_image_dir).glob("*.jpg"))

    if not test_images:
        print("未找到测试图像，正在创建...")
        test_image_dir = create_test_images()
        test_images = list(Path(test_image_dir).glob("*.jpg"))

    print(f"找到 {len(test_images)} 个测试图像")

    for img_path in test_images:
        print(f"\n{'='*40}")
        print(f"测试: {img_path.name}")
        print(f"{'='*40}")

        # 运行各种测试
        test_edge_detection(str(img_path))
        test_contour_detection(str(img_path))
        test_perspective_correction(str(img_path))

def main():
    """主函数"""
    parser = argparse.ArgumentParser(description='AIBookScanner 页面检测测试工具')
    parser.add_argument('--image', '-i', help='测试图像路径')
    parser.add_argument('--test-dir', '-d', default='test_images', help='测试图像目录')
    parser.add_argument('--create-test', '-c', action='store_true', help='创建测试图像')

    args = parser.parse_args()

    if args.create_test:
        create_test_images()
        return

    if args.image:
        # 测试单个图像
        test_edge_detection(args.image)
        test_contour_detection(args.image)
        test_perspective_correction(args.image)
    else:
        # 运行全面测试
        run_comprehensive_test(args.test_dir)

    print("\n测试完成!")

if __name__ == "__main__":
    main()
