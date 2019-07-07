//
//  PostRouter.swift
//  dvach
//
//  Created by Kirill Solovyov on 07/06/2019.
//  Copyright © 2019 Kirill Solovyov. All rights reserved.
//

import Foundation

// Используется как для 4 экрана с постами, так и для экрана 8 с реплаями

protocol IPostRouter {
    
    /// Нажали на "Ответить"
    func postCommentView(_ view: PostCommentView, didTapAnswerButton postNumber: String)
    
    /// Нажали на "Ответы"
    func postCommentView(_ view: PostCommentView,
                         didTapAnswersButton postNumber: String,
                         posts: [Post],
                         replies: Replies,
                         board: String,
                         thread: ThreadShortInfo)
    
    /// Нажали на "Еще"
    func postCommentView(_ view: PostCommentView,
                         didTapMoreButton post: Post,
                         thread: ThreadShortInfo,
                         boardId: String,
                         row: Int)
    
    /// Нажали на миниатюру прикрепленого файла
    func presentMediaController(source: MediaViewerManager.Source)
}

final class PostRouter: IPostRouter {
    
    // Dependencies
    weak var viewHandler: UIViewController?
    private let actionSheetFactory = PostBottomSheetFactory()
    private let mediaViewerManager = MediaViewerManager()
    
    // MARK: - IPostRouter
    
    func postCommentView(_ view: PostCommentView, didTapAnswerButton postNumber: String) {
        print("didTapAnswerButton")
    }
    
    func postCommentView(_ view: PostCommentView,
                         didTapAnswersButton postNumber: String,
                         posts: [Post],
                         replies: Replies,
                         board: String,
                         thread: ThreadShortInfo) {
        let viewController = RepliesAssembly.assemble(postId: postNumber, posts: posts, replies: replies, board: board, thread: thread)
        viewController.title = ">> \(postNumber)"

        viewHandler?.navigationController?.pushViewController(viewController, animated: true)
    }
    
    func postCommentView(_ view: PostCommentView,
                         didTapMoreButton post: Post,
                         thread: ThreadShortInfo,
                         boardId: String,
                         row: Int) {
        let bottomSheet = actionSheetFactory.createBottomSheet(post: post, threadInfo: (thread, boardId, row))
        viewHandler?.present(bottomSheet, animated: true)
    }
    
    func presentMediaController(source: MediaViewerManager.Source) {
        guard let mediaController = mediaViewerManager.mediaViewer(source: source) else { return }
        viewHandler?.present(mediaController, animated: true, completion: nil)
    }
}
