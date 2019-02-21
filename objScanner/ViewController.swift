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

    var parser: JFOBJParser<JFLineReader>?

    var sceneView: SCNView {
        return self.view as! SCNView
    }

    lazy var cameraNode = SCNNode()
    lazy var scene = SCNScene()

    override func viewDidLoad() {
        super.viewDidLoad()

//        sceneView.autoenablesDefaultLighting = true
//        sceneView.allowsCameraControl = true
//        sceneView.scene = scene
//        sceneView.backgroundColor = UIColor.black
//        sceneView.showsStatistics = true

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
//        sceneView.delegate = self

        sceneView.showsStatistics = true

        sceneView.allowsCameraControl = true

        sceneView.autoenablesDefaultLighting = true

        sceneView.backgroundColor = .black

        //setupCamera()

        sceneView.isPlaying = true
    }

    private func showModel() {
        guard let parser = self.parser else {
            return
        }

        let groups = parser.model.groups

        let material = SCNMaterial()
        let image = UIImage(named: "roof")
//        material.diffuse.contents = UIColor.red
        material.multiply.contentsTransform =  SCNMatrix4MakeScale(1/10, 1 / 10, 1)
        material.multiply.contents = image
        material.multiply.wrapS = .repeat
        material.multiply.wrapT = .repeat
        //material.multiply.contentsTransform = textureScale
        material.multiply.minificationFilter = .none
        material.multiply.mipFilter = .none
        material.isDoubleSided = false
        material.lightingModel = .lambert

        let material2 = SCNMaterial()
        let image2 = UIImage(named: "brick")
        //        material.diffuse.contents = UIColor.red
        material2.multiply.contentsTransform =  SCNMatrix4MakeScale(1/10, 1 / 10, 1)
        material2.multiply.contents = image2
        material2.multiply.wrapS = .repeat
        material2.multiply.wrapT = .repeat
        //material.multiply.contentsTransform = textureScale
        material2.multiply.minificationFilter = .none
        material2.multiply.mipFilter = .none
        material2.isDoubleSided = false
        material2.lightingModel = .lambert

        for group in groups where !group.name.contains("WallPen") {
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

                if group.name.contains("Roof") {
                    geometry.materials = [material]
                } else {
                    geometry.materials = [material2]
                }


                let node = SCNNode(geometry: geometry)

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
