/*****************************************************************************
 * VLCSidebarController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCSidebarController.h"
#import "GHRevealViewController.h"
#if 0
#import "VLCMenuTableViewController.h"
#endif

@interface VLCSidebarController()
{
    GHRevealViewController *_revealController;
#if 0
    VLCMenuTableViewController *_menuViewController;
#endif
    UIViewController *_contentViewController;
}

@end

@implementation VLCSidebarController

+ (instancetype)sharedInstance
{
    static VLCSidebarController *sharedInstance = nil;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        sharedInstance = [VLCSidebarController new];
    });

    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];

    if (!self)
        return self;

    _revealController = [[GHRevealViewController alloc] initWithNibName:nil bundle:nil];
    _revealController.extendedLayoutIncludesOpaqueBars = YES;
    _revealController.edgesForExtendedLayout = UIRectEdgeAll;

#if 0
    _menuViewController = [[VLCMenuTableViewController alloc] initWithNibName:nil bundle:nil];
    _revealController.sidebarViewController = _menuViewController;
#endif
    return self;
}

#pragma mark - VC handling

- (UIViewController *)fullViewController
{
    return _revealController;
}

- (void)setContentViewController:(UIViewController *)contentViewController
{
    contentViewController.view.backgroundColor = [UIColor VLCDarkBackgroundColor];
    _revealController.contentViewController = contentViewController;
}

- (UIViewController *)contentViewController
{
    return _revealController.contentViewController;
}

#pragma mark - actual work

- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath scrollPosition:(UITableViewScrollPosition)scrollPosition
{
#if 0
    [_menuViewController selectRowAtIndexPath:indexPath
                                     animated:NO
                               scrollPosition:scrollPosition];
#endif
}

- (void)hideSidebar
{
    [_revealController toggleSidebar:NO duration:kGHRevealSidebarDefaultAnimationDuration];
}

- (void)toggleSidebar
{
    [_revealController toggleSidebar:!_revealController.sidebarShowing duration:kGHRevealSidebarDefaultAnimationDuration];
}

@end
