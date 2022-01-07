#include "core/os/os.h"
#include "core/version.h"
#include "scene/resources/surface_tool.h"

#if VERSION_MAJOR == 4
#include "core/input/input.h"
#include "servers/rendering/rendering_server_globals.h"

#define GODOT_MAKE_THREAD_SAFE ;

#else

#include "core/os/input.h"
#include "servers/visual/visual_server_globals.h"
#include "core/os/thread_safe.h"

#define GODOT_MAKE_THREAD_SAFE _THREAD_SAFE_METHOD_

#endif

#import <ARKit/ARKit.h>
#import <UIKit/UIKit.h>

#include <dlfcn.h>

#include "facetrack.h"
#include "facetrack_session_delegate.h"

API_AVAILABLE(ios(11.0))
ARSession *ar_session;

FaceTrackSessionDelegate *facetrack_delegate;

FaceTrack* FaceTrack::instance = NULL;

enum BlendShapes{
  //Left Eye
  BlendShapeLocationEyeBlinkLeft = 0,
  BlendShapeLocationEyeLookDownLeft,
  BlendShapeLocationEyeLookInLeft,
  BlendShapeLocationEyeLookOutLeft,
  BlendShapeLocationEyeLookUpLeft,
  BlendShapeLocationEyeSquintLeft,
  BlendShapeLocationEyeWideLeft,

  //Right Eye
  BlendShapeLocationEyeBlinkRight,
  BlendShapeLocationEyeLookDownRight,
  BlendShapeLocationEyeLookInRight,
  BlendShapeLocationEyeLookOutRight,
  BlendShapeLocationEyeLookUpRight,
  BlendShapeLocationEyeSquintRight,
  BlendShapeLocationEyeWideRight,

  //Mouth and Jaw
  BlendShapeLocationJawForward,
  BlendShapeLocationJawLeft,
  BlendShapeLocationJawRight,
  BlendShapeLocationJawOpen,
  BlendShapeLocationMouthClose,
  BlendShapeLocationMouthFunnel,
  BlendShapeLocationMouthPucker,
  BlendShapeLocationMouthLeft,
  BlendShapeLocationMouthRight,
  BlendShapeLocationMouthSmileLeft,
  BlendShapeLocationMouthSmileRight,
  BlendShapeLocationMouthFrownLeft,
  BlendShapeLocationMouthFrownRight,
  BlendShapeLocationMouthDimpleLeft,
  BlendShapeLocationMouthDimpleRight,
  BlendShapeLocationMouthStretchLeft,
  BlendShapeLocationMouthStretchRight,
  BlendShapeLocationMouthRollLower,
  BlendShapeLocationMouthRollUpper,
  BlendShapeLocationMouthShrugLower,
  BlendShapeLocationMouthShrugUpper,
  BlendShapeLocationMouthPressLeft,
  BlendShapeLocationMouthPressRight,
  BlendShapeLocationMouthLowerDownLeft,
  BlendShapeLocationMouthLowerDownRight,
  BlendShapeLocationMouthUpperUpLeft,
  BlendShapeLocationMouthUpperUpRight,

  //Eyebrows, Cheeks, and Nose
  BlendShapeLocationBrowDownLeft,
  BlendShapeLocationBrowDownRight,
  BlendShapeLocationBrowInnerUp,
  BlendShapeLocationBrowOuterUpLeft,
  BlendShapeLocationBrowOuterUpRight,
  BlendShapeLocationCheekPuff,
  BlendShapeLocationCheekSquintLeft,
  BlendShapeLocationCheekSquintRight,
  BlendShapeLocationNoseSneerLeft,
  BlendShapeLocationNoseSneerRight,

  //Tongue
  BlendShapeLocationTongueOut,

  BlendShapeMax,
};

GodotFloatVector blendShapes;

void FaceTrack::_bind_methods() {
  ClassDB::bind_method(D_METHOD("initialize"), &FaceTrack::initialize);
  ClassDB::bind_method(D_METHOD("is_initialized"), &FaceTrack::is_initialized);
  ClassDB::bind_method(D_METHOD("get_blend_shapes"), &FaceTrack::get_blend_shapes);
};

FaceTrack* FaceTrack::get_singleton() {
  return instance;
};

FaceTrack::FaceTrack() {
  ERR_FAIL_COND(instance != NULL);
  instance = this;
}

FaceTrack::~FaceTrack() {}

bool FaceTrack::is_initialized() const {
  return initialized;
}

bool FaceTrack::initialize() {
  if (initialized) {
    return false;
  }

  blendShapes.resize(BlendShapeMax);

  if (@available(iOS 11, *)) {
    Class ARSessionClass = NSClassFromString(@"ARSession");
    if (ARSessionClass == Nil) {
      void *arkit_handle = dlopen("/System/Library/Frameworks/ARKit.framework/ARKit", RTLD_NOW);
      if (arkit_handle) {
        ARSessionClass = NSClassFromString(@"ARSession");
      } else {
        print_line("ARKit init failed");
        return false;
      }
    }
    ar_session = [ARSessionClass new];
    facetrack_delegate = [FaceTrackSessionDelegate new];
    facetrack_delegate.facetrack = this;
    ar_session.delegate = facetrack_delegate;
  
    initialized = true;

    start_session();
  }

  return true;
}

void FaceTrack::start_session() {
  if (!initialized) {
    return;
  }

  if (@available(iOS 13.0, *)) {
    Class ARFaceTrackingConfigurationClass = NSClassFromString(@"ARFaceTrackingConfiguration");
    if (!ARFaceTrackingConfiguration.isSupported) {
      return;
    }

    ARFaceTrackingConfiguration *configuration = [ARFaceTrackingConfigurationClass new];

    configuration.maximumNumberOfTrackedFaces = ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces;

    [ar_session runWithConfiguration:configuration];
  }
}

void FaceTrack::stop_session() {
  if (!initialized) {
    return;
  }
  if (@available(iOS 11.0, *)) {
    [ar_session pause];
  }
}

void FaceTrack::_add_anchor(GodotARAnchor *p_anchor) {
  // GODOT_MAKE_THREAD_SAFE
  if (@available(iOS 13.0, *)) {
    ARFaceAnchor *anchor = (ARFaceAnchor *)p_anchor;
    String name = String::utf8([anchor.name UTF8String]);
    print_line("add:" + name);
  }
}

void FaceTrack::_remove_anchor(GodotARAnchor *p_anchor) {
  // GODOT_MAKE_THREAD_SAFE
  if (@available(iOS 13.0, *)) {
    ARFaceAnchor *anchor = (ARFaceAnchor *)p_anchor;
    String name = String::utf8([anchor.name UTF8String]);
    print_line("remove:" + name);
  }
}

void FaceTrack::_update_anchor(GodotARAnchor *p_anchor) {
  // GODOT_MAKE_THREAD_SAFE
  if (@available(iOS 13.0, *)) {
    ARFaceAnchor *anchor = (ARFaceAnchor *)p_anchor;

#if VERSION_MAJOR == 4
    float *w = blendShapes.ptrw();
#else
    PoolVector<float>::Write w = blendShapes.write();
#endif

    // Left Eye
    w[BlendShapeLocationEyeBlinkLeft] = [anchor.blendShapes[ARBlendShapeLocationEyeBlinkLeft] floatValue];
    w[BlendShapeLocationEyeLookDownLeft] = [anchor.blendShapes[ARBlendShapeLocationEyeLookDownLeft] floatValue];
    w[BlendShapeLocationEyeLookInLeft] = [anchor.blendShapes[ARBlendShapeLocationEyeLookInLeft] floatValue];
    w[BlendShapeLocationEyeLookOutLeft] = [anchor.blendShapes[ARBlendShapeLocationEyeLookOutLeft] floatValue];
    w[BlendShapeLocationEyeLookUpLeft] = [anchor.blendShapes[ARBlendShapeLocationEyeLookUpLeft] floatValue];
    w[BlendShapeLocationEyeSquintLeft] = [anchor.blendShapes[ARBlendShapeLocationEyeSquintLeft] floatValue];
    w[BlendShapeLocationEyeWideLeft] = [anchor.blendShapes[ARBlendShapeLocationEyeWideLeft] floatValue];

    // Right Eye
    w[BlendShapeLocationEyeBlinkRight] = [anchor.blendShapes[ARBlendShapeLocationEyeBlinkRight] floatValue];
    w[BlendShapeLocationEyeLookDownRight] = [anchor.blendShapes[ARBlendShapeLocationEyeLookDownRight] floatValue];
    w[BlendShapeLocationEyeLookInRight] = [anchor.blendShapes[ARBlendShapeLocationEyeLookInRight] floatValue];
    w[BlendShapeLocationEyeLookOutRight] = [anchor.blendShapes[ARBlendShapeLocationEyeLookOutRight] floatValue];
    w[BlendShapeLocationEyeLookUpRight] = [anchor.blendShapes[ARBlendShapeLocationEyeLookUpRight] floatValue];
    w[BlendShapeLocationEyeSquintRight] = [anchor.blendShapes[ARBlendShapeLocationEyeSquintRight] floatValue];
    w[BlendShapeLocationEyeWideRight] = [anchor.blendShapes[ARBlendShapeLocationEyeWideRight] floatValue];

    // Mouth and Jaw
    w[BlendShapeLocationJawForward] = [anchor.blendShapes[ARBlendShapeLocationJawForward] floatValue];
    w[BlendShapeLocationJawLeft] = [anchor.blendShapes[ARBlendShapeLocationJawLeft] floatValue];
    w[BlendShapeLocationJawRight] = [anchor.blendShapes[ARBlendShapeLocationJawRight] floatValue];
    w[BlendShapeLocationJawOpen] = [anchor.blendShapes[ARBlendShapeLocationJawOpen] floatValue];
    w[BlendShapeLocationMouthClose] = [anchor.blendShapes[ARBlendShapeLocationMouthClose] floatValue];
    w[BlendShapeLocationMouthFunnel] = [anchor.blendShapes[ARBlendShapeLocationMouthFunnel] floatValue];
    w[BlendShapeLocationMouthPucker] = [anchor.blendShapes[ARBlendShapeLocationMouthPucker] floatValue];
    w[BlendShapeLocationMouthLeft] = [anchor.blendShapes[ARBlendShapeLocationMouthLeft] floatValue];
    w[BlendShapeLocationMouthRight] = [anchor.blendShapes[ARBlendShapeLocationMouthRight] floatValue];
    w[BlendShapeLocationMouthSmileLeft] = [anchor.blendShapes[ARBlendShapeLocationMouthSmileLeft] floatValue];
    w[BlendShapeLocationMouthSmileRight] = [anchor.blendShapes[ARBlendShapeLocationMouthSmileRight] floatValue];
    w[BlendShapeLocationMouthFrownLeft] = [anchor.blendShapes[ARBlendShapeLocationMouthFrownLeft] floatValue];
    w[BlendShapeLocationMouthFrownRight] = [anchor.blendShapes[ARBlendShapeLocationMouthFrownRight] floatValue];
    w[BlendShapeLocationMouthDimpleLeft] = [anchor.blendShapes[ARBlendShapeLocationMouthDimpleLeft] floatValue];
    w[BlendShapeLocationMouthDimpleRight] = [anchor.blendShapes[ARBlendShapeLocationMouthDimpleRight] floatValue];
    w[BlendShapeLocationMouthStretchLeft] = [anchor.blendShapes[ARBlendShapeLocationMouthStretchLeft] floatValue];
    w[BlendShapeLocationMouthStretchRight] = [anchor.blendShapes[ARBlendShapeLocationMouthStretchRight] floatValue];
    w[BlendShapeLocationMouthRollLower] = [anchor.blendShapes[ARBlendShapeLocationMouthRollLower] floatValue];
    w[BlendShapeLocationMouthRollUpper] = [anchor.blendShapes[ARBlendShapeLocationMouthRollUpper] floatValue];
    w[BlendShapeLocationMouthShrugLower] = [anchor.blendShapes[ARBlendShapeLocationMouthShrugLower] floatValue];
    w[BlendShapeLocationMouthShrugUpper] = [anchor.blendShapes[ARBlendShapeLocationMouthShrugUpper] floatValue];
    w[BlendShapeLocationMouthPressLeft] = [anchor.blendShapes[ARBlendShapeLocationMouthPressLeft] floatValue];
    w[BlendShapeLocationMouthPressRight] = [anchor.blendShapes[ARBlendShapeLocationMouthPressRight] floatValue];
    w[BlendShapeLocationMouthLowerDownLeft] = [anchor.blendShapes[ARBlendShapeLocationMouthLowerDownLeft] floatValue];
    w[BlendShapeLocationMouthLowerDownRight] = [anchor.blendShapes[ARBlendShapeLocationMouthLowerDownRight] floatValue];
    w[BlendShapeLocationMouthUpperUpLeft] = [anchor.blendShapes[ARBlendShapeLocationMouthUpperUpLeft] floatValue];
    w[BlendShapeLocationMouthUpperUpRight] = [anchor.blendShapes[ARBlendShapeLocationMouthUpperUpRight] floatValue];

    // Eyebrows, Cheeks, and Nose
    w[BlendShapeLocationBrowDownRight] = [anchor.blendShapes[ARBlendShapeLocationBrowDownRight] floatValue];
    w[BlendShapeLocationBrowDownLeft] = [anchor.blendShapes[ARBlendShapeLocationBrowDownLeft] floatValue];
    w[BlendShapeLocationBrowInnerUp] = [anchor.blendShapes[ARBlendShapeLocationBrowInnerUp] floatValue];
    w[BlendShapeLocationBrowOuterUpLeft] = [anchor.blendShapes[ARBlendShapeLocationBrowOuterUpLeft] floatValue];
    w[BlendShapeLocationBrowOuterUpRight] = [anchor.blendShapes[ARBlendShapeLocationBrowOuterUpRight] floatValue];
    w[BlendShapeLocationCheekPuff] = [anchor.blendShapes[ARBlendShapeLocationCheekPuff] floatValue];
    w[BlendShapeLocationCheekSquintLeft] = [anchor.blendShapes[ARBlendShapeLocationCheekSquintLeft] floatValue];
    w[BlendShapeLocationCheekSquintRight] = [anchor.blendShapes[ARBlendShapeLocationCheekSquintRight] floatValue];
    w[BlendShapeLocationNoseSneerLeft] = [anchor.blendShapes[ARBlendShapeLocationNoseSneerLeft] floatValue];
    w[BlendShapeLocationNoseSneerRight] = [anchor.blendShapes[ARBlendShapeLocationNoseSneerRight] floatValue];

    // Tongue
    w[BlendShapeLocationTongueOut] = [anchor.blendShapes[ARBlendShapeLocationTongueOut] floatValue];
  }
}

GodotFloatVector FaceTrack::get_blend_shapes() {
  return blendShapes;
}
