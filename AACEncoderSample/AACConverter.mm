//
//  AACConverter.m
//  AACEncoderSample
//
//  Created by pebble8888 on 2016/07/02.
//  Copyright © 2016年 pebble8888. All rights reserved.
//

#import "AACConverter.h"
#import <AudioToolBox/AudioToolBox.h>
#import <AVFoundation/AVFoundation.h>
#import "PBAudioTool.h"

typedef struct {
	SInt64                       srcFilePos;
	char *                       srcBuffer;
	UInt32                       srcBufferSize;
	AudioStreamBasicDescription  srcFormat;
	UInt32                       srcSizePerPacket;
} AudioFileIO, *AudioFileIOPtr;

enum {
    kMyAudioConverterErr_CannotResumeFromInterruptionError = 'CANT',
    eofErr = -39 // End of file
};

// Input data proc callback
static OSStatus EncoderDataProc(AudioConverterRef inAudioConverter,
                                UInt32 *ioNumberDataPackets, 
                                AudioBufferList *ioData, 
                                AudioStreamPacketDescription **outDataPacketDescription, 
                                void *inUserData)
{
	AudioFileIOPtr afio = (AudioFileIOPtr)inUserData;
    OSStatus error = noErr;
	
    // figure out how much to read
	UInt32 maxPackets = afio->srcBufferSize / afio->srcSizePerPacket;
	if (*ioNumberDataPackets > maxPackets) *ioNumberDataPackets = maxPackets;

    // read from the file
	UInt32 outNumBytes;
    int64_t pos = afio->srcFilePos;
    int16_t* p = (int16_t*)afio->srcBuffer; 
    const int16_t* end = p + *ioNumberDataPackets;
    while(p < end){
        *(p++) = (int16_t)(32767.0 * sin(2.0 * M_PI * (double)pos / 440.0));  
        ++pos;
    }
    outNumBytes = (uint32_t)((char*)p - afio->srcBuffer); 
    
    //NSLog(@"*ioNumberDataPackets %d", *ioNumberDataPackets);
	if (eofErr == error) error = noErr;
	if (error) {
        NSLog(@"Input Proc Read error: %@ (%4.4s)\n", @(error), (char*)&error); 
        return error;
    }
    
    //printf("Input Proc: Read %lu packets, at position %lld size %lu\n", *ioNumberDataPackets, afio->srcFilePos, outNumBytes);
    NSLog(@"feed afio->srcFilePos %@ *ioNumberDataPackets %d", @(afio->srcFilePos), *ioNumberDataPackets);
	
    // advance input file packet position
	afio->srcFilePos += *ioNumberDataPackets;

    // put the data pointer into the buffer list
	ioData->mBuffers[0].mData = afio->srcBuffer;
	ioData->mBuffers[0].mDataByteSize = outNumBytes;
	ioData->mBuffers[0].mNumberChannels = afio->srcFormat.mChannelsPerFrame;

    return error;
}

@interface AACConverter ()
{
    AudioConverterRef converter;
    AudioFileIO afio;
    AudioStreamBasicDescription srcFormat;
    AudioStreamBasicDescription dstFormat;
    UInt32 theOutputBufSize;
    char *outputBuffer;
    UInt32 numOutputPackets;
    AudioStreamPacketDescription *outputPacketDescriptions;
    UInt64 totalOutputFrames;
    SInt64 outputFilePos;
}
@end

@implementation AACConverter
/*
- (void)run
{
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* destinationFilePath = [[NSString alloc] initWithFormat: @"%@/output.caf", documentsDirectory];
    CFURLRef destinationURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)destinationFilePath, kCFURLPOSIXPathStyle, false);
    
    DoConvertFile(destinationURL);
}
*/
 
- (void)setupEncoder
{
    afio = {0}; 
    outputPacketDescriptions = NULL;
    OSStatus status;
    
    // get the source data format
    srcFormat = [PBAudioTool monoWAVWithSampleRate:44100];
    UInt32 size = sizeof(srcFormat);
    dstFormat = {0};
    // setup the output file format
    dstFormat.mSampleRate = 44100;
    // compressed format - need to set at least format, sample rate and channel fields for kAudioFormatProperty_FormatInfo
    dstFormat.mFormatID = kAudioFormatMPEG4AAC;
    dstFormat.mChannelsPerFrame = srcFormat.mChannelsPerFrame;
    
    // use AudioFormat API to fill out the rest of the description
    size = sizeof(dstFormat);
    status = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &dstFormat);
    assert(status==noErr);
    
    // create the AudioConverter
    status = AudioConverterNew(&srcFormat, &dstFormat, &converter);
    assert(status==noErr);
    
    /*
    size = sizeof(dstFormat);
    status = AudioConverterGetProperty(converter, kAudioConverterCurrentOutputStreamDescription, &size, &dstFormat);
    assert(status==noErr);
    */
    
    // if encoding to AAC set the bitrate
    // kAudioConverterEncodeBitRate is a UInt32 value containing the number of bits per second to aim for when encoding data
    // when you explicitly set the bit rate and the sample rate, this tells the encoder to stick with both bit rate and sample rate
    //     but there are combinations (also depending on the number of channels) which will not be allowed
    // if you do not explicitly set a bit rate the encoder will pick the correct value for you depending on samplerate and number of channels
    // bit rate also scales with the number of channels, therefore one bit rate per sample rate can be used for mono cases
    //    and if you have stereo or more, you can multiply that number by the number of channels.
    if (dstFormat.mFormatID == kAudioFormatMPEG4AAC) {
        UInt32 outputBitRate = 64000; // 64kbs
        UInt32 propSize = sizeof(outputBitRate);
        
        if (dstFormat.mSampleRate >= 44100) {
            outputBitRate = 192000; // 192kbs
        } else if (dstFormat.mSampleRate < 22000) {
            outputBitRate = 32000; // 32kbs
        }
        
        // set the bit rate depending on the samplerate chosen
        status = AudioConverterSetProperty(converter, kAudioConverterEncodeBitRate, propSize, &outputBitRate);
        assert(status==noErr);
        
        // get it back and print it out
        AudioConverterGetProperty(converter, kAudioConverterEncodeBitRate, &propSize, &outputBitRate);
        NSLog(@"AAC Encode Bitrate: %@\n", @(outputBitRate));
    }
    
    /*
    // create the destination file 
    status = AudioFileCreateWithURL(destinationURL, kAudioFileCAFType, &dstFormat, kAudioFileFlags_EraseFile, &destinationFileID);
    assert(status==noErr);
    */
    
    // set up source buffers and data proc info struct
    afio.srcBufferSize = 32768;
    afio.srcBuffer = new char [afio.srcBufferSize];
    afio.srcFilePos = 0;
    afio.srcFormat = srcFormat;
    
    // CBR source format
    afio.srcSizePerPacket = srcFormat.mBytesPerPacket;
    
    // set up output buffers
    UInt32 outputSizePerPacket = dstFormat.mBytesPerPacket; // this will be non-zero if the format is CBR
    theOutputBufSize = 32768;
    outputBuffer = new char[theOutputBufSize];
    
    assert(outputSizePerPacket == 0);
    // if the destination format is VBR, we need to get max size per packet from the converter
    size = sizeof(outputSizePerPacket);
    status = AudioConverterGetProperty(converter, kAudioConverterPropertyMaximumOutputPacketSize, &size, &outputSizePerPacket);
    assert(status==noErr);
    
    // allocate memory for the PacketDescription structures describing the layout of each packet
    outputPacketDescriptions = new AudioStreamPacketDescription[theOutputBufSize / outputSizePerPacket];
    
    numOutputPackets = theOutputBufSize / outputSizePerPacket;
    
    /*
     // write destination channel layout
     if (srcFormat.mChannelsPerFrame > 2) {
     WriteDestinationChannelLayout(converter, sourceFileID, destinationFileID);
     }
     */
    
    totalOutputFrames = 0; // used for debgging printf
    outputFilePos = 0;
}

- (void)teardown
{
    // cleanup
    if (converter) AudioConverterDispose(converter);
    
    if (afio.srcBuffer) delete [] afio.srcBuffer;
    if (outputBuffer) delete [] outputBuffer;
    if (outputPacketDescriptions) delete [] outputPacketDescriptions;
}

- (void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer completionBlock:(void (^)(NSData *encodedData, NSError* error))completionBlock;
{
    //NSLog(@"encodeSampleBuffer %d", CMSampleBufferGetNumSamples(sampleBuffer));
    
    // TODO:post sampleBuffer to srcBuffer
    
    OSStatus error;
    // loop to convert data
    printf("Converting...\n");
    //while (true)
    {
        // set up output buffer list
        AudioBufferList fillBufList;
        fillBufList.mNumberBuffers = 1;
        fillBufList.mBuffers[0].mNumberChannels = dstFormat.mChannelsPerFrame;
        fillBufList.mBuffers[0].mDataByteSize = theOutputBufSize;
        fillBufList.mBuffers[0].mData = outputBuffer;
        
        // convert data
        UInt32 ioOutputDataPackets = numOutputPackets;
        printf("AudioConverterFillComplexBuffer...\n");
        error = AudioConverterFillComplexBuffer(converter, EncoderDataProc, &afio, &ioOutputDataPackets, &fillBufList, outputPacketDescriptions);
        // if interrupted in the process of the conversion call, we must handle the error appropriately
        if (error != noErr) {
            if (kAudioConverterErr_HardwareInUse == error) {
                printf("Audio Converter returned kAudioConverterErr_HardwareInUse!\n");
            } else {
                NSLog(@"AudioConverterFillComplexBuffer error! %d", error);
                assert(false);
            }
        } else {
            // noErr
            if (ioOutputDataPackets == 0) {
                // this is the EOF conditon
                error = noErr;
            } else {
                // write to output file
                UInt32 inNumBytes = fillBufList.mBuffers[0].mDataByteSize;
                /*
                status = AudioFileWritePackets(destinationFileID, false, inNumBytes, outputPacketDescriptions, outputFilePos, &ioOutputDataPackets, outputBuffer);
                assert(status==noErr);
                 */
                NSData* data = [NSData dataWithBytes:outputBuffer length:inNumBytes]; 
                completionBlock(data, nil);
               
                //NSLog(@"Convert Output: Write %@ packets at position %lld, size: %@\n", @(ioOutputDataPackets), outputFilePos, @(inNumBytes));
                
                // advance output file packet position
                outputFilePos += ioOutputDataPackets;
                
                if (dstFormat.mFramesPerPacket) { 
                    // the format has constant frames per packet
                    totalOutputFrames += (ioOutputDataPackets * dstFormat.mFramesPerPacket);
                } else if (outputPacketDescriptions != NULL) {
                    // variable frames per packet require doing this for each packet (adding up the number of sample frames of data in each packet)
                    for (UInt32 i = 0; i < ioOutputDataPackets; ++i){
                        totalOutputFrames += outputPacketDescriptions[i].mVariableFramesInPacket;
                    }
                }
                
            }
        }
    }
    
    if (noErr == error) {
        // write out any of the leading and trailing frames for compressed formats only
        if (dstFormat.mBitsPerChannel == 0) {
            // our output frame count should jive with
            
            // TODO:something to do ? 
            /*
            printf("Total number of output frames counted: %lld\n", totalOutputFrames); 
            WritePacketTableInfo(converter, destinationFileID);
             */
        }
    }
}

@end
