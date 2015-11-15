/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaybackInfoTracksTVViewController.h"
#import "VLCPlaybackInfoTrackTVCell.h"
#import "VLCPlaybackInfoTrackTVTitleView.h"
#import "VLCPlaybackController.h"

@interface VLCPlaybackInfoTracksDataSource : NSObject
@property (nonatomic, readonly) VLCMediaPlayer *mediaPlayer;
@property (nonatomic) NSString *title;
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface VLCPlaybackInfoTracksDataSourceAudio : VLCPlaybackInfoTracksDataSource <UICollectionViewDataSource, UICollectionViewDelegate>
@end
@interface VLCPlaybackInfoTracksDataSourceSubtitle : VLCPlaybackInfoTracksDataSource <UICollectionViewDataSource, UICollectionViewDelegate>
@end


@interface VLCPlaybackInfoTracksTVViewController ()
@property (nonatomic) IBOutlet VLCPlaybackInfoTracksDataSourceAudio *audioDataSource;
@property (nonatomic) IBOutlet VLCPlaybackInfoTracksDataSourceSubtitle *subtitleDataSource;
@end


@implementation VLCPlaybackInfoTracksTVViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"TRACK_SELECTION", nil);
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    UINib *nib = [UINib nibWithNibName:@"VLCPlaybackInfoTrackTVCell" bundle:nil];
    NSString *identifier = [VLCPlaybackInfoTrackTVCell identifier];
    [self.audioTrackCollectionView registerNib:nib forCellWithReuseIdentifier:identifier];
    [self.subtitleTrackCollectionView registerNib:nib forCellWithReuseIdentifier:identifier];
    [VLCPlaybackInfoTrackTVTitleView registerInCollectionView:self.audioTrackCollectionView];
    [VLCPlaybackInfoTrackTVTitleView registerInCollectionView:self.subtitleTrackCollectionView];

    self.audioDataSource.title = NSLocalizedString(@"AUDIO", nil);
    self.subtitleDataSource.title = NSLocalizedString(@"SUBTITLES", nil);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaPlayerChanged) name:VLCPlaybackControllerPlaybackMetadataDidChange object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self mediaPlayerChanged];
}

- (CGSize)preferredContentSize
{
    CGFloat prefferedHeight = MAX(self.audioTrackCollectionView.contentSize.height, self.subtitleTrackCollectionView.contentSize.height);
    return CGSizeMake(CGRectGetWidth(self.view.bounds), prefferedHeight);
}

- (void)mediaPlayerChanged
{
    [self.audioTrackCollectionView reloadData];
    [self.subtitleTrackCollectionView reloadData];
}

@end

@implementation VLCPlaybackInfoTracksDataSource
- (VLCMediaPlayer *)mediaPlayer
{
    return [VLCPlaybackController sharedInstance].mediaPlayer;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    VLCPlaybackInfoTrackTVTitleView *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[VLCPlaybackInfoTrackTVTitleView identifier] forIndexPath:indexPath];

    BOOL showTitle = [collectionView numberOfItemsInSection:indexPath.section] != 0;
    header.titleLabel.text = showTitle ? self.title : nil;
    return header;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [collectionView dequeueReusableCellWithReuseIdentifier:[VLCPlaybackInfoTrackTVCell identifier] forIndexPath:indexPath];
}
@end

@implementation VLCPlaybackInfoTracksDataSourceAudio
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.mediaPlayer.numberOfAudioTracks;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    VLCPlaybackInfoTrackTVCell *trackCell = (VLCPlaybackInfoTrackTVCell*)cell;
    BOOL isSelected = [self.mediaPlayer.audioTrackIndexes[indexPath.row] intValue] == self.mediaPlayer.currentAudioTrackIndex;
    trackCell.selectionMarkerVisible = isSelected;
    trackCell.titleLabel.text = self.mediaPlayer.audioTrackNames[indexPath.row];
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.mediaPlayer.currentAudioTrackIndex = [self.mediaPlayer.audioTrackIndexes[indexPath.row] intValue];
    [collectionView reloadData];
}

@end

@implementation VLCPlaybackInfoTracksDataSourceSubtitle
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.mediaPlayer.numberOfSubtitlesTracks;
}
- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    VLCPlaybackInfoTrackTVCell *trackCell = (VLCPlaybackInfoTrackTVCell*)cell;
    BOOL isSelected = [self.mediaPlayer.videoSubTitlesIndexes[indexPath.row] intValue] == self.mediaPlayer.currentVideoSubTitleIndex;
    trackCell.selectionMarkerVisible = isSelected;
    trackCell.titleLabel.text = self.mediaPlayer.videoSubTitlesNames[indexPath.row];
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.mediaPlayer.currentVideoSubTitleIndex = [self.mediaPlayer.videoSubTitlesIndexes[indexPath.row] intValue];
    [collectionView reloadData];
}

@end