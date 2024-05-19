//
//  MainViewController.swift
//  Gitodo
//
//  Created by 이지현 on 4/25/24.
//

import UIKit

class MainViewController: BaseViewController<MainView>, BaseViewControllerProtocol {

    private let viewModel: MainViewModel
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()
        hideKeyboardWhenTappedAround()
        contentView.bind(with: viewModel)
        contentView.setIssueDelegate(self)
        NotificationCenter.default.addObserver(self, selector: #selector(handleRepoOrderChange), name: .RepositoryOrderDidUpdate, object: nil)
        
        if UserDefaultsManager.isFirst {
            UserDefaultsManager.isFirst = false
            let repositorySettingsViewController = RepositorySettingsViewController()
            navigationController?.pushViewController(repositorySettingsViewController, animated: true)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(handleAccessTokenExpire), name: .AccessTokenDidExpire, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        viewModel.input.viewWillAppear.onNext(())
    }
    
    init(viewModel: MainViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupNavigationBar() {
        setTitle("Gitodo",at: .left, font: .systemFont(ofSize: 20, weight: .bold))
        Task {
            do {
                let me = try await APIManager.shared.fetchMe()
                DispatchQueue.main.async {
                    self.setProfileImageView(url: URL(string:me.avatarUrl))
                }
            } catch {
                print("실패: \(error.localizedDescription)")
            }
        }
        setProfileImageViewAction(#selector(handleProfileImageViewTap))
    }
    
    @objc private func handleProfileImageViewTap(_ gesture: UITapGestureRecognizer) {
        guard let imageView = gesture.view as? SymbolCircleView else { return }
        
        let menuViewController = MenuViewController()
        menuViewController.delegate = self
        menuViewController.modalPresentationStyle = .popover
        
        if let popoverController = menuViewController.popoverPresentationController {
            popoverController.sourceView = imageView
            popoverController.sourceRect = CGRect(x: imageView.bounds.midX, y: imageView.bounds.midY + 100, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
            popoverController.delegate = self
        }
        
        present(menuViewController, animated: true)
    }
    
    @objc private func handleRepoOrderChange() {
        viewModel.input.viewWillAppear.onNext(())
    }
    
    @objc private func handleAccessTokenExpire() {
        UserDefaultsManager.isLogin = false
        guard let window = view.window else { return }
        window.rootViewController = LoginViewController()
    }
    
}

extension MainViewController: MenuDelegate {
    
    func pushViewController(_ menu: MenuType) {
        switch menu {
        case .repositorySettings:
            let repositorySettingsViewController = RepositorySettingsViewController()
            navigationController?.pushViewController(repositorySettingsViewController, animated: true)
        case .contact:
            print("문의하기")
        case .logout:
            presentAlertViewController()
        }
    }
    
    private func presentAlertViewController() {
        let alertController = UIAlertController(
            title: "",
            message: "모든 설정 및 할 일이 삭제됩니다.",
            preferredStyle: .alert
        )
        
        let deleteAction = UIAlertAction(title: "로그아웃", style: .destructive) { [weak self] _ in
            // 모든 레포지토리 삭제
            self?.viewModel.input.resetAllRepository.onNext(())
            // 액세스 토큰 삭제 및 설정 초기화
            LoginManager.shared.deleteAccessToken()
            UserDefaultsManager.isLogin = false
            UserDefaultsManager.isFirst = true
            // 화면 이동
            let loginViewController = LoginViewController()
            self?.view.window?.rootViewController = UINavigationController(rootViewController: loginViewController)
        }
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
}

extension MainViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
}

extension MainViewController: IssueDelegate {
    
    func presentInfoViewController(issue: Issue) {
        let issueInfoViewController = IssueInfoViewController()
        issueInfoViewController.issue = issue
        present(issueInfoViewController, animated: true)
    }
    
}
