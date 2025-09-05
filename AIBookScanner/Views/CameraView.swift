import AVFoundation
import SwiftUI
import UIKit

/// 相机视图 - 用于捕获书籍页面的自定义相机界面
struct CameraView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    // 处理完成的回调
    var onImageCaptured: ((UIImage) -> Void)?

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // 视图更新处理
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CameraViewControllerDelegate {
        var parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func cameraViewController(
            _ controller: CameraViewController, didCaptureImage image: UIImage
        ) {
            // 处理捕获的图像
            parent.onImageCaptured?(image)
            parent.dismiss()
        }

        func cameraViewControllerDidCancel(_ controller: CameraViewController) {
            parent.dismiss()
        }

        func cameraViewController(_ controller: CameraViewController, didFailWithError error: Error)
        {
            print("相机捕获失败: \(error.localizedDescription)")
            parent.dismiss()
        }
    }
}

/// 相机视图控制器协议
protocol CameraViewControllerDelegate: AnyObject {
    func cameraViewController(_ controller: CameraViewController, didCaptureImage image: UIImage)
    func cameraViewControllerDidCancel(_ controller: CameraViewController)
    func cameraViewController(_ controller: CameraViewController, didFailWithError error: Error)
}

/// 自定义相机视图控制器
class CameraViewController: UIViewController {
    weak var delegate: CameraViewControllerDelegate?

    // AVFoundation组件
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var photoOutput: AVCapturePhotoOutput!
    private var videoDeviceInput: AVCaptureDeviceInput!

    // UI组件
    private var captureButton: UIButton!
    private var cancelButton: UIButton!
    private var switchCameraButton: UIButton!
    private var focusView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCaptureSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCaptureSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    // MARK: - 相机设置

    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo

        // 配置照片输出
        photoOutput = AVCapturePhotoOutput()

        // 获取后置相机
        guard
            let videoDevice = AVCaptureDevice.default(
                .builtInWideAngleCamera, for: .video, position: .back)
        else {
            delegate?.cameraViewController(
                self,
                didFailWithError: NSError(
                    domain: "CameraError", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "无法访问相机设备"]))
            return
        }

        do {
            videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)

            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
            }

            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }

            // 设置预览层
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.connection?.videoOrientation = .portrait
            view.layer.addSublayer(previewLayer)

        } catch {
            delegate?.cameraViewController(self, didFailWithError: error)
        }
    }

    private func startCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }

    private func stopCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.stopRunning()
        }
    }

    // MARK: - UI设置

    private func setupUI() {
        view.backgroundColor = .black

        // 捕获按钮
        captureButton = UIButton(type: .system)
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.backgroundColor = .white
        captureButton.tintColor = .black
        captureButton.layer.cornerRadius = 35
        captureButton.layer.borderWidth = 4
        captureButton.layer.borderColor = UIColor.lightGray.cgColor
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        view.addSubview(captureButton)

        // 取消按钮
        cancelButton = UIButton(type: .system)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.tintColor = .white
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        view.addSubview(cancelButton)

        // 切换相机按钮
        switchCameraButton = UIButton(type: .system)
        switchCameraButton.translatesAutoresizingMaskIntoConstraints = false
        switchCameraButton.setImage(UIImage(systemName: "camera.rotate"), for: .normal)
        switchCameraButton.tintColor = .white
        switchCameraButton.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
        view.addSubview(switchCameraButton)

        // 对焦指示器
        focusView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        focusView.backgroundColor = .clear
        focusView.layer.borderColor = UIColor.yellow.cgColor
        focusView.layer.borderWidth = 2
        focusView.layer.cornerRadius = 40
        focusView.isHidden = true
        view.addSubview(focusView)

        // 添加手势识别器用于对焦
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tapGesture)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 捕获按钮
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),

            // 取消按钮
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),

            // 切换相机按钮
            switchCameraButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -20),
            switchCameraButton.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
        ])
    }

    // MARK: - 用户交互

    @objc private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    @objc private func cancel() {
        delegate?.cameraViewControllerDidCancel(self)
    }

    @objc private func switchCamera() {
        captureSession.beginConfiguration()

        // 移除当前输入
        captureSession.removeInput(videoDeviceInput)

        // 切换相机位置
        let newPosition: AVCaptureDevice.Position =
            (videoDeviceInput.device.position == .back) ? .front : .back

        guard
            let newVideoDevice = AVCaptureDevice.default(
                .builtInWideAngleCamera, for: .video, position: newPosition),
            let newVideoInput = try? AVCaptureDeviceInput(device: newVideoDevice)
        else {
            return
        }

        videoDeviceInput = newVideoInput

        if captureSession.canAddInput(videoDeviceInput) {
            captureSession.addInput(videoDeviceInput)
        }

        captureSession.commitConfiguration()
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: view)
        focus(at: point)
    }

    private func focus(at point: CGPoint) {
        guard let device = videoDeviceInput.device else { return }

        do {
            try device.lockForConfiguration()

            // 对焦
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = previewLayer.captureDevicePointConverted(
                    fromLayerPoint: point)
                device.focusMode = .autoFocus
            }

            // 曝光
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = previewLayer.captureDevicePointConverted(
                    fromLayerPoint: point)
                device.exposureMode = .autoExpose
            }

            device.unlockForConfiguration()

            // 显示对焦指示器
            showFocusIndicator(at: point)

        } catch {
            print("对焦设置失败: \(error.localizedDescription)")
        }
    }

    private func showFocusIndicator(at point: CGPoint) {
        focusView.center = point
        focusView.isHidden = false
        focusView.alpha = 1.0

        UIView.animate(
            withDuration: 0.3,
            animations: {
                self.focusView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }
        ) { _ in
            UIView.animate(
                withDuration: 0.3,
                animations: {
                    self.focusView.transform = CGAffineTransform.identity
                }
            ) { _ in
                UIView.animate(
                    withDuration: 0.5, delay: 0.5, options: [],
                    animations: {
                        self.focusView.alpha = 0
                    }
                ) { _ in
                    self.focusView.isHidden = true
                }
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            delegate?.cameraViewController(self, didFailWithError: error)
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
            let image = UIImage(data: imageData)
        else {
            delegate?.cameraViewController(
                self,
                didFailWithError: NSError(
                    domain: "CameraError", code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "无法处理图像数据"]))
            return
        }

        // 传递给委托
        delegate?.cameraViewController(self, didCaptureImage: image)
    }
}
