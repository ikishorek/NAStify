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

#import "VLCPlaybackInfoPanelTVViewController.h"

@interface VLCPlaybackInfoRateTVViewController : VLCPlaybackInfoPanelTVViewController
@property (nonatomic, weak) IBOutlet UISegmentedControl *segmentedControl;
- (IBAction)segmentedControlChanged:(UISegmentedControl *)sender;
@end
