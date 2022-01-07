#include "facetrack_module.h"

#include "core/version.h"

#if VERSION_MAJOR == 4
#include "core/config/engine.h"
#else
#include "core/engine.h"
#endif

#include "facetrack.h"

FaceTrack *facetrack;

void register_facetrack_types() {
  facetrack = memnew(FaceTrack);
  Engine::get_singleton()->add_singleton(Engine::Singleton("FaceTrack", facetrack));
}

void unregister_facetrack_types() {
  if (facetrack) {
    memdelete(facetrack);
  }
}
