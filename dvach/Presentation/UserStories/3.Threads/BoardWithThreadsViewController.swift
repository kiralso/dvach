//
//  ThreadsViewController.swift
//  dvach
//
//  Created by Ruslan Timchenko on 01/06/2019.
//  Copyright © 2019 Kirill Solovyov. All rights reserved.
//

import Foundation
import UIKit

private extension CGFloat {
    static let tableViewContentInset: CGFloat = 12
    static let threadWithImageCellHeight: CGFloat = 185
    static let threadWithoutImageCellHeight: CGFloat = 125
}

protocol BoardWithThreadsView: AnyObject {
    func updateTable()
}

final class ThreadsViewController: UIViewController {
    
    // Dependencies
    private let presenter: IBoardWithThreadsPresenter
    
    // UI
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(ThreadWithImageCell.self)
        tableView.register(ThreadWithoutImageCell.self)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.contentInset = .init(top: .tableViewContentInset,
                                       left: 0,
                                       bottom: 0,
                                       right: 0)
        
        return tableView
    }()
    
    // MARK: - Initialization
    
    init(boardID: String) {
        let presenter = BoardWithThreadsPresenter(boardID: boardID)
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
        
        presenter.view = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
         setupUI()
         presenter.viewDidLoad()
    }
    
    // MARK: - Private
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

// MARK: - BoardWithThreadsView

extension ThreadsViewController: BoardWithThreadsView {
    func updateTable() {
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource

extension ThreadsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let model = presenter.dataSource[safeIndex: indexPath.row] else { return UITableViewCell() }
        switch model {
        case .withImage(let threadWithImageModel):
            let cell: ThreadWithImageCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
            cell.configure(with: threadWithImageModel)
            return cell
        case .withoutImage(let threadWithoutImageModel):
            let cell: ThreadWithoutImageCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
            cell.configure(with: threadWithoutImageModel)
            return cell
        }
    }
}

// MARK: - UITableViewDelegate

extension ThreadsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let model = presenter.dataSource[safeIndex: indexPath.row] else { return .zero }
        switch model {
        case .withImage: return .threadWithImageCellHeight
        case .withoutImage: return .threadWithoutImageCellHeight
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presenter.didSelectCell(index: indexPath.row)
    }
}

