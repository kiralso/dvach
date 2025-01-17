//
//  Extension+UIDevice.swift
//  dvach
//
//  Created by Ruslan Timchenko on 18/06/2019.
//  Copyright © 2019 Kirill Solovyov. All rights reserved.
//

import Foundation

extension UIDevice {
    var hasNotch: Bool {
        let bottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        return bottom > 0
    }
    
    var isPortrait: Bool {
        let size = UIScreen.main.bounds.size
        if size.width < size.height {
            return true
        } else {
            return false
        }
    }
}
