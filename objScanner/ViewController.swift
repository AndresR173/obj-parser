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

    //MARK: - Properties
    lazy var roofMaterial: SCNMaterial = {
        let material = SCNMaterial()
        let image = roofTextures[0]
        material.multiply.contentsTransform =  SCNMatrix4MakeScale(1/10, 1 / 10, 1)
        material.multiply.contents = image
        material.multiply.wrapS = .repeat
        material.multiply.wrapT = .repeat
        material.multiply.minificationFilter = .none
        material.multiply.mipFilter = .none
        material.isDoubleSided = false
        material.lightingModel = .lambert

        return material
    }()

    lazy var wallMaterial: SCNMaterial = {
        let material = SCNMaterial()
        let image = wallTextures[0]
        material.multiply.contentsTransform =  SCNMatrix4MakeScale(1/10, 1 / 10, 1)
        material.multiply.contents = image
        material.multiply.wrapS = .repeat
        material.multiply.wrapT = .repeat
        material.multiply.minificationFilter = .none
        material.multiply.mipFilter = .none
        material.isDoubleSided = false
        material.lightingModel = .lambert

        return material
    }()

    lazy var windowMaterial: SCNMaterial = {
        let material = SCNMaterial()
        let image = #imageLiteral(resourceName: "window")
        material.multiply.contentsTransform =  SCNMatrix4MakeScale(1/10, 1 / 10, 1)
        material.multiply.contents = image
        material.multiply.wrapS = .repeat
        material.multiply.wrapT = .repeat
        material.multiply.minificationFilter = .none
        material.multiply.mipFilter = .none
        material.isDoubleSided = false
        material.lightingModel = .lambert

        return material
    }()

    let wallTextures = [#imageLiteral(resourceName: "wall1"), #imageLiteral(resourceName: "wall2"), #imageLiteral(resourceName: "wall3")]
    let roofTextures = [#imageLiteral(resourceName: "roof1"), #imageLiteral(resourceName: "roof2"), #imageLiteral(resourceName: "roof3")]

    // MARK: - IBOutlets
    @IBOutlet weak var sceneView: SCNView!

    // MARK: - IBActions

    @IBAction func setWallsTexture(_ sender: UIButton) {
        let index = Int.random(in: 0 ..< 3)
        let texture = wallTextures[index]
        wallMaterial.multiply.contents = texture
    }
    @IBAction func setRoofsTexture(_ sender: UIButton) {
        let index = Int.random(in: 0 ..< 3)
        let texture = roofTextures[index]
        roofMaterial.multiply.contents = texture
    }

    // AMRK: - Properties
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

    private func createModel() {

    }

    private func showModel() {
        guard let parser = self.parser else {
            return
        }

        let groups = parser.model.groups



        for group in groups {
            for face in group.faces {
                let indices: [Int32] = [0, 1, 2]

                var vertices = [SCNVector3]()
                for vertex in face.vertices {
                    let vector = SCNVector3(vertex.x, vertex.y, vertex.z)
                    vertices.append(vector)
                }

                let sVertices = SCNGeometrySource(vertices: vertices)
                let normals = face.normals.filter({$0 != nil }) as! [SCNVector3]
                let sNormals = SCNGeometrySource(normals: normals)
                let textures = face.textures.filter({$0 != nil}) as! [CGPoint]
                let sTextures = SCNGeometrySource(textureCoordinates: textures)

                let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)

                let geometry = SCNGeometry(sources: [sVertices, sNormals, sTextures], elements: [element])

                let node = SCNNode(geometry: geometry)
                node.name = group.name

                if group.name.contains("Roof") {
                    geometry.materials = [roofMaterial]
                } else if group.name.contains("WallPen") {
                    geometry.materials = [windowMaterial]
                } else {
                    geometry.materials = [wallMaterial]
                }

                scene.rootNode.addChildNode(node)
            }
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
