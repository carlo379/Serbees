//  ServiceImage.m
//  SerBees

#import "ServiceImage.h"

@interface ServiceImage ()

- (instancetype) initWithRecord:(CKRecord *)record andButtonAssetURL:(NSURL *)assetThumbURL isOnServer:(BOOL)onServer;

@end

#pragma mark -
@implementation ServiceImage

// Designated initializer
- (instancetype) initWithRecord:(CKRecord *)record andButtonAssetURL:(NSURL *)assetThumbURL isOnServer:(BOOL)onServer
{
    NSAssert([[record recordType] isEqual:ServiceImageRecordType], @"Wrong type for image record");
    self = [super init];
    if (self != nil)
    {
        _onServer = onServer;
        _record = record;
        
        // Loads thumbnail
        NSURL *thumbFileURL = [_record[ServiceImageThumbnailKey] fileURL];
        NSData *thumbImageData = [NSData dataWithContentsOfURL:thumbFileURL];
        _thumbnail = [[UIImage alloc] initWithData:thumbImageData];
        
        // Loads full size
        NSURL *fullFileURL = [_record[ServiceImageFullsizeKey] fileURL];
        NSData *fullImageData = [NSData dataWithContentsOfURL:fullFileURL];
        _fullImage = [[UIImage alloc] initWithData:fullImageData];
        
        // Loads asset thumb
        NSData *assetImageData = [NSData dataWithContentsOfURL:assetThumbURL];
        _assetThumb = [[UIImage alloc] initWithData:assetImageData];
    }
    return self;
}

- (instancetype) initWithRecord:(CKRecord *)record isOnServer:(BOOL)onServer
{
    NSAssert([[record recordType] isEqual:ServiceImageRecordType], @"Wrong type for image record");
    self = [super init];
    if (self != nil)
    {
        _onServer = onServer;
        _record = record;
        
        // Loads thumbnail
        NSURL *thumbFileURL = [_record[ServiceImageThumbnailKey] fileURL];
        NSData *thumbImageData = [NSData dataWithContentsOfURL:thumbFileURL];
        _thumbnail = [[UIImage alloc] initWithData:thumbImageData];
        
        // Loads full size
        NSURL *fullFileURL = [_record[ServiceImageFullsizeKey] fileURL];
        NSData *fullImageData = [NSData dataWithContentsOfURL:fullFileURL];
        _fullImage = [[UIImage alloc] initWithData:fullImageData];
    }
    return self;
}

// Creates an AAPLImage from a UIImage (photo was taken from camera or photo library)
- (instancetype) initWithImage:(UIImage *)image andButtonSize:(CGFloat)buttonSize
{
    CGImageRef CGRawImage = image.CGImage;
    CGImageRef cropped = NULL;
    if(CGImageGetHeight(CGRawImage) > CGImageGetWidth(CGRawImage))
    {
        // Crops from top and bottom evenly
        size_t maxDimen = CGImageGetWidth(CGRawImage);
        size_t offset = (CGImageGetHeight(CGRawImage) - CGImageGetWidth(CGRawImage)) / 2;
        cropped = CGImageCreateWithImageInRect(image.CGImage, CGRectMake(0, offset, maxDimen, maxDimen));
    }
    else if(CGImageGetHeight(CGRawImage) <= CGImageGetWidth(CGRawImage))
    {
        // Crops from left and right evenly
        size_t maxDimen = CGImageGetHeight(CGRawImage);
        size_t offset = (CGImageGetWidth(CGRawImage) - CGImageGetHeight(CGRawImage)) / 2;
        cropped = CGImageCreateWithImageInRect(image.CGImage, CGRectMake(offset, 0, maxDimen, maxDimen));
    }
    
    // Resizes image to be 1500 x 1500 px and saves it to a temporary file
    NSURL *fullURL = [self resizeImage:image croppedRef:cropped withFileName:@"toUploadFull.tmp" andSize:1500];
    
    // Resizes thumbnail to be 200 x 200 px and then saves to different temp file
    NSURL *thumbURL = [self resizeImage:image croppedRef:cropped withFileName:@"toUploadThumb.tmp" andSize:53];
    
    // Resizes thumbnail for asset button depending on device zise and then saves to different temp file
    NSURL *assetThumbURL = [self resizeImage:image croppedRef:cropped withFileName:@"toAssetThumb.tmp" andSize:buttonSize];
    
    // Cleans up memory that ARC won't touch
    CGImageRelease(cropped);
    
    // Creates Image record type with two assets, full sized image and thumbnail sized image
    CKRecord *newImageRecord = [[CKRecord alloc] initWithRecordType:ServiceImageRecordType];
    newImageRecord[ServiceImageFullsizeKey] = [[CKAsset alloc] initWithFileURL:fullURL];
    newImageRecord[ServiceImageThumbnailKey] = [[CKAsset alloc] initWithFileURL:thumbURL];
    
    // Calls designated initalizer, this is a new image so it is not on the server
    return [self initWithRecord:newImageRecord andButtonAssetURL:assetThumbURL isOnServer:NO];
}

- (NSURL *) resizeImage:(UIImage *)image croppedRef:(CGImageRef)cropped withFileName:(NSString *)fileName andSize:(int)size {
    UIGraphicsBeginImageContext(CGSizeMake(size, size));
    [[UIImage imageWithCGImage:cropped scale:image.scale orientation:image.imageOrientation] drawInRect:CGRectMake(0,0,size,size)];
    UIImage *fullImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSString *path = [NSTemporaryDirectory() stringByAppendingString:fileName];
    NSData *imageData = UIImageJPEGRepresentation(fullImage,0.5);
    [imageData writeToFile:path atomically:YES];
    return [NSURL fileURLWithPath:path];
}

// Creates an AAPLImage from a CKRecord that has been fetched
- (instancetype) initWithRecord:(CKRecord *)record andButtonAssetURL:(NSURL *)assetThumbURL
{
    return [self initWithRecord:record andButtonAssetURL:assetThumbURL isOnServer:YES];
}

// Creates an AAPLImage from a CKRecord that has been fetched
- (instancetype) initWithRecord:(CKRecord *)record
{
    return [self initWithRecord:record isOnServer:YES];
}
@end
