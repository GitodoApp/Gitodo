//
//  RepositorySettingsView.swift
//  Gitodo
//
//  Created by jiyeon on 4/27/24.
//

import UIKit

import RxCocoa
import RxSwift
import SnapKit

protocol RepositorySettingsDelegate: AnyObject {
    func presentAlertViewController(completion: @escaping (() -> Void))
    func presentRepositoryInfoViewController(repository: MyRepo)
}

class RepositorySettingsView: UIView {
    
    private var viewModel: RepositorySettingsViewModel?
    private let disposeBag = DisposeBag()
    weak var delegate: RepositorySettingsDelegate?
    
    private let insetFromSuperView: CGFloat = 20.0
    private let insetFromContentSuperViewTop: CGFloat = 10.0
    private let offsetFromPreviewView: CGFloat = 10.0
    private let offsetFromOtherView: CGFloat = 25.0
    private let offsetFromFriendView: CGFloat = 10.0
    private let heightForRow: CGFloat = 50.0
    private var repoTableViewHeightConstraint: Constraint?
    private var deletedRepoTableViewHeightConstraint: Constraint?
    
    // MARK: - UI Components
    
    private lazy var previewView = {
        let collectionView = RepoCollectionView()
        collectionView.delegate = self
        return collectionView
    }()
    
    private lazy var scrollView = UIScrollView()
    
    private lazy var contentView = UIView()
    
    private lazy var repoLabel = createLabel(withText: "할 일을 관리하고 싶은 레포지토리를 선택하세요")
    
    private lazy var repoTableView = {
        let tableView = createTableView()
        tableView.register(RepositoryCell.self, forCellReuseIdentifier: RepositoryCell.reuseIdentifier)
        return tableView
    }()
    
    private lazy var deletedRepoLabel = {
        let label = createLabel(withText: "원격 저장소에서 삭제된 레포지토리")
        return label
    }()
    
    private lazy var deletedRepoTableView = {
        let tableView = createTableView()
        tableView.register(RepositoryCell.self, forCellReuseIdentifier: RepositoryCell.reuseIdentifier)
        tableView.setEditing(true, animated: false)
        return tableView
    }()
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .secondarySystemBackground
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupLayout() {
        addSubview(previewView)
        previewView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(insetFromSuperView)
            make.height.equalTo(80)
        }
        
        addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(previewView.snp.bottom).offset(offsetFromPreviewView)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.snp.width)
        }
        
        contentView.addSubview(repoLabel)
        repoLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(insetFromContentSuperViewTop)
            make.leading.trailing.equalToSuperview().inset(insetFromSuperView)
        }
        
        contentView.addSubview(repoTableView)
        repoTableView.snp.makeConstraints { make in
            make.top.equalTo(repoLabel.snp.bottom).offset(offsetFromFriendView)
            make.leading.trailing.equalToSuperview().inset(insetFromSuperView)
            self.repoTableViewHeightConstraint = make.height.equalTo(0).constraint
        }
        
        contentView.addSubview(deletedRepoLabel)
        deletedRepoLabel.snp.makeConstraints { make in
            make.top.equalTo(repoTableView.snp.bottom).offset(offsetFromOtherView)
            make.leading.equalToSuperview().inset(insetFromSuperView)
        }
        
        contentView.addSubview(deletedRepoTableView)
        deletedRepoTableView.snp.makeConstraints { make in
            make.top.equalTo(deletedRepoLabel.snp.bottom).offset(offsetFromFriendView)
            make.leading.trailing.equalToSuperview().inset(insetFromSuperView)
            self.deletedRepoTableViewHeightConstraint = make.height.equalTo(0).constraint
            make.bottom.equalToSuperview().inset(insetFromSuperView)
        }
    }
    
    func bind(with viewModel: RepositorySettingsViewModel) {
        self.viewModel = viewModel
        
        viewModel.output.repos
            .map { $0.filter { $0.isPublic } }
            .drive { [weak self] repos in
                guard let self = self else { return }
                previewView.repos = repos
            }.disposed(by: disposeBag)
        
        let repos = viewModel.output.repos
            .map { $0.filter { !$0.isDeleted } }
        
        repos
            .drive(repoTableView.rx.items(cellIdentifier: RepositoryCell.reuseIdentifier, cellType: RepositoryCell.self)) { _, repo, cell in
                cell.configure(withName: repo.fullName)
            }.disposed(by: disposeBag)

        repos
            .map { CGFloat($0.count) * self.heightForRow }
            .drive(onNext: { [weak self] height in
                guard let self = self else { return }
                repoTableViewHeightConstraint?.update(offset: height)
                repoTableView.layoutIfNeeded() // 즉시 레이아웃 업데이트
            }).disposed(by: disposeBag)
        
        let deletedRepos = viewModel.output.repos
            .map { $0.filter { $0.isDeleted } }
        
        deletedRepos
            .drive(deletedRepoTableView.rx.items(cellIdentifier: RepositoryCell.reuseIdentifier, cellType: RepositoryCell.self)) { _, repo, cell in
                cell.configure(withName: repo.fullName)
            }.disposed(by: disposeBag)
        
        deletedRepos
            .map { CGFloat($0.count) * self.heightForRow }
            .drive(onNext: { [weak self] height in
                guard let self = self else { return }
                deletedRepoTableView.isHidden = height == 0
                deletedRepoTableViewHeightConstraint?.update(offset: height)
                deletedRepoTableView.layoutIfNeeded() // 즉시 레이아웃 업데이트
            }).disposed(by: disposeBag)
    }
    
}

extension RepositorySettingsView {
    
    private func createLabel(withText text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .darkGray
        label.font = .systemFont(ofSize: 13)
        return label
    }
    
    private func createTableView() -> UITableView {
        let tableView = UITableView()
        tableView.rowHeight = heightForRow
        tableView.separatorStyle = .none
        tableView.clipsToBounds = true
        tableView.layer.cornerRadius = 10
        tableView.backgroundColor = .systemBackground
        tableView.isScrollEnabled = false
        return tableView
    }
    
}

extension RepositorySettingsView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let viewModel = viewModel else { return }
        delegate?.presentRepositoryInfoViewController(repository: viewModel.repo(at: indexPath))
    }
    
}
