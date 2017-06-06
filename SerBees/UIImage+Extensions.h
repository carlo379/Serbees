//  UIImage+Extensions.h
//  SerBees

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#define BCameraBRight 00
#define BCameraBLeft  01
#define BCameraBUp    02
#define BCameraBDown  03
#define FCameraBLeft  10
#define FCameraBRight 11
#define FCameraBUp    12
#define FCameraBDown  13

@interface UIImage (Extensions)
+ (UIImage *)correctImage:(UIImage*)image withCameraOrientation:(int)orientation andCameraUsed:(int)camera;
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;
+ (UIImage *)makeRoundedImage:(UIImage *)image radius:(float)radius;
+ (UIImage *)roundImage:(UIImage *)image radius:(float)radius;
+ (UIImage *)blendImage:(UIImage *)mainImage withImage:(UIImage *)topImage;
+ (UIImage *)unrotateImage:(UIImage *)image;

- (UIImage *)croppedImageWithRect:(CGRect)bounds;
- (UIImage *)mirrorTopOnImage;
- (UIImage *)mirrorSideOnImage;
- (UIImage *)roundedCornersImageWithRadius:(float)radius;
- (UIImage *)imageAtRect:(CGRect)rect;
- (UIImage *)imageByScalingProportionallyToMinimumSize:(CGSize)targetSize;
- (UIImage *)imageByScalingProportionallyToSize:(CGSize)targetSize;
- (UIImage *)imageByScalingToSize:(CGSize)targetSize;
- (UIImage *)imageRotatedByRadians:(CGFloat)radians;
- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees;
- (UIImage *)fixOrientation;
- (UIImage *)normalizedImage;
- (UIImage *)makeRoundedImage:(UIImage *) image radius:(float) radius;
- (UIImage *)resizedImage:(CGSize)newSize interpolationQuality:(CGInterpolationQuality)quality;
- (UIImage *)resizedImageWithMaxDimension:(int)maxDimension interpolationQuality:(CGInterpolationQuality)quality;
- (UIImage *)scaleAndRotateImage:(UIImage *)image;
- (UIImage *)rotateImage:(UIImage *)img byOrientationFlag:(UIImageOrientation)orient;

@end
