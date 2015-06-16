//
// Screenshot.h
//
// Created by Simon Madine on 29/04/2010.
// Copyright 2010 The Angry Robot Zombie Factory.
// - Converted to Cordova 1.6.1 by Josemando Sobral.
// MIT licensed
//
// Modifications to support orientation change by @ffd8
//

#import <Cordova/CDV.h>
#import "Screenshot.h"

@implementation Screenshot

@synthesize webView;

//- (void)saveScreenshot:(NSArray*)arguments withDict:(NSDictionary*)options

 - (void)saveScreenshot:(CDVInvokedUrlCommand*)command
{
    NSString *filename = [command.arguments objectAtIndex:2];
    NSNumber *quality = [command.arguments objectAtIndex:1];
    NSString *path = [NSString stringWithFormat:@"%@.jpg",filename];
    NSString *tPath = [NSString stringWithFormat:@"thumb-%@.jpg",filename];
    NSString *thumbPath = [NSTemporaryDirectory() stringByAppendingPathComponent:tPath ];
    NSString *jpgPath = [NSTemporaryDirectory() stringByAppendingPathComponent:path ];

    CGRect imageRect;
    CGRect screenRect = [[UIScreen mainScreen] bounds];

    // statusBarOrientation is more reliable than UIDevice.orientation
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;

    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
        // landscape check
        imageRect = CGRectMake(0, 0, CGRectGetHeight(screenRect), CGRectGetWidth(screenRect));
    } else {
        // portrait check
        imageRect = CGRectMake(0, 0, CGRectGetWidth(screenRect), CGRectGetHeight(screenRect));
    }

    // Adds support for Retina Display. Code reverts back to original if iOs 4 not detected.
    if (NULL != UIGraphicsBeginImageContextWithOptions)
        UIGraphicsBeginImageContextWithOptions(imageRect.size, NO, 0);
    else
        UIGraphicsBeginImageContext(imageRect.size);

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor blackColor] set];
    CGContextTranslateCTM(ctx, 0, 0);
    CGContextFillRect(ctx, imageRect);

    if ([webView respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        [webView drawViewHierarchyInRect:webView.bounds afterScreenUpdates:YES];
    } else {
        [webView.layer renderInContext:ctx];
    }

    UIImage *image =UIGraphicsGetImageFromCurrentImageContext();
    NSData *imageData = UIImageJPEGRepresentation(image,[quality floatValue]);
    [imageData writeToFile:jpgPath atomically:NO];
    image = [self imageCompressForWidth:UIGraphicsGetImageFromCurrentImageContext() targetWidth:100];
    imageData = UIImageJPEGRepresentation(image,[quality floatValue]);
    [imageData writeToFile:thumbPath atomically:NO];

    UIGraphicsEndImageContext();

    CDVPluginResult* pluginResult = nil;
    NSDictionary *jsonObj = [ [NSDictionary alloc]
        initWithObjectsAndKeys :
        jpgPath, @"filePath",
        @"true", @"success",
        nil
        ];

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:jsonObj];
    [self writeJavascript:[pluginResult toSuccessCallbackString:command.callbackId]];
}
-(UIImage *) imageCompressForWidth:(UIImage *)sourceImage targetWidth:(CGFloat)defineWidth{
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = defineWidth;
    CGFloat targetHeight = height / (width / targetWidth);
    CGSize size = CGSizeMake(targetWidth, targetHeight);
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0, 0.0);
    if(CGSizeEqualToSize(imageSize, size) == NO){
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        if(widthFactor > heightFactor){
            scaleFactor = widthFactor;
        }
        else{
            scaleFactor = heightFactor;
        }
        scaledWidth = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        if(widthFactor > heightFactor){
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }else if(widthFactor < heightFactor){
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    UIGraphicsBeginImageContext(size);
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if(newImage == nil){
        NSLog(@"scale image fail");
    }
    
    UIGraphicsEndImageContext();
    return newImage;
}
@end
