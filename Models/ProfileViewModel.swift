//
//  ProfileViewModel.swift
//  MessengerApp
//
//  Created by Akdag on 1.04.2021.
//

import Foundation

enum ProfileViewModelType {
    case info , logout
}
struct ProfileViewModel {
    let viewModelType : ProfileViewModelType
    let title : String
    let handler : (() -> Void)?
}
