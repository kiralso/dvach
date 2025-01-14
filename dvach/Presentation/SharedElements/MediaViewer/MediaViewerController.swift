//
//  MediaViewerController.swift
//  dvach
//
//  Created by Ruslan Timchenko on 20/06/2019.
//  Copyright © 2019 Kirill Solovyov. All rights reserved.
//

import Foundation
import SafariServices

protocol MediaViewer: AnyObject, SFSafariViewControllerDelegate {
    func lockController()
}

final class MediaViewerController: DTMediaViewerController {
    
    // Dependencies
    private let presenter: IMediaViewerPresenter
    private let componentsFactory = Locator.shared.componentsFactory()
    
    // UI
    private lazy var closeButton = componentsFactory.createCloseButton(style: .dismiss,
                                                                       imageColor: .black,
                                                                       backgroundColor: .white) { [weak self] in
        self?.configureSecondaryViews(hidden: true, animated: false)
        self?.dismiss(animated: true)
    }
    
    private lazy var horizontalMoreButton = componentsFactory.createHorizontalMoreButton(.white) { [weak self] in
        self?.presenter.didTapMoreButton()
    }
    
    // Properties
    private var initialDeviceOrientation: UIDeviceOrientation = .portrait
    
    // Overridden UIViewController Variables
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        hideStatusBar(true, animation: false)
        return false
    }
    
    // Overridden DTMediaViewController Variables
    override var scaleWhileDragging: Bool {
        return false
    }
    
    // MARK: - Initialization
    
    override init(referencedViews: [UIImageView]?,
                  files: [MediaFile]?,
                  index: Int?) {
        let presenter = MediaViewerPresenter()
        self.presenter = presenter
        super.init(referencedViews: referencedViews,
                   files: files,
                   index: index)
        
        presenter.view = self
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialDeviceOrientation = UIDevice.current.orientation
        
        setupUI()
        presenter.viewDidLoad()
        configureSecondaryViews(hidden: true, animated: false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIDevice.current.setValue(Int(initialDeviceOrientation.rawValue),
                                  forKey: "orientation")
    }
        
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        closeButton.snp.updateConstraints { make in
            make.top.equalToSuperview().inset(CGFloat.inset2 + view.safeAreaInsets.top)
        }
        // TODO: - Сделать три точки видимыми, когда появится функционал
//        horizontalMoreButton.snp.updateConstraints { make in
//            make.top.equalToSuperview().inset(CGFloat.inset12 + view.safeAreaInsets.top)
//        }
    }
    
    // MARK: - Private Setup
    
    private func setupUI() {
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(CGFloat.inset2)
            make.leading.equalToSuperview().inset(CGFloat.inset16)
        }
        
        // TODO: - Сделать три точки видимыми, когда появится функционал
//        view.addSubview(horizontalMoreButton)
//        horizontalMoreButton.snp.makeConstraints { make in
//            make.top.equalToSuperview().inset(CGFloat.inset12)
//            make.trailing.equalToSuperview().inset(CGFloat.inset16)
//        }
        
        registerClassPhotoViewer(PhotoViewerCollectionViewCell.self)
    }
    
    // MARK: - Hide/Unhide Secondary Views Behaviour
    
    public func configureSecondaryViews(hidden: Bool, animated: Bool) {
        if hidden != closeButton.isHidden {
            let duration: TimeInterval = animated ? 0.2 : 0
            let alpha: CGFloat = hidden ? 0 : 1
            
            // Always unhide view before animation
            closeButton.isHidden = false
            horizontalMoreButton.isHidden = false
            
            UIView.animate(withDuration: duration, animations: { [weak self] in
                self?.closeButton.alpha = alpha
                self?.horizontalMoreButton.alpha = alpha
                }, completion: { [weak self] _ in
                    self?.closeButton.isHidden = hidden
                    self?.horizontalMoreButton.isHidden = hidden
                }
            )
        }
    }
    
    // Hide & Show info layer view
    private func hideUnhideViewsWithZoom(hide: Bool? = nil) {
        if zoomScale == 1 {
            if let hide = hide {
                configureSecondaryViews(hidden: hide, animated: true)
            } else {
                if closeButton.isHidden == true {
                    configureSecondaryViews(hidden: false, animated: true)
                } else {
                    configureSecondaryViews(hidden: true, animated: true)
                }
            }
        }
    }
    
    // MARK: - Overridden DTMediaViewerController Methods
    
    override func shouldOpenMediaFile(url: URL?, type: MediaFile.MediaType) {
        if let url = url {
            presenter.openMediaFile(at: url, type: type)
        }
    }
    
    override func didReceiveTapGesture(hideControls hide: Bool?) {
        hideUnhideViewsWithZoom(hide: hide)
    }
    
    override func willZoomOnPhoto(at index: Int) {
        configureSecondaryViews(hidden: true, animated: false)
    }
    
    override func didEndZoomingOnPhoto(at index: Int, atScale scale: CGFloat) {
        if scale == 1 {
            configureSecondaryViews(hidden: false, animated: true)
        }
    }
    
    override func didEndPresentingAnimation() {
        configureSecondaryViews(hidden: false, animated: true)
    }
    
    override func willBegin(panGestureRecognizer gestureRecognizer: UIPanGestureRecognizer) {
        configureSecondaryViews(hidden: true, animated: false)
    }
    
    override func didReceiveDoubleTapGesture() {
        if !closeButton.isHidden {
            configureSecondaryViews(hidden: true, animated: false)
        }
    }
}

// MARK: - MediaViewer

extension MediaViewerController: MediaViewer {
    func lockController() {
        controllerIsLocked = true
    }
}


// MARK: - SFSafariViewControllerDelegate

extension MediaViewerController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
