//
//  FileProviderBrowserViewController.m
//  NAStify
//
//  Created by Sylver Bruneau.
//  Copyright (c) 2014 CodeIsALie. All rights reserved.
//

#import "FileProviderBrowserViewController.h"
#import "CustomNavigationController.h"
#import "CustomTabBarController.h"
#import "FileItem.h"

#import "private.h"

@interface FileProviderBrowserViewController ()
- (void)triggerReconnect;
@end

/* HUD Tags */
#define TAG_HUD_DOWNLOAD    1
#define TAG_HUD_UPLOAD      2

#define TABLE_ROW_HEIGHT    50.0f

#define SEARCH_SCOPE_FOLDER 0
#define SEARCH_SCOPE_RECURSIVE 1

@implementation FileProviderBrowserViewController

- (id)init
{
    self = [super init];
    if (self)
    {
        self.isConnected = FALSE;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!self.connectionManager)
    {
        self.connectionManager = [[ConnectionManager alloc] init];
        self.connectionManager.userAccount = self.userAccount;
    }
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    
    // Setup tableView
    self.tableView = [[UITableView alloc] initWithFrame:[[self view] bounds] style:UITableViewStylePlain];
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    [self.tableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = TABLE_ROW_HEIGHT;
    
    [self.view addSubview:self.tableView];
    
    NSString *title = [[self.currentFolder.path componentsSeparatedByString:@"/"] lastObject];
    if ([title length] == 0)
    {
        title = @"/";
        [self.navigationItem setHidesBackButton:YES animated:NO];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                                                              target:self
                                                                                              action:@selector(confirmDisconnect)];
        [super viewDidLoad];
    }
    
    self.navigationItem.title = title;
    
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    [self.navigationController.toolbar setTintColor:[UIColor blackColor]];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(dropViewDidBeginRefreshing:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    // Toolbar setup
    UIBarButtonItem *flexibleSpaceButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                             target:nil
                                                                                             action:nil];
    UIBarButtonItem *selectButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save here",@"")
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(selectButton:event:)];
    
    UIBarButtonItem *addFolderButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                         target:self
                                                                                         action:@selector(addFolderButton:event:)];
    addFolderButtonItem.style = UIBarButtonItemStylePlain;
    
    NSMutableArray *buttons = [NSMutableArray arrayWithObjects:flexibleSpaceButtonItem,nil];

    if (ServerSupportsFeature(FileUpload))
    {
        [buttons addObjectsFromArray:[NSArray arrayWithObjects:
                                      selectButtonItem,
                                      nil]];
    }

    if (ServerSupportsFeature(FolderCreate))
    {
        [buttons addObjectsFromArray:[NSArray arrayWithObjects:
                                      flexibleSpaceButtonItem,
                                      addFolderButtonItem,
                                      nil]];
    }

    [buttons addObjectsFromArray:[NSArray arrayWithObjects:
                                  flexibleSpaceButtonItem,
                                  nil]];

    [self setToolbarItems:buttons];
}

- (void)dropViewDidBeginRefreshing:(UIRefreshControl *)refreshControl
{
    [self.connectionManager listForPath:self.currentFolder];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = NO;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(triggerReconnect)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.sylver.NAStify"];
    if ([defaults objectForKey:@"sortingType"])
    {
        self.sortingType = (FileItemSortType)[[defaults objectForKey:@"sortingType"] integerValue];
    }
    else
    {
        self.sortingType = SORT_BY_NAME_DESC_FOLDER_FIRST;
    }
    
    if ([self.filesArray count] != 0)
    {
        [self.filesArray sortFileItemArrayWithOrder:self.sortingType];
        [self.tableView reloadData];
    }
    
    // Show tab bar if it was not visible
    [(CustomTabBarController *)self.tabBarController setTabBarHidden:NO withAnimation:YES];

    // If in export mode, show the toolbar
    if (self.mode == ProviderModeExport)
    {
        self.navigationController.toolbarHidden = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    self.connectionManager.delegate = self;
    
    if ([self.currentFolder.path isEqualToString:@"/"])
    {
        if (([self.filesArray count] == 0))
        {
            // Login
            BOOL needToWaitLogin = NO;
            needToWaitLogin = [self.connectionManager login];
            
            // Get file list if possible
            if (!needToWaitLogin)
            {
                [self.connectionManager listForPath:self.currentFolder];
                [self.connectionManager spaceInfoAtPath:self.currentFolder];
            }
        }
        else if (self.userAccount.serverType == SERVER_TYPE_LOCAL)
        {
            // Get file list
            [self.connectionManager listForPath:self.currentFolder];
            [self.connectionManager spaceInfoAtPath:self.currentFolder];
        }
    }
    else if ([self.filesArray count] == 0)
    {
        // Get file list
        [self.connectionManager listForPath:self.currentFolder];
        [self.connectionManager spaceInfoAtPath:self.currentFolder];
    }
    else if (self.userAccount.serverType == SERVER_TYPE_LOCAL)
    {
        // Get file list (we are with local files, it costs nothing to reload here)
        [self.connectionManager listForPath:self.currentFolder];
        [self.connectionManager spaceInfoAtPath:self.currentFolder];
    }
    
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSArray *viewControllers = self.navigationController.viewControllers;
    if ((viewControllers.count > 1) &&
        ([viewControllers objectAtIndex:viewControllers.count-2] == self))
    {
        // We are pushing a new view, nothing to do
    }
    else if ((![viewControllers containsObject:self]) && (viewControllers.count == 1) && self.isConnected)
    {
        // We are going back to servers list, logout from server
        [self.connectionManager logout];
    }
    
    // Remove popover if needed
    if (self.sortPopoverController.isPopoverVisible)
    {
        [self.sortPopoverController dismissPopoverAnimated:YES];
        self.sortPopoverController = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
    [super viewWillDisappear:animated];
}

#pragma mark -
#pragma mark Disconnection handling

- (void)confirmDisconnect
{
    if ((self.isConnected) && ([self.connectionManager needLogout]))
    {
        BOOL needToWaitLogout = FALSE;
        // We are going back to servers list, logout from server
        needToWaitLogout = [self.connectionManager logout];
        
        if (needToWaitLogout)
        {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view
                                                      animated:YES];
            hud.delegate = self;
            hud.labelText = NSLocalizedString(@"Disconnect", nil);
        }
        else
        {
            self.isConnected = FALSE;
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.filesArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *FileBrowserCellIdentifier = @"FileBrowserCell";
    
    FileItem *fileItem = (FileItem *)([self.filesArray objectAtIndex:indexPath.row]);
    
    {
        FileBrowserCell *fileBrowserCell = (FileBrowserCell *)[tableView dequeueReusableCellWithIdentifier:FileBrowserCellIdentifier];
        if (fileBrowserCell == nil)
        {
            fileBrowserCell = [[FileBrowserCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                     reuseIdentifier:FileBrowserCellIdentifier];
        }
        
        // Remove long tap gesture recognizer if present
        NSArray *gestureList = [fileBrowserCell gestureRecognizers];
        for (id gesture in gestureList)
        {
            if ([gesture isKindOfClass:[UILongPressGestureRecognizer class]])
            {
                [fileBrowserCell removeGestureRecognizer:gesture];
                break;
            }
        }
        
        // Configure the cell...
        [fileBrowserCell setFileItem:fileItem
                        withDelegate:self
                              andTag:TAG_TEXTFIELD_FILENAME];
        
        return fileBrowserCell;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FileItem *fileItem = (FileItem *)([self.filesArray objectAtIndex:indexPath.row]);
    
    switch ([fileItem fileType])
    {
        case FILETYPE_FOLDER:
        {
            FileProviderBrowserViewController *fileBrowserViewController = [[FileProviderBrowserViewController alloc] init];
            fileBrowserViewController.delegate = self.delegate;
            fileBrowserViewController.validTypes = self.validTypes;
            fileBrowserViewController.isConnected = TRUE;
            fileBrowserViewController.currentFolder = fileItem;
            fileBrowserViewController.userAccount = self.userAccount; // Not needed, may be useful for future needs
            fileBrowserViewController.connectionManager = self.connectionManager;
            fileBrowserViewController.mode = self.mode;
            fileBrowserViewController.fileURL = self.fileURL;
            [self.navigationController pushViewController:fileBrowserViewController animated:YES];
            break;
        }
        default:
        {
            if (self.mode == ProviderModeImport)
            {
                // Download file
                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view
                                                          animated:YES];
                if (ServerSupportsFeature(UploadCancel))
                {
                    hud.allowsCancelation = YES;
                    hud.tag = TAG_HUD_DOWNLOAD;
                }
                
                hud.delegate = self;
                hud.labelText = NSLocalizedString(@"Downloading", nil);
                
                NSURL *containerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.sylver.NAStify"];
                NSString *downloadFilePath = [containerURL.path stringByAppendingFormat:@"/File Provider Storage/%@",fileItem.name];
                self.downloadFilename = downloadFilePath;
                [self.connectionManager downloadFile:fileItem
                                         toLocalName:downloadFilePath];
            }
            break;
        }
            
    }
    // deselect the cell
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)hudDidCancel:(MBProgressHUD *)hud;
{
    switch (hud.tag)
    {
        case TAG_HUD_DOWNLOAD:
        {
            [self.connectionManager cancelDownloadTask];
            [hud hide:YES];
            break;
        }
        case TAG_HUD_UPLOAD:
        {
            [self.connectionManager cancelUploadTask];
            [hud hide:YES];
            break;
        }
        default:
            break;
    }
}

#pragma mark - Reconnection delegate
- (void)triggerReconnect
{
    [self.connectionManager reconnect];
}

#pragma mark - OTP (2-Step authentication) support

- (void)sendOTP:(NSString *)otp
{
    [self.connectionManager sendOTP:otp];
}

- (void)sendOTPEmergencyCode
{
    [self.connectionManager sendOTPEmergencyCode];
}

#pragma mark - ConnectionManager protocol

- (void)CMAction:(NSDictionary *)dict
{
    // If there is a message, show it
    if ([dict objectForKey:@"message"])
    {
        // Show error
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:[dict objectForKey:@"title"]
                                                                       message:[dict objectForKey:@"message"]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [alert dismissViewControllerAnimated:YES completion:nil];
                                                              }];
        [alert addAction:defaultAction];
        if ([[dict objectForKey:@"action"] integerValue] == BROWSER_ACTION_QUIT_SERVER)
        {
            [self.delegate.nc popToRootViewControllerAnimated:YES];
             [self.delegate.nc presentViewController:alert animated:YES completion:nil];
        }
        else
        {
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
    else if ([dict objectForKey:@"action"])
    {
        switch ([[dict objectForKey:@"action"] integerValue])
        {
            case BROWSER_ACTION_QUIT_SERVER:
            {
                // Go back to servers list
                [self.delegate.nc popToRootViewControllerAnimated:YES];
                break;
            }
            case BROWSER_ACTION_DO_NOTHING:
            default:
            {
                break;
            }
        }
        
    }
}

- (void)CMLogin:(NSDictionary *)dict
{
    // If login is ok, request list
    if ([[dict objectForKey:@"success"] boolValue])
    {
        // Request list
        self.isConnected = TRUE;
        [self.connectionManager listForPath:self.currentFolder];
        [self.connectionManager spaceInfoAtPath:self.currentFolder];
    }
    else
    {
        // Remove any HUD
        MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
        [hud hide:YES];
        
        // Show error
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Login",nil)
                                                                       message:NSLocalizedString([dict objectForKey:@"error"],nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [alert dismissViewControllerAnimated:YES completion:nil];
                                                                  // Go back to servers list
                                                                  [self.navigationController popToRootViewControllerAnimated:YES];
                                                                  
                                                              }];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)CMLogout:(NSDictionary *)dict
{
    if (self.isConnected)
    {
        self.isConnected = FALSE;
        [self.navigationController popViewControllerAnimated:YES];
        MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
        [hud hide:YES];
    }
}

- (void)CMRequestOTP:(NSNotification *)notification
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"2-Factor Authentication",nil)
                                                                   message:NSLocalizedString(@"Enter 6-digit code or 8-digit emergency code",nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action) {
                                                   UITextField *textField = alert.textFields[0];
                                                   [self sendOTP:textField.text];

                                                   [alert dismissViewControllerAnimated:YES completion:nil];
                                               }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",nil)
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       // Go back to servers list
                                                       [self.navigationController popToRootViewControllerAnimated:YES];
                                                       [alert dismissViewControllerAnimated:YES completion:nil];
                                                   }];
    
    [alert addAction:ok];
    [alert addAction:cancel];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"code",nil);
    }];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)CMFilesList:(NSDictionary *)dict
{
    [self.refreshControl endRefreshing];
    
    // Check if the notification is for this folder
    if ((([dict objectForKey:@"path"]) && ([self.currentFolder.path isEqualToString:[dict objectForKey:@"path"]])) ||
        (([dict objectForKey:@"id"]) && ([[self.currentFolder.objectIds lastObject] isEqualToString:[dict objectForKey:@"id"]])))
    {
        if ([[dict objectForKey:@"success"] boolValue])
        {
            self.isConnected = TRUE;
            
            NSArray *filesList = [dict objectForKey:@"filesList"];
            
            self.filesArray = [[NSMutableArray alloc] init];
            
            for (NSDictionary *element in filesList)
            {
                FileItem *fileItem = [[FileItem alloc] init];
                fileItem.name = [element objectForKey:@"filename"];
                fileItem.isDir = [[element objectForKey:@"isdir"] boolValue];
                fileItem.shortPath = self.currentFolder.path;
                if ([self.currentFolder.path isEqualToString:@"/"])
                {
                    fileItem.path = [@"/" stringByAppendingPathComponent:fileItem.name]; // Path to file
                }
                else
                {
                    fileItem.path = [self.currentFolder.path stringByAppendingPathComponent:fileItem.name]; // Path to file
                }
                if ([element objectForKey:@"path"])
                {
                    fileItem.fullPath = [element objectForKey:@"path"]; // Path with filename/foldername
                }
                else
                {
                    fileItem.fullPath = fileItem.path;
                }
                
                if ([element objectForKey:@"id"])
                {
                    fileItem.objectIds = [self.currentFolder.objectIds arrayByAddingObject:[element objectForKey:@"id"]];
                }
                
                if ([element objectForKey:@"iscompressed"])
                {
                    fileItem.isCompressed = [[element objectForKey:@"iscompressed"] boolValue];
                }
                else
                {
                    fileItem.isCompressed = NO;
                }
                
                if (fileItem.isDir)
                {
                    fileItem.fileSize = nil;
                    fileItem.fileSizeNumber = nil;
                    fileItem.owner = nil;
                    if ([element objectForKey:@"isejectable"])
                    {
                        fileItem.isEjectable = [[element objectForKey:@"isejectable"] boolValue];
                    }
                    else
                    {
                        fileItem.isEjectable = NO;
                    }
                }
                else
                {
                    if ([element objectForKey:@"type"])
                    {
                        fileItem.type = [element objectForKey:@"type"];
                    }
                    else
                    {
                        fileItem.type = [[fileItem.name componentsSeparatedByString:@"."] lastObject];
                    }
                    
                    if ([element objectForKey:@"filesizenumber"])
                    {
                        fileItem.fileSizeNumber = [element objectForKey:@"filesizenumber"];
                    }
                    else
                    {
                        fileItem.fileSizeNumber = nil;
                    }
                    fileItem.fileSize = [[element objectForKey:@"filesizenumber"] stringForNumberOfBytes];
                    
                    fileItem.owner = [element objectForKey:@"owner"];
                    
                    fileItem.isEjectable = NO;
                }
                fileItem.writeAccess = [[element objectForKey:@"writeaccess"] boolValue];
                
                /* Date */
                if (([element objectForKey:@"date"]) &&
                    ([[element objectForKey:@"date"] doubleValue] != 0))
                {
                    fileItem.fileDateNumber = [NSNumber numberWithDouble:[[element objectForKey:@"date"] doubleValue]];
                    NSTimeInterval mtime = (NSTimeInterval)[[element objectForKey:@"date"] doubleValue];
                    NSDate *mdate = [NSDate dateWithTimeIntervalSince1970:mtime];
                    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
                    [formatter setDateStyle:NSDateFormatterMediumStyle];
                    [formatter setTimeStyle:NSDateFormatterShortStyle];
                    
                    fileItem.fileDate = [formatter stringFromDate:mdate];
                }
                [self.filesArray addObject:fileItem];
            }
            
            // Sort files array
            [self.filesArray sortFileItemArrayWithOrder:self.sortingType];
            
            // Refresh tableView
            [self.tableView performSelectorOnMainThread:@selector(reloadData)
                                             withObject:nil
                                          waitUntilDone:NO];
        }
        else
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Browse",nil)
                                                                           message:NSLocalizedString([dict objectForKey:@"error"],nil)
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      [alert dismissViewControllerAnimated:YES completion:nil];
                                                                  }];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}

- (void)CMSpaceInfo:(NSDictionary *)dict
{
    if ([[dict objectForKey:@"success"] boolValue])
    {
        if (self.spaceInfo == nil)
        {
            CGRect tableViewFrame = self.tableView.frame;
            tableViewFrame.size.height -= 30;
            [self.tableView setFrame:tableViewFrame];
            
            self.spaceInfo = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                                       self.tableView.bounds.size.height,
                                                                       self.view.bounds.size.width,
                                                                       30)];
            self.spaceInfo.textAlignment = NSTextAlignmentCenter;
            self.spaceInfo.textColor = [UIColor whiteColor];
            self.spaceInfo.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
            self.spaceInfo.backgroundColor = [UIColor colorWithRed:0.0
                                                             green:0.0
                                                              blue:0.0
                                                             alpha:0.65];
            self.spaceInfo.font = [UIFont fontWithName:@"Helvetica" size:17];
            [self.view addSubview:self.spaceInfo];
        }
        self.spaceInfo.text = [NSString stringWithFormat:@"Free/Total : %@ / %@",
                               [[dict objectForKey:@"freespace"] stringForNumberOfBytes],
                               [[dict objectForKey:@"totalspace"] stringForNumberOfBytes]];
    }
}

- (void)CMCreateFolder:(NSDictionary *)dict
{
    if ([[dict objectForKey:@"success"] boolValue])
    {
        // Get file list
        [self.connectionManager listForPath:self.currentFolder];
    }
    else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Create folder",nil)
                                                                       message:NSLocalizedString([dict objectForKey:@"error"],nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [alert dismissViewControllerAnimated:YES completion:nil];
                                                              }];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)CMDownloadProgress:(NSDictionary *)dict
{
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
    if ([dict objectForKey:@"progress"])
    {
        float progress = [[dict objectForKey:@"progress"] floatValue];
        if (progress != 0)
        {
            hud.mode = MBProgressHUDModeAnnularDeterminate;
            hud.progress = progress;
        }
        if ([dict objectForKey:@"downloadedBytes"])
        {
            NSNumber *downloaded = [dict objectForKey:@"downloadedBytes"];
            NSNumber *totalSize = [dict objectForKey:@"totalBytes"];
            hud.detailsLabelText = [NSString stringWithFormat:@"%@ of %@ done",[downloaded stringForNumberOfBytes],[totalSize stringForNumberOfBytes]];
        }
    }
    else
    {
        NSNumber *downloaded = [dict objectForKey:@"downloadedBytes"];
        hud.detailsLabelText = [NSString stringWithFormat:@"%@ done",[downloaded stringForNumberOfBytes]];
    }
}

- (void)CMDownloadFinished:(NSDictionary *)dict
{
    if ([[dict objectForKey:@"success"] boolValue])
    {
        // call dismissGrantingAccessToURL from DocumentPickerViewController
        [self.delegate openDocument:self.downloadFilename];
    }
    else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"File download",nil)
                                                                       message:NSLocalizedString([dict objectForKey:@"error"],nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [alert dismissViewControllerAnimated:YES completion:nil];
                                                              }];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
    
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
    [hud hide:YES];
}

- (void)CMUploadProgress:(NSDictionary *)dict
{
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
    if ([dict objectForKey:@"progress"])
    {
        float progress = [[dict objectForKey:@"progress"] floatValue];
        if (progress != 0)
        {
            hud.mode = MBProgressHUDModeAnnularDeterminate;
            hud.progress = progress;
        }
        if ([dict objectForKey:@"uploadedBytes"])
        {
            NSNumber *uploaded = [dict objectForKey:@"uploadedBytes"];
            NSNumber *totalSize = [dict objectForKey:@"totalBytes"];
            hud.detailsLabelText = [NSString stringWithFormat:@"%@ of %@ done",[uploaded stringForNumberOfBytes],[totalSize stringForNumberOfBytes]];
        }
    }
    else
    {
        NSNumber *uploaded = [dict objectForKey:@"uploadedBytes"];
        hud.detailsLabelText = [NSString stringWithFormat:@"%@ done",[uploaded stringForNumberOfBytes]];
    }
}

- (void)CMUploadFinished:(NSDictionary *)dict
{
    if ([[dict objectForKey:@"success"] boolValue])
    {
        // Close Application extension
        [self.delegate uploadFinished];
    }
    else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"File upload",nil)
                                                                       message:NSLocalizedString([dict objectForKey:@"error"],nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [alert dismissViewControllerAnimated:YES completion:nil];
                                                              }];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
    
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
    [hud hide:YES];
}

- (void)CMConnectionError:(NSDictionary *)dict
{
    // We should hide HUD if any ...
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
    [hud hide:YES];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Connection error",nil)
                                                                   message:NSLocalizedString([dict objectForKey:@"error"],nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [alert dismissViewControllerAnimated:YES completion:nil];
                                                          }];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Orientation management

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)inOrientation
{
    return YES;
}

#pragma mark - Sorting option management

- (void)selectedSortingType:(FileItemSortType)sortingType
{
    if (self.sortPopoverController.isPopoverVisible)
    {
        [self.sortPopoverController dismissPopoverAnimated:YES];
        self.sortPopoverController = nil;
    }
    
    self.sortingType = sortingType;
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.sylver.NAStify"];
    [defaults setInteger:sortingType forKey:@"sortingType"];
    [defaults synchronize];
    
    [self.filesArray sortFileItemArrayWithOrder:self.sortingType];
    [self.tableView reloadData];
}

- (void)cancelSortingType
{
    if (self.sortPopoverController.isPopoverVisible)
    {
        [self.sortPopoverController dismissPopoverAnimated:YES];
        self.sortPopoverController = nil;
    }
}

#pragma mark - Tabbar buttons Methods

- (void)selectButton:(UIBarButtonItem*)sender event:(UIEvent*)event
{
    // Upload file
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view
                                              animated:YES];
    if (ServerSupportsFeature(UploadCancel))
    {
        hud.allowsCancelation = YES;
        hud.tag = TAG_HUD_UPLOAD;
    }
    
    hud.delegate = self;
    hud.labelText = NSLocalizedString(@"Uploading", nil);
    
    FileItem *fileItem = [[FileItem alloc] init];
    fileItem.name = [[self.fileURL lastPathComponent] precomposedStringWithCanonicalMapping];
    fileItem.fullPath = [[self.fileURL path] precomposedStringWithCanonicalMapping];
    NSDictionary *fileAttrib = [[NSFileManager defaultManager] attributesOfItemAtPath:fileItem.fullPath error:nil];
    fileItem.fileSizeNumber = [fileAttrib objectForKey:NSFileSize];
    
    [self.connectionManager uploadLocalFile:fileItem
                                     toPath:self.currentFolder
                                  overwrite:YES
                                serverFiles:self.filesArray];
}

- (void)addFolderButton:(UIBarButtonItem*)sender event:(UIEvent*)event
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Create folder",nil)
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action) {
                                                   UITextField *textField = alert.textFields[0];
                                                   [self.connectionManager createFolder:textField.text inFolder:self.currentFolder];
                                                   
                                                   [alert dismissViewControllerAnimated:YES completion:nil];
                                               }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",nil)
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       [alert dismissViewControllerAnimated:YES completion:nil];
                                                   }];
    
    [alert addAction:ok];
    [alert addAction:cancel];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"Folder name", nil);
    }];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Memory management

- (void)dealloc
{
    // To fix "-[UIView release]: message sent to deallocated instance xxxxx"
    self.tableView.tableHeaderView = nil;
}

@end