import Foundation
import SceneKit

// https://en.wikipedia.org/wiki/Wavefront_.obj_file

public struct JFOBJParserStats {

    public var numberOfVertices: Int = 0
    public var numberOfTextureCoords: Int = 0
    public var numberOfVertexNormals: Int = 0
    public var numberOfParameterSpaceVertices: Int = 0
    public var numberOfFaces: Int = 0
    public var numberOfGroups: Int = 0

}

public struct Model {

    var vertices = [SCNVector4]()
    var normals = [SCNVector3?]()
    var texturesCoord = [CGPoint?]()
    var groups = [Group]()

}

struct Face {
    let count: Int
    let vertices: [SCNVector4]
    let textures: [CGPoint?]
    let normals: [SCNVector3?]
}

struct Group {
    let name: String
    var faces: [Face]
}

public class JFOBJParser<T: Sequence> where T.Iterator.Element == String {
    private var currentGroup: Group?

//    public var onVertex: (Float, Float, Float, Float) -> Void
//    public var onTextureCoord: (Float, Float, Float) -> Void
//    public var onParameterSpaceVertex: (Double, Double, Double) -> Void
//    public var onVertexNormal: (Float, Float, Float) -> Void
//    public var onFace: (Int, [Int], [Int], [Int]) -> Void
//    public var group: (String) -> Void
//    public var onUnknown: (String) -> Void
    public var finish: () -> Void

    private let source: T

    var model = Model()

    public init(source: T) {
        self.source = source
        /*self.onVertex = { (x, y, z, w) in }
        self.onTextureCoord = { (u, v, w) in }
        self.onVertexNormal = { (x, y, z) in }
        self.onParameterSpaceVertex = { (u, v, w) in }
        self.onFace = { (count, vs, vtcs, vns) in }
        self.onUnknown = { (line) in }
        self.group = { (name) in}*/
        self.finish = {}
    }

    public func count() -> JFOBJParserStats {
        var stats = JFOBJParserStats()
        for line in source {
            if line.hasPrefix("v ") {
                stats.numberOfVertices += 1
            } else if line.hasPrefix("vt ") {
                stats.numberOfTextureCoords += 1
            } else if line.hasPrefix("vn ") {
                stats.numberOfVertexNormals += 1
            } else if line.hasPrefix("vp ") {
                stats.numberOfParameterSpaceVertices += 1
            } else if line.hasPrefix("f ") {
                stats.numberOfFaces += 1
            } else if line.hasPrefix("o ") {
                stats.numberOfGroups += 1
            }
        }
        return stats
    }

    public func parse() {
        var fVertices = [SCNVector4](), fTextureCoords = [CGPoint?](), fVertexNormals = [SCNVector3?]()
        fVertices.reserveCapacity(4)
        fTextureCoords.reserveCapacity(4)
        fVertexNormals.reserveCapacity(4)

        for line in source {
            let scanner = Scanner(string: line)
            if line.hasPrefix("v ") {
                // # List of geometric vertices, with (x,y,z[,w]) coordinates, w is optional and defaults to 1.0.
                // also supports trailing r,g,b vertex colours
                // v 0.123 0.234 0.345 1.0
                scanner.scanLocation = 2
                var x: Float = 0.0,
                    y: Float = 0.0,
                    z: Float = 0.0,
                    w: Float = 1.0
                scanner.scanFloat(&x)
                scanner.scanFloat(&y)
                scanner.scanFloat(&z)
                if !scanner.isAtEnd {
                    scanner.scanFloat(&w)
                    if !scanner.isAtEnd {
                        if scanner.isAtEnd {
                            w = 1.0
                        }
                    }
                }
                let vertex = SCNVector4(x: x, y: y, z: z, w: w)
                self.model.vertices.append(vertex)
                //onVertex(x, y, z, w)
            } else if line.hasPrefix("vt ") {
                // # List of texture coordinates, in (u, v [,w]) coordinates, these will vary between 0 and 1, w is optional and defaults to 0.
                // vt 0.500 1
                scanner.scanLocation = 3
                var u: Float = 0.0,
                    v: Float = 0.0,
                    w: Float = 0.0
                scanner.scanFloat(&u)
                scanner.scanFloat(&v)
                if !scanner.isAtEnd {
                    scanner.scanFloat(&w)
                }
                let point = CGPoint(x: CGFloat(u), y: CGFloat(v))
                self.model.texturesCoord.append(point)
//                onTextureCoord(u, v, w)
            } else if line.hasPrefix("vn ") {
                // # List of vertex normals in (x,y,z) form; normals might not be unit vectors.
                // vn 0.707 0.000 0.707
                scanner.scanLocation = 3
                var x: Float = 0.0,
                    y: Float = 0.0,
                    z: Float = 0.0
                scanner.scanFloat(&x)
                scanner.scanFloat(&y)
                scanner.scanFloat(&z)
                let vector = SCNVector3(x: x, y: y, z: z)
                self.model.normals.append(vector)
//                onVertexNormal(x, y, z)
            } else if line.hasPrefix("vp ") {
                // # Parameter space vertices in ( u [,v] [,w] ) form; free form geometry statement
                // vp 0.310000 3.210000 2.100000
                scanner.scanLocation = 3
                var u: Double = 0.0,
                    v: Double = 0.0,
                    w: Double = 0.0
                scanner.scanDouble(&u)
                if !scanner.isAtEnd {
                    scanner.scanDouble(&v)
                    if !scanner.isAtEnd {
                        scanner.scanDouble(&w)  
                    }   
                }
                //onParameterSpaceVertex(u, v, w)
            } else if line.hasPrefix("f ") {
                // # Polygonal face element
                // f 1 2 3
                // f 3/1 4/2 5/3
                // f 6/4/1 3/5/3 7/6/5
                // f 7//1 8//2 9//3
                scanner.scanLocation = 2
                var tmp: Int = 0, vertexCount: Int = 0
                while !scanner.isAtEnd {
                    scanner.scanInt(&tmp)
                    let vector = self.model.vertices[tmp - 1]
                    fVertices.append(vector)
                    if getChar(scanner) == "/" {
                        scanner.scanLocation += 1
                        if getChar(scanner) != "/" {
                            scanner.scanInt(&tmp)
                            let vector = self.model.texturesCoord[tmp - 1]
                            fTextureCoords.append(vector)
                        } else {
                            fTextureCoords.append(nil)
                        }
                        if getChar(scanner) == "/" {
                            scanner.scanLocation += 1
                            scanner.scanInt(&tmp)
                            let vector = self.model.normals[tmp - 1]
                            fVertexNormals.append(vector)
                        } else {
                            fVertexNormals.append(nil)
                        }
                    } else {
                        fTextureCoords.append(nil)
                        fVertexNormals.append(nil)
                    }
                    vertexCount += 1
                }
                guard self.currentGroup != nil else { continue }
                let face = Face(count: vertexCount, vertices: fVertices, textures: fTextureCoords, normals: fVertexNormals)
                self.currentGroup!.faces.append(face)
                //onFace(vertexCount, fVertices, fTextureCoords, fVertexNormals)
                fVertices.removeAll()
                fTextureCoords.removeAll()
                fVertexNormals.removeAll()
            } else if line.hasPrefix("#") {
                // comment, skip
            } else if line.hasPrefix("o ") {
                scanner.scanLocation = 2
                let name = line.suffix(line.count - 2).filter({!"\n".contains($0)})
                if self.currentGroup != nil {
                    self.model.groups.append(self.currentGroup!)
                }
                self.currentGroup = Group(name: String(name), faces: [])
//                group(String(name))
            } //else if !scanner.isAtEnd {
//                onUnknown(line)
//            }
        }
        if self.currentGroup != nil {
            self.model.groups.append(self.currentGroup!)
        }
        finish()
    }

    private func getChar(_ s: Scanner) -> Character {
        return s.string[s.string.index(s.string.startIndex, offsetBy: s.scanLocation)]
    }


}
