//
//  GPUImageCustomRawDataOutput.m
//  gpuimagetokbox
//
//  Created by Fujiki Takeshi on 12/18/15.
//  Copyright © 2015 takecian. All rights reserved.
//

#import "GPUImageCustomRawDataOutput.h"
#import "TBExamplePublisher.h"

static NSString* const kApiKey = @"100";
// Replace with your generated session ID
static NSString* const kSessionId = @"1_MX4xMDB-fjE0NTA0NTc4NTEzODZ-ZlhzaWh3TVk3WG10UE1zd3ZscWlyRmVIfn4";
// Replace with your generated token
static NSString* const kToken = @"T1==cGFydG5lcl9pZD0xMDAmc2RrX3ZlcnNpb249dGJwaHAtdjAuOTEuMjAxMS0wNy0wNSZzaWc9NzQ5MzdiMzAyODllODYwOTU3NDAxYjg0N2EzODg4ZmMxOWJjMTQwMDpzZXNzaW9uX2lkPTFfTVg0eE1EQi1makUwTlRBME5UYzROVEV6T0RaLVpsaHphV2gzVFZrM1dHMTBVRTF6ZDNac2NXbHlSbVZJZm40JmNyZWF0ZV90aW1lPTE0NTA0NTYxODkmcm9sZT1tb2RlcmF0b3Imbm9uY2U9MTQ1MDQ1NjE4OS4xMDgxOTA0NjkzODYzJmV4cGlyZV90aW1lPTE0NTMwNDgxODk=";

@interface GPUImageCustomRawDataOutput ()<OTSessionDelegate, OTPublisherDelegate>

@end

@implementation GPUImageCustomRawDataOutput{
    OTSession* _session;
    OTVideoFrame* _videoFrame;
    TBExamplePublisher* _publisher;
    
    BOOL _capturing;
    uint32_t _captureWidth;
    uint32_t _captureHeight;
}

@synthesize newFrameAvailableBlockWithTime = _newFrameAvailableBlockWithTime;

- (void)startRecording;
{
    _captureWidth = 640;
    _captureHeight = 480;
    
    _videoFrame = [[OTVideoFrame alloc] initWithFormat:
                   [OTVideoFormat videoFormatNV12WithWidth:_captureWidth
                                                    height:_captureHeight]];
    // setup session
    // Step 1: As the view comes into the foreground, initialize a new instance
    // of OTSession and begin the connection process.
    _session = [[OTSession alloc] initWithApiKey:kApiKey
                                       sessionId:kSessionId
                                        delegate:self];
    [self doConnect];
    
}

- (void)finishRecording{
    [self doUnpublish];
}

/**
 * Asynchronously begins the session connect process. Some time later, we will
 * expect a delegate method to call us back with the results of this action.
 */
- (void)doConnect
{
    OTError *error = nil;
    [_session connectWithToken:kToken error:&error];
    if (error)
    {
        NSLog(@"error doConnect");
        //        [self showAlert:[error localizedDescription]];
    }
}

- (void)doPublish
{
    NSLog(@"doPublish");
    _publisher = [[TBExamplePublisher alloc]
                  initWithDelegate:self
                  name:[[UIDevice currentDevice] name]
                  capture: self];
    
    OTError *error = nil;
    [_session publish:_publisher error:&error];
    if (error)
    {
        NSLog(@"error doPublish");
        //        [self showAlert:[error localizedDescription]];
    }
    
    //    [_publisher.view setFrame:CGRectMake(0, 0, widgetWidth, widgetHeight)];
    //    [self.view addSubview:_publisher.view];
}

- (void)doUnpublish
{
    NSLog(@"doUnpublish");
    OTError *error = nil;
    [_session unpublish:_publisher error:&error];
    if (error)
    {
        NSLog(@"error doUnpublish");
        //        [self showAlert:[error localizedDescription]];
    }
    
    //    [_publisher.view setFrame:CGRectMake(0, 0, widgetWidth, widgetHeight)];
    //    [self.view addSubview:_publisher.view];
}


# pragma mark - OTSession delegate callbacks

- (void)sessionDidConnect:(OTSession*)session
{
    NSLog(@"sessionDidConnect (%@)", session.sessionId);
    
    // Step 2: We have successfully connected, now instantiate a publisher and
    // begin pushing A/V streams into OpenTok.
    [self doPublish];
}

- (void)sessionDidDisconnect:(OTSession*)session
{
    NSString* alertMessage =
    [NSString stringWithFormat:@"Session disconnected: (%@)",
     session.sessionId];
    NSLog(@"sessionDidDisconnect (%@)", alertMessage);
}

- (void)session:(OTSession*)mySession
  streamCreated:(OTStream *)stream
{
    NSLog(@"session streamCreated (%@)", stream.streamId);
    
    // Step 3a: (if NO == subscribeToSelf): Begin subscribing to a stream we
    // have seen on the OpenTok session.
    //    if (nil == _subscriber && !subscribeToSelf)
    //    {
    //        [self doSubscribe:stream];
    //    }
}

- (void)session:(OTSession*)session
streamDestroyed:(OTStream *)stream
{
    NSLog(@"session streamDestroyed (%@)", stream.streamId);
    
    //    if ([_subscriber.stream.streamId isEqualToString:stream.streamId])
    //    {
    //        [self cleanupSubscriber];
    //    }
}

- (void)  session:(OTSession *)session
connectionCreated:(OTConnection *)connection
{
    NSLog(@"session connectionCreated (%@)", connection.connectionId);
}

- (void)    session:(OTSession *)session
connectionDestroyed:(OTConnection *)connection
{
    NSLog(@"session connectionDestroyed (%@)", connection.connectionId);
    //    if ([_subscriber.stream.connection.connectionId
    //         isEqualToString:connection.connectionId])
    //    {
    //        [self cleanupSubscriber];
    //    }
}

- (void) session:(OTSession*)session
didFailWithError:(OTError*)error
{
    NSLog(@"didFailWithError: (%@)", error);
}

# pragma mark - OTPublisher delegate callbacks

- (void)publisher:(OTPublisherKit *)publisher
    streamCreated:(OTStream *)stream
{
    NSLog(@"streamCreated");
    // Step 3b: (if YES == subscribeToSelf): Our own publisher is now visible to
    // all participants in the OpenTok session. We will attempt to subscribe to
    // our own stream. Expect to see a slight delay in the subscriber video and
    // an echo of the audio coming from the device microphone.
    //    if (nil == _subscriber && subscribeToSelf)
    //    {
    //        [self doSubscribe:stream];
    //    }
    [self startCapture];
}

- (void)publisher:(OTPublisherKit*)publisher
  streamDestroyed:(OTStream *)stream
{
    NSLog(@"streamDestroyed");
    //    if ([_subscriber.stream.streamId isEqualToString:stream.streamId])
    //    {
    //        [self cleanupSubscriber];
    //    }
    
    [self cleanupPublisher];
    [self stopCapture];
}

- (void)publisher:(OTPublisherKit*)publisher
 didFailWithError:(OTError*) error
{
    NSLog(@"publisher didFailWithError %@", error);
    [self cleanupPublisher];
}

- (void)cleanupPublisher {
    //    [_publisher.view removeFromSuperview];
    _publisher = nil;
    // this is a good place to notify the end-user that publishing has stopped.
    [self stopCapture];
}

- (BOOL)active {
    return _capturing;
}

- (void)mute:(BOOL)value{
    
}

/// Start/Stop sending video frames.
- (void)showVideo:(BOOL)show {
    //    sendVideo = show;
}

// OTVideoCapture
/**
 * Initializes the video capturer.
 */
- (void)initCapture {
    
}
/**
 * Releases the video capturer.
 */
- (void)releaseCapture{
    
}
- (BOOL) isCaptureStarted {
    return _capturing;
}

- (int32_t) startCapture {
    _capturing = YES;
    return 0;
}

- (int32_t) stopCapture {
    _capturing = NO;
    return 0;
}

- (void)updateCaptureFormatWithWidth:(int)width height:(int)height
{
    _captureWidth = width;
    _captureHeight = height;
    [_videoFrame setFormat:[OTVideoFormat
                            videoFormatNV12WithWidth:_captureWidth
                            height:_captureHeight]];
}

/**
 * Def: sanitary(n): A contiguous image buffer with no padding. All bytes in the
 * store are actual pixel data.
 */
- (BOOL)imageBufferIsSanitary:(CVImageBufferRef)imageBuffer
{
    size_t planeCount = CVPixelBufferGetPlaneCount(imageBuffer);
    
    for (int i = 0; i < CVPixelBufferGetPlaneCount(imageBuffer); i++) {
        size_t imageWidth =
        CVPixelBufferGetWidthOfPlane(imageBuffer, i) *
        CVPixelBufferGetHeightOfPlane(imageBuffer, i);
        
        size_t dataWidth =
        CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, i) *
        CVPixelBufferGetHeightOfPlane(imageBuffer, i);
        
        if (imageWidth != dataWidth) {
            return NO;
        }
        
        BOOL hasNextAddress = CVPixelBufferGetPlaneCount(imageBuffer) > i + 1;
        BOOL nextPlaneContiguous = YES;
        
        if (hasNextAddress) {
            size_t planeLength = dataWidth;
            
            uint8_t* baseAddress =
            CVPixelBufferGetBaseAddressOfPlane(imageBuffer, i);
            
            uint8_t* nextAddress =
            CVPixelBufferGetBaseAddressOfPlane(imageBuffer, i + 1);
            
            nextPlaneContiguous = &(baseAddress[planeLength]) == nextAddress;
        }
        
        if (!nextPlaneContiguous) {
            return NO;
        }
    }
    
    return YES;
}

- (size_t)sanitizeImageBuffer:(CVImageBufferRef)imageBuffer
                         data:(uint8_t**)data
                       planes:(NSPointerArray*)planes
{
    uint32_t pixelFormat = CVPixelBufferGetPixelFormatType(imageBuffer);
    if (kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange == pixelFormat ||
        kCVPixelFormatType_420YpCbCr8BiPlanarFullRange == pixelFormat)
    {
        return [self sanitizeBiPlanarImageBuffer:imageBuffer
                                            data:data
                                          planes:planes];
    } else {
        NSLog(@"No sanitization implementation for pixelFormat %d",
              pixelFormat);
        *data = NULL;
        return 0;
    }
}

- (size_t)sanitizeBiPlanarImageBuffer:(CVImageBufferRef)imageBuffer
                                 data:(uint8_t**)data
                               planes:(NSPointerArray*)planes
{
    size_t sanitaryBufferSize = 0;
    for (int i = 0; i < CVPixelBufferGetPlaneCount(imageBuffer); i++) {
        size_t planeImageWidth =
        // TODO: (Apple bug?) biplanar pixel format reports 1/2 the width of
        // what actually ends up in the pixel buffer for interleaved chroma.
        // The only thing I could do about it is use image width for both plane
        // calculations, in spite of this being technically wrong.
        //CVPixelBufferGetWidthOfPlane(imageBuffer, i);
        CVPixelBufferGetWidth(imageBuffer);
        size_t planeImageHeight =
        CVPixelBufferGetHeightOfPlane(imageBuffer, i);
        sanitaryBufferSize += (planeImageWidth * planeImageHeight);
    }
    uint8_t* newImageBuffer = malloc(sanitaryBufferSize);
    size_t bytesCopied = 0;
    for (int i = 0; i < CVPixelBufferGetPlaneCount(imageBuffer); i++) {
        [planes addPointer:&(newImageBuffer[bytesCopied])];
        void* planeBaseAddress =
        CVPixelBufferGetBaseAddressOfPlane(imageBuffer, i);
        size_t planeDataWidth =
        CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, i);
        size_t planeImageWidth =
        // Same as above. Use full image width for both luma and interleaved
        // chroma planes.
        //CVPixelBufferGetWidthOfPlane(imageBuffer, i);
        CVPixelBufferGetWidth(imageBuffer);
        size_t planeImageHeight =
        CVPixelBufferGetHeightOfPlane(imageBuffer, i);
        for (int rowIndex = 0; rowIndex < planeImageHeight; rowIndex++) {
            memcpy(&(newImageBuffer[bytesCopied]),
                   &(planeBaseAddress[planeDataWidth * rowIndex]),
                   planeImageWidth);
            bytesCopied += planeImageWidth;
        }
    }
    assert(bytesCopied == sanitaryBufferSize);
    *data = newImageBuffer;
    return bytesCopied;
}

-(void)sendFrame:(CMSampleBufferRef)sampleBuffer {
    if (!(_capturing && _videoCaptureConsumer)) {
        return;
    }
    
    CMTime time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    _videoFrame.timestamp = time;
    OSType pixelFormat = CVPixelBufferGetPixelFormatType(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    if (width != _captureWidth || height != _captureHeight) {
        [self updateCaptureFormatWithWidth:width height:height];
    }
    _videoFrame.format.imageWidth = width;
    _videoFrame.format.imageHeight = height;
    _videoFrame.format.estimatedFramesPerSecond = 12;
    // TODO: how do we measure this from AVFoundation?
    _videoFrame.format.estimatedCaptureDelay = 100;
    _videoFrame.orientation = OTVideoOrientationLeft;
    
    [_videoFrame clearPlanes];
    uint8_t* sanitizedImageBuffer = NULL;
    
    if (!CVPixelBufferIsPlanar(imageBuffer))
    {
        [_videoFrame.planes addPointer:CVPixelBufferGetBaseAddress(imageBuffer)];
    } else if ([self imageBufferIsSanitary:imageBuffer]) {
        for (int i = 0; i < CVPixelBufferGetPlaneCount(imageBuffer); i++) {
            [_videoFrame.planes addPointer: CVPixelBufferGetBaseAddressOfPlane(imageBuffer, i)];
        }
    } else {
        [self sanitizeImageBuffer:imageBuffer data:&sanitizedImageBuffer planes:_videoFrame.planes];
    }
    
    NSLog(@"send height = %zu, width = %zu, time.value = %lld", height, width, time.value/time.timescale);
    [_videoCaptureConsumer consumeFrame:_videoFrame];
    
    free(sanitizedImageBuffer);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
}

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    [super newFrameReadyAtTime:frameTime atIndex:textureIndex];

    if (_newFrameAvailableBlockWithTime != NULL)
    {
        _newFrameAvailableBlockWithTime(frameTime);
    }
}

@end
