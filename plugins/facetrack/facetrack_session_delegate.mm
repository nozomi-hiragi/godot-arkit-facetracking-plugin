#include "facetrack_session_delegate.h"
#include "facetrack.h"

@implementation FaceTrackSessionDelegate

@synthesize facetrack;

- (void)session:(ARSession *)session didAddAnchors:(NSArray<ARAnchor *> *)anchors {
  for (ARAnchor *anchor in anchors) {
    facetrack->_add_anchor(anchor);
  }
}

- (void)session:(ARSession *)session didRemoveAnchors:(NSArray<ARAnchor *> *)anchors {
  for (ARAnchor *anchor in anchors) {
    facetrack->_remove_anchor(anchor);
  }
}

- (void)session:(ARSession *)session didUpdateAnchors:(NSArray<ARAnchor *> *)anchors {
  for (ARAnchor *anchor in anchors) {
    facetrack->_update_anchor(anchor);
  }
}

@end
