import AVFoundation
import Combine

struct CameraInfo: Identifiable, Hashable {
    let id: String      // AVCaptureDevice.uniqueID
    let name: String
}

final class CameraService: NSObject {
    let session = AVCaptureSession()

    private let frameSubject = PassthroughSubject<CMSampleBuffer, Never>()
    var framePublisher: AnyPublisher<CMSampleBuffer, Never> { frameSubject.eraseToAnyPublisher() }

    private let queue = DispatchQueue(label: "com.promptbreak.camera", qos: .userInteractive)
    private var currentInput: AVCaptureDeviceInput?
    private var outputConfigured = false

    override init() {
        super.init()
    }

    // Lists built-in, external (USB), and iPhone Continuity cameras.
    static func availableCameras() -> [CameraInfo] {
        let types: [AVCaptureDevice.DeviceType] = [
            .builtInWideAngleCamera,
            .external,
            .continuityCamera
        ]
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: types,
            mediaType: .video,
            position: .unspecified
        )
        return discovery.devices.map { CameraInfo(id: $0.uniqueID, name: $0.localizedName) }
    }

    func start() {
        queue.async {
            self.configureInput()
            if !self.session.isRunning { self.session.startRunning() }
        }
    }

    func stop() {
        guard session.isRunning else { return }
        queue.async { self.session.stopRunning() }
    }

    // Reads the selected camera from Rules each time it starts, so changes apply immediately.
    private func configureInput() {
        let device = resolveDevice()
        guard let device, let input = try? AVCaptureDeviceInput(device: device) else { return }

        session.beginConfiguration()
        session.sessionPreset = .vga640x480

        // Swap input
        if let existing = currentInput { session.removeInput(existing) }
        if session.canAddInput(input) {
            session.addInput(input)
            currentInput = input
        }

        // Output (only once)
        if !outputConfigured {
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
            output.setSampleBufferDelegate(self, queue: queue)
            if session.canAddOutput(output) {
                session.addOutput(output)
                outputConfigured = true
            }
        }

        session.commitConfiguration()
    }

    private func resolveDevice() -> AVCaptureDevice? {
        if let id = Rules.current.cameraID, let device = AVCaptureDevice(uniqueID: id) {
            return device
        }
        // Default: prefer front built-in
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            ?? AVCaptureDevice.default(for: .video)
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        frameSubject.send(sampleBuffer)
    }
}
