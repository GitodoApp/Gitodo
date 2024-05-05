//
//  MainViewModel.swift
//  Gitodo
//
//  Created by 이지현 on 5/3/24.
//

import Foundation

import RxCocoa
import RxSwift

final class MainViewModel {
    let input: Input
    let output: Output
    
    private var tempRepo = TempRepository()
    
    struct Input {
        let reload: AnyObserver<Void>
        let toggleTodo: AnyObserver<UUID>
        let deleteTodo: AnyObserver<UUID>
    }
    
    struct Output {
        var todos: Driver<[TodoCellViewModel]>
    }
    
    private let reloadSubject = PublishSubject<Void>()
    private let toggleTodoSubject = PublishSubject<UUID>()
    private let deleteTodoSubject = PublishSubject<UUID>()
    private var todos = PublishRelay<[TodoCellViewModel]>()
    private let disposeBag = DisposeBag()
    
    init() {
        input = Input(
            reload: reloadSubject.asObserver(),
            toggleTodo: toggleTodoSubject.asObserver(),
            deleteTodo: deleteTodoSubject.asObserver()
        )
        output = Output(todos: todos.asDriver(onErrorJustReturn: []))
        
        reloadSubject.subscribe(onNext: { [weak self] in
            self?.fetchTodoList()
        })
        .disposed(by: disposeBag)
        
        toggleTodoSubject.subscribe(onNext: { [weak self] id in
            self?.toggleTodo(with: id)
        })
        .disposed(by: disposeBag)
        
        deleteTodoSubject.subscribe(onNext: { [weak self] id in
            self?.deleteTodo(with: id)
        })
        .disposed(by: disposeBag)
    }
    
    private func fetchTodoList() {
        
        let fetchedTodos = tempRepo.getRepo()
        
        let todoViewModels = fetchedTodos.map{ (todoItem) -> TodoCellViewModel in
            let viewModel = TodoCellViewModel(todoItem: todoItem, tintColorHex: 0xB5D3FF)
            viewModel.delegate = self
            return viewModel
        }.sorted {
            return !$0.isComplete || $1.isComplete
        }
        
        todos.accept(todoViewModels)
    }
    
//    func viewModel(at indexPath: IndexPath) -> TodoCellViewModel {
//        return viewModels[indexPath.row]
//    }
//    
//    var numberOfItems: Int {
//        viewModels.count
//    }
//    
//    func insert(_ todoItem: TodoItem, at indexPath: IndexPath) {
//        let newViewModel = TodoCellViewModel(todoItem: todoItem)
//        viewModels.insert(newViewModel, at: indexPath.row)
//    }
//    
//    func append(_ todoItem: TodoItem) {
//        insert(todoItem, at: .init(row: numberOfItems, section: 0))
//    }
    
    private func toggleTodo(with id: UUID) {
        tempRepo.toggleTodo(with: id)
        fetchTodoList()
    }
    
    
    private func deleteTodo(with id: UUID) {
        tempRepo.deleteTodo(with: id)
        fetchTodoList()
    }
    
//    func appendPlaceholderIfNeeded() -> Bool {
//        if numberOfItems == 0 {
//            append(.placeholderItem())
//            return true
//        }
//        
//        guard let lastItem = viewModels.last else { return false }
//        if !lastItem.todo.isEmpty {
//            append(.placeholderItem())
//            return true
//        }
//        return false
//    }
}

class TempRepository {
    private var firstRepoTodo = [
        TodoItem(todo: "끝내주게 숨쉬기", isComplete: false),
        TodoItem(todo: "간지나게 자기", isComplete: false),
        TodoItem(todo: "작살나게 밥먹기", isComplete: false)
    ]
    
    func index(with id: UUID) -> Int? {
        guard let firstIndex = firstRepoTodo.firstIndex(where: { $0.id == id }) else { return nil }
        return firstIndex
    }
    
    func getRepo() -> [TodoItem] {
        firstRepoTodo
    }
    
    func deleteTodo(with id: UUID) {
        guard let index = index(with: id) else { return }
        firstRepoTodo.remove(at: index)
    }
    
    func toggleTodo(with id: UUID) {
        guard let index = index(with: id) else { return }
        firstRepoTodo[index].isComplete.toggle()
    }
    
    func updateTodo(_ newValue: TodoItem) {
        guard let index = index(with: newValue.id) else { return }
        firstRepoTodo[index] = newValue
    }
    
}

extension MainViewModel: TodoCellViewModelDelegate {
    func todoCellViewModel(_ viewModel: TodoCellViewModel, didUpdateItem todoItem: TodoItem) {
        tempRepo.updateTodo(todoItem)
    }
}
