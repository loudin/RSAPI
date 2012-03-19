//
//  AFImageCache.m
//  Boundabout
//
//  Created by Michael Dinerstein on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AFImageCache.h"

static inline NSString * AFImageCacheKeyFromURLRequest(NSURLRequest *request) {
  return [[request URL] absoluteString];
}

@implementation AFImageCache

- (UIImage *)cachedImageForRequest:(NSURLRequest *)request {
  switch ([request cachePolicy]) {
    case NSURLRequestReloadIgnoringCacheData:
    case NSURLRequestReloadIgnoringLocalAndRemoteCacheData:
      return nil;
    default:
      break;
  }
  
	UIImage *image = [UIImage imageWithData:[self objectForKey:AFImageCacheKeyFromURLRequest(request)]];
	if (image) {
		return [UIImage imageWithCGImage:[image CGImage] scale:[[UIScreen mainScreen] scale] orientation:image.imageOrientation];
	}
  
  return image;
}

- (void)cacheImageData:(NSData *)imageData
            forRequest:(NSURLRequest *)request{
  [self setObject:[NSPurgeableData dataWithData:imageData] forKey:AFImageCacheKeyFromURLRequest(request)];
}

@end
