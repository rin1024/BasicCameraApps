//
//  PhotoCell.m
//  CameraApps
//
//  Created by Yuki ANAI on 5/1/14.
//  Copyright (c) 2014 Yuki ANAI. All rights reserved.
//

#import "PhotoCell.h"

@interface PhotoCell ()
@property(nonatomic, weak) IBOutlet UIImageView *photoImageView;
@end

@implementation PhotoCell

- (void) setAsset:(ALAsset *)asset
{
    _asset = asset;
    self.photoImageView.image = [UIImage imageWithCGImage:[asset thumbnail]];
}

@end
