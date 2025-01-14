//
//  DTVideoCollectionViewCell.swift
//  dvach
//
//  Created by Ruslan Timchenko on 29/06/2019.
//  Copyright © 2019 Kirill Solovyov. All rights reserved.
//

import Foundation
import OGVKit

@objc public protocol VideoContainer {
    var snapshotCropNeeded: Bool { get }
    func controlsViewFrame() -> CGRect
    func pause()
    func play()
    func snapshot(pauseVideo: Bool) -> UIImage?
    func configure(urlPath: String?, image: UIImage?)
    @objc optional func updateLayout()
}

public protocol VideoContainerDelegate: class {
    var isRotating: Bool { get }
    func handleVideoTapGesture(hideControls hide: Bool)
    func shouldOpenMediaFile(url: URL?, type: DTMediaViewerController.MediaFile.MediaType)
}

open class DTWebMCollectionViewCell: UICollectionViewCell, VideoContainer {
    
    public var snapshotCropNeeded = true
    
    // Player View (WebM Only!)
    public private(set) weak var playerView: OGVPlayerView?
    // Private NSFW preview Image View
    private weak var imageView: UIImageView?
    
    // Open in browser button
    private lazy var button: BottomButton = {
        let button = BottomButton()
        let model = BottomButton.Model(text: "Открыть видео в VLC",
                                       backgroundColor: .white, textColor: .black)
        button.configure(with: model)
        button.isHidden = true
        button.enablePressStateAnimation { [weak self] in
            self?.delegate?.shouldOpenMediaFile(url: self?.url,
                                                type: .webm)
        }
        return button
    }()
    
    // NSFW Flag
    private var isNSFW = true
    
    // Media File URL
    private var url: URL?
    
    // Delegate
    public weak var delegate: VideoContainerDelegate?

    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupButton()
    }
    
    // Overridden
    override open func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        button.snp.updateConstraints {
            $0.bottom.equalToSuperview().inset(safeAreaInsets.bottom + CGFloat.inset8)
        }
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        resizeImageView()
    }
    
    // MARK: - Setup UI
    
    private func setupPlayerView() {
        if playerView == nil {
            let playerView = OGVPlayerView(frame: bounds)
            playerView.delegate = self
            addSubview(playerView)
            playerView.snp.makeConstraints { $0.edges.equalToSuperview() }
            self.playerView = playerView
        }
    }
    
    private func setupButton() {
        addSubview(button)
        let inset: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 50 : .inset16
        button.snp.makeConstraints {
            $0.trailing.leading.equalToSuperview().inset(inset)
            $0.bottom.equalToSuperview().inset(CGFloat.inset8)
        }
    }
    
    private func setupImageView() {
        if imageView == nil {
            let imageView = UIImageView(frame: .zero)
            imageView.contentMode = .scaleAspectFit
            insertSubview(imageView, at: 0)
            self.imageView = imageView
        }
    }
    
    private func resizeImageView() {
        if let image = imageView?.image {
            let rect = AVMakeRect(aspectRatio: image.size, insideRect: bounds)
            //Then figure out offset to center vertically or horizontally
            let x = (bounds.width - rect.width) / 2
            let y = (bounds.height - rect.height) / 2
            
            imageView?.frame = CGRect(x: x, y: y, width: rect.width, height: rect.height)
        }
    }
    
    // MARK: - Configuration
    
    public func configure(urlPath: String?, image: UIImage?) {
        if let urlPath = urlPath,
            let url = URL(string: "\(GlobalUtils.base2chPath)\(urlPath)") {
            self.url = url
            if let image = image, !image.isNFFW {
                if let delegate = delegate, !delegate.isRotating {
                    isNSFW = false
                    setupPlayerView()
                    playerView?.sourceURL = url
                }
            } else {
                isNSFW = true
                snapshotCropNeeded = false
                setupImageView()
                imageView?.image = image
                resizeImageView()
                button.isHidden = false
            }
        }
    }
    
    // MARK: - VideoContainer
    
    public func pause() {
        if let playerView = playerView, !playerView.paused {
            playerView.pause()
        }
    }
    
    public func play() {
        if let playerView = playerView, playerView.paused {
            playerView.play()
        }
    }
    
    public func updateLayout() {
        playerView?.frameView.frame = bounds
    }
    
    public func snapshot(pauseVideo: Bool) -> UIImage? {
        if !isNSFW {
            if pauseVideo {
                pause()
            }
            return playerView?.frameView.snapshot
        } else {
            return imageView?.image
        }
    }
    
    public func controlsViewFrame() -> CGRect {
        if let playerView = playerView, !playerView.controlBar.isHidden {
            return playerView.controlBar.frame
        } else {
            return .zero
        }
    }
}

extension DTWebMCollectionViewCell: OGVPlayerDelegate {
    
    public func ogvPlayerControlsWillHide(_ sender: OGVPlayerView!) {
        delegate?.handleVideoTapGesture(hideControls: true)
    }
    
    public func ogvPlayerControlsWillShow(_ sender: OGVPlayerView!) {
        delegate?.handleVideoTapGesture(hideControls: false)
    }
}
