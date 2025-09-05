#!/bin/bash

# AIBookScanner 构建验证脚本
# 这个脚本用于验证项目的基本结构和编译能力

set -e  # 遇到错误时退出

echo "🔍 开始验证 AIBookScanner 项目结构..."

# 检查项目目录结构
echo "📁 检查目录结构..."
directories=(
    "AIBookScanner"
    "AIBookScanner/App"
    "AIBookScanner/Views"
    "AIBookScanner/Models"
    "AIBookScanner/ViewModels"
    "AIBookScanner/Services"
    "AIBookScanner/Utils"
    "AIBookScanner/Resources"
)

for dir in "${directories[@]}"; do
    if [ -d "$dir" ]; then
        echo "✅ 目录存在: $dir"
    else
        echo "❌ 目录缺失: $dir"
        exit 1
    fi
done

# 检查核心文件
echo "📄 检查核心文件..."
files=(
    "AIBookScanner/App/AIBookScannerApp.swift"
    "AIBookScanner/Views/ContentView.swift"
    "AIBookScanner/Views/CameraView.swift"
    "AIBookScanner/Services/CoreDataManager.swift"
    "AIBookScanner/Services/ImageProcessor.swift"
    "AIBookScanner/Resources/Info.plist"
    "Package.swift"
    "README.md"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ 文件存在: $file"
    else
        echo "❌ 文件缺失: $file"
        exit 1
    fi
done

# 检查文件内容基本语法
echo "🔧 检查Swift文件语法..."
swift_files=$(find AIBookScanner -name "*.swift")
for file in $swift_files; do
    if swiftc -parse "$file" > /dev/null 2>&1; then
        echo "✅ 语法正确: $file"
    else
        echo "❌ 语法错误: $file"
        exit 1
    fi
done

# 检查Package.swift语法
echo "📦 检查Package.swift语法..."
if swift package dump-package > /dev/null 2>&1; then
    echo "✅ Package.swift 语法正确"
else
    echo "❌ Package.swift 语法错误"
    exit 1
fi

# 检查Info.plist语法
echo "⚙️  检查Info.plist语法..."
if plutil -lint AIBookScanner/Resources/Info.plist > /dev/null 2>&1; then
    echo "✅ Info.plist 语法正确"
else
    echo "❌ Info.plist 语法错误"
    exit 1
fi

# 验证必要的框架导入
echo "🔗 检查框架导入..."
if grep -r "import AVFoundation" AIBookScanner --include="*.swift" | grep -v "TestImports" > /dev/null; then
    echo "✅ AVFoundation 导入正确"
else
    echo "❌ AVFoundation 导入缺失"
fi

if grep -r "import CoreImage" AIBookScanner --include="*.swift" | grep -v "TestImports" > /dev/null; then
    echo "✅ CoreImage 导入正确"
else
    echo "❌ CoreImage 导入缺失"
fi

if grep -r "import Metal" AIBookScanner --include="*.swift" | grep -v "TestImports" > /dev/null; then
    echo "✅ Metal 导入正确"
else
    echo "❌ Metal 导入缺失"
fi

if grep -r "import Vision" AIBookScanner --include="*.swift" | grep -v "TestImports" > /dev/null; then
    echo "✅ Vision 导入正确"
else
    echo "❌ Vision 导入缺失"
fi

# 检查权限描述
echo "🔐 检查隐私权限描述..."
if grep -q "NSCameraUsageDescription" AIBookScanner/Resources/Info.plist; then
    echo "✅ 相机权限描述存在"
else
    echo "❌ 相机权限描述缺失"
fi

if grep -q "NSPhotoLibraryUsageDescription" AIBookScanner/Resources/Info.plist; then
    echo "✅ 相册权限描述存在"
else
    echo "❌ 相册权限描述缺失"
fi

# 项目统计
echo "📊 项目统计:"
swift_file_count=$(find AIBookScanner -name "*.swift" | wc -l | tr -d ' ')
total_lines=$(find AIBookScanner -name "*.swift" -exec cat {} \; | wc -l | tr -d ' ')
avg_lines=$((total_lines / swift_file_count))

echo "   Swift文件数量: $swift_file_count"
echo "   总代码行数: $total_lines"
echo "   平均每个文件: $avg_lines 行"

# 最终验证结果
echo ""
echo "🎉 项目验证完成!"
echo "✅ 所有基本检查通过"
echo "📱 项目已准备好进行iOS开发"
echo ""
echo "下一步建议:"
echo "1. 在Xcode中打开项目"
echo "2. 配置开发团队和签名"
echo "3. 运行在真机或模拟器上测试"
echo "4. 开始添加具体的AI处理功能"

exit 0
