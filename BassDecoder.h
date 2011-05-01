//
//  BassDecoder.h
//  cog_bass
//
//  Created by Mike Burke on 11-05-01.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Plugin.h"


@interface BassDecoder : NSObject <CogDecoder> {
	id<CogSource> source;
	long length;
    int chan;
}


- (void)cleanUp;

@end
