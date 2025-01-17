//
//  PostAssembly.swift
//  dvach
//
//  Created by Kirill Solovyov on 07/06/2019.
//  Copyright © 2019 Kirill Solovyov. All rights reserved.
//

import Foundation

final class PostAssembly {
    
    static func assemble(board: String, thread: ThreadShortInfo, postNumber: String? = nil) -> UIViewController {
        let router = PostRouter()
        let presenter = PostPresenter(router: router, board: board, thread: thread, postNumber: postNumber)
        let viewController = PostViewController(presenter: presenter)
        
        presenter.view = viewController
        router.viewHandler = viewController
        
        return viewController
    }
}
