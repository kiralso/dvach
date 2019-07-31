//
//  ScrollButton.swift
//  dvach
//
//  Created by Kirill Solovyov on 31/07/2019.
//  Copyright © 2019 Kirill Solovyov. All rights reserved.
//

import Foundation

private extension CGSize {
    static let ovalSize = CGSize(width: 35, height: 35)
    static let arrowSize = CGSize(width: 20, height: 20)
}

protocol ScrollButtonDelegate: AnyObject {
    func scrollButtonDidTapped()
}

final class ScrollButton: UIView, PressStateAnimatable {
    
    enum Direction {
        case up
        case down
    }
    
    // Properties
    weak var delegate: ScrollButtonDelegate?
    var currentDirection: Direction = .down
    
    // UI
    private lazy var oval: UIView = {
        let view = UIView()
        view.backgroundColor = .n2Gray
        view.alpha = 0.7
        
        return view
    }()
    
    private lazy var arrow: UIImageView = {
        let image = UIImage(named: "downArrow")?.withRenderingMode(.alwaysTemplate)
        let arrow = UIImageView(image: image)
        arrow.tintColor = .white
        arrow.alpha = 0.7
        
        return arrow
    }()
    
    // MARK: - Initialization
    
    init() {
        super.init(frame: .zero)
        setupUI()
        enableTapping(true)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        oval.makeRounded()
    }
    
    // MARK: - Public
    
    func change(direction: Direction) {
        guard currentDirection != direction else { return }
        currentDirection = direction
        enableTapping(false)
        
        switch direction {
        case .down:
            UIView.animate(withDuration: 0.3, animations: {
                self.arrow.transform = .identity
            })
        case .up:
            UIView.animate(withDuration: 0.3, animations: {
                self.arrow.transform = CGAffineTransform(rotationAngle: .pi)
            })
        }
        enableTapping(true)
    }
    
    // MARK: - Private
    
    private func setupUI() {
        addSubview(oval)
        oval.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.size.equalTo(CGSize.ovalSize)
        }
        oval.addSubview(arrow)
        arrow.snp.makeConstraints {
            $0.size.equalTo(CGSize.arrowSize)
            $0.center.equalToSuperview()
        }
    }
    
    private func enableTapping(_ isEnabled: Bool) {
        if isEnabled {
            enablePressStateAnimation { [weak self] in
                self?.delegate?.scrollButtonDidTapped()
            }
        } else {
            disablePressStateAnimation()
        }
    }
}
