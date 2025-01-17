//
//  BoardsListPresenter.swift
//  dvach
//
//  Created by Kirill Solovyov on 04/06/2019.
//  Copyright © 2019 Kirill Solovyov. All rights reserved.
//

import Foundation

protocol IBoardsListPresenter {
    var dataSource: [BoardView.Model] { get }
    func viewDidLoad()
    func update(boards: [Board])
    func didSelectBoard(index: Int)
    func searchBoard(for text: String?)
}

final class BoardsListPresenter {
    
    // Dependencies
    weak var view: (BoardsListView & UIViewController)?
    
    // Properties
    private var boards: [Board]
    private var filteredBoards = [Board]()
    var dataSource = [BoardView.Model]()
    
    // MARK: - Initialization
    
    init(boards: [Board]) {
        self.boards = boards
    }
    
    // MARK: - Private
    
    private func createViewModels(from boards: [Board]) -> [BoardView.Model] {
        return boards.map {
            return BoardView.Model(title: $0.shortInfo.name,
                                   subtitle: "/\($0.shortInfo.identifier)/",
                icon: .icon(boardId: $0.shortInfo.identifier))
        }
    }
}

// MARK: - IBoardsListPresenter

extension BoardsListPresenter: IBoardsListPresenter {
    
    func viewDidLoad() {
        dataSource = createViewModels(from: boards)
        view?.updateTable()
        Analytics.logEvent("BoardsListShown", parameters: [:])
    }
    
    func update(boards: [Board]) {
        self.boards = boards
    }
    
    func didSelectBoard(index: Int) {
        let board = filteredBoards.isEmpty ? boards[index] : filteredBoards[index]
        view?.didSelectBoard(board)
        
        let viewController = BoardWithThreadsViewController(boardID: board.shortInfo.identifier)
        viewController.title = board.shortInfo.name
        view?.navigationController?.pushViewController(viewController, animated: true)
    }
    
    func searchBoard(for text: String?) {
        guard let text = text, !text.isEmpty else { return }
        filteredBoards = boards.filter {
            // TODO: - Временно из поиска удалены доски для взрослых, а также /d/ и /abu/ -
            ($0.shortInfo.name.lowercased().contains(text) || $0.shortInfo.identifier.lowercased().contains(text)) &&
            $0.shortInfo.category != .adults &&
            !($0.shortInfo.identifier == "d" || $0.shortInfo.identifier == "abu")
        }
        let viewModels = createViewModels(from: filteredBoards)
        dataSource = viewModels
        view?.updateTable()
    }
}
