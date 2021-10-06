/*===============================================================================
Copyright (c) 2020, PTC Inc. All rights reserved.

Vuforia is a trademark of PTC Inc., registered in the United States and other
countries.
===============================================================================*/

#include "VuforiaWrapper.h"

#include "AppController.h"
#include "MemoryStream.h"
#include "Models.h"
#include "tiny_obj_loader.h"

#include <vector>

#include "VuMatrixToString.h"
#include "Log.h"

#include "vuforiaKey.h"

AppController controller;

//#ifdef VUFORIA_FEATURE_AREA_TARGET_CAPTURE // TODO: make it conditionally compiled

#include "CaptureController.h"

CaptureController captureController;


//#endif /* VUFORIA_FEATURE_AREA_TARGET_CAPTURE */

struct
{
    void* callbackClass = nullptr;
    void(*errorCallbackMethod)(void *, const char *) = nullptr;
    void(*initDoneCallbackMethod)(void *) = nullptr;
    
    std::function<void(const char* arg)> cameraMatrixCallback = nullptr;
    std::function<void(TrackableObservation* observations, int numObservations)> visibleMarkersCallback = nullptr;
    std::function<void(const char* arg)> projectionMatrixCallback = nullptr;

} gWrapperData;


/// Method to load obj model files, uses C++ so outside extern block
bool loadObjModel(const char * const data, int dataSize,
                  int& numVertices, float** vertices, float** texCoords);


extern "C"
{

int getImageTargetId()
{
    return AppController::IMAGE_TARGET_ID;
}


int getModelTargetId()
{
    return AppController::MODEL_TARGET_ID;
}


void initAR(VuforiaInitConfig config, int target)
{
    // Hold onto pointers for later use by the lambda passed to initAR below
    gWrapperData.callbackClass = config.classPtr;
    gWrapperData.errorCallbackMethod = config.errorCallback;
    gWrapperData.initDoneCallbackMethod = config.initDoneCallback;

    // Create InitConfig structure and populate...
    AppController::InitConfig initConfig;
    initConfig.vbRenderBackend = config.vbRenderBackend;
    initConfig.showErrorCallback = [](const char *errorString) {
        gWrapperData.errorCallbackMethod(gWrapperData.callbackClass, errorString);
    };
    initConfig.initDoneCallback = [](){
        gWrapperData.initDoneCallbackMethod(gWrapperData.callbackClass);
    };
    
    // Call AppController to initialize Vuforia ...
    controller.initAR(initConfig, target, vuforiaKey);
    
    captureController.initWithAppController(&controller);
}


bool startAR()
{
    return controller.startAR();
}


void stopAR()
{
    controller.stopAR();
}


void deinitAR()
{
    controller.deinitAR();
}


bool isARStarted()
{
    return controller.isARStarted();
}


void cameraPerformAutoFocus()
{
    controller.cameraPerformAutoFocus();
}


void cameraRestoreAutoFocus()
{
    controller.cameraRestoreAutoFocus();
}


void configureRendering(int width, int height, void* orientation)
{
    controller.configureRendering(width, height, orientation);
}


bool prepareToRender(double* viewport, void* metalDevice, void* texture, void* encoder)
{
    // Integer to hold the texture unit which is always 0 for Metal
    static int textureUnit = 0;

    VuRenderVideoBackgroundData renderVideoBackgroundData;
    renderVideoBackgroundData.renderData = encoder;
    renderVideoBackgroundData.textureData = texture;
    renderVideoBackgroundData.textureUnitData = &textureUnit;

    return controller.prepareToRender(viewport, &renderVideoBackgroundData);
}


void finishRender()
{
    controller.finishRender();
}


// contents is a 16 element float array
void getVideoBackgroundProjection(void *mvp)
{
    auto renderState = controller.getRenderState();

    memset(mvp, 0, 16 * sizeof(float));
    memcpy(mvp, renderState.vbProjectionMatrix.data, sizeof(renderState.vbProjectionMatrix.data));
}


VuMesh* getVideoBackgroundMesh()
{
    auto renderState = controller.getRenderState();
    assert(renderState.vbMesh);
    return renderState.vbMesh;
}

bool getOrigin(void* projection, void* modelView)
{
    VuMatrix44F projectionMat44;
    VuMatrix44F modelViewMat44;
    if (controller.getOrigin(projectionMat44, modelViewMat44))
    {
        memcpy(projection, &projectionMat44.data, sizeof(projectionMat44.data));
        memcpy(modelView, &modelViewMat44.data, sizeof(modelViewMat44.data));
        
        if (gWrapperData.cameraMatrixCallback) {
            // we invert the view matrix back into the camera pose matrix to maintain backwards-compatibility with existing userinterface API
            // TODO: in future, provide a new API that directly requests the view matrix, eliminating both inversions
            VuMatrix44F cameraPoseMatrix = vuMatrix44FInverse(modelViewMat44); // camera modelView is really just the view matrix, so invert it to get its modelMatrix
            cameraPoseMatrix.data[12] *= 1000;
            cameraPoseMatrix.data[13] *= 1000;
            cameraPoseMatrix.data[14] *= 1000;
            gWrapperData.cameraMatrixCallback(vuMatrix44fToString(cameraPoseMatrix).c_str());
        }
        
        if (gWrapperData.projectionMatrixCallback) {
            gWrapperData.projectionMatrixCallback(vuMatrix44fToString(projectionMat44).c_str());
//            LOG("Sent projection matrix. Resetting projection callback.");
        }
        
        return true;
    }
    
    return false;
}

const char* getDevicePoseStatusInfo()
{
    return controller.getDevicePoseStatusInfo();
}

const char* getDevicePoseStatus()
{
    return controller.getDevicePoseStatus();
}

TrackableObservation* getVisibleTargets()
{
    TrackableObservation* results = controller.getVisibleTargets();
    
    if (results[0].name == nullptr && getNumVisibleTargets() > 0) {
        LOG("results[0].name == NULL. what happened?");
    }

    // TODO: BEN - only include if trackingStatus is not limited, otherwise it never disappears after seeing it once... s
    if (gWrapperData.visibleMarkersCallback) {
//        TrackableObservation visibleMarkers[2];
//
//        visibleMarkers[0].name = "TestName1";
//        visibleMarkers[0].trackingStatus = "NORMAL";
//        visibleMarkers[0].modelViewMatrix = "[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]";
//
//        visibleMarkers[1].name = "TestName2";
//        visibleMarkers[1].trackingStatus = "NORMAL";
//        visibleMarkers[1].modelViewMatrix = "[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]";
//
        
        gWrapperData.visibleMarkersCallback(results, getNumVisibleTargets());
        
//        gWrapperData.visibleMarkersCallback(results->observationData, results->numObservations);
    }
    
    return results;
}

int getNumVisibleTargets() {
    return controller.getNumVisibleTargets();
}

bool getImageTargetResult(void* projection, void* modelView, void* scaledModelView)
{
    VuMatrix44F projectionMatrix;
    VuMatrix44F modelViewMatrix;
    VuMatrix44F scaledModelViewMatrix;
    
    // TODO: BEN - add a new API to controller to get a list of all current observations {name, matrix, status}
    if (controller.getImageTargetResult(projectionMatrix, modelViewMatrix, scaledModelViewMatrix))
    {
        memcpy(projection, &projectionMatrix.data, sizeof(projectionMatrix.data));
        memcpy(modelView, &modelViewMatrix.data, sizeof(modelViewMatrix.data));
        memcpy(scaledModelView, &scaledModelViewMatrix.data, sizeof(scaledModelViewMatrix.data));
        
//        // TODO: BEN - only include if trackingStatus is not limited, otherwise it never disappears after seeing it once... s
//        if (gWrapperData.visibleMarkersCallback) {
//            TrackableObservation visibleMarkers[2];
//
//            visibleMarkers[0].name = "TestName1";
//            visibleMarkers[0].trackingStatus = "NORMAL";
//            visibleMarkers[0].modelViewMatrix = "[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]";
//
//            visibleMarkers[1].name = "TestName2";
//            visibleMarkers[1].trackingStatus = "NORMAL";
//            visibleMarkers[1].modelViewMatrix = "[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]";
//
//            gWrapperData.visibleMarkersCallback(visibleMarkers, 2);
//        }

        return true;
    }
    
//    if (gWrapperData.visibleMarkersCallback) {
//        TrackableObservation visibleMarkers[0];
//        gWrapperData.visibleMarkersCallback(visibleMarkers, 0);
//    }

    return false;
}


bool getModelTargetResult(void* projection, void* modelView, void* scaledModelView)
{
    VuMatrix44F projectionMatrix;
    VuMatrix44F modelViewMatrix;
    VuMatrix44F scaledModelViewMatrix;
    if (controller.getModelTargetResult(projectionMatrix, modelViewMatrix, scaledModelViewMatrix))
    {
        memcpy(projection, &projectionMatrix.data, sizeof(projectionMatrix.data));
        memcpy(modelView, &modelViewMatrix.data, sizeof(modelViewMatrix.data));
        memcpy(scaledModelView, &scaledModelViewMatrix.data, sizeof(scaledModelViewMatrix.data));

        return true;
    }

    return false;
}


bool getModelTargetGuideView(void* mvp, VuImageInfo* guideViewImage)
{
    VuMatrix44F projection;
    VuMatrix44F modelView;
    if (controller.getModelTargetGuideView(projection, modelView, *guideViewImage))
    {
        VuMatrix44F modelViewProjection = vuMatrix44FMultiplyMatrix(projection, modelView);
        memcpy(mvp, &modelViewProjection.data, sizeof(modelViewProjection.data));


        return true;
    }

    return false;
}


VuPlatformARKitInfo getARKitInfo()
{
    auto platformController = controller.getPlatformController();
    assert(platformController);
    
    VuFusionProviderPlatformType fusionProviderPlatformType { VU_FUSION_PROVIDER_PLATFORM_TYPE_UNKNOWN };
    vuPlatformControllerGetFusionProviderPlatformType(platformController, &fusionProviderPlatformType);
    if (fusionProviderPlatformType != VU_FUSION_PROVIDER_PLATFORM_TYPE_ARKIT)
    {
        // ARKit is not in use
        return { nullptr, nullptr };
    }

    VuPlatformARKitInfo arkitInfo;
    if (vuPlatformControllerGetARKitInfo(platformController, &arkitInfo) != VU_SUCCESS)
    {
        // Error getting ARKitInfo
        NSLog(@"Error getting ARKit info");
        return { nullptr, nullptr };
    }
    
    return arkitInfo;
}



VuforiaModel loadModel(const char * const data, int dataSize)
{
    int numVertices = 0;
    float* rawVertices = nullptr;
    float* rawTexCoords = nullptr;
  
    bool ret = loadObjModel(data, dataSize, numVertices, &rawVertices, &rawTexCoords);

    return VuforiaModel {
        ret,
        numVertices,
        rawVertices,
        rawTexCoords,
    };
}


void releaseModel(VuforiaModel* model)
{
    model->isLoaded = false;
    model->numVertices = 0;
    delete[] model->vertices;
    model->vertices = nullptr;
    delete[] model->textureCoordinates;
    model->textureCoordinates = nullptr;
}


// Map the static Model data into the struct instance exposed to Swift
Models_t Models =
{
    NUM_SQUARE_VERTEX,
    NUM_SQUARE_INDEX,
    NUM_SQUARE_WIREFRAME_INDEX,
    squareVertices,
    squareTexCoords,
    squareIndices,
    squareWireframeIndices,
    NUM_CUBE_VERTEX,
    NUM_CUBE_INDEX,
    NUM_CUBE_WIREFRAME_INDEX,
    cubeVertices,
    cubeTexCoords,
    cubeIndices,
    cubeWireframeIndices,
    NUM_AXIS_INDEX,
    NUM_AXIS_VERTEX,
    NUM_AXIS_COLOR,
    axisVertices,
    axisColors,
    axisIndices,
};

} // extern "C"


bool loadObjModel(const char * const data, int dataSize,
                  int& numVertices, float** vertices, float** texCoords)
{
    tinyobj::attrib_t attrib;
    std::vector<tinyobj::shape_t> shapes;
    std::vector<tinyobj::material_t> materials;

    std::string warn;
    std::string err;

    MemoryInputStream aFileDataStream(data, dataSize);
    bool ret = tinyobj::LoadObj(&attrib, &shapes, &materials, &warn, &err, &aFileDataStream);
    if (ret && err.empty())
    {
        numVertices = 0;
        std::vector<float> vecVertices;
        std::vector<float> vecTexCoords;

        // Loop over shapes
        // s is the index into the shapes vector
        // f is the index of the current face
        // v is the index of the current vertex
        for (size_t s = 0; s < shapes.size(); ++s)
        {
            // Loop over faces(polygon)
            size_t index_offset = 0;
            for (size_t f = 0; f < shapes[s].mesh.num_face_vertices.size(); ++f)
            {
                int fv = shapes[s].mesh.num_face_vertices[f];
                numVertices += fv;

                // Loop over vertices in the face.
                for (size_t v = 0; v < fv; ++v)
                {
                    // access to vertex
                    tinyobj::index_t idx = shapes[s].mesh.indices[index_offset + v];

                    vecVertices.push_back(attrib.vertices[3 * idx.vertex_index + 0]);
                    vecVertices.push_back(attrib.vertices[3 * idx.vertex_index + 1]);
                    vecVertices.push_back(attrib.vertices[3 * idx.vertex_index + 2]);

                    // The model may not have texture coordinates for every vertex
                    // If a texture coordinate is missing we just set it to 0,0
                    // This may not be suitable for rendering some OBJ model files
                    if (idx.texcoord_index < 0)
                    {
                        vecTexCoords.push_back(0.f);
                        vecTexCoords.push_back(0.f);
                    }
                    else
                    {
                        vecTexCoords.push_back(attrib.texcoords[2 * idx.texcoord_index + 0]);
                        vecTexCoords.push_back(attrib.texcoords[2 * idx.texcoord_index + 1]);
                    }
                }
                index_offset += fv;
            }
        }

        *vertices = new float[vecVertices.size() * 3];
        memcpy(*vertices, vecVertices.data(), vecVertices.size() * sizeof(float));
        *texCoords = new float[vecTexCoords.size() * 2];
        memcpy(*texCoords, vecTexCoords.data(), vecTexCoords.size() * sizeof(float));
    }
    
    return ret;
}

bool addImageTarget(const char* targetPath, const char* targetName)
{
    return controller.createImageTargetObserver(targetPath, targetName);
}

bool addImageTargetJPG(const char* targetPath, const char* targetName, float targetWidthMeters)
{
    return controller.createImageTargetObserverFromJPG(targetPath, targetName, targetWidthMeters);
}

bool addObjectTarget(const char* targetPath, const char* targetName)
{
    return controller.createObjectTargetObserver(targetPath, targetName);
}

bool addModelTarget(const char* targetPath, const char* targetName)
{
    return controller.createModelTargetObserver(targetPath, targetName);
}

bool addAreaTarget(const char* targetPath, const char* targetName)
{
    return controller.createAreaTargetObserver(targetPath, targetName);
}

//In file CApi.cpp
typedef struct Callbacks
{
    void * classPtr;
    void(*callback)(void *, const char*);
           
}Callbacks;

typedef struct MarkerCallbacks
{
    void * classPtr;
    void(*callback)(void *, TrackableObservation *, int);
           
}MarkerCallbacks;

typedef struct StatusCallback
{
    void * classPtr;
    void(*callback)(void *, const char*, const char*);
}StatusCallback;

typedef struct ProgressCallback
{
    void * classPtr;
    void(*callback)(void *, float);
}ProgressCallback;


typedef struct SuccessOrErrorCallback
{
    void * classPtr;
    void(*callback)(void *, bool, const char*);
}SuccessOrErrorCallback;

//can be inited in some method. Must also be released somewhere. Or can be used with shared_ptr
static Callbacks * cameraCallbacks = new Callbacks();
static MarkerCallbacks * visibleMarkersCallbacks = new MarkerCallbacks();
static Callbacks * projectionCallbacks = new Callbacks();
static StatusCallback * areaTargetStatusCallback = new StatusCallback();
static ProgressCallback * areaTargetProgressCallback = new ProgressCallback();
static SuccessOrErrorCallback * areaTargetSuccessOrErrorCallback = new SuccessOrErrorCallback();

void setCameraMatrixCallback(void * classPtr, void(*callback)(void *, const char*))
{
    cameraCallbacks->classPtr = classPtr;
    cameraCallbacks->callback = callback;
    
    gWrapperData.cameraMatrixCallback = [&](const char* arg) {
        cameraCallbacks->callback(cameraCallbacks->classPtr, arg);
    };
}

void setVisibleMarkersCallback(void * classPtr, void(*callback)(void *, TrackableObservation *, int))
{
    visibleMarkersCallbacks->classPtr = classPtr;
    visibleMarkersCallbacks->callback = callback;
    
    gWrapperData.visibleMarkersCallback = [&](TrackableObservation* arg, int numObservations){
        visibleMarkersCallbacks->callback(cameraCallbacks->classPtr, arg, numObservations);
    };
}

void setProjectionMatrixCallback(void * classPtr, void(*callback)(void *, const char*))
{
    projectionCallbacks->classPtr = classPtr;
    projectionCallbacks->callback = callback;
    
    gWrapperData.projectionMatrixCallback = [&](const char* matrixString) {
        projectionCallbacks->callback(projectionCallbacks->classPtr, matrixString);
//        gWrapperData.projectionMatrixCallback = nullptr; // only call this once
    };
}

void cGetVideoBackgroundPixels() {
    const void* renderData = controller.getVideoBackgroundPixels();
    LOG("got renderData");
    LOG("...");
}

VuImageInfo* cGetCameraFrameImage() {
    return controller.getCameraFrameImage();
}

void cVuforiaCleanupStateMemory() {
    controller.cleanupStateMemory();
}

bool cAreaTargetCaptureStart(const char* objectId, void * classPtr, void(*callback)(void *, const char*, const char*))
{
    areaTargetStatusCallback->classPtr = classPtr;
    areaTargetStatusCallback->callback = callback;
    
    return captureController.areaTargetCaptureStart(objectId, [&](const char* statusString, const char* statusInfoString) {
        areaTargetStatusCallback->callback(areaTargetStatusCallback->classPtr, statusString, statusInfoString);
    });
}

bool cAreaTargetCaptureStop(void * classPtr, void(*callback)(void *, bool, const char *))
{
    areaTargetSuccessOrErrorCallback->classPtr = classPtr;
    areaTargetSuccessOrErrorCallback->callback = callback;

    return captureController.areaTargetCaptureStop([&](bool success, const char* errorMessage) {
        areaTargetSuccessOrErrorCallback->callback(areaTargetSuccessOrErrorCallback->classPtr, success, errorMessage);
    });
}

bool cAreaTargetCaptureGenerate() {
    return captureController.areaTargetCaptureGenerate();
}

//void initCaptureController(VuEngine* engine) {
//    captureController.initWithEngine(engine);
//}

void cSetAreaTargetOutputFolder(const char* path) {
    captureController.setAreaTargetOutputFolder(path);
}

void cOnAreaTargetCaptureProgress(void * classPtr, void(*callback)(void *, float))
{
    areaTargetProgressCallback->classPtr = classPtr;
    areaTargetProgressCallback->callback = callback;
    
    return captureController.onAreaTargetCaptureProgress([&](float progress) {
        areaTargetProgressCallback->callback(areaTargetStatusCallback->classPtr, progress);
    });
}
