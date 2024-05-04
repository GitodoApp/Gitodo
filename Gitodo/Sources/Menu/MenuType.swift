//
//  MenuType.swift
//  Gitodo
//
//  Created by jiyeon on 5/4/24.
//

import Foundation

enum MenuType: CaseIterable {
    case repositorySettings
    case contact
    case logout
    
    var title: String {
        switch self {
        case .repositorySettings: "레포지토리 설정"
        case .contact: "문의하기"
        case .logout: "로그아웃"
        }
    }
    
    var symbol: String {
        switch self {
        case .repositorySettings: "folder"
        case .contact: "questionmark.circle"
        case .logout: "door.left.hand.open"
        }
    }
}
