#ifndef FACETRACK_SESSION_DELEGATE_H
#define FACETRACK_SESSION_DELEGATE_H

#import <ARKit/ARKit.h>
#import <UIKit/UIKit.h>

class FaceTrack;

@interface FaceTrackSessionDelegate : NSObject <ARSessionDelegate> {
  FaceTrack *facetrack;
}

@property(nonatomic) FaceTrack *facetrack;

- (void)session:(ARSession *)session didAddAnchors:(NSArray<ARAnchor *> *)anchors API_AVAILABLE(ios(11.0));
- (void)session:(ARSession *)session didRemoveAnchors:(NSArray<ARAnchor *> *)anchors API_AVAILABLE(ios(11.0));
- (void)session:(ARSession *)session didUpdateAnchors:(NSArray<ARAnchor *> *)anchors API_AVAILABLE(ios(11.0));
@end

#endif /* !FACETRACK_SESSION_DELEGATE_H */
