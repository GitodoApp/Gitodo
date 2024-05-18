//
//  TodoCell.swift
//  Gitodo
//
//  Created by 이지현 on 4/29/24.
//

import UIKit

import RxSwift
import SnapKit

class TodoCell: UITableViewCell {
    static let reuseIdentifier = "TodoCell"
    var viewModel: TodoCellViewModel?
    var disposeBag = DisposeBag()
    
    lazy var checkbox = {
        let imageView = UIImageView(image: UIImage(systemName: "circle"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray4
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleCheckbox))
        imageView.addGestureRecognizer(tapGesture)
        imageView.isUserInteractionEnabled = true
        imageView.tintAdjustmentMode = .normal
        return imageView
    }()
    
    private lazy var todoTextField = {
        let textField = UITextField()
        textField.font = .systemFont(ofSize: 15)
        textField.textColor = .label
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.delegate = self
        return textField
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupLayout()
        observeTextChanges()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag = DisposeBag()
        checkbox.image = UIImage(systemName: "circle")
        checkbox.tintColor = .systemGray4
        todoTextField.text = nil
        todoTextField.textColor = .label
    }
    
    private func setupLayout() {
        contentView.addSubview(checkbox)
        checkbox.snp.makeConstraints { make in
            make.height.width.equalTo(25)
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
        
        contentView.addSubview(todoTextField)
        todoTextField.snp.makeConstraints { make in
            make.leading.equalTo(checkbox.snp.trailing).offset(10)
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
    }
    
    func configure(with viewModel: TodoCellViewModel) {
        self.viewModel = viewModel
        todoTextField.text = viewModel.todo
        configureCheckbox()
    }
    
    func todoBecomeFirstResponder() {
        todoTextField.becomeFirstResponder()
    }
    
    @objc private func toggleCheckbox() {
        viewModel?.isComplete.toggle()
    }
    
    private func observeTextChanges() {
        todoTextField.addTarget(self, action: #selector(todoDidChange(_:)), for: .editingChanged)
    }
    
    @objc private func todoDidChange(_ textField: UITextField) {
        viewModel?.todo = textField.text ?? ""
    }
    
    private func configureCheckbox() {
        let isComplete = viewModel?.isComplete == true
        var tintColor = UIColor.label
        
        if let hex = viewModel?.tintColorHex {
            tintColor = UIColor(hex: hex)
        }
        
        checkbox.image = UIImage(systemName: isComplete ? "checkmark.circle" : "circle")
        checkbox.tintColor = isComplete ? tintColor : .systemGray4
        todoTextField.textColor = isComplete ? .secondaryLabel : .label
        todoTextField.isUserInteractionEnabled = !isComplete
    }
}

extension TodoCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
            viewModel?.endEditingTodo(with: textField.text)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.text?.isEmpty == false {
            viewModel?.addNewTodoItem()
            return false
        } else {
            textField.resignFirstResponder()
            return false
        }
    }
}