//
//  IComponentsFactory.swift
//  Receipt
//
//  Created by Kirill Solovyov on 22.03.2018.
//  Copyright © 2018 Kirill Solovyov. All rights reserved.
//

import Foundation
import UIKit

public protocol IComponentsFactory {
    
    /// контейнер на основе стек вью
    func createStackViewContainer() -> StackViewContainer
    
    /// контейнер с тенью
    func createShadowViewContainer(with contentView: UIView, insets: UIEdgeInsets) -> ShadowViewContainer
    
    /// контейнер для контента
    func createContentContainer(content: UIView) -> UIView
    
    /// пустая вью с заданной высотой
    func createEmptyView(height: CGFloat) -> UIView
    
    /// Кнопка закрыть
    func createCloseButton(style: CloseButton.Style,
                           imageColor: UIColor?,
                           backgroundColor: UIColor?,
                           completion: @escaping () -> Void) -> CloseButton
    
    /// Горизонтальная кнопка с тремя точками
    func createHorizontalMoreButton(_ color: UIColor?, completion: @escaping () -> Void) -> HorizontalMoreButton
    
    /// Блок с кнопкой
    func createBlockWithTitle() -> BlockWithTitle
    
    /// Сепаратор
    func createSeparator() -> SeparatorView
}

extension IComponentsFactory {
    
    func createShadowViewContainer(with contentView: UIView) -> ShadowViewContainer {
        let container = ShadowViewContainer(insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
        container.contentView = contentView
        
        return container
    }
}
