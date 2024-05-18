//
//  TodoView.swift
//  Gitodo
//
//  Created by 이지현 on 5/17/24.
//

import UIKit

import RxCocoa
import RxSwift
import SnapKit

class TodoView: UIView {
    private var viewModel: TodoViewModel?
    private let disposeBag = DisposeBag()
    
    private lazy var todoTableView = {
        let view = UITableView()
        view.separatorStyle = .none
        view.rowHeight = 46
        view.register(TodoCell.self, forCellReuseIdentifier: TodoCell.reuseIdentifier)
        view.keyboardDismissMode = .interactive
        return view
    }()
    
    private lazy var todoAddButton = {
        let button = UIButton()
        button.tintAdjustmentMode = .normal
        button.setImage(UIImage(systemName: "plus.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)), for: .normal)
        button.setImage(UIImage(systemName: "plus.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)), for: .highlighted)
        button.setTitle(" 할 일 추가", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.tintColor = .init(hex: PaletteColor.blue1.hex)
        button.setTitleColor(.init(hex: PaletteColor.blue1.hex), for: .normal)
        button.addTarget(self, action: #selector(todoAddButtonTapped), for: .touchUpInside)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupLayout()
        bind()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout() {
        addSubview(todoTableView)
        todoTableView.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
        }
        
        addSubview(todoAddButton)
        todoAddButton.snp.makeConstraints { make in
            make.top.equalTo(todoTableView.snp.bottom).offset(10)
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).inset(10)
        }
    }
    
    @objc private func todoAddButtonTapped() {
        viewModel?.input.appendTodo.onNext(())
    }
    
    private func bind() {
        todoTableView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)
        
    }
    
    func bind(with viewModel: TodoViewModel) {
        self.viewModel = viewModel
        
        viewModel.output.todos
            .map({
                $0.sorted {
                    if $0.isComplete == $1.isComplete {
                        return $0.statusChangedAt < $1.statusChangedAt
                    }
                    return !$0.isComplete && $1.isComplete
                }
            })
            .drive(todoTableView.rx.items(cellIdentifier: TodoCell.reuseIdentifier, cellType: TodoCell.self)) { [weak self] index, todo, cell in
                cell.selectionStyle = .none
                cell.configure(with: todo)
                cell.checkbox.rx.tapGesture()
                    .when(.recognized)
                    .subscribe(onNext: { _ in
                        self?.viewModel?.input.toggleTodo.onNext(todo.id)
                    })
                    .disposed(by: cell.disposeBag)
            }.disposed(by: disposeBag)
        
        viewModel.output.makeFirstResponder
            .drive(onNext: { [weak self] indexPath in
                guard let indexPath,
                      let cell = self?.todoTableView.cellForRow(at: indexPath) as? TodoCell else { return }
                cell.todoBecomeFirstResponder()
            }).disposed(by: disposeBag)
    }
    
    func setAddButtonTintColor(_ color: UIColor) {
        todoAddButton.setTitleColor(color, for: .normal)
        todoAddButton.tintColor = color
    }
}

extension TodoView: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .normal, title: "Delete") { [weak self] action, view, completionHandler in
            guard let cell = tableView.cellForRow(at: indexPath) as? TodoCell,
                    let id = cell.viewModel?.id else { return }
            self?.viewModel?.input.deleteTodo.onNext(id)
        }
        deleteAction.backgroundColor = .systemGray4
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        
        return configuration
    }
    
}