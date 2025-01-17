//
//  Board.swift
//  dvach
//
//  Created by Kirill Solovyov on 30/05/2019.
//  Copyright © 2019 Kirill Solovyov. All rights reserved.
//

import Foundation
import SwiftyJSON

struct Board {
    let shortInfo: BoardShortInfo
    let pages: Int?
    let boardSpeed: Int?
    let currentPage: Int?
    let bumpLimit: Int
    let defaultName: String
    let isDicesEnabled: Bool
    let isFlagsEnabled: Bool
    let isIconsEnabled: Bool
    let isLikesEnabled: Bool
    let isNamesEnabled: Bool
    let isOekakiEnabled: Bool
    let isPostingEnabled: Bool
    let isSageEnabled: Bool
    let isShieldEnabled: Bool
    let isSubjectEnabled: Bool
    let isThreadTagsEnabled: Bool
    let isTripsEnabled: Bool
    let additionalInfo: BoardAdditionalInfo?
}

// MARK: - JSONParsable

extension Board: JSONParsable {
    
    static func from(json: JSON) -> Board? {
        guard let bumpLimit = json["bump_limit"].int,
            let defaultName = json["default_name"].string,
            let isDicesEnabled = json["enable_dices"].int,
            let isFlagsEnabled = json["enable_flags"].int,
            let isIconsEnabled = json["enable_icons"].int,
            let isLikesEnabled = json["enable_likes"].int,
            let isNamesEnabled = json["enable_names"].int,
            let isOekakiEnabled = json["enable_oekaki"].int,
            let isPostingEnabled = json["enable_posting"].int,
            let isSageEnabled = json["enable_sage"].int,
            let isShieldEnabled = json["enable_shield"].int,
            let isSubjectEnabled = json["enable_subject"].int,
            let isThreadTagsEnabled = json["enable_thread_tags"].int,
            let isTripsEnabled = json["enable_trips"].int else { return nil }
        
        var identifier: String
        if let identifierValue = json["id"].string {
            identifier = identifierValue
        } else if let identifierValue = json["Board"].string {
            identifier = identifierValue
        } else {
            return nil
        }
        
        var name: String
                if let nameValue = json["name"].string {
            name = nameValue
        } else if let nameValue = json["BoardName"].string {
            name = nameValue
        } else {
            return nil
        }
        
        let pages = json["pages"].int
        let arrayOfPages = json["pages"].arrayObject as? [Int]
        let boardSpeed = json["board_speed"].int
        let currentPage = json["current_page"].int
        
        let additionalInfo = BoardAdditionalInfo.from(json: json)
        let category = Category(rawValue: json["category"].stringValue) ?? .other
        let shortInfo = BoardShortInfo(identifier: identifier, category: category, name: name)
        
        return Board(shortInfo: shortInfo,
                     pages: pages ?? arrayOfPages?.count,
                     boardSpeed: boardSpeed,
                     currentPage: currentPage,
                     bumpLimit: bumpLimit,
                     defaultName: defaultName,
                     isDicesEnabled: isDicesEnabled.boolValue,
                     isFlagsEnabled: isFlagsEnabled.boolValue,
                     isIconsEnabled: isIconsEnabled.boolValue,
                     isLikesEnabled: isLikesEnabled.boolValue,
                     isNamesEnabled: isNamesEnabled.boolValue,
                     isOekakiEnabled: isOekakiEnabled.boolValue,
                     isPostingEnabled: isPostingEnabled.boolValue,
                     isSageEnabled: isSageEnabled.boolValue,
                     isShieldEnabled: isShieldEnabled.boolValue,
                     isSubjectEnabled: isSubjectEnabled.boolValue,
                     isThreadTagsEnabled: isThreadTagsEnabled.boolValue,
                     isTripsEnabled: isTripsEnabled.boolValue,
                     additionalInfo: additionalInfo)
    }
}
