//
//  EVModel.swift
//  objScanner
//
//  Created by Andres Rojas on 2/26/19.
//  Copyright © 2019 Andres. All rights reserved.
//

import Foundation
import SceneKit

struct EVModel {

    // MARK: - Properties

    var roofObjects = [EVObject]()
    var wallObjects = [EVObject]()
    var penObjects = [EVObject]()
    let wallTextures = [#imageLiteral(resourceName: "wall1"), #imageLiteral(resourceName: "wall2"), #imageLiteral(resourceName: "wall3")]
    let roofTextures = [#imageLiteral(resourceName: "roof1"), #imageLiteral(resourceName: "roof2"), #imageLiteral(resourceName: "roof3")]

    init(groups: [Group]) {
        for group in groups {
            var evObject: EVObject
            if group.name.contains("Roof") {
                evObject = EVObject(type: .roof, group: group)
                roofObjects.append(evObject)
            } else if group.name.contains("WallPen") {
                evObject = EVObject(type: .penetration, group: group)
                penObjects.append(evObject)
            } else {
                evObject = EVObject(type: .wall, group: group)
                wallObjects.append(evObject)
            }
        }
    }
}
