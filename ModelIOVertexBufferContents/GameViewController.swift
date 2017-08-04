//
//  GameViewController.swift
//  ModelIOVertexBufferContents
//
//  Created by kevin on 8/4/17.
//  Copyright © 2017 Bit Shape Software, LLC. All rights reserved.
//

import UIKit
import Metal
import MetalKit

class GameViewController:UIViewController, MTKViewDelegate {
    
    //===================================================================================
    //MARK: Testing Properties
    //===================================================================================
    
    let modelNames = ["uv-sphere.stl", "wavePlane.obj"]
    
    //===================================================================================
    //MARK: Properties
    //===================================================================================
    
    var device: MTLDevice! = nil
    var library: MTLLibrary! = nil
    let textField = UITextView()
    var text = "\n\n'uv-sphere.stl' should resolve to this vertex:\n{\n   position: (-0.892934, 0.145383, 1.18061),\n   normal: (-0.470888, 0.0463828, 0.880973),\n   color: (0.0, 0.0, 0.0, 1.0),\n   textureCoordinate: (0.0)\n}\n\n'wavePlane.obj' should resolve to this vertex:\n{\n   position: (-1.7199, 0.085319, 2.25768),\n   normal: (-0.0048, 0.9858, -0.1676),\n   color: (0.0, 0.0, 0.0, 1.0),\n   textureCoordinate: (0.0)\n}"
    
    //===================================================================================
    //MARK: View Loading
    //===================================================================================
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        device = MTLCreateSystemDefaultDevice()
        guard device != nil else { // Fallback to a blank UIView, an application could also fallback to OpenGL ES here.
            print("Metal is not supported on this device")
            self.view = UIView(frame: self.view.frame)
            return
        }

        // setup view properties
        let view = self.view as! MTKView
        view.device = device
        view.delegate = self
        
        textField.frame = view.bounds
        textField.isUserInteractionEnabled = false
        view.addSubview(textField)
       
        for modelName in modelNames {
            testModelBufferContentsForModelNamed(modelName)
        }
        
        textField.text = text
    }
    
    //===================================================================================
    //MARK: Testing MTKMesh Buffer Contents
    //===================================================================================
    
    func testModelBufferContentsForModelNamed(_ name: String) {
        
        let mtlVertexDescriptor = MTLVertexDescriptor();
        
        //Vertex3DIn attributes:
        //positions
        mtlVertexDescriptor.attributes[0].format = MTLVertexFormat.float3
        mtlVertexDescriptor.attributes[0].offset = 0
        mtlVertexDescriptor.attributes[0].bufferIndex = 0
        
        //normal
        mtlVertexDescriptor.attributes[1].format = MTLVertexFormat.float3
        mtlVertexDescriptor.attributes[1].offset = 12
        mtlVertexDescriptor.attributes[1].bufferIndex = 0
        
        //color
        mtlVertexDescriptor.attributes[2].format = MTLVertexFormat.float4
        mtlVertexDescriptor.attributes[2].offset = 24
        mtlVertexDescriptor.attributes[2].bufferIndex = 0
        
        //texture coordinates
        mtlVertexDescriptor.attributes[3].format = MTLVertexFormat.half2
        mtlVertexDescriptor.attributes[3].offset = 40
        mtlVertexDescriptor.attributes[3].bufferIndex = 0
        
        //single interleaved buffer
        mtlVertexDescriptor.layouts[0].stride = 44;
        mtlVertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunction.perVertex;
        
        let mdlVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(mtlVertexDescriptor)
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        
        renameMDLVertexAttributeAtIndex(0, name: MDLVertexAttributePosition, descriptor: mdlVertexDescriptor)
        renameMDLVertexAttributeAtIndex(1, name: MDLVertexAttributeNormal, descriptor: mdlVertexDescriptor)
        renameMDLVertexAttributeAtIndex(2, name: MDLVertexAttributeColor, descriptor: mdlVertexDescriptor)
        renameMDLVertexAttributeAtIndex(3, name: MDLVertexAttributeTextureCoordinate, descriptor: mdlVertexDescriptor)
        
        if let modelURL = Bundle.main.url(forResource: name, withExtension: nil) {
            let asset = MDLAsset(url: modelURL, vertexDescriptor: mdlVertexDescriptor, bufferAllocator: bufferAllocator)
            
            //create metalkit shapes
            var mtkShapes: [MTKMesh] = []
            let arrayPtr = UnsafeMutablePointer<[MDLMesh]>.allocate(capacity: 0)
            let mdlShapesPointer = AutoreleasingUnsafeMutablePointer<NSArray?>(arrayPtr)
            
            do {
                try mtkShapes = MTKMesh.newMeshes(from: asset, device: device, sourceMeshes: mdlShapesPointer)
            }
            catch {
                print("failed to load mesh \(error)")
            }
            
            if let mesh = mtkShapes.first {
                //print the buffer:
                text.append("\n\nloading mesh with name: \(name)\n\n")
                
                let vertexBuffer = mesh.vertexBuffers[0]
                let floatData = vertexBuffer.buffer.contents().bindMemory(to: Float.self, capacity: vertexBuffer.length / MemoryLayout<Float>.stride)
                for i in 0..<11 {
                    text.append("data [\(i)] = \(floatData[i])\n")
                }
                text.append("...")
            }
        }
    }
    
    private func renameMDLVertexAttributeAtIndex(_ index: Int, name: String, descriptor: MDLVertexDescriptor) {
        let originalAttribute = descriptor.attributes[index] as! MDLVertexAttribute
        let renamedAttribute = MDLVertexAttribute(name: name, format: originalAttribute.format, offset: originalAttribute.offset, bufferIndex: originalAttribute.bufferIndex)
        descriptor.attributes.replaceObject(at: index, with: renamedAttribute)
    }
    
    func draw(in view: MTKView) {
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
}
