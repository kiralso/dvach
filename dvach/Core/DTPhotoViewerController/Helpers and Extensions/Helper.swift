//
//  Helper.swift
//  dvach
//
//  Created by Ruslan Timchenko on 18/06/2019.
//  Copyright © 2019 Kirill Solovyov. All rights reserved.
//

import QuartzCore

func clip<T : Comparable>(_ x0: T, _ x1: T, _ v: T) -> T {
    return max(x0, min(x1, v))
}

func lerp<T : FloatingPoint>(_ v0: T, _ v1: T, _ t: T) -> T {
    return v0 + (v1 - v0) * t
}
