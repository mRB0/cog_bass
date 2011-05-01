//
//  BassMetadataReader.m
//  cog_bass
//
//  Created by Mike Burke on 11-05-01.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <objc/objc.h>

#import "bass.h"

#import "BassMetadataReader.h"
#import "BassDecoder.h"

@implementation BassMetadataReader

+ (NSArray *)fileTypes
{
	return [BassDecoder fileTypes];
}

+ (NSArray *)mimeTypes
{
	return [BassDecoder mimeTypes];
}

+ (NSDictionary *)metadataForURL:(NSURL *)url
{
	if (![url isFileURL])
		return nil;
    
	//Some titles are all spaces?!
	NSString *title = [url path];
	
	return [NSDictionary dictionaryWithObject:title forKey:@"title"];
}

@end
