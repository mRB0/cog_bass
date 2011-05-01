//
//  BassDecoder.m
//  cog_bass
//
//  Created by Mike Burke on 11-05-01.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <objc/objc.h>

#import "bass.h"

#import "BassDecoder.h"

static BOOL bassIsInited;

NSString *const BASSErrorDomain = @"libbass";
static NSDictionary *BASSErrorCodes;

@interface BassDecoder ()
@property (nonatomic, retain) id<CogSource> source;
@end

@implementation BassDecoder

@synthesize source;

+ (void)initialize {
    BASSErrorCodes = [[NSDictionary alloc] initWithObjectsAndKeys:
                      @"all is OK",                                     [NSNumber numberWithInt:0],
                      @"memory error",                                  [NSNumber numberWithInt:1],
                      @"can't open the file",                           [NSNumber numberWithInt:2],
                      @"can't find a free/valid driver",                [NSNumber numberWithInt:3],
                      @"the sample buffer was lost",                    [NSNumber numberWithInt:4],
                      @"invalid handle",                                [NSNumber numberWithInt:5],
                      @"unsupported sample format",                     [NSNumber numberWithInt:6],
                      @"invalid position",                              [NSNumber numberWithInt:7],
                      @"BASS_Init has not been successfully called",    [NSNumber numberWithInt:8],
                      @"BASS_Start has not been successfully called",   [NSNumber numberWithInt:9],
                      @"already initialized/paused/whatever",           [NSNumber numberWithInt:14],
                      @"can't get a free channel",                      [NSNumber numberWithInt:18],
                      @"an illegal type was specified",                 [NSNumber numberWithInt:19],
                      @"an illegal parameter was specified",            [NSNumber numberWithInt:20],
                      @"no 3D support",                                 [NSNumber numberWithInt:21],
                      @"no EAX support",                                [NSNumber numberWithInt:22],
                      @"illegal device number",                         [NSNumber numberWithInt:23],
                      @"not playing",                                   [NSNumber numberWithInt:24],
                      @"illegal sample rate",                           [NSNumber numberWithInt:25],
                      @"the stream is not a file stream",               [NSNumber numberWithInt:27],
                      @"no hardware voices available",                  [NSNumber numberWithInt:29],
                      @"the MOD music has no sequence data",            [NSNumber numberWithInt:31],
                      @"no internet connection could be opened",        [NSNumber numberWithInt:32],
                      @"couldn't create the file",                      [NSNumber numberWithInt:33],
                      @"effects are not available",                     [NSNumber numberWithInt:34],
                      @"requested data is not available",               [NSNumber numberWithInt:37],
                      @"the channel is a \"decoding channel\"",         [NSNumber numberWithInt:38],
                      @"a sufficient DirectX version is not installed", [NSNumber numberWithInt:39],
                      @"connection timedout",                           [NSNumber numberWithInt:40],
                      @"unsupported file format",                       [NSNumber numberWithInt:41],
                      @"unavailable speaker",                           [NSNumber numberWithInt:42],
                      @"invalid BASS version (used by add-ons)",        [NSNumber numberWithInt:43],
                      @"codec is not available/supported",              [NSNumber numberWithInt:44],
                      @"the channel/file has ended",                    [NSNumber numberWithInt:45],
                      @"the device is busy",                            [NSNumber numberWithInt:46],
                      @"some other mystery problem",                    [NSNumber numberWithInt:-1],
                      nil
                      ];
}

- (void)bassError {
    int code = BASS_ErrorGetCode();
    
    NSLog(@"Bass error: %@", [BASSErrorCodes objectForKey:[NSNumber numberWithInt:code]]);
}

- (NSDictionary *)properties
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:0], @"bitrate",
            [NSNumber numberWithFloat:44100], @"sampleRate",
            [NSNumber numberWithDouble:((length / 65.536f)*44.1000)], @"totalFrames",
            [NSNumber numberWithInt:16], @"bitsPerSample", //Samples are short
            [NSNumber numberWithInt:2], @"channels", //output from gme_play is in stereo
            [NSNumber numberWithBool:[source seekable]], @"seekable",
            @"host", @"endian",
            nil];
}

+ (NSArray *)mimeTypes {
    NSMutableArray *types = [NSMutableArray array];
    for (NSString *filetype in [[self class] fileTypes]) {
        [types addObject:[NSString stringWithFormat:@"audio/x-%@", filetype]];
    }
    return types;
}

+ (NSArray *)fileTypes {
    return [NSArray arrayWithObjects:@"mo3", @"it", @"xm", @"s3m", @"mtm", @"mod", @"umx", nil];
}

- (int)bytesPerFrame {
    int mult = 1;
    
    mult *= [[[self properties] objectForKey:@"bitsPerSample"] intValue] / 8;
    mult *= [[[self properties] objectForKey:@"channels"] intValue];
    
    return mult;
}

- (int)readAudio:(void *)buffer frames:(UInt32)frames {
    int mult = [self bytesPerFrame];
    
    DWORD readLen = frames * mult;
    int totalRead = 0;
    int bytesRead;
    
    while (BASS_ChannelIsActive(chan) && (bytesRead = BASS_ChannelGetData(chan, buffer+totalRead, readLen-totalRead))) {
        totalRead += bytesRead;
    }
    
    return totalRead / mult;
}

- (BOOL)bassInitIfNecessary {
    if (bassIsInited) {
        return YES;
    }
    NSLog(@"Initializing bass");
    bassIsInited = BASS_Init(0, 44100, 0, 0, NULL);
    return bassIsInited;
}

- (BOOL)open:(id<CogSource>)s {
    if (![[s url] isFileURL]) {
        return NO;
    }
    
    NSLog(@"source is %@", [s url]);
    
    self.source = s;
    if (![self bassInitIfNecessary]) {
        NSLog(@"Failed to initialize bass!");
        [self bassError];
        return NO;
    }
    
//    int const readBufSize = 4096;
//    unsigned char *readBuf = (unsigned char*)malloc(sizeof(unsigned char) * readBufSize);
//    unsigned char *modBuf = NULL;
//    size_t modBufSize = 0;
//    int amtRead;
//    
//    while (0 != (amtRead = [s read:readBuf amount:readBufSize])) {
//        size_t endPtr = modBufSize;
//        modBufSize += amtRead;
//        modBuf = (unsigned char*)realloc(modBuf, modBufSize);
//        memcpy(modBuf+endPtr, readBuf, amtRead);
//    }
//    
//    free(readBuf);
    
    
    char *playbackPath = strdup([[[[NSFileManager alloc] init] autorelease] fileSystemRepresentationWithPath:[[s url] path]]);
    
//    chan = BASS_MusicLoad(TRUE, modBuf, 0, 0, BASS_MUSIC_DECODE | BASS_MUSIC_RAMPS | BASS_MUSIC_PRESCAN, 0);
    chan = BASS_MusicLoad(FALSE, playbackPath, 0, 0, BASS_MUSIC_DECODE | BASS_MUSIC_RAMPS | BASS_MUSIC_PRESCAN, 0);
//    free(modBuf);
    free(playbackPath);
    
    if (!chan) {
        NSLog(@"Failed to load mod.");
        [self bassError];
        return NO;
    }
    
    length = BASS_ChannelGetLength(chan, BASS_POS_BYTE) / [self bytesPerFrame] * 1.5; // ??? why do I need to multiply?
    
	[self willChangeValueForKey:@"properties"];
	[self didChangeValueForKey:@"properties"];
    
    return YES;
}

- (long)seek:(long)frame {
    BASS_ChannelSetPosition(chan, frame * [self bytesPerFrame], BASS_POS_BYTE | BASS_POS_DECODETO);
    return BASS_ChannelGetPosition(chan, BASS_POS_BYTE) / [self bytesPerFrame];
}

- (void)close {
    [self cleanUp];
    self.source = nil;
}

- (void)cleanUp {
}

- (void)dealloc {
    self.source = nil;
    [super dealloc];
}

@end
