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

    var model: EVModel!

    lazy var cameraNode = SCNNode()
    lazy var scene = SCNScene()

    // MARK: - IBOutlets

    @IBOutlet weak var sceneView: SCNView!

    // MARK: - IBActions

    @IBAction func setWallTexture(_ sender: UIButton) {
        let objectIndex = Int.random(in: 0 ..< model.wallObjects.count)
        var rootNode = model.wallObjects[objectIndex]
        let index = Int.random(in: 0 ..< 3)
        let texture = model.wallTextures[index]
        rootNode.material.multiply.contents = texture
    }

    @IBAction func setRoofTexture(_ sender: UIButton) {
        let objectIndex = Int.random(in: 0 ..< model.roofObjects.count)
        var rootNode = model.roofObjects[objectIndex]
        let index = Int.random(in: 0 ..< 3)
        let texture = model.roofTextures[index]
        rootNode.material.multiply.contents = texture
    }

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
        let source: SourceMethod = .file

        guard let path = bundle.path(forResource: "model", ofType: "obj") else {
            fatalError("File not found")
        }
        if source == .string {
            let fileURL = URL(fileURLWithPath: path)
            //reading
            do {
                let text = try String(contentsOf: fileURL, encoding: .utf8)
                let data = text.split(separator: "\n").map( { String($0) })
                let parser = JFOBJParser(source: data)

                parser.finish = {
                    self.showModel(groups: parser.model.groups)
                }

                parser.parse()
            } catch {/* error handling here */}
        } else {
            let reader = JFLineReader(path: path)!
            reader.rewind()
            let parser = JFOBJParser(source: reader)
            parser.finish = {
                self.showModel(groups: parser.model.groups)
            }
            parser.parse()
        }
    }

    private func setupScene() {
        sceneView.scene = scene

        sceneView.showsStatistics = true

        sceneView.allowsCameraControl = true

        sceneView.autoenablesDefaultLighting = true

        sceneView.backgroundColor = .black

        sceneView.isPlaying = true
    }

    private func showModel(groups: [Group]) {

        model = EVModel(groups: groups)

        model.roofObjects.forEach {
            scene.rootNode.addChildNode($0.rootNode)
        }

        model.wallObjects.forEach {
            scene.rootNode.addChildNode($0.rootNode)
        }

        model.penObjects.forEach {
            scene.rootNode.addChildNode($0.rootNode)
        }
    }
}

enum NodeType {
    case roof, wall, penetration
}

enum SourceMethod {
    case file, string
}
