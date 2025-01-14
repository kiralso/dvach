//
//  DTMediaViewerController.swift
//  dvach
//
//  Created by Ruslan Timchenko on 18/06/2019.
//  Copyright © 2019 Kirill Solovyov. All rights reserved.
//

import UIKit
import AVKit
import FLAnimatedImage
import Photos

private extension String {
    static let photoCollectionViewCellIdentifier = "photoCollectionViewCell"
    static let webmCollectionViewCellIdentifier = "webmCollectionViewCell"
    static let mp4CollectionViewCellIdentifier = "mp4CollectionViewCell"
}

open class DTMediaViewerController: UIViewController, VideoContainerDelegate {
    
    public struct MediaFile {
        let type: MediaType
        
        let image: UIImage?
        let urlPath: String?
        
        public enum MediaType {
            case image
            case webm
            case mp4
        }
    }
    
    /// Scroll direction
    /// Default value is UICollectionViewScrollDirectionVertical
    public var scrollDirection: UICollectionView.ScrollDirection = UICollectionView.ScrollDirection.horizontal {
        didSet {
            // Update collection view flow layout
            (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection = scrollDirection
        }
    }
    
    /// Datasource
    /// Providing number of image items to controller and how to confiure image for each image view in it.
    public weak var mediaViewControllerDataSource: DTMediaViewerControllerDataSource?
    
    /// Delegate
    public weak var mediaViewControllerDelegate: DTMediaViewerControllerDelegate?
    
    /// Indicates if status bar should be hidden after photo viewer controller is presented.
    /// Default value is true
    open var shouldHideStatusBarOnPresent = true
    
    /// Indicates status bar style when photo viewer controller is being presenting
    /// Default value if UIStatusBarStyle.default
    open var statusBarStyleOnPresenting: UIStatusBarStyle = UIStatusBarStyle.default
    
    /// Indicates status bar animation style when changing hidden status
    /// Default value if UIStatusBarStyle.fade
    open var statusBarAnimationStyle: UIStatusBarAnimation = UIStatusBarAnimation.fade
    
    /// Indicates status bar style after photo viewer controller is being dismissing
    /// Include when pan gesture recognizer is active.
    /// Default value if UIStatusBarStyle.LightContent
    open var statusBarStyleOnDismissing: UIStatusBarStyle = UIStatusBarStyle.default
    
    /// Background color of the viewer.
    /// Default value is black.
    open var backgroundColor: UIColor = UIColor.black {
        didSet {
            backgroundView.backgroundColor = backgroundColor
        }
    }
    
    /// Indicates if referencedView should be shown or hidden automatically during presentation and dismissal.
    /// Setting automaticallyUpdateReferencedViewVisibility to false means you need to update isHidden property of this view by yourself.
    /// Setting automaticallyUpdateReferencedViewVisibility will also set referencedView isHidden property to false.
    /// Default value is true
    open var automaticallyUpdateReferencedViewVisibility = true {
        didSet {
            if !automaticallyUpdateReferencedViewVisibility {
                referencedView?.isHidden = false
            }
        }
    }
    
    /// Indicates where image should be scaled smaller when being dragged.
    /// Default value is true.
    open var scaleWhileDragging: Bool {
        return true
    }
    
    /// This variable sets original frame of image view to animate from
    open fileprivate(set) var referenceSize: CGSize = CGSize.zero
    
    fileprivate var referencedViews: [UIImageView]?
    fileprivate var mediaFiles: [MediaFile]?
    
    /// This is the image view that is mainly used for the presentation and dismissal effect.
    /// How it animates from the original view to fullscreen and vice versa.
    public fileprivate(set) var imageView: FLAnimatedImageView
    
    /// The view where photo viewer originally animates from.
    /// Provide this correctly so that you can have a nice effect.
    public weak internal(set) var referencedView: UIImageView? {
        didSet {
            // Unhide old referenced view and hide the new one
            oldValue?.isHidden = false
            if automaticallyUpdateReferencedViewVisibility {
                referencedView?.isHidden = true
            }
        }
    }
    
    /// Collection view.
    /// This will be used when displaying multiple images.
    fileprivate(set) var collectionView: UICollectionView
    public var scrollView: UIScrollView {
        return collectionView
    }
    
    /// Currently Visible Photo Cell (if any)
    public var currentPhotoCell: DTPhotoCollectionViewCell? {
        return collectionView.cellForItem(at: IndexPath(row: currentIndex,
                                                        section: 0)) as? DTPhotoCollectionViewCell
    }
    
    /// Currently Visible Video Container (if any)
    public var currentVideoContainer: VideoContainer? {
        return collectionView.cellForItem(at: IndexPath(row: currentIndex,
                                                        section: 0)) as? VideoContainer
    }
    
    /// View used for fading effect during presentation and dismissal animation or when controller is being dragged.
    public internal(set) var backgroundView: UIView
    
    /// Pan gesture for dragging controller
    public internal(set) var panGestureRecognizer: UIPanGestureRecognizer!
    
    /// Double tap gesture
    public internal(set) var doubleTapGestureRecognizer: UITapGestureRecognizer!
    
    /// Single tap gesture
    public internal(set) var singleTapGestureRecognizer: UITapGestureRecognizer!
    
    fileprivate var _shouldHideStatusBar = false
    fileprivate var _shouldUseStatusBarStyle = false
    
    public var isRotating = false
    
    private var isOpening = true
    private var openingIndex = 0
    
    // We need to lock our controller if we open media content in Safari inside the app to avoid unexpected behaviour 
    open var controllerIsLocked = false
    
    /// Transition animator
    /// Customizable if you wish to provide your own transitions.
    open lazy var animator: DTMediaViewerBaseAnimator = DTMediaAnimator()
    
    // MARK: - Initialization
    
    public init(referencedViews: [UIImageView]?,
                files: [MediaFile]?,
                index: Int?) {
        openingIndex = index ?? 0
        let flowLayout = DTCollectionViewFlowLayout()
        flowLayout.scrollDirection = scrollDirection
        flowLayout.sectionInset = UIEdgeInsets.zero
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        
        // Collection view
        collectionView = UICollectionView(frame: CGRect.zero,
                                          collectionViewLayout: flowLayout)
        collectionView.register(DTPhotoCollectionViewCell.self, forCellWithReuseIdentifier: .photoCollectionViewCellIdentifier)
        collectionView.register(DTWebMCollectionViewCell.self, forCellWithReuseIdentifier: .webmCollectionViewCellIdentifier)
        collectionView.register(DTMP4CollectionViewCell.self, forCellWithReuseIdentifier: .mp4CollectionViewCellIdentifier)
        
        collectionView.backgroundColor = UIColor.clear
        collectionView.isPagingEnabled = true
        
        backgroundView = UIView(frame: CGRect.zero)
        
        // Image view
        let newImageView = DTImageView(frame: CGRect.zero)
        imageView = newImageView
        
        mediaFiles = files
        
        super.init(nibName: nil, bundle: nil)
        
        transitioningDelegate = self
        
        let referencedView = referencedViews?[safeIndex: index ?? 0]
        
        imageView.image = referencedView?.image
        self.referencedView = referencedView
        collectionView.dataSource = self
        collectionView.delegate = self
        
        modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        modalPresentationCapturesStatusBarAppearance = true
        
        collectionView.contentInsetAdjustmentBehavior = .never
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override open func viewDidLoad() {
        if let view = referencedView {
            // Content mode should be identical between image view and reference view
            imageView.contentMode = view.contentMode
        }
        
        //Background view
        view.addSubview(backgroundView)
        backgroundView.alpha = 0
        backgroundView.backgroundColor = backgroundColor
        
        // Image view
        // Configure this block for changing image size when image changed
        (imageView as? DTImageView)?.imageChangeBlock = { [weak self] image in
            // Update image frame whenever image changes and when the imageView is not being visible
            // imageView is only being visible during presentation or dismissal
            // For that reason, we should not update frame of imageView no matter what.
            if let strongSelf = self, let image = image, strongSelf.imageView.isHidden == true {
                strongSelf.imageView.frame.size = strongSelf.imageViewSizeForImage(image)
                strongSelf.imageView.center = strongSelf.view.center
                
                // No datasource, only 1 item in collection view --> reloadData
                guard let _ = strongSelf.mediaViewControllerDataSource else {
                    strongSelf.collectionView.reloadData()
                    return
                }
            }
        }
        
        imageView.frame = _frameForReferencedView()
        imageView.clipsToBounds = true
        
        //Scroll view
        scrollView.delegate = self
        view.addSubview(imageView)
        view.addSubview(scrollView)
        
        //Tap gesture recognizer
        singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(_handleTapGesture))
        singleTapGestureRecognizer.numberOfTapsRequired = 1
        singleTapGestureRecognizer.numberOfTouchesRequired = 1
        
        //Pan gesture recognizer
        panGestureRecognizer = UIPanGestureRecognizer(target: self,
                                                      action: #selector(_handlePanGesture))
        panGestureRecognizer.maximumNumberOfTouches = 1
        view.isUserInteractionEnabled = true
        
        //Double tap gesture recognizer
        doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(_handleDoubleTapGesture))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        doubleTapGestureRecognizer.numberOfTouchesRequired = 1
        singleTapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
        
        scrollView.addGestureRecognizer(doubleTapGestureRecognizer)
        scrollView.addGestureRecognizer(singleTapGestureRecognizer)
        view.addGestureRecognizer(panGestureRecognizer)
        
        super.viewDidLoad()
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        backgroundView.frame = view.bounds
        scrollView.frame = view.bounds
        
        // Update image view frame everytime view changes frame
        (imageView as? DTImageView)?.imageChangeBlock?(imageView.image)
        updateImageViewFrameDuringRotation()
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Update layout
        (collectionView.collectionViewLayout as? DTCollectionViewFlowLayout)?.currentIndex = currentIndex
        
        let cell = currentPhotoCell
        let container = currentVideoContainer
        
        cell?.scrollView.zoomScale = 1.0
        imageView.image = cell?.imageView.image
        _hideImageView(false)
        isRotating = true

        coordinator.animate(alongsideTransition: { (context) in
            
        }) { (context) in
            self._hideImageView(true)
            container?.updateLayout?()
            self.isRotating = false
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        if !controllerIsLocked {
            super.viewWillAppear(animated)
            
            if !animated {
                presentingAnimation()
                presentationAnimationDidFinish()
            }
            else {
                presentationAnimationWillStart()
            }
        }
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isOpening = false
        controllerIsLocked = false
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        if !controllerIsLocked {
            // Update image view before animation
            updateImageView(scrollView: scrollView)
            
            if let videoContainer = currentVideoContainer {
                videoContainer.pause()
            }
            
            super.viewWillDisappear(animated)
            
            if !animated {
                dismissingAnimation()
                dismissalAnimationDidFinish()
            }
            else {
                dismissalAnimationWillStart()
            }
        }
    }
    
    // MARK: - Overridden Variables
    
    open override var prefersStatusBarHidden: Bool {
        return true
    }
    
    open override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    open override var preferredStatusBarUpdateAnimation : UIStatusBarAnimation {
        return statusBarAnimationStyle
    }
    
    open override var preferredStatusBarStyle : UIStatusBarStyle {
        if _shouldUseStatusBarStyle {
            return statusBarStyleOnPresenting
        }
        return statusBarStyleOnDismissing
    }
    
    //MARK: - Private methods
    
    fileprivate func startAnimation() {
        //Hide reference image view
        if automaticallyUpdateReferencedViewVisibility {
            referencedView?.isHidden = true
        }
        
        //Animate to center
        _animateToCenter()
    }
    
    func _animateToCenter() {
        UIView.animate(withDuration: animator.presentingDuration, animations: {
            self.presentingAnimation()
        }) { (finished) in
            // Presenting animation ended
            self.presentationAnimationDidFinish()
        }
    }
    
    func _hideImageView(_ imageViewHidden: Bool) {
        // Hide image view should show collection view and vice versa
        imageView.isHidden = imageViewHidden
        scrollView.isHidden = !imageViewHidden
    }
    
    func _dismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Handle Different Types of Gestures and Pans
    
    public func handleVideoTapGesture(hideControls hide: Bool) {
        didReceiveTapGesture(hideControls: hide)
    }
    
    @objc func _handleTapGesture(_ gesture: UITapGestureRecognizer) {
        if currentVideoContainer != nil || controllerIsLocked { return }
        
        // Method to override
        didReceiveTapGesture()
        
        // Delegate method
        mediaViewControllerDelegate?.photoViewerControllerDidReceiveTapGesture?(self)
        
        let indexPath: IndexPath
        
        if scrollDirection == .horizontal {
            let index = Int(scrollView.contentOffset.x / scrollView.bounds.size.width)
            indexPath = IndexPath(item: index, section: 0)
        }
        else {
            let index = Int(scrollView.contentOffset.y / scrollView.bounds.size.height)
            indexPath = IndexPath(item: index, section: 0)
        }
        
        if let cell = collectionView.cellForItem(at: indexPath) as? DTPhotoCollectionViewCell {
            
            let minimumZoomScale: CGFloat = 1.0
            let maximumZoomScale: CGFloat = cell.scrollView.maximumZoomScale
            let currentZoomScale = cell.scrollView.zoomScale
            
            if currentZoomScale > minimumZoomScale
                && currentZoomScale <= maximumZoomScale {
                // Zoom out
                cell.minimumZoomScale = minimumZoomScale
                cell.scrollView.setZoomScale(cell.scrollView.minimumZoomScale,
                                             animated: true)
            }
        }
    }
    
    @objc func _handleDoubleTapGesture(_ gesture: UITapGestureRecognizer) {
        if currentVideoContainer != nil || controllerIsLocked { return }
        // Method to override
        didReceiveDoubleTapGesture()
        
        // Delegate method
        mediaViewControllerDelegate?.photoViewerControllerDidReceiveDoubleTapGesture?(self)
        
        let indexPath: IndexPath
        
        if scrollDirection == .horizontal {
            let index = Int(scrollView.contentOffset.x / scrollView.bounds.size.width)
            indexPath = IndexPath(item: index, section: 0)
        }
        else {
            let index = Int(scrollView.contentOffset.y / scrollView.bounds.size.height)
            indexPath = IndexPath(item: index, section: 0)
        }
        
        if let cell = collectionView.cellForItem(at: indexPath) as? DTPhotoCollectionViewCell {
            // Double tap
            // imageViewerControllerDidDoubleTapImageView()
            
            let minimumZoomScale: CGFloat = 1.0
            let maximumZoomScale: CGFloat = cell.scrollView.maximumZoomScale
            let currentZoomScale = cell.scrollView.zoomScale
            
            if currentZoomScale > minimumZoomScale
                && currentZoomScale <= maximumZoomScale {
                // Zoom out
                cell.minimumZoomScale = minimumZoomScale
                cell.scrollView.setZoomScale(cell.scrollView.minimumZoomScale,
                                             animated: true)
                
            } else {
                let location = gesture.location(in: view)
                let center = cell.imageView.convert(location, from: view)
                
                // Zoom in
                cell.minimumZoomScale = minimumZoomScale
                let rect = zoomRect(for: cell.imageView, withScale: cell.scrollView.maximumZoomScale, withCenter: center)
                cell.scrollView.zoom(to: rect, animated: true)
            }
        }
    }
    
    func _frameForReferencedView() -> CGRect {
        if let referencedView = referencedView {
            if let superview = referencedView.superview {
                var frame = (superview.convert(referencedView.frame, to: view))
                
                if abs(frame.size.width - referencedView.frame.size.width) > 1 {
                    // This is workaround for bug in ios 8, everything is double.
                    frame = CGRect(x: frame.origin.x/2, y: frame.origin.y/2, width: frame.size.width/2, height: frame.size.height/2)
                }
                
                return frame
            }
        }
        
        // Work around when there is no reference view, dragging might behave oddly
        // Should be fixed in the future
        let defaultSize: CGFloat = 1
        return CGRect(x: view.frame.midX - defaultSize/2, y: view.frame.midY - defaultSize/2, width: defaultSize, height: defaultSize)
    }
    
    // Update zoom inside UICollectionViewCell
    fileprivate func _updateZoomScaleForSize(cell: DTPhotoCollectionViewCell, size: CGSize) {
        let widthScale = size.width / cell.imageView.bounds.width
        let heightScale = size.height / cell.imageView.bounds.height
        let zoomScale = min(widthScale, heightScale)
        
        cell.maximumZoomScale = zoomScale
    }
    
    fileprivate func zoomRect(for imageView: UIImageView, withScale scale: CGFloat, withCenter center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        
        // The zoom rect is in the content view's coordinates.
        // At a zoom scale of 1.0, it would be the size of the
        // imageScrollView's bounds.
        // As the zoom scale decreases, so more content is visible,
        // the size of the rect grows.
        zoomRect.size.height = imageView.frame.size.height / scale
        zoomRect.size.width  = imageView.frame.size.width  / scale
        
        // choose an origin so as to get the right center.
        zoomRect.origin.x = center.x - (zoomRect.size.width  / 2.0)
        zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0)
        
        return zoomRect
    }
    
    fileprivate func updateImageViewFrameDuringRotation() {
        if let image = imageView.image {
            let rect = AVMakeRect(aspectRatio: image.size, insideRect: view.bounds)
            //Then figure out offset to center vertically or horizontally
            let x = (view.frame.width - rect.width) / 2
            let y = (view.frame.height - rect.height) / 2
            
            imageView.frame = CGRect(x: x, y: y, width: rect.width, height: rect.height)
        }
    }
    
    @objc func _handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        if let gestureView = gesture.view {
            
            switch gesture.state {
            case .began:
                
                // Cancel gesture if tap was in a controls zone
                if isNeededToCancelDragging(gesture) {
                    gesture.state = .cancelled
                    return
                }
                
                // Delegate method
                mediaViewControllerDelegate?.photoViewerController?(self, willBeginPanGestureRecognizer: panGestureRecognizer)
                
                // Update image view when starting to drag
                updateImageView(scrollView: scrollView)
                
                // Make status bar visible when beginning to drag image view
                updateStatusBar(isHidden: false, defaultStatusBarStyle: false)
                
                // Hide collection view & display image view
                _hideImageView(false)
                
                // Method to override
                willBegin(panGestureRecognizer: panGestureRecognizer)
                
            case .changed:
                // Just need that method to ensure that controls will be hidden
                didReceiveDoubleTapGesture()
                
                let translation = gesture.translation(in: gestureView)
                imageView.center = CGPoint(x: view.center.x + translation.x,
                                           y: view.center.y + translation.y)
                
                //Change opacity of background view based on vertical distance from center
                let yDistance = CGFloat(abs(imageView.center.y - view.center.y))
                var alpha = 1.0 - yDistance/(gestureView.center.y)
                
                if alpha < 0 {
                    alpha = 0
                }
                
                backgroundView.alpha = alpha
                
                // Scale image
                // Should not go smaller than max ratio
                if let image = imageView.image, scaleWhileDragging {
                    let referenceSize = _frameForReferencedView().size
                    
                    // If alpha = 0, then scale is max ratio, if alpha = 1, then scale is 1
                    let scale = alpha
                    
                    // imageView.transform = CGAffineTransformMakeScale(scale, scale)
                    // Do not use transform to scale down image view
                    // Instead change width & height
                    if scale < 1 && scale >= 0 {
                        let maxSize = imageViewSizeForImage(image)
                        let scaleSize = CGSize(width: maxSize.width * scale, height: maxSize.height * scale)
                        
                        if scaleSize.width >= referenceSize.width || scaleSize.height >= referenceSize.height {
                            imageView.frame.size = scaleSize
                        }
                    }
                }
                
            default:
                // Animate back to center
                if backgroundView.alpha < 0.8 {
                    _dismiss()
                }
                else {
                    _animateToCenter()
                }
                
                // Method to override
                didEnd(panGestureRecognizer: panGestureRecognizer)
                
                // Delegate method
                mediaViewControllerDelegate?.photoViewerController?(self, didEndPanGestureRecognizer: panGestureRecognizer)
            }
        }
    }
    
    private func imageViewSizeForImage(_ image: UIImage?) -> CGSize {
        if let image = image {
            let rect = AVMakeRect(aspectRatio: image.size, insideRect: view.bounds)
            return rect.size
        }
        
        return CGSize.zero
    }
    
    public func isNeededToCancelDragging(_ gesture: UIPanGestureRecognizer) -> Bool {
        guard let container = currentVideoContainer else { return false }
        let controlsFrame = container.controlsViewFrame()
        let gesturePoint = gesture.location(in: view)
        if controlsFrame.contains(gesturePoint) {
            return true
        } else {
            return false
        }
    }
    
    func presentingAnimation() {
        // Hide reference view
        if automaticallyUpdateReferencedViewVisibility {
            referencedView?.isHidden = true
        }
        
        // Calculate final frame
        var destinationFrame = CGRect.zero
        destinationFrame.size = imageViewSizeForImage(imageView.image)
        
        // Animate image view to the center
        imageView.frame = destinationFrame
        imageView.center = view.center
        
        // Change status bar to black style
        updateStatusBar(isHidden: true, defaultStatusBarStyle: true)
        
        // Animate background alpha
        backgroundView.alpha = 1.0
    }
    
    private func updateStatusBar(isHidden: Bool, defaultStatusBarStyle isDefaultStyle: Bool) {
        _shouldUseStatusBarStyle = isDefaultStyle
        _shouldHideStatusBar = isHidden
        setNeedsStatusBarAppearanceUpdate()
    }
    
    func dismissingAnimation() {
        imageView.frame = _frameForReferencedView()
        backgroundView.alpha = 0
    }
    
    func presentationAnimationDidFinish() {
        // Method to override
        didEndPresentingAnimation()
        
        // Delegate method
        mediaViewControllerDelegate?.photoViewerControllerDidEndPresentingAnimation?(self)
        
        // Hide animating image view and show collection view
        _hideImageView(true)
    }
    
    func presentationAnimationWillStart() {
        // Hide collection view and show image view
        _hideImageView(false)
    }
    
    func dismissalAnimationWillStart() {
        // Update Image View (It could be resized for scaled form
        updateImageViewDismissalAnimationWillStart()
        // Hide collection view and show image view
        _hideImageView(false)
    }
    
    func dismissalAnimationDidFinish() {
        if automaticallyUpdateReferencedViewVisibility {
            //referencedView?.image = imageView.image
            referencedView?.isHidden = false
        }
    }
    
    // MARK: - Get Cropped Snapshot from Current Scale State
    
    public func getScaledPhotoSnapshot() -> UIImage? {
        guard let scrollView = currentPhotoCell?.scrollView else { return imageView.image }
        guard let image = currentPhotoCell?.imageView.image else { return imageView.image }
        
        var scrollViewHeight = scrollView.contentSize.height
        
        if scrollViewHeight > UIScreen.main.bounds.height {
            scrollViewHeight = UIScreen.main.bounds.height
        }
        
        let ratio = image.size.height / scrollViewHeight
        let origin = CGPoint(x: scrollView.contentOffset.x * ratio, y: scrollView.contentOffset.y * ratio)
        let size = CGSize(width: scrollView.bounds.size.width * ratio,
                          height: scrollView.bounds.size.height * ratio)
        let cropFrame = CGRect(origin: origin, size: size)
        return image.croppedInRect(rect: cropFrame)
    }
    
    public func getVideoSnapshot() -> UIImage? {
        guard let container = currentVideoContainer else { return imageView.image }
        
        let snapshot = container.snapshot(pauseVideo: true)
        
        if container.snapshotCropNeeded {
            return snapshot?.croppedInRect(rect: imageView.frame)
        } else {
            return snapshot
        }
    }
    
    // MARK: - Public behavior methods
    
    open func shouldOpenMediaFile(url: URL?, type: MediaFile.MediaType) {
        
    }
    
    open func didScrollToPhoto(at index: Int) {
        
    }
    
    open func didZoomOnPhoto(at index: Int, atScale scale: CGFloat) {
        
    }
    
    open func didEndZoomingOnPhoto(at index: Int, atScale scale: CGFloat) {
        
    }
    
    open func willZoomOnPhoto(at index: Int) {
        
    }
    
    open func didReceiveTapGesture(hideControls hide: Bool? = nil) {
        
    }
    
    open func didReceiveDoubleTapGesture() {
        
    }
    
    open func willBegin(panGestureRecognizer gestureRecognizer: UIPanGestureRecognizer) {
        
    }
    
    open func didEnd(panGestureRecognizer gestureRecognizer: UIPanGestureRecognizer) {
        
    }
    
    open func didEndPresentingAnimation() {
        
    }
}

// MARK: - UIViewControllerTransitioningDelegate

extension DTMediaViewerController: UIViewControllerTransitioningDelegate {
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return animator
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return animator
    }
}

// MARK: - UICollectionViewDataSource

extension DTMediaViewerController: UICollectionViewDataSource {
    
    // MARK: - Public Helpers
    
    public var currentIndex: Int {
        if scrollDirection == .horizontal {
            if scrollView.frame.width == 0 {
                return 0
            }
            return Int(scrollView.contentOffset.x / scrollView.frame.width)
        }
        else {
            if scrollView.frame.height == 0 {
                return 0
            }
            return Int(scrollView.contentOffset.y / scrollView.frame.height)
        }
    }
    
    public var zoomScale: CGFloat {
        let index = currentIndex
        let indexPath = IndexPath(item: index, section: 0)
        
        if let cell = collectionView.cellForItem(at: indexPath) as? DTPhotoCollectionViewCell {
            return cell.scrollView.zoomScale
        }
        
        return 1.0
    }
    
    // MARK: - Genuine Data Source Methods
    
    public func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
        return mediaFiles?.count ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let file = mediaFiles?[safeIndex: indexPath.row] else { return UICollectionViewCell() }
        
        switch file.type {
        case .image:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: .photoCollectionViewCellIdentifier,
                                                          for: indexPath) as! DTPhotoCollectionViewCell
            cell.delegate = self
            
            if let dataSource = mediaViewControllerDataSource,
                dataSource.numberOfItems(in: self) > 0 {
                dataSource.photoViewerController?(self,
                                                  configureCell: cell,
                                                  forPhotoAt: indexPath.row)
                return cell
                
            } else {
                cell.imageView.image = imageView.image
                return cell
            }
            
        case .mp4:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: .mp4CollectionViewCellIdentifier,
                                                          for: indexPath) as! DTMP4CollectionViewCell
            cell.delegate = self
            
            if let dataSource = mediaViewControllerDataSource,
                dataSource.numberOfItems(in: self) > 0 {
                dataSource.mediaViewerController?(self,
                                                  configureCell: cell,
                                                  forVideoAt: indexPath.row)
                return cell
                
            } else {
                return cell
            }
        case .webm:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: .webmCollectionViewCellIdentifier,
                                                          for: indexPath) as! DTWebMCollectionViewCell
            cell.delegate = self
            if let dataSource = mediaViewControllerDataSource,
                dataSource.numberOfItems(in: self) > 0 {
                dataSource.mediaViewerController?(self,
                                                  configureCell: cell,
                                                  forVideoAt: indexPath.row)
                return cell
                
            } else {
                return cell
            }
        }
    }
}

extension DTMediaViewerController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? VideoContainer else { return }
        if (!isRotating) {
            if !isOpening || openingIndex == indexPath.row {
                cell.play()
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? VideoContainer else { return }
        cell.pause()
    }
}

// MARK: - Open methods

extension DTMediaViewerController {
    // For each reuse identifier that the collection view will use, register either a class or a nib from which to instantiate a cell.
    // If a nib is registered, it must contain exactly 1 top level object which is a DTPhotoCollectionViewCell.
    // If a class is registered, it will be instantiated via alloc/initWithFrame:
    open func registerClassPhotoViewer(_ cellClass: Swift.AnyClass?) {
        collectionView.register(cellClass, forCellWithReuseIdentifier: .photoCollectionViewCellIdentifier)
    }
    
    open func registerNibForPhotoViewer(_ nib: UINib?) {
        collectionView.register(nib, forCellWithReuseIdentifier: .photoCollectionViewCellIdentifier)
    }
    
    // Update data before calling theses methods
    open func reloadData() {
        collectionView.reloadData()
    }
    
    open func insertPhotos(at indexes: [Int], completion: ((Bool) -> Void)?) {
        let indexPaths = indexPathsForIndexes(indexes: indexes)
        
        collectionView.performBatchUpdates({
            self.collectionView.insertItems(at: indexPaths)
        }, completion: completion)
    }
    
    open func deletePhotos(at indexes: [Int], completion: ((Bool) -> Void)?) {
        let indexPaths = indexPathsForIndexes(indexes: indexes)
        
        collectionView.performBatchUpdates({
            self.collectionView.deleteItems(at: indexPaths)
        }, completion: completion)
    }
    
    open func reloadPhotos(at indexes: [Int]) {
        let indexPaths = indexPathsForIndexes(indexes: indexes)
        
        collectionView.reloadItems(at: indexPaths)
    }
    
    open func movePhoto(at index: Int, to newIndex: Int) {
        let indexPath = IndexPath(item: index, section: 0)
        let newIndexPath = IndexPath(item: newIndex, section: 0)
        
        collectionView.moveItem(at: indexPath, to: newIndexPath)
    }
    
    open func scrollToPhoto(at index: Int, animated: Bool) {
        if collectionView.numberOfItems(inSection: 0) > index {
            let indexPath = IndexPath(item: index, section: 0)
            
            let position: UICollectionView.ScrollPosition
            
            if scrollDirection == .vertical {
                position = .bottom
            } else {
                position = .right
            }
            
            collectionView.scrollToItem(at: indexPath, at: position, animated: animated)
            
            if !animated {
                // Need to call these methods since scrollView delegate method won't be called when not animated
                // Method to override
                didScrollToPhoto(at: index)
                
                // Call delegate
                mediaViewControllerDelegate?.photoViewerController?(self, didScrollToPhotoAt: index)
            }
        }
    }
    
    // Helper for indexpaths
    func indexPathsForIndexes(indexes: [Int]) -> [IndexPath] {
        return indexes.map() {
            IndexPath(item: $0, section: 0)
        }
    }
}

// MARK: - DTPhotoCollectionViewCellDelegate

extension DTMediaViewerController: DTPhotoCollectionViewCellDelegate {
    
    open func collectionViewCellDidZoomOnPhoto(_ cell: DTPhotoCollectionViewCell, atScale scale: CGFloat) {
        if let indexPath = collectionView.indexPath(for: cell) {
            // Method to override
            didZoomOnPhoto(at: indexPath.row, atScale: scale)
            
            // Call delegate
            mediaViewControllerDelegate?.photoViewerController?(self, didZoomOnPhotoAtIndex: indexPath.row, atScale: scale)
        }
    }
    
    open func collectionViewCellDidEndZoomingOnPhoto(_ cell: DTPhotoCollectionViewCell, atScale scale: CGFloat) {
        if let indexPath = collectionView.indexPath(for: cell) {
            // Method to override
            didEndZoomingOnPhoto(at: indexPath.row, atScale: scale)
            
            // Call delegate
            mediaViewControllerDelegate?.photoViewerController?(self, didEndZoomingOnPhotoAtIndex: indexPath.row, atScale: scale)
        }
    }
    
    open func collectionViewCellWillZoomOnPhoto(_ cell: DTPhotoCollectionViewCell) {
        if let indexPath = collectionView.indexPath(for: cell) {
            // Method to override
            willZoomOnPhoto(at: indexPath.row)
            
            // Call delegate
            mediaViewControllerDelegate?.photoViewerController?(self, willZoomOnPhotoAtIndex: indexPath.row)
        }
    }
}
