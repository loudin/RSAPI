//
//  AFImageCache.h
//  Boundabout
//
//  Created by Michael Dinerstein on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AFImageCache : NSCache
- (UIImage *)cachedImageForRequest:(NSURLRequest *)request;
- (void)cacheImageData:(NSData *)imageData
            forRequest:(NSURLRequest *)request;
@end
