//
//  PBAudioTool.m
//
//  Created by pebble8888 on 2016/07/02.
//  Copyright © 2016年 pebble8888. All rights reserved.
//

#import "PBAudioTool.h"

@implementation PBAudioTool
// WAV 16bit mono
+ (AudioStreamBasicDescription)monoWAVWithSampleRate:(uint32_t)sampleRate
{
    AudioStreamBasicDescription asbd;
    asbd.mSampleRate = sampleRate;
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kAudioFormatFlagIsSignedInteger|kAudioFormatFlagIsPacked;
    asbd.mBitsPerChannel = sizeof(int16_t)*8;
    asbd.mChannelsPerFrame = 1;
    asbd.mFramesPerPacket = 1;
    asbd.mBytesPerFrame = sizeof(int16_t)*asbd.mChannelsPerFrame;
    asbd.mBytesPerPacket = sizeof(int16_t)*asbd.mChannelsPerFrame;
    asbd.mReserved = 0;
    return asbd;
}

// WAV 16bit stereo
+ (AudioStreamBasicDescription)stereoWAVWithSampleRate:(uint32_t)sampleRate
{
    AudioStreamBasicDescription asbd;
    asbd.mSampleRate = sampleRate;
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kAudioFormatFlagIsSignedInteger|kAudioFormatFlagIsPacked;
    asbd.mBitsPerChannel = sizeof(int16_t)*8;
    asbd.mChannelsPerFrame = 2;
    asbd.mFramesPerPacket = 1;
    asbd.mBytesPerFrame = sizeof(int16_t)*asbd.mChannelsPerFrame;
    asbd.mBytesPerPacket = sizeof(int16_t)*asbd.mChannelsPerFrame;
    asbd.mReserved = 0;
    return asbd;
}

@end
