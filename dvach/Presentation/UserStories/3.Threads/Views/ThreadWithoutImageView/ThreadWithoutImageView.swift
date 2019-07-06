//
//  ThreadWithoutImageView.swift
//  dvach
//
//  Created by Ruslan Timchenko on 01/06/2019.
//  Copyright © 2019 Kirill Solovyov. All rights reserved.
//

import Foundation
import UIKit

typealias ThreadWithoutImageCell = TableViewContainerCellBase<ThreadWithoutImageView>

final class ThreadWithoutImageView: UIView, ConfigurableView, ReusableView, PressStateAnimatable {
    
    typealias ConfigurationModel = Model
    
    // Model
    struct Model {
        let subjectTitle: String
        let commentTitle: String
        let postsCountTitle: String
    }
    
    // Outlets
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var postsCountLabel: UILabel!
    @IBOutlet weak var threadView: UIView!
    
    // Constraints
    @IBOutlet weak var commentLabelTopConstraint: NSLayoutConstraint!
    
    // Layers
    private var viewShadowLayer: CAShapeLayer!

    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        enablePressStateAnimation()
        subjectLabel.textColor = .n1Gray
        commentLabel.textColor = .n1Gray
        postsCountLabel.textColor = .n7Blue
        
        threadView.layer.cornerRadius = 12
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if viewShadowLayer == nil {
            viewShadowLayer = CAShapeLayer()
            layer.insertSublayer(viewShadowLayer, at: 0)
        }
        
        viewShadowLayer.addThreadShadow(aroundRoundedRect: threadView.frame)
    }
    
    // MARK: - ConfigurableView
    
    func configure(with model: ThreadWithoutImageView.Model) {
        subjectLabelValueWillBeChanged(with: model.subjectTitle)
        subjectLabel.text = model.subjectTitle
        commentLabel.text = model.commentTitle
        postsCountLabel.text = model.postsCountTitle
    }

    // MARK: - ReusableView
    
    func prepareForReuse() {
        subjectLabel.text = nil
        commentLabel.text = nil
        postsCountLabel.text = nil
    }
}

// MARK: - Constraints Configuration

extension ThreadWithoutImageView {
    fileprivate func subjectLabelValueWillBeChanged(with value: String) {
        if value == "" {
            subjectLabel.isHidden = true
            commentLabelTopConstraint.constant = 8.0
        } else {
            subjectLabel.isHidden = false
            commentLabelTopConstraint.constant = 25.0
        }
    }
}
