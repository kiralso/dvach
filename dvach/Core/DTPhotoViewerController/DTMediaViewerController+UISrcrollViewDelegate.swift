//
//  DTMediaViewerController+UISrcrollViewDelegate.swift
//  dvach
//
//  Created by Ruslan Timchenko on 18/06/2019.
//  Copyright © 2019 Kirill Solovyov. All rights reserved.
//

import UIKit

// MARK: - UICollectionViewDelegateFlowLayout

extension DTMediaViewerController: UICollectionViewDelegateFlowLayout {
    
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        mediaViewControllerDelegate?.photoViewerController?(self, scrollViewDidScroll: scrollView)
    }
    
    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        let index = currentIndex
        
        // Method to override
        didScrollToPhoto(at: index)
        
        // Call delegate
        mediaViewControllerDelegate?.photoViewerController?(self, didScrollToPhotoAt: index)
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
    
    open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    open func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateFrameFor(view.frame.size)
        
        // Disable pan gesture if zoom scale is not 1
        if scrollView.zoomScale != 1 {
            panGestureRecognizer.isEnabled = false
        }
        else {
            panGestureRecognizer.isEnabled = true
        }
    }
    
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if isNeededToCancelDragging(scrollView.panGestureRecognizer) {
            scrollView.panGestureRecognizer.isEnabled = false
            scrollView.panGestureRecognizer.isEnabled = true
        }
    }
    
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            let index = currentIndex
            didScrollToPhoto(at: index)
            
            // Call delegate
            mediaViewControllerDelegate?.photoViewerController?(self, didScrollToPhotoAt: index)
        }
    }
    
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = currentIndex
        didScrollToPhoto(at: index)
        
        // Call delegate
        mediaViewControllerDelegate?.photoViewerController?(self, didScrollToPhotoAt: index)
    }
    
    // MARK: - Helpers
    
    fileprivate func _updateZoomScaleForSize(_ size: CGSize) {
        let widthScale = size.width / imageView.bounds.width
        let heightScale = size.height / imageView.bounds.height
        let zoomScale = min(widthScale, heightScale)
        
        scrollView.maximumZoomScale = zoomScale
    }
    
    fileprivate func zoomRectForScrollView(_ scrollView: UIScrollView, withScale scale: CGFloat, withCenter center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        
        // The zoom rect is in the content view's coordinates.
        // At a zoom scale of 1.0, it would be the size of the
        // imageScrollView's bounds.
        // As the zoom scale decreases, so more content is visible,
        // the size of the rect grows.
        zoomRect.size.height = scrollView.frame.size.height / scale
        zoomRect.size.width  = scrollView.frame.size.width  / scale
        
        // choose an origin so as to get the right center.
        zoomRect.origin.x = center.x - (zoomRect.size.width  / 2.0)
        zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0)
        
        return zoomRect
    }
    
    fileprivate func updateFrameFor(_ size: CGSize) {
        
        let y = max(0, (size.height - imageView.frame.height) / 2)
        let x = max(0, (size.width - imageView.frame.width) / 2)
        
        imageView.frame.origin = CGPoint(x: x, y: y)
    }
    
    // Update image view image
    func updateImageView(scrollView: UIScrollView) {
        let index = currentIndex
        
        // Update image view before pan gesture happens
        if let dataSource = mediaViewControllerDataSource, dataSource.numberOfItems(in: self) > 0 {
            dataSource.photoViewerController(self,
                                             configurePhotoAt: index,
                                             withImageView: imageView)
            if let _ = currentVideoContainer {
                imageView.image = getVideoSnapshot()
            } else {
                imageView.image = getScaledPhotoSnapshot()
            }
        }
        
        // Change referenced image view
        if let view = mediaViewControllerDataSource?.photoViewerController?(self,
                                                         referencedViewForPhotoAt: index) {
            referencedView = view
        }
    }
    
    func updateImageViewDismissalAnimationWillStart() {
        if let dataSource = mediaViewControllerDataSource, dataSource.numberOfItems(in: self) > 0 {
            let index = currentIndex
            dataSource.photoViewerController(self,
                                             configurePhotoAt: index,
                                             withImageView: imageView)
        }
    }
}
