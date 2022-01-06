#ifndef FACETRACK_H
#define FACETRACK_H

#include "core/version.h"

#if VERSION_MAJOR == 4
#include "core/object/class_db.h"
typedef Vector<float> GodotFloatVector;
#else
#include "core/object.h"
typedef PoolVector<float> GodotFloatVector;
#endif

#ifdef __OBJC__
typedef NSObject GodotARAnchor;
#else
typedef void GodotARAnchor;
#endif

class FaceTrack : public Object {

  GDCLASS(FaceTrack, Object);

  static FaceTrack *instance;
  static void _bind_methods();

  bool initialized;

public:
  bool initialize();

  bool is_initialized() const;

  void start_session();
  void stop_session();

  GodotFloatVector get_blend_shapes();

  static FaceTrack *get_singleton();

  void _add_anchor(GodotARAnchor *p_anchor);
  void _remove_anchor(GodotARAnchor *p_anchor);
  void _update_anchor(GodotARAnchor *p_anchor);

  FaceTrack();
  ~FaceTrack();
};

#endif
