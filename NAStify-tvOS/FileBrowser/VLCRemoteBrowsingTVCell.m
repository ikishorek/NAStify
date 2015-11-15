/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCRemoteBrowsingTVCell.h"
//#import "VLCMDFBrowsingArtworkProvider.h"

NSString *const VLCRemoteBrowsingTVCellIdentifier = @"VLCRemoteBrowsingTVCell";

@interface VLCRemoteBrowsingTVCell ()
{
//    VLCMDFBrowsingArtworkProvider *_artworkProvider;
}
@property (nonatomic) IBOutlet NSLayoutConstraint *aspectRationConstraint;

@end

@implementation VLCRemoteBrowsingTVCell

//@synthesize thumbnailURL = _thumbnailURL, isDirectory = _isDirectory, couldBeAudioOnlyMedia = _couldBeAudioOnlyMedia;

- (void)awakeFromNib
{
    [super awakeFromNib];
//    _artworkProvider = [[VLCMDFBrowsingArtworkProvider alloc] init];
//    _artworkProvider.artworkReceiver = self;
    UILayoutGuide *focusedFrameGuide = self.thumbnailImageView.focusedFrameGuide;
    NSLayoutConstraint *constraint = [self.titleLabel.topAnchor constraintEqualToAnchor:focusedFrameGuide.bottomAnchor constant:15];
    [self.contentView addConstraint:constraint];

    [self prepareForReuse];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
//    [_artworkProvider reset];
    [self.thumbnailImageView cancelLoading];
    self.title = nil;
    self.subtitle = nil;
}

#if 0
- (void)setCouldBeAudioOnlyMedia:(BOOL)couldBeAudioOnlyMedia
{
    _artworkProvider.searchForAudioMetadata = _couldBeAudioOnlyMedia;
    if (_couldBeAudioOnlyMedia != couldBeAudioOnlyMedia) {
        [_artworkProvider reset];
    }
    _couldBeAudioOnlyMedia = couldBeAudioOnlyMedia;
}

- (void)setThumbnailURL:(NSURL *)thumbnailURL
{
    _thumbnailURL = thumbnailURL;
    if (_thumbnailURL) {
        [self.thumbnailImageView setImageWithURL:thumbnailURL];
    } else {
        NSString *searchString = self.title;
        if (searchString != nil && !_isDirectory) {
            [_artworkProvider searchForArtworkForVideoRelatedString:searchString];
        }
    }
}

- (void)setThumbnailImage:(UIImage *)thumbnailImage
{
    [self.thumbnailImageView setImage:thumbnailImage];
}
#endif

-(UIImage *)thumbnailImage
{
    return self.thumbnailImageView.image;
}

- (void)setTitle:(NSString *)title
{
    self.titleLabel.text = title;
#if 0
    if (title != nil && !_isDirectory) {
        [_artworkProvider searchForArtworkForVideoRelatedString:title];
    }
#endif
}

- (NSString *)title
{
    return self.titleLabel.text;
}

- (void)setSubtitle:(NSString *)subtitle
{
    self.subtitleLabel.text = subtitle;
}

- (NSString *)subtitle
{
    return self.subtitleLabel.text;
}

@end
