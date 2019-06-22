//
//  AboutPresenter.swift
//  dvach
//
//  Created by Kirill Solovyov on 22/06/2019.
//  Copyright © 2019 Kirill Solovyov. All rights reserved.
//

import Foundation

protocol IAboutPresenter {
    func viewDidLoad()
    func didTapContactUs()
    func didTapRateUs()
}

final class AboutPresenter {
    
    // Dependencies
    weak var view: (AboutView & UIViewController)?
    
    // MARK: - Private
    
    private var viewModel: AboutViewController.ViewModel {
        return AboutViewController.ViewModel(infoViewModel: infoViewModel,
                                             rulesViewModel: rulesBlockModel,
                                             newsViewModel: newsBlockModel)
    }
    
    private var infoViewModel: AppInfoView.Model {
        guard let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") else {
            return AppInfoView.Model(version: "Версия 1.0")
        }
        return AppInfoView.Model(version: "Версия \(version)")
    }
    
    private var rulesBlockModel: (BlockWithTitle.Model, String) {
        let rulesBlockModel = BlockWithTitle.Model(title: "Правила", buttonTitle: nil)
        let text = "- Рекламные баннеры будут появляться при постинге, также в тредах вы можете встретить контекстную рекламу. Отключить все это можно купив полную версию либо оформив подписку.\n\n- Политика Apple обязывает нас показывать баннер с предупреждениями об опасном контенте, без него это приложение бы не смогло существовать в сторе. Просим отнестись с пониманием (сами бы его с удовольствем выпилили).\n\n- Все просьбы и предложения можно обсудить в нашем телеграм-канале"
        
        return (rulesBlockModel, text)
    }
    
    private var newsBlockModel: (BlockWithTitle.Model, String) {
        let rulesBlockModel = BlockWithTitle.Model(title: "Новости проекта", buttonTitle: nil)
        let text = "Всем привет, мы наконец выкатили первую версию.\n\nНадеемся вам понравится. Проект только в начале пути, скоро будут новые фичи, которых мы все очень ждем."
        
        return (rulesBlockModel, text)
    }
}

// MARK: - IAboutPresenter

extension AboutPresenter: IAboutPresenter {
    
    func viewDidLoad() {
        view?.update(model: viewModel)
    }
    
    func didTapContactUs() {
        guard let url = URL(string: "tg://resolve?domain=dvachios") else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            let alert = UIAlertController(title: "Ошибочка вышла", message: "Установим телеграм?", preferredStyle: .alert)
            let action = UIAlertAction(title: "Да", style: .default, handler: { (UIAlertAction) in
                if let urlAppStore = URL(string: "itms-apps://itunes.apple.com/app/id686449807"),
                    UIApplication.shared.canOpenURL(urlAppStore) {
                    UIApplication.shared.open(urlAppStore, options: [:], completionHandler: nil)
                }
                
            })
            let actionCancel = UIAlertAction(title: "Нет", style: .cancel, handler: nil)
            alert.addAction(action)
            alert.addAction(actionCancel)
            view?.present(alert, animated: true)
        }
    }
    
    func didTapRateUs() {
    
    }
}
