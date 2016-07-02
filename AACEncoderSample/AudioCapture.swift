//
//  AudioCapture.swift
//  AACEncoderSample
//
//  Created by pebble8888 on 2016/07/02.
//  Copyright © 2016年 pebble8888. All rights reserved.
//

import Foundation
import AVFoundation

class AudioCapture : NSObject, AVCaptureAudioDataOutputSampleBufferDelegate
{
    var audioConnection:AVCaptureConnection?
    var sessions = AVCaptureSession()
    var aacConverter:AACConverter = AACConverter()
    var aacEncoder: AACEncoder = AACEncoder()
    
    override init()
    {
        super.init()
        setupMicrophone()
    }
    
    func setupMicrophone()
    {
        let audio_output = AVCaptureAudioDataOutput()
        let audioSession:AVAudioSession = AVAudioSession.sharedInstance()
        try! audioSession.setCategory(AVAudioSessionCategoryRecord)
        //try! audioSession.setPreferredSampleRate(16000.0)        
        try! audioSession.setPreferredIOBufferDuration(1024.0/44100.0)
        try! audioSession.setActive(true)
        
        self.sessions.beginConfiguration()
        self.sessions = AVCaptureSession()
        self.sessions.automaticallyConfiguresApplicationAudioSession = false
        self.sessions.commitConfiguration()
        
        sessions.sessionPreset = AVCaptureSessionPresetLow
        
        let mic = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
        
        var mic_input: AVCaptureDeviceInput!
        
        audio_output.setSampleBufferDelegate(self, queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
        
        do
        {
            mic_input = try AVCaptureDeviceInput(device: mic)
        }
        catch
        {
            return
        }
        sessions.addInput(mic_input)
        sessions.addOutput(audio_output)
        audioConnection = audio_output.connectionWithMediaType(AVMediaTypeAudio)
    }
    
    func start()
    {
        //aacConverter.setupEncoder()
        sessions.startRunning()
    }

    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBufferRef!, fromConnection connection: AVCaptureConnection!){
        if connection == audioConnection {
            /*
            aacConverter.encodeSampleBuffer(sampleBuffer) { (data:NSData!, err:NSError!) in
                if data != nil{
                    NSLog("complete data.length %d", data.length)
                }
            }
            */
            print("bare data count \(CMSampleBufferGetNumSamples(sampleBuffer))")
            aacEncoder.encodeSampleBuffer(sampleBuffer) { (data:NSData!, error:NSError!) in 
                if data != nil{
                    NSLog("complete data.length %d", data.length)
                }
            } 
        }
    }
}
