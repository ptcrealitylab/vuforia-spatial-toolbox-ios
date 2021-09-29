/*===============================================================================
Copyright (c) 2020, PTC Inc. All rights reserved.

Vuforia is a trademark of PTC Inc., registered in the United States and other
countries.
===============================================================================*/

import UIKit
import MetalKit


/// Class to encapsulate Metal rendering for the sample
class MetalRenderer {

    private var mMetalDevice:MTLDevice

    private var mVideoBackgroundPipelineState:MTLRenderPipelineState!
    private var mAxisPipelineState:MTLRenderPipelineState!
    private var mUniformColorShaderPipelineState:MTLRenderPipelineState!
    private var mTexturedVertexShaderPipelineState:MTLRenderPipelineState!

    private var mDefaultSamplerState:MTLSamplerState?
    private var mWrappingSamplerState:MTLSamplerState?

    private var mVideoBackgroundVertices:MTLBuffer!
    private var mVideoBackgroundIndices:MTLBuffer!
    private var mVideoBackgroundTextureCoordinates:MTLBuffer!

    private var mCubeVertices:MTLBuffer!
    private var mCubeIndices:MTLBuffer!
    private var mCubeWireframeIndices:MTLBuffer!

    private var mSquareVertices:MTLBuffer!
    private var mSquareIndices:MTLBuffer!
    private var mSquareWireframeIndices:MTLBuffer!
    private var mSquareTextureCoordinates:MTLBuffer!

    private var mAxisVertices:MTLBuffer!
    private var mAxisIndices:MTLBuffer!
    private var mAxisColors:MTLBuffer!

    // Buffers for world origin model-view-projection matrices
    private var mWorldOriginAxisMVP:MTLBuffer!
    private var mWorldOriginCubeMVP:MTLBuffer!

    // Buffers for augmentation model-view-projection matrices
    private var mAugmentationMVP:MTLBuffer!
    private var mAugmentationAxisMVP:MTLBuffer!
    private var mAugmentationScaledMVP:MTLBuffer!

    // The guide view image data from AppController
    private var mGuideViewBuffer:MTLBuffer!
    // The texture for rendering the Guide View
    private var mGuideViewTexture:MTLTexture!
    
    private var mAstronautVertices:MTLBuffer!
    private var mAstronautTextureCoordinates:MTLBuffer!
    private var mAstronautVertexCount:Int = 0
    private var mAstronautTexture:MTLTexture!

    private var mLanderVertices:MTLBuffer!
    private var mLanderTextureCoordinates:MTLBuffer!
    private var mLanderVertexCount:Int = 0
    private var mLanderTexture:MTLTexture!

    private let colorRed = vector_float4(Float(1), Float(0), Float(0), Float(1))
    private let colorGrey = vector_float4(Float(0.8), Float(0.8), Float(0.8), Float(1.0))


    /// Initialize the renderer ready for use
    init(metalDevice: MTLDevice, layer: CAMetalLayer, library: MTLLibrary?, depthAttachmentPixelFormat: MTLPixelFormat) {
        mMetalDevice = metalDevice
        
        let stateDescriptor = MTLRenderPipelineDescriptor()

        //
        // Video background
        //
        
        stateDescriptor.vertexFunction = library?.makeFunction(name: "texturedVertex")
        stateDescriptor.fragmentFunction = library?.makeFunction(name: "texturedFragment")
        stateDescriptor.colorAttachments[0].pixelFormat = layer.pixelFormat
        stateDescriptor.depthAttachmentPixelFormat = depthAttachmentPixelFormat
        
        // And create the pipeline state with the descriptor
        do {
            try self.mVideoBackgroundPipelineState = metalDevice.makeRenderPipelineState(descriptor: stateDescriptor)
        } catch {
            print("Failed to create video background render pipeline state:",error)
        }
        
        //
        // Augmentations
        //

        // Create pipeline for world origin
        stateDescriptor.vertexFunction = library?.makeFunction(name: "vertexColorVertex")
        stateDescriptor.fragmentFunction = library?.makeFunction(name: "vertexColorFragment")
        stateDescriptor.colorAttachments[0].pixelFormat = layer.pixelFormat;
        stateDescriptor.depthAttachmentPixelFormat = depthAttachmentPixelFormat
        do {
            try self.mAxisPipelineState = metalDevice.makeRenderPipelineState(descriptor: stateDescriptor)
        } catch {
            print("Failed to create axis render pipeline state:",error)
            return
        }

        // Create pipeline for transparent object overlays
        stateDescriptor.vertexFunction = library?.makeFunction(name: "uniformColorVertex")
        stateDescriptor.fragmentFunction = library?.makeFunction(name: "uniformColorFragment")
        stateDescriptor.colorAttachments[0].pixelFormat = layer.pixelFormat;
        stateDescriptor.colorAttachments[0].isBlendingEnabled = true
        stateDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.add
        stateDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.add
        stateDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.sourceAlpha
        stateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.sourceAlpha
        stateDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactor.oneMinusSourceAlpha
        stateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.oneMinusSourceAlpha
        stateDescriptor.depthAttachmentPixelFormat = depthAttachmentPixelFormat
        do {
            try self.mUniformColorShaderPipelineState = metalDevice.makeRenderPipelineState(descriptor: stateDescriptor)
        } catch {
            print("Failed to create augmentation render pipeline state:",error)
            return
        }

        stateDescriptor.vertexFunction = library?.makeFunction(name: "texturedVertex")
        stateDescriptor.fragmentFunction = library?.makeFunction(name: "texturedFragment")
        
        // Create pipeline for rendering textures
        do {
            try self.mTexturedVertexShaderPipelineState = metalDevice.makeRenderPipelineState(descriptor: stateDescriptor)
        } catch {
            print("Failed to create guide view render pipeline state:", error)
            return
        }

        mDefaultSamplerState = MetalRenderer.defaultSampler(device: metalDevice)
        mWrappingSamplerState = MetalRenderer.wrappingSampler(device: metalDevice)
        
        // Allocate space for rendering data for Video background
        mVideoBackgroundVertices = mMetalDevice.makeBuffer(length: MemoryLayout<Float>.size * 3 * 4, options: [])
        mVideoBackgroundTextureCoordinates = mMetalDevice.makeBuffer(length: MemoryLayout<Float>.size * 2 * 4, options: [])
        mVideoBackgroundIndices = mMetalDevice.makeBuffer(length: MemoryLayout<UInt32>.size * 6, options: [])

        // Load rendering data for cube
        mCubeVertices = metalDevice.makeBuffer(bytes: Models.cubeVertices, length: MemoryLayout<Float>.size * 3 * Int(Models.NUM_CUBE_VERTEX), options: [])
        mCubeIndices = metalDevice.makeBuffer(bytes: Models.cubeIndices, length: MemoryLayout<UInt16>.size * Int(Models.NUM_CUBE_INDEX), options: [])
        mCubeWireframeIndices
            = metalDevice.makeBuffer(bytes: Models.cubeWireframeIndices, length: MemoryLayout<UInt16>.size * Int(Models.NUM_CUBE_WIREFRAME_INDEX), options: [])

        // Load rendering data for square
        mSquareVertices = metalDevice.makeBuffer(bytes: Models.squareVertices, length: MemoryLayout<Float>.size * 3 * Int(Models.NUM_SQUARE_VERTEX), options: [])
        mSquareIndices = metalDevice.makeBuffer(bytes: Models.squareIndices, length: MemoryLayout<UInt16>.size * Int(Models.NUM_SQUARE_INDEX), options: [])
        mSquareWireframeIndices
            = metalDevice.makeBuffer(bytes: Models.squareWireframeIndices, length: MemoryLayout<UInt16>.size * Int(Models.NUM_SQUARE_WIREFRAME_INDEX), options: [])
        mSquareTextureCoordinates = metalDevice.makeBuffer(bytes: Models.squareTexCoords, length: MemoryLayout<Float>.size * 8, options: [])

        // Load rendering data for axes
        mAxisVertices = metalDevice.makeBuffer(bytes: Models.axisVertices, length: MemoryLayout<Float>.size * 3 * Int(Models.NUM_AXIS_VERTEX), options:[])
        mAxisIndices = metalDevice.makeBuffer(bytes: Models.axisIndices, length: MemoryLayout<UInt16>.size * Int(Models.NUM_AXIS_INDEX), options: [])
        mAxisColors = metalDevice.makeBuffer(bytes: Models.axisColors, length: MemoryLayout<Float>.size * 4 * Int(Models.NUM_AXIS_COLOR), options:[])

// BEN:       loadModels()

        mWorldOriginAxisMVP = mMetalDevice.makeBuffer(length: MemoryLayout<Float>.size * 16)
        mWorldOriginCubeMVP = mMetalDevice.makeBuffer(length: MemoryLayout<Float>.size * 16)
        mAugmentationMVP = mMetalDevice.makeBuffer(length: MemoryLayout<Float>.size * 16)
        mAugmentationAxisMVP = mMetalDevice.makeBuffer(length: MemoryLayout<Float>.size * 16)
        mAugmentationScaledMVP = mMetalDevice.makeBuffer(length: MemoryLayout<Float>.size * 16)
    }


    /// Render the video background
    func renderVideoBackground(encoder: MTLRenderCommandEncoder?, projectionMatrix: MTLBuffer, mesh: VuMesh) {

        // Copy mesh data into metal buffers
        mVideoBackgroundVertices.contents().copyMemory(from: mesh.pos, byteCount: MemoryLayout<Float>.size * Int(mesh.numVertices) * 3)
        mVideoBackgroundTextureCoordinates.contents().copyMemory(from: mesh.tex, byteCount: MemoryLayout<Float>.size * Int(mesh.numVertices) * 2)
        mVideoBackgroundIndices.contents().copyMemory(from: mesh.faceIndices, byteCount: MemoryLayout<CUnsignedInt>.size * Int(mesh.numFaces) * 3)
        
        // Set the render pipeline state
        encoder?.setRenderPipelineState(mVideoBackgroundPipelineState)
        
        // Set the texture coordinate buffer
        encoder?.setVertexBuffer(mVideoBackgroundTextureCoordinates, offset: 0, index: 2)
        
        // Set the vertex buffer
        encoder?.setVertexBuffer(mVideoBackgroundVertices, offset: 0, index: 0)
        
        // Set the projection matrix
        encoder?.setVertexBuffer(projectionMatrix, offset: 0, index: 1)
       
        encoder?.setFragmentSamplerState(mDefaultSamplerState, index: 0)

        // Draw the geometry
        encoder?.drawIndexedPrimitives(type: MTLPrimitiveType.triangle,indexCount: 6, indexType: .uint32, indexBuffer: mVideoBackgroundIndices, indexBufferOffset: 0)
    }

    
    /// Render augmentation for the world origin
    func renderWorldOrigin(encoder: MTLRenderCommandEncoder?, projectionMatrix: matrix_float4x4, modelViewMatrix: matrix_float4x4) {

        renderAxis(encoder: encoder, mvpBuffer: mWorldOriginAxisMVP,
                 projectionMatrix: projectionMatrix, modelViewMatrix: modelViewMatrix, scale: vector_float3(0.1, 0.1, 0.1))

        // Scale the model view for cube rendering and update MVP
        let modelViewMatrixScaled = modelViewMatrix * matrix_float4x4(diagonal: SIMD4<Float>(0.015, 0.015, 0.015, 1.0))
        var modelViewProjectionMatrix = projectionMatrix * modelViewMatrixScaled
        mWorldOriginCubeMVP.contents().copyMemory(from: &modelViewProjectionMatrix.columns, byteCount: MemoryLayout<Float>.size * 16)

        encoder?.setRenderPipelineState(mUniformColorShaderPipelineState)
        encoder?.setVertexBuffer(mCubeVertices, offset: 0, index: 0)
        encoder?.setVertexBuffer(mWorldOriginCubeMVP, offset: 0, index: 1)
        var color = colorGrey
        encoder?.setFragmentBytes(&color, length: MemoryLayout.size(ofValue: color), index: 0)
        encoder?.drawIndexedPrimitives(type: .triangle, indexCount: Int(Models.NUM_CUBE_INDEX), indexType: .uint16, indexBuffer: mCubeIndices, indexBufferOffset: 0)
    }

    
    /// Render a bounding box augmentation on an Image Target
    func renderImageTarget(encoder: MTLRenderCommandEncoder?,
                           projectionMatrix: matrix_float4x4,
                           modelViewMatrix: matrix_float4x4, scaledModelViewMatrix: matrix_float4x4) {

        var modelViewProjection = projectionMatrix * modelViewMatrix
        mAugmentationMVP.contents().copyMemory(from: &modelViewProjection.columns, byteCount: MemoryLayout<Float>.size * 16)
        var scaledModelViewProjectionMatrix = projectionMatrix * scaledModelViewMatrix
        mAugmentationScaledMVP.contents().copyMemory(from: &scaledModelViewProjectionMatrix.columns, byteCount: MemoryLayout<Float>.size * 16)

        // Draw translucent bounding box overlay
        encoder?.setRenderPipelineState(mUniformColorShaderPipelineState)

        encoder?.setVertexBuffer(mSquareVertices, offset: 0, index: 0)
        encoder?.setVertexBuffer(mAugmentationScaledMVP, offset: 0, index: 1)

        var color = colorRed
        // Draw translucent square
        color[3] = 0.2
        encoder?.setFragmentBytes(&color, length: MemoryLayout.size(ofValue: color), index: 0)
        encoder?.drawIndexedPrimitives(type: .triangle, indexCount: Int(Models.NUM_SQUARE_INDEX), indexType: .uint16, indexBuffer: mSquareIndices, indexBufferOffset: 0)
        // Draw solid wireframe
        color[3] = 1.0
        encoder?.setFragmentBytes(&color, length: MemoryLayout.size(ofValue: color), index: 0)
        encoder?.drawIndexedPrimitives(type: .line, indexCount: Int(Models.NUM_SQUARE_WIREFRAME_INDEX), indexType: .uint16, indexBuffer: mSquareWireframeIndices, indexBufferOffset: 0)
        
        // Draw an axis
        renderAxis(encoder: encoder, mvpBuffer: mAugmentationAxisMVP,
                 projectionMatrix: projectionMatrix, modelViewMatrix: modelViewMatrix, scale: vector_float3(0.02, 0.02, 0.02))

        // Draw the Astronaut
        renderModel(encoder: encoder,
                    vertices: mAstronautVertices, vertexCount: mAstronautVertexCount,
                    textureCoordinates: mAstronautTextureCoordinates, texture: mAstronautTexture,
                    mvpBuffer: mAugmentationMVP)
    }

    
    /// Render a bounding cube augmentation on a Model Target
    func renderModelTarget(encoder: MTLRenderCommandEncoder?,
                           projectionMatrix: matrix_float4x4,
                           modelViewMatrix: matrix_float4x4, scaledModelViewMatrix: matrix_float4x4) {

        var modelViewProjection = projectionMatrix * modelViewMatrix
        mAugmentationMVP.contents().copyMemory(from: &modelViewProjection.columns, byteCount: MemoryLayout<Float>.size * 16)

        // Draw an axis
        renderAxis(encoder: encoder, mvpBuffer: mAugmentationAxisMVP,
                 projectionMatrix: projectionMatrix, modelViewMatrix: modelViewMatrix, scale: vector_float3(0.1, 0.1, 0.1))

        // Draw the Lander
        renderModel(encoder: encoder,
                    vertices: mLanderVertices, vertexCount: mLanderVertexCount,
                    textureCoordinates: mLanderTextureCoordinates, texture: mLanderTexture,
                    mvpBuffer: mAugmentationMVP)
    }

    
    /// Render the Guide View for a model target
    func renderModelTargetGuideView(encoder: MTLRenderCommandEncoder?,
                                    modelViewProjectionMatrix: MTLBuffer,
                                    guideViewImageInfo: inout VuImageInfo) {

        if (mGuideViewTexture == nil || mGuideViewBuffer == nil) {
            // We only have a single Guide View in this app so we load the texture once now
            
            // Setup texture for Guide View
            let textureDescriptor = MTLTextureDescriptor.init()
            textureDescriptor.pixelFormat = MTLPixelFormat.bgra8Unorm;
            textureDescriptor.width = Int(guideViewImageInfo.bufferWidth);
            textureDescriptor.height = Int(guideViewImageInfo.bufferHeight);
            mGuideViewTexture = mMetalDevice.makeTexture(descriptor: textureDescriptor);
            
            let bufferSize = Int(guideViewImageInfo.height * guideViewImageInfo.stride)
            mGuideViewBuffer = mMetalDevice.makeBuffer(bytes: guideViewImageInfo.buffer, length: Int(guideViewImageInfo.bufferSize), options: [])
            let data = NSData(bytes: mGuideViewBuffer.contents(), length: bufferSize)
            let region = MTLRegion.init(origin: MTLOrigin(x: 0, y: 0, z: 0), size: MTLSize(width: Int(guideViewImageInfo.bufferWidth), height: Int(guideViewImageInfo.bufferHeight), depth: 1))
            mGuideViewTexture.replace(region: region, mipmapLevel: 0, withBytes: data.bytes, bytesPerRow: Int(guideViewImageInfo.stride))
        }

        encoder?.setRenderPipelineState(mTexturedVertexShaderPipelineState)
        encoder?.setFragmentTexture(mGuideViewTexture, index: 0)
        encoder?.setVertexBuffer(mSquareTextureCoordinates, offset: 0, index: 2)
        encoder?.setVertexBuffer(mSquareVertices, offset: 0, index: 0)
        encoder?.setVertexBuffer(modelViewProjectionMatrix, offset: 0, index: 1)
        encoder?.drawIndexedPrimitives(type: .triangle, indexCount: 6, indexType: .uint16, indexBuffer: mSquareIndices, indexBufferOffset: 0)
    }
    
    
    private func renderAxis(encoder: MTLRenderCommandEncoder?, mvpBuffer: MTLBuffer,
                          projectionMatrix: matrix_float4x4, modelViewMatrix: matrix_float4x4, scale: vector_float3) {
        // Scale the model view for axis rendering and update MVP
        let modelViewMatrixScaled = modelViewMatrix * matrix_float4x4(diagonal: SIMD4<Float>(scale.x, scale.y, scale.z, 1.0))
        var modelViewProjectionMatrix = projectionMatrix * modelViewMatrixScaled
        mvpBuffer.contents().copyMemory(from: &modelViewProjectionMatrix.columns, byteCount: MemoryLayout<Float>.size * 16)
        
        encoder?.setRenderPipelineState(mAxisPipelineState)
        encoder?.setVertexBuffer(mAxisVertices, offset: 0, index: 0)
        encoder?.setVertexBuffer(mAxisColors, offset: 0, index: 1)
        encoder?.setVertexBuffer(mvpBuffer, offset: 0, index: 2)
        encoder?.drawIndexedPrimitives(type: .line, indexCount: 6, indexType: .uint16, indexBuffer: mAxisIndices, indexBufferOffset: 0)
    }

    
    private func renderModel(encoder: MTLRenderCommandEncoder?,
                             vertices: MTLBuffer, vertexCount: Int,
                             textureCoordinates: MTLBuffer, texture: MTLTexture,
                             mvpBuffer: MTLBuffer) {

        encoder?.setRenderPipelineState(mTexturedVertexShaderPipelineState)
        encoder?.setFragmentTexture(texture, index: 0)
        encoder?.setFragmentSamplerState(mWrappingSamplerState, index: 0)
        encoder?.setVertexBuffer(textureCoordinates, offset: 0, index: 2)
        encoder?.setVertexBuffer(vertices, offset: 0, index: 0)
        encoder?.setVertexBuffer(mvpBuffer, offset: 0, index: 1)
        encoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
    }
    
    
    /// Load rendering data for Astronaut and Lander models
    private func loadModels() {
        let bundle = Bundle.main
        let loader = MTKTextureLoader(device: mMetalDevice)
        
        let astronautImage = bundle.url(forResource: "Astronaut", withExtension: "jpg")!
        // Load the texture, note that we specify the origin as the texture coordinates
        // are OpenGL convention with the origin at the bottom left
        mAstronautTexture = try! loader.newTexture(URL: astronautImage, options: [MTKTextureLoader.Option.origin: MTKTextureLoader.Origin.bottomLeft])
        
        let astronautModelPath = bundle.path(forResource: "Astronaut", ofType: "obj")
        let astronautModelData = NSData(contentsOfFile: astronautModelPath!)
        
        // Copy the bytes to an array, needed for iOS 12 where using the array constructor
        // like this 'var astronautModelBytes = [UInt8](astronautModelData!)' doesn't work
        let astronautByteCount = astronautModelData!.length / MemoryLayout<Int8>.size
        var astronautModelBytes = [Int8](repeating: 0, count: astronautByteCount)
        astronautModelData!.getBytes(&astronautModelBytes, length:astronautByteCount * MemoryLayout<Int8>.size)

        var astronautModel: VuforiaModel = loadModel(&astronautModelBytes, Int32(astronautModelBytes.count))
        if (astronautModel.isLoaded) {
            mAstronautVertexCount = Int(astronautModel.numVertices)
            mAstronautVertices = mMetalDevice.makeBuffer(bytes: astronautModel.vertices, length: MemoryLayout<Float>.size * 3 * Int(astronautModel.numVertices), options:[])
            mAstronautTextureCoordinates = mMetalDevice.makeBuffer(bytes: astronautModel.textureCoordinates, length: MemoryLayout<Float>.size * 2 * Int(astronautModel.numVertices), options:[])
        } else {
            NSLog("Failed to load astronaut model")
        }
        releaseModel(&astronautModel)

        let landerImage = bundle.url(forResource: "VikingLander", withExtension: "jpg")!
        // Load the texture, note that we specify the origin as the texture coordinates
        // are OpenGL convention with the origin at the bottom left
        mLanderTexture = try! loader.newTexture(URL: landerImage, options: [MTKTextureLoader.Option.origin: MTKTextureLoader.Origin.bottomLeft])
        
        let landerModelPath = bundle.path(forResource: "VikingLander", ofType: "obj")
        let landerModelData = NSData(contentsOfFile: landerModelPath!)

        let landerByteCount = landerModelData!.length / MemoryLayout<Int8>.size
        var landerModelBytes = [Int8](repeating: 0, count: landerByteCount)
        landerModelData!.getBytes(&landerModelBytes, length:landerByteCount * MemoryLayout<Int8>.size)

        var landerModel: VuforiaModel = loadModel(&landerModelBytes, Int32(landerModelData!.count))
        if (landerModel.isLoaded) {
            mLanderVertexCount = Int(landerModel.numVertices)
            mLanderVertices = mMetalDevice.makeBuffer(bytes: landerModel.vertices, length: MemoryLayout<Float>.size * 3 * Int(landerModel.numVertices), options:[])
            mLanderTextureCoordinates = mMetalDevice.makeBuffer(bytes: landerModel.textureCoordinates, length: MemoryLayout<Float>.size * 2 * Int(landerModel.numVertices), options:[])
        } else {
            NSLog("Failed to load lander model")
        }
        releaseModel(&landerModel)
    }
    
    
    class func defaultSampler(device: MTLDevice) -> MTLSamplerState? {
        let sampler = MTLSamplerDescriptor()
        sampler.minFilter             = MTLSamplerMinMagFilter.linear
        sampler.magFilter             = MTLSamplerMinMagFilter.linear
        sampler.mipFilter             = MTLSamplerMipFilter.linear
        sampler.maxAnisotropy         = 1
        sampler.sAddressMode          = MTLSamplerAddressMode.clampToEdge
        sampler.tAddressMode          = MTLSamplerAddressMode.clampToEdge
        sampler.rAddressMode          = MTLSamplerAddressMode.clampToEdge
        sampler.normalizedCoordinates = true
        sampler.lodMinClamp           = 0
        sampler.lodMaxClamp           = .greatestFiniteMagnitude
        return device.makeSamplerState(descriptor: sampler)
    }


    class func wrappingSampler(device: MTLDevice) -> MTLSamplerState? {
        let sampler = MTLSamplerDescriptor()
        sampler.minFilter             = MTLSamplerMinMagFilter.nearest
        sampler.magFilter             = MTLSamplerMinMagFilter.nearest
        sampler.mipFilter             = MTLSamplerMipFilter.nearest
        sampler.maxAnisotropy         = 1
        sampler.sAddressMode          = MTLSamplerAddressMode.repeat
        sampler.tAddressMode          = MTLSamplerAddressMode.repeat
        sampler.rAddressMode          = MTLSamplerAddressMode.repeat
        sampler.normalizedCoordinates = true
        sampler.lodMinClamp           = 0
        sampler.lodMaxClamp           = .greatestFiniteMagnitude
        return device.makeSamplerState(descriptor: sampler)
    }
}
