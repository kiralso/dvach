//
//  GeneralSettingsPresenter.swift
//  dvach
//
//  Created by Kirill Solovyov on 22/06/2019.
//  Copyright © 2019 Kirill Solovyov. All rights reserved.
//

import Foundation

protocol IGeneralSettingsPresenter {
    func viewDidLoad()
    func didChangeSafeModeSwitchValue(_ value: Bool)
}

final class GeneralSettingsPresenter {
    
    // Dependencies
    weak var view: GeneralSettingsView?
    private let appSettingsStorage = Locator.shared.appSettingsStorage()
    private let dvachService = Locator.shared.dvachService()
    
    // MARK: - Private
    
    private var nsfwViewModel: SettingsSwitcherView.Model {
        let subtitle = "Весь графический контент будет появляться размытым"
        return SettingsSwitcherView.Model(title: "Безопасный режим",
                                          subtitle: subtitle,
                                          isSwitcherOn: appSettingsStorage.isSafeMode)
    }
}

// MARK: - IGeneralSettingsPresenter

extension GeneralSettingsPresenter: IGeneralSettingsPresenter {
    
    func viewDidLoad() {
        let model = GeneralSettingsViewController.Model(nsfwViewModel: nsfwViewModel)
        view?.update(model: model)
    }
    
    func didChangeSafeModeSwitchValue(_ value: Bool) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        Analytics.logEvent("SafeModeSwitchDidChangeValue", parameters: [:])        
        appSettingsStorage.isSafeMode = value
    }
}
