//
//  EVObject.swift
//  objScanner
//
//  Created by Andres Rojas on 2/26/19.
//  Copyright © 2019 Andres. All rights reserved.
//

import Foundation
import SceneKit

struct EVObject {
    let name: String
    let rootNode = SCNNode()
    let type: NodeType

    lazy var material: SCNMaterial = {
        let material = SCNMaterial()
        material.multiply.contentsTransform =  SCNMatrix4MakeScale(1/10, 1 / 10, 1)
        material.multiply.wrapS = .repeat
        material.multiply.wrapT = .repeat
        material.multiply.minificationFilter = .none
        material.multiply.mipFilter = .none
        material.isDoubleSided = false
        material.lightingModel = .lambert

        return material
    }()

    init(type: NodeType, group: Group ) {
        self.name = group.name
        self.type = type

        switch type {
        case .roof:
            material.multiply.contents = #imageLiteral(resourceName: "roof1")
        case .wall:
            material.multiply.contents = #imageLiteral(resourceName: "wall1")
        default:
            material.multiply.contents = #imageLiteral(resourceName: "window")
        }

        var vertices = [SCNVector3]()
        var normals = [SCNVector3]()
        var textures = [CGPoint]()

        for face in group.faces {
            face.vertices.forEach {
                vertices.append(SCNVector3($0.x, $0.y, $0.z))
            }

            (face.normals.filter({ $0 != nil }) as! [SCNVector3]).forEach {
                normals.append($0)
            }

            (face.textures.filter({ $0 != nil }) as! [CGPoint]).forEach {
                textures.append($0)
            }
        }

        var indices = [Int16]()
        for index in 0 ..< vertices.count {
            indices.append(Int16(index))
        }

        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)

        let sVertices = SCNGeometrySource(vertices: vertices)
        let sNormals = SCNGeometrySource(normals: normals)
        let sTextures = SCNGeometrySource(textureCoordinates: textures)

        let geometry = SCNGeometry(sources: [sVertices, sNormals, sTextures], elements: [element])
        geometry.materials = [material]

        let node = SCNNode(geometry: geometry)
        rootNode.addChildNode(node)
    }
}
