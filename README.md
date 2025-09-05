# AIBookScanner - AI书籍扫描仪

一个完全本地的、隐私保护的iOS应用，使用AI技术将手机拍摄的书籍页面转换为清晰的数字文档。

## ✨ 特性

- **📷 智能拍摄**: 专业的书籍页面拍摄界面，支持自动对焦和曝光
- **🤖 AI增强处理**: 使用Core ML和Vision框架进行本地AI处理
- **🔒 完全本地**: 所有处理在设备上完成，无需网络连接
- **⚡ Metal加速**: 利用Metal API进行GPU加速图像处理
- **📄 透视校正**: 自动检测书页边缘并进行透视变换
- **🎨 图像增强**: 智能提升清晰度、对比度和色彩质量
- **💾 本地存储**: 使用Core Data安全存储扫描记录

## 🛠️ 技术栈

- **SwiftUI** - 现代化的声明式UI框架
- **AVFoundation** - 相机捕获和媒体处理
- **Core ML** - 本地机器学习推理
- **Vision** - 计算机视觉框架
- **Metal** - 高性能图形和计算
- **Core Data** - 本地数据持久化
- **Vision** - 高级页面检测
- **Core Image** - 实时图像处理

## 📱 功能

### 核心功能
- [x] 书籍页面拍摄
- [x] 自动边缘检测
- [x] 高级透视校正（多尺度检测）
- [x] 智能图像增强（文字优化）
- [x] 本地存储
- [x] 多尺度页面检测算法
- [x] 多尺度页面检测
- [x] 隐私保护
- [x] 智能页面评分系统
- [x] 智能页面选择算法

### 高级功能
- [ ] OCR文字识别（Vision框架）
- [ ] 多页文档管理
- [ ] 实时处理预览
- [ ] PDF导出
- [ ] iCloud同步
- [ ] 批量处理

## 🚀 快速开始

### 系统要求
- iOS 17.0+
- Xcode 15.0+
- 支持Metal的iOS设备

### 安装

1. 克隆项目:
```bash
git clone https://github.com/your-username/AIBookScanner.git
cd AIBookScanner
```

2. 打开Xcode项目:
```bash
open AIBookScanner.xcodeproj
```

3. 选择开发团队并运行

### 使用说明

1. 打开应用并授予相机权限
2. 点击"开始扫描"按钮
3. 将相机对准书籍页面
4. 点击拍摄按钮捕获图像
5. AI会自动处理并保存结果

## 🔧 开发

### 项目结构
```
AIBookScanner/
├── App/                 # 应用入口和配置
├── Views/               # SwiftUI视图
├── Models/              # 数据模型
├── ViewModels/          # 视图模型
├── Services/            # 业务服务
├── Utils/               # 工具类
└── Resources/           # 资源文件
```

### 核心服务

- `ImageProcessor` - 图像处理管道
- `BookPageDetector` - 高级页面检测
- `CoreDataManager` - 数据存储管理
- `CameraService` - 相机控制
- 测试框架 - Python测试脚本

## 📄 许可证

本项目采用MIT许可证。详见[LICENSE](LICENSE)文件。

## 🤝 贡献

欢迎提交Issue和Pull Request！

## 📞 支持

如有问题，请通过以下方式联系：
- 创建[Issue](https://github.com/your-username/AIBookScanner/issues)
- 发送邮件至: support@example.com

## 🔒 隐私政策

我们高度重视用户隐私：
- 所有图像处理在设备本地完成
- 不会收集或上传任何用户数据
- 符合ISO42001数据保护标准

---

## 🧪 测试工具

项目包含完整的测试框架：
- Python测试脚本 (`test_detection.py`)
- 边缘检测算法验证
- 轮廓分析测试
- 透视校正评估
- 测试图像生成工具

运行测试：
```bash
python test_detection.py --create-test  # 创建测试图像
python test_detection.py --test-dir test_images  # 运行全面测试
```

**AIBookScanner** - 让书籍数字化变得简单而安全 📚✨