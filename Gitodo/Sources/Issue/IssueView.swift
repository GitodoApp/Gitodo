//
//  IssueView.swift
//  Gitodo
//
//  Created by jiyeon on 5/3/24.
//

import UIKit

import RxCocoa
import RxSwift
import SnapKit

protocol IssueDelegate: AnyObject {
    func presentInfoViewController(issue: Issue)
}

class IssueView: UIView {
    
    weak var issueDelegate: IssueDelegate?
    private var viewModel: IssueViewModel?
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Components
    
    private lazy var issueTableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(IssueCell.self, forCellReuseIdentifier: IssueCell.reuseIdentifier)
        return tableView
    }()
    
    private lazy var emptyLabel = {
        let label = UILabel()
        label.text = "생성된 이슈가 없습니다 🫥"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .tertiaryLabel
        return label
    }()
    
    private lazy var loadingView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }()
    
    private lazy var loadingIndicator = UIActivityIndicatorView()
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupLayout()
        setupNotificationCenterObserver()
        bind()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup Methods
    
    private func setupLayout() {
        addSubview(issueTableView)
        issueTableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-45)
        }
        
        addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        loadingView.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { make in
            make.width.height.equalTo(50)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-45)
        }
    }
    
    private func setupNotificationCenterObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHeightChange),
            name: .AssigneeCollectionViewHeightDidUpdate,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHeightChange),
            name: .LabelCollectionViewHeightDidUpdate,
            object: nil
        )
    }
    
    @objc private func handleHeightChange(notification: Notification) {
        UIView.performWithoutAnimation { [weak self] in
            self?.issueTableView.beginUpdates()
            self?.issueTableView.endUpdates()
        }
    }
    
    private func bind() {
        issueTableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let self = self, let viewModel = viewModel else { return }
                issueDelegate?.presentInfoViewController(issue: viewModel.issue(at: indexPath))
            }).disposed(by: disposeBag)
    }
    
    func bind(with viewModel: IssueViewModel) {
        self.viewModel = viewModel
        
        viewModel.output.issues
            .map { $0.count }
            .drive(onNext: { [weak self] count in
                self?.emptyLabel.isHidden = count != 0
            }).disposed(by: disposeBag)
        
        viewModel.output.issues
            .drive(issueTableView.rx.items(
                cellIdentifier: IssueCell.reuseIdentifier,
                cellType: IssueCell.self)
            ) { _, issue, cell in
                cell.configure(with: issue)
            }.disposed(by: disposeBag)
        
        viewModel.output.isLoading
            .drive(onNext: { [weak self] isLoading in
                if isLoading {
                    self?.loadingView.isHidden = false
                    self?.loadingIndicator.startAnimating()
                } else {
                    DispatchQueue.main.async {
                        self?.loadingIndicator.stopAnimating()
                        self?.loadingView.isHidden = true
                    }
                }
            }).disposed(by: disposeBag)
    }
    
}
