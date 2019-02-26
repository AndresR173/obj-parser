//
//  ViewController.swift
//  objScanner
//
//  Created by Andres Rojas on 2/19/19.
//  Copyright © 2019 Andres. All rights reserved.
//

import UIKit
import SceneKit

class ViewController: UIViewController {

    // MARK: - Properties

    var roofObjects = [EVObject]()
    var wallObjects = [EVObject]()
    var penObjects = [EVObject]()
    let wallTextures = [#imageLiteral(resourceName: "wall1"), #imageLiteral(resourceName: "wall2"), #imageLiteral(resourceName: "wall3")]
    let roofTextures = [#imageLiteral(resourceName: "roof1"), #imageLiteral(resourceName: "roof2"), #imageLiteral(resourceName: "roof3")]

    // MARK: - IBOutlets

    @IBOutlet weak var sceneView: SCNView!

    // MARK: - IBActions

    @IBAction func setWallTexture(_ sender: UIButton) {
        let objectIndex = Int.random(in: 0 ..< wallObjects.count)
        var rootNode = wallObjects[objectIndex]
        let index = Int.random(in: 0 ..< 3)
        let texture = wallTextures[index]
        rootNode.material.multiply.contents = texture
    }

    @IBAction func setRoofTexture(_ sender: UIButton) {
        let objectIndex = Int.random(in: 0 ..< roofObjects.count)
        var rootNode = roofObjects[objectIndex]
        let index = Int.random(in: 0 ..< 3)
        let texture = roofTextures[index]
        rootNode.material.multiply.contents = texture
    }

    // MARK: - Properties
    var parser: JFOBJParser<JFLineReader>?

    lazy var cameraNode = SCNNode()
    lazy var scene = SCNScene()

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupScene()

        loadModel()
    }
    
}

extension ViewController {
    private func loadModel() {
        let bundle = Bundle.main

        guard let path = bundle.path(forResource: "model", ofType: "obj") else {
            fatalError("File not found")
        }
        let reader = JFLineReader(path: path)!
        self.parser = JFOBJParser(source: reader)

        parser?.finish = {
            self.showModel()
        }

        // second pass - parse file into data structures
        reader.rewind()
        parser?.parse()
    }

    private func setupScene() {
        sceneView.scene = scene

        sceneView.showsStatistics = true

        sceneView.allowsCameraControl = true

        sceneView.autoenablesDefaultLighting = true

        sceneView.backgroundColor = .black

        sceneView.isPlaying = true
    }

    private func showModel() {
        guard let parser = self.parser else {
            return
        }

        let groups = parser.model.groups

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

            scene.rootNode.addChildNode(evObject.rootNode)
        }

    }

    private func setupCamera() {
        let camera = SCNCamera()
        cameraNode.camera = camera
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 10

        cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
        scene.rootNode.addChildNode(cameraNode)
    }
}

enum NodeType {
    case roof, wall, penetration
}

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
