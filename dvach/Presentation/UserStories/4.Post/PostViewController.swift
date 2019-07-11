//
//  PostViewController.swift
//  dvach
//
//  Created by Kirill Solovyov on 07/06/2019.
//  Copyright © 2019 Kirill Solovyov. All rights reserved.
//

import Foundation
import KafkaRefresh

protocol PostView: AnyObject {
    func updateTable(scrollTo indexPath: IndexPath?)
    func showPlaceholder(text: String)
    func endRefreshing(indexPath: IndexPath?)
}

final class PostViewController: UIViewController {
    
    // Dependencies
    private let presenter: IPostViewPresenter
    private let componentsFactory = Locator.shared.componentsFactory()
    
    // Properties
    private var startRefreshTime = Date().timeIntervalSince1970
    private var deltaRefreshTime: TimeInterval {
        return Date().timeIntervalSince1970 - startRefreshTime
    }
    private var closeButtonStyle: CloseButton.Style {
        return (navigationController?.viewControllers.count ?? 0 > 1) ? .pop : .dismiss
    }
    private var visibleRows = [IndexPath]()
    
    // UI
    private lazy var closeButton = componentsFactory.createCloseButton(style: closeButtonStyle,
                                                                       imageColor: nil,
                                                                       backgroundColor: nil) { [weak self] in
        guard let self = self else { return }
        self.showNavigation()
        switch self.closeButtonStyle {
        case .pop: self.navigationController?.popViewController(animated: true)
        case .dismiss: self.dismiss(animated: true, completion: nil)
        }
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(PostCommentWithMediaCell.self)
        tableView.register(PostCommentWithoutMediaCell.self)
        tableView.register(ContextAdCell.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 600
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.alpha = 0.0
        tableView.footRefreshControl = refreshControll
        
        return tableView
    }()
    private lazy var refreshControll: KafkaReplicatorFooter = {
        let refresh = KafkaReplicatorFooter()
        refresh.themeColor = .n7Blue
        refresh.refreshHandler = { [weak self] in
            self?.refreshThread()
        }
        return refresh
    }()
    private lazy var placeholder = PlaceholderView()
    private lazy var skeleton = SkeletonPostView.fromNib()
    private var popRecognizer: SwipeToBackRecognizer?
    
    private var heightDictionary: [Int : CGFloat] = [:]

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - Initialization
    
    init(presenter: IPostViewPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackBarButton()
        setupPopRecognizer()
        setupUI()
        presenter.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.setNavigationBarHidden(true, animated: animated)
        skeleton.update(state: .active)
    }
    
    // MARK: - Private
    
    private func setupUI() {
        view.backgroundColor = .white
        extendedLayoutIncludesOpaqueBars = true
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        view.addSubview(skeleton)
        skeleton.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        view.addSubview(placeholder)
        placeholder.snp.makeConstraints { $0.edges.equalToSuperview() }
        placeholder.isHidden = true
        
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { $0.top.trailing.equalToSuperview().inset(CGFloat.inset16) }
    }
    
    private func setupBackBarButton() {
        let backItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        backItem.tintColor = .n1Gray
        navigationItem.backBarButtonItem = backItem
    }
    
    private func setupPopRecognizer() {
        guard let controller = navigationController else { return }
        popRecognizer = SwipeToBackRecognizer(controller: controller)
        controller.interactivePopGestureRecognizer?.delegate = popRecognizer
    }
    
    private func hideSkeleton() {
        skeleton.update(state: .nonactive)
        view.skeletonAnimation(skeletonView: skeleton, mainView: tableView)
    }
    
    private func showNavigation() {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    private func updateTable(indexPath: IndexPath?) {
        tableView.reloadData()
        if let indexPath = indexPath, indexPath.row > 0 {
            tableView.scrollToRow(at: indexPath,
                                  at: .middle,
                                  animated: false)
        }
        hideSkeleton()
    }
    
    // MARK: - Actions
    
    @objc private func refreshThread() {
        startRefreshTime = Date().timeIntervalSince1970
        presenter.refresh()
    }
}

// MARK: - PostView

extension PostViewController: PostView {
    
    func updateTable(scrollTo indexPath: IndexPath?) {
        updateTable(indexPath: indexPath)
    }
    
    func showPlaceholder(text: String) {
        placeholder.configure(with: text)
        placeholder.isHidden = false
        hideSkeleton()
    }
    
    func endRefreshing(indexPath: IndexPath?) {
        if deltaRefreshTime < 2 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.updateTable(scrollTo: indexPath)
                self.refreshControll.endRefreshing()
            }
        } else {
            updateTable(scrollTo: indexPath)
            refreshControll.endRefreshing()
        }
    }
}

// MARK: - UITableViewDataSource

extension PostViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch presenter.dataSource[indexPath.row] {
        case .post(let viewModel):
            
            if viewModel.fileURLs.isEmpty {
                let cell: PostCommentWithoutMediaCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                cell.prepareForReuse()
                cell.configure(with: viewModel)
                cell.containedView.delegate = self
                if indexPath.row == presenter.dataSource.count - 1 {
                    cell.containedView.removeBottomSeparator()
                }
                return cell
            } else {
                let cell: PostCommentWithMediaCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                cell.prepareForReuse()
                cell.configure(with: viewModel)
                cell.containedView.delegate = self
                if indexPath.row == presenter.dataSource.count - 1 {
                    cell.containedView.removeBottomSeparator()
                }
                return cell
            }
            
        case .ad(let adView):
            let cell: ContextAdCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
            cell.containedView.addSubview(adView)
            adView.snp.makeConstraints { $0.edges.equalToSuperview() }
            return cell
        }
    }
}

// MARK: - UITableViewDelegate

extension PostViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        heightDictionary[indexPath.row] = cell.frame.size.height
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let height = heightDictionary[indexPath.row]
        return height ?? UITableView.automaticDimension
    }
}

// MARK: - PostCommentViewDelegate

extension PostViewController: PostCommentViewDelegate {
    
    func postCommentView(_ view: PostCommentViewContainer,
                         didTapFile index: Int,
                         postIndex: Int,
                         imageViews: [UIImageView]) {
        presenter.didTapFile(index: index,
                             postIndex: postIndex,
                             imageViews: imageViews)
    }
    
    func postCommentView(_ view: PostCommentViewContainer, didTapURL url: URL) {
        presenter.postCommentView(view, didTapURL: url)
    }
    
    func postCommentView(_ view: PostCommentViewContainer, didTapAnswerButton postNumber: String) {
        presenter.postCommentView(view, didTapAnswerButton: postNumber)
    }
    
    func postCommentView(_ view: PostCommentViewContainer, didTapAnswersButton postNumber: String) {
        presenter.postCommentView(view, didTapAnswersButton: postNumber)
        showNavigation()
    }
    
    func postCommentView(_ view: PostCommentViewContainer, didTapMoreButton postNumber: String) {
        presenter.postCommentView(view, didTapMoreButton: postNumber)
    }
}
