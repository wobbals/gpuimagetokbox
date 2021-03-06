//
//  StreamerViewModel.swift
//  nrhd
//
//  Created by Fujiki Takeshi on 11/24/15.
//  Copyright © 2015 Sony Computer Science Laboratories Inc. All rights reserved.
//

import UIKit

final class ViewModel: NSObject, GPUImageVideoCameraDelegate {
    let filterView = GPUImageView()
    var camera: GPUImageVideoCamera!
    var filterGroup: GPUImageFilterGroup?
    var output: GPUImageCustomRawDataOutput!
    
    func startCapture() {
        camera = GPUImageVideoCamera(sessionPreset: AVCaptureSessionPreset640x480, cameraPosition: AVCaptureDevicePosition.Front)
        
        camera.frameRate = 12
        
        camera.outputImageOrientation = UIInterfaceOrientation.Portrait
        camera.horizontallyMirrorFrontFacingCamera = true
        camera.horizontallyMirrorRearFacingCamera = false
        
        camera.startCameraCapture()
        
        output = GPUImageCustomRawDataOutput(imageSize: CGSizeMake(640, 480), resultsInBGRAFormat: false)
        output.newFrameAvailableBlockWithTime = {
            [unowned self] (frametime) in
            if self.output.active() {
                VideoGenerator.sampleBufferFromRawData(self.output, frametime: frametime, block: { [unowned self] (sampleBuffer) -> Void in
                    self.output.sendFrame(sampleBuffer)
                    })
            }
        }
        camera.delegate = self
        updateEffect()
    }
    
    func startStreaming() {
        output.startRecording()
    }
    
    func finishStreaming() {
        output.finishRecording()
        filterGroup?.removeTarget(output)
        camera.audioEncodingTarget = nil;
    }
    
    func updateEffect() {
        camera.removeAllTargets()
        filterGroup?.removeAllTargets()
        var filters = [GPUImageOutput]()
        
//        filters.append(GPUImageColorInvertFilter())
        filters.append(GPUImageChromaKeyFilter())
        
        filterGroup = connectFilters(filters)
        camera.addTarget(filterGroup)
        filterGroup?.addTarget(filterView)
        filterGroup?.addTarget(output)
    }
    
    func connectFilters(filters: [GPUImageOutput]) -> GPUImageFilterGroup {
        let filterGroup = GPUImageFilterGroup()
        
        var firstFilter: GPUImageOutput!
        var lastFilter: GPUImageOutput!
        for filter in filters {
            filterGroup.addFilter(filter)
            
            if firstFilter == nil {
                firstFilter = filter
            }
            
            if lastFilter != nil {
                if let f = filter as? GPUImageFilterGroup {
                    lastFilter.addTarget(f)
                }else if let f = filter as? GPUImageFilter {
                    lastFilter.addTarget(f)
                }
            }
            lastFilter = filter
        }
        filterGroup.initialFilters = [firstFilter]
        filterGroup.terminalFilter = lastFilter
        
        return filterGroup
    }
    
    // MARK:
    func willOutputSampleBuffer(sampleBuffer: CMSampleBufferRef) {
        if output.active() {
//            let copyBuffer = VideoGenerator.copySampleBuffer(sampleBuffer).takeRetainedValue()
//            output.sendFrame(copyBuffer)
        }
    }
}
