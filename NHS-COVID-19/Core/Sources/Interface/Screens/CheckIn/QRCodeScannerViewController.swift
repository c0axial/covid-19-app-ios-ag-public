//
// Copyright © 2020 NHSX. All rights reserved.
//

import Combine
import Common
import Localization
import UIKit

public protocol QRCodeScannerViewControllerInteracting {
    func showHelp()
}

public class QRScanner {
    public typealias StartScanning = (UIView, CGRect, @escaping (String) -> Void) -> Void
    public typealias StopScanning = () -> Void
    public typealias LayoutFinished = (CGRect, CGRect, UIInterfaceOrientation) -> Void
    
    public enum State: Equatable {
        case starting
        case failed
        case requestingPermission
        case running
        case scanning
        case processing
        case stopped
    }
    
    public var state: AnyPublisher<State, Never>
    
    private var _startScanning: StartScanning
    private var _stopScanning: StopScanning
    private var _layoutFinished: LayoutFinished
    
    public init(state: AnyPublisher<State, Never>,
                startScanning: @escaping StartScanning,
                stopScanning: @escaping StopScanning,
                layoutFinished: @escaping LayoutFinished) {
        self.state = state
        _startScanning = startScanning
        _stopScanning = stopScanning
        _layoutFinished = layoutFinished
    }
    
    func startScanning(targetView: UIView, scanViewBounds: CGRect, resultHandler: @escaping (String) -> Void) {
        _startScanning(targetView, scanViewBounds, resultHandler)
    }
    
    func stopScanning() {
        _stopScanning()
    }
    
    func layoutFinished(viewBounds: CGRect, scanViewBounds: CGRect, orientation: UIInterfaceOrientation) {
        _layoutFinished(viewBounds, scanViewBounds, orientation)
    }
}

public class QRCodeScannerViewController: UIViewController {
    
    public typealias Interacting = QRCodeScannerViewControllerInteracting
    
    private var scanner: QRScanner
    
    private var scanView: ScanView!
    
    private var cameraPermissionState: AnyPublisher<CameraPermissionState, Never>
    
    private var isCameraSetup: Bool = false
    
    private var completion: (String) -> Void
    
    private var interactor: Interacting
    
    public init(
        interactor: Interacting,
        cameraPermissionState: AnyPublisher<CameraPermissionState, Never>,
        scanner: QRScanner,
        completion: @escaping (String) -> Void
    ) {
        self.interactor = interactor
        self.cameraPermissionState = cameraPermissionState
        self.completion = completion
        self.scanner = scanner
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scanner.startScanning(targetView: view, scanViewBounds: scanView.scanWindowBound, resultHandler: completion)
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        scanner.stopScanning()
    }
    
    override public func accessibilityPerformEscape() -> Bool {
        dismiss(animated: true, completion: nil)
        return true
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scanner.layoutFinished(viewBounds: view.bounds, scanViewBounds: scanView.scanWindowBound, orientation: view.interfaceOrientation)
    }
    
    private func setupUI() {
        scanView = ScanView(
            frame: view.bounds,
            cameraState: scanner.state,
            helpHandler: { [weak self] in
                self?.showHelp()
            }
        )
        
        view.addFillingSubview(scanView)
        
        let closeButton = UIButton()
        closeButton.setTitleColor(UIColor(.surface), for: .normal)
        closeButton.setTitle(localize(.checkin_qrcode_scanner_close_button_title), for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton.showsLargeContentViewer = true
        closeButton.largeContentTitle = localize(.checkin_qrcode_scanner_close_button_title)
        closeButton.addInteraction(UILargeContentViewerInteraction())
        view.addAutolayoutSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: .standardSpacing),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        ])
    }
    
    private func showHelp() {
        interactor.showHelp()
    }
    
    @objc func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
}
