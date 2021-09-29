/*===============================================================================
Copyright (c) 2020, PTC Inc. All rights reserved.
 
Vuforia is a trademark of PTC Inc., registered in the United States and other
countries.
===============================================================================*/

import UIKit
import MetalKit
import ARKit


func getOrientation() -> UIInterfaceOrientation {
    var orientation: UIInterfaceOrientation? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.windows.first?.windowScene?.interfaceOrientation
        } else {
            return UIApplication.shared.statusBarOrientation
        }
    }
    
    if (orientation == nil) {
        return UIInterfaceOrientation.unknown
    }
    
    return orientation!
}


class VuforiaView:UIView {

    private var mDisplayLink:CADisplayLink?
    
    var mVuforiaStarted = false
    // Note: UIInterfaceOrientation.landscapeRight corresponds to Vuforia's "Landscape Left"
    private var mCurrentOrientation = UIInterfaceOrientation.unknown
    
    private var mLibrary:MTLLibrary!
    private var mRenderer:MetalRenderer!
    
    private var mMetalDevice:MTLDevice!
    private var mMetalCommandQueue:MTLCommandQueue!
    private var mCommandExecutingSemaphore:DispatchSemaphore!

    private var mDepthStencilState:MTLDepthStencilState!
    private var mDepthTexture:MTLTexture!

    private var mVideoBackgroundProjectionBuffer:MTLBuffer!
    private var mGuideViewModelViewProjectionBuffer:MTLBuffer!

    /// Used by accessFusionProviderPointers() method to avoid logging every frame
    private var mLastLog = Date().timeIntervalSinceReferenceDate
    
    override class var layerClass: AnyClass {
        return CAMetalLayer.self
    }
    
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
                
        mDisplayLink = CADisplayLink(target: self, selector: #selector(renderFrame))
        mDisplayLink?.add(to: .current, forMode: .common)
        
        contentScaleFactor = UIScreen.main.nativeScale

        // Get the system default metal device
        mMetalDevice = MTLCreateSystemDefaultDevice()
        
        // Metal command queue
        mMetalCommandQueue = mMetalDevice.makeCommandQueue()
        
        // Create a dispatch semaphore, used to synchronise command execution
        self.mCommandExecutingSemaphore = DispatchSemaphore.init(value:1)

        // Create a CAMetalLayer and set its frame to match that of the view
        let layer = self.layer as! CAMetalLayer
        layer.device = mMetalDevice
        layer.pixelFormat = MTLPixelFormat.bgra8Unorm
        layer.framebufferOnly = true
        layer.contentsScale = self.contentScaleFactor
        
        // Get the default library from the bundle (Metal shaders)
        mLibrary = mMetalDevice.makeDefaultLibrary()
        
        // Video background projection matrix buffer
        mVideoBackgroundProjectionBuffer = mMetalDevice.makeBuffer(length: MemoryLayout<Float>.size * 16, options: [])
        // Guide view model view projection matrix buffer
        mGuideViewModelViewProjectionBuffer = mMetalDevice.makeBuffer(length: MemoryLayout<Float>.size * 16, options: [])

        // Fragment depth stencil
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = MTLCompareFunction.less
        depthStencilDescriptor.isDepthWriteEnabled = true
        self.mDepthStencilState = mMetalDevice.makeDepthStencilState(descriptor: depthStencilDescriptor)

        mRenderer = MetalRenderer(metalDevice: mMetalDevice, layer: layer, library: mLibrary, depthAttachmentPixelFormat: MTLPixelFormat.depth32Float)
    }
    
    
    required convenience init?(coder: NSCoder) {
        // This view fills the whole screen
        self.init(frame: UIScreen.main.bounds)
    }

    
    func finish() {
        // Break reference cycle with mDisplayLink to allow the view to be deinit'ed
        mDisplayLink?.invalidate()
        mDisplayLink = nil
    }
    
    
    func createScreenSizeDependentResources(screenSizePixels:CGSize) {
        // Create a depth texture that is needed when rendering the augmentation.
        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.depth32Float,
                                                                              width: Int(screenSizePixels.width), height: Int(screenSizePixels.height),
                                                                              mipmapped: false)
        depthTextureDescriptor.usage = MTLTextureUsage.renderTarget

        mDepthTexture = mMetalDevice.makeTexture(descriptor: depthTextureDescriptor)
    }


    func configureView() {
        let orientation = getOrientation()
        
        if (orientation != UIInterfaceOrientation.unknown && orientation != mCurrentOrientation) {
            mCurrentOrientation = orientation
            
            var screenSizePixels = UIScreen.main.bounds.size
            screenSizePixels.width *= self.contentScaleFactor
            screenSizePixels.height *= self.contentScaleFactor

            // Update the layer size
            let layer = self.layer as! CAMetalLayer
            layer.drawableSize.width = screenSizePixels.width
            layer.drawableSize.height = screenSizePixels.height

            // Update Vuforia
            configureRendering(
                Int32(screenSizePixels.width),
                Int32(screenSizePixels.height),
                &mCurrentOrientation)
            
            // Update Metal resources that depend on the screen size
            createScreenSizeDependentResources(screenSizePixels: screenSizePixels)
        }
    }
    
    
    @objc func renderFrame() {
        objc_sync_enter(self)
        if (mVuforiaStarted) {
            configureView()
            renderFrameVuforiaInternal()
        }
        objc_sync_exit(self)
    }
    
    
    func renderFrameVuforiaInternal() {
        //Check if Camera is Started
        if (!isARStarted()) {
            return;
        }
        
        // ========== Set up ==========
        let layer = self.layer as! CAMetalLayer
        
        // --- Command buffer ---
        // Get the command buffer from the command queue
        guard let commandBuffer = mMetalCommandQueue.makeCommandBuffer() else {
            return
        }
        
        // Get the next drawable from the CAMetalLayer
        let drawable = layer.nextDrawable()
        
        // It's possible for nextDrawable to return nil, which means a call to
        // renderCommandEncoderWithDescriptor will fail
        if (drawable == nil) {
            return
        }
        
        // Wait for exclusive access to the GPU
        let _ = mCommandExecutingSemaphore.wait(timeout: DispatchTime.distantFuture)
        
        // -- Render pass descriptor ---
        // Set up a render pass decriptor
        let renderPassDescriptor = MTLRenderPassDescriptor()
        
        // Draw to the drawable's texture
        renderPassDescriptor.colorAttachments[0].texture = drawable?.texture
        // Clear the colour attachment in case there is no video frame
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadAction.clear
        // Store the data in the texture when rendering is complete
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreAction.store
        // Use textureDepth for depth operations.
        renderPassDescriptor.depthAttachment.texture = mDepthTexture;
        
        // Get a command encoder to encode into the command buffer
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        var viewportsValue: Array<Double> = Array(arrayLiteral:0.0, 0.0, 0.0, 0.0, 0.0, 1.0)
        if (prepareToRender(&viewportsValue,
                            UnsafeMutableRawPointer(Unmanaged.passUnretained(mMetalDevice!).toOpaque()),
                            UnsafeMutableRawPointer(Unmanaged.passUnretained(drawable!.texture).toOpaque()),
                            UnsafeMutableRawPointer(Unmanaged.passUnretained(encoder).toOpaque()))) {

            let viewport = MTLViewport(
                originX: viewportsValue[0], originY: viewportsValue[1],
                width: viewportsValue[2], height: viewportsValue[3],
                znear: viewportsValue[4], zfar: viewportsValue[5])
            encoder.setViewport(viewport)

            // Once the camera is initialized we can get the video background rendering values
            getVideoBackgroundProjection(mVideoBackgroundProjectionBuffer.contents())
            // Call the renderer to draw the video background
            mRenderer.renderVideoBackground(encoder: encoder, projectionMatrix: mVideoBackgroundProjectionBuffer, mesh: getVideoBackgroundMesh().pointee)

            encoder.setDepthStencilState(mDepthStencilState)
            
            var worldOriginProjectionMatrix = matrix_float4x4()
            var worldOriginModelViewMatrix = matrix_float4x4()
            if (getOrigin(&worldOriginProjectionMatrix.columns, &worldOriginModelViewMatrix.columns)) {
                mRenderer.renderWorldOrigin(encoder: encoder, projectionMatrix: worldOriginProjectionMatrix, modelViewMatrix: worldOriginModelViewMatrix)
            }
            
            getVisibleTargets();

//            var trackableProjection = matrix_float4x4()
//            var trackableModelView = matrix_float4x4()
//            var trackableScaledModelView = matrix_float4x4()
//
//            // Render image target bounding box if detected
//            if (getImageTargetResult(&trackableProjection.columns, &trackableModelView.columns, &trackableScaledModelView.columns)) {
////                mRenderer.renderImageTarget(encoder: encoder,
////                                            projectionMatrix: trackableProjection,
////                                            modelViewMatrix: trackableModelView,
////                                            scaledModelViewMatrix: trackableScaledModelView)
//
//                print("detected imageTarget");
//            }
//
//            var guideViewImageInfo: VuImageInfo = VuImageInfo()
//            // Render model target bounding box if detected, if not render guide view
//            if (getModelTargetResult(&trackableProjection.columns, &trackableModelView.columns, &trackableScaledModelView.columns)) {
////                mRenderer.renderModelTarget(encoder: encoder,
////                                            projectionMatrix: trackableProjection,
////                                            modelViewMatrix: trackableModelView,
////                                            scaledModelViewMatrix: trackableScaledModelView)
//
//                print("detected modelTarget");
//
//            } else if (getModelTargetGuideView(mGuideViewModelViewProjectionBuffer.contents(), &guideViewImageInfo)) {
//                mRenderer.renderModelTargetGuideView(encoder: encoder, modelViewProjectionMatrix: mGuideViewModelViewProjectionBuffer, guideViewImageInfo: &guideViewImageInfo)
//            }
            
            //accessFusionProviderPointers()
        }
        
        finishRender()
        
        // ========== Finish Metal rendering ==========
        encoder.endEncoding()
        
        // Commit the rendering commands
        // Command completed handler
        commandBuffer.addCompletedHandler { _ in self.mCommandExecutingSemaphore.signal()}
        
        // Present the drawable when the command buffer has been executed (Metal
        // calls to CoreAnimation to tell it to put the texture on the display when
        // the rendering is complete)
        commandBuffer.present(drawable!)
        
        // Commit the command buffer for execution as soon as possible
        commandBuffer.commit()
    }

    
    /// Method to demonstrate how to get access to the ARKit session and frame objects held by Vuforia
    func accessFusionProviderPointers()
    {
        let info = getARKitInfo()
        if ((info.arSession == nil) ||
            (info.arFrame == nil))
        {
            NSLog("Fusion provider platform pointers are not set")
            return
        }
        
        let arSession = Unmanaged<ARSession>.fromOpaque(info.arSession).takeUnretainedValue()
        
        // The ARKit ARFrame pointer is provided as part of the ARKitInfo
        // It is preferred to extract it from the session, see below.
        let arFrame = Unmanaged<ARFrame>.fromOpaque(info.arFrame).takeUnretainedValue()
        
        // In ARKit the same ARFrame can also be extracted from the session
        // as shown below, and should be the preferred method.
        let arSessionFrame = arSession.currentFrame
        if (arFrame != arSessionFrame)
        {
            // This test would not normally be needed, it is here for
            // example purposes only
            NSLog("Error: arFrame does not match the one on the ARSession")
            return
        }
        
        // Simple demonstration of access to the ARKit objects,
        // log the session object and current tracking state.
        // This code runs every frame but only generates log messages
        // every 5 seconds to avoid flooding the log output.

        let now = Date().timeIntervalSinceReferenceDate
        if ((now - mLastLog) > 5)
        {
            mLastLog = now
            
            NSLog("ARSession is %@", arSession);
            if (arSessionFrame?.camera != nil)
            {
                let trackingStateStr:String
                switch(arSessionFrame?.camera.trackingState)
                {
                case .notAvailable:
                        trackingStateStr = "notAvailable"
                        break
                case .normal:
                        trackingStateStr = "Normal"
                        break
                case .none:
                    trackingStateStr = "None"
                    break
                case .some(.limited(_)):
                    trackingStateStr = "Limited"
                    break
                }
                NSLog("The current tracking state is: %@", trackingStateStr)
            }
        }
    }
}
