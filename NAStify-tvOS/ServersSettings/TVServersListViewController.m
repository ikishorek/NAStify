//
//  ServersListViewController.m
//  NAStify-tvOS
//
//  Created by Sylver B on 27/09/15.
//  Copyright © 2015 Sylver B. All rights reserved.
//

#import "TVServersListViewController.h"
#import "ConnectionManager.h"
#import "TVFileBrowserCollectionViewController.h"
#import "TVFileBrowserTableViewController.h"
#import "ServerTypeViewController.h"
#import "SSKeychain.h"

// Servers settings views
#import "ServerSettingsFreeboxRevViewController.h"
#import "ServerSettingsFtpViewController.h"
#import "ServerSettingsOwnCloudViewController.h"
#import "ServerSettingsQnapViewController.h"
#import "ServerSettingsSambaViewController.h"
#import "ServerSettingsSynologyViewController.h"
#import "ServerSettingsWebDavViewController.h"

@interface ServersListViewController ()
@property(nonatomic) NSInteger timeCounter;
@property(nonatomic, strong) NSTimer *longTapTimer;

- (void)longPressAction:(UILongPressGestureRecognizer*)longPressRecognizer;

@end

@implementation ServersListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.sylver.NAStify"];
    NSData * accountsData = [defaults objectForKey:@"accounts"];
    if (!accountsData)
    {
        self.accounts = [[NSMutableArray alloc] init];
    }
    else
    {
        self.accounts = [[NSMutableArray alloc] initWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:accountsData]];
    }
    
    self.navigationItem.title = NSLocalizedString(@"Servers", nil);

    self.smbDevices = [[NSMutableArray alloc] init];
    
    // Register account changes notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addAccountNotification:)
                                                 name:@"ADDACCOUNT"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateAccountNotification:)
                                                 name:@"UPDATEACCOUNT"
                                               object:nil];
    
    // Register to application notifications
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnteredBackground:)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleBecomeActive:)
                                                 name: UIApplicationDidBecomeActiveNotification
                                               object: nil];
    
    self.tableView.layoutMargins = UIEdgeInsetsMake(0, 90, 0, 90);
}

- (void)viewDidAppear:(BOOL)animated
{
    // Reachability
    self.manager = [AFHTTPRequestOperationManager manager];
    
    __weak __typeof(self)weakSelf = self;
    __weak __typeof(_filteredUPNPDevices)weakFilteredUPNPDevices = _filteredUPNPDevices;
    __weak __typeof(self.smbDevices)weakSmbDevices = self.smbDevices;
    
    [self.manager.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        __strong __typeof(weakFilteredUPNPDevices)strongFilteredUPNPDevices = weakFilteredUPNPDevices;
        switch (status) {
            case AFNetworkReachabilityStatusReachableViaWiFi:
                [weakSelf performSelectorInBackground:@selector(startUPNPDiscovery) withObject:nil];
                [weakSelf performSelectorInBackground:@selector(startNetbiosDiscovery) withObject:nil];
                break;
            default:
                [weakSelf stopUPNPDiscovery];
                strongFilteredUPNPDevices = nil;
                [weakSelf stopNetbiosDiscovery];
                [weakSmbDevices removeAllObjects];
                [weakSelf.tableView reloadData];
                break;
        }
    }];
    [self.manager.reachabilityManager startMonitoring];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopNetbiosDiscovery];
}

#pragma mark - Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL result = NO;
    switch (indexPath.section)
    {
        case 0:
        {
            result = NO;
            break;
        }
        default:
            break;
    }
    return result;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = 0;
    switch (section)
    {
        case 0: // Servers
        {
            rows = [self.accounts count]+1;
            break;
        }
        case 1: // UPnP
        {
            if (self.manager.reachabilityManager.networkReachabilityStatus == AFNetworkReachabilityStatusReachableViaWiFi)
            {
                rows = _filteredUPNPDevices.count;
            }
            break;
        }
        case 2: // SMB/CIFS
        {
            if (self.smbDevices.count > 0)
            {
                rows = self.smbDevices.count;
            }
            break;
        }
        default:
        {
            break;
        }
    }
    return rows;
}

- (NSString *)tableView:(UITableView *)atableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sectionName = nil;
    switch (section)
    {
        case 0:
        {
            sectionName = NSLocalizedString(@"Servers",nil);
            break;
        }
        case 1:
        {
            if ((self.manager.reachabilityManager.networkReachabilityStatus == AFNetworkReachabilityStatusReachableViaWiFi) &&
                (_filteredUPNPDevices.count > 0))
            {
                sectionName = NSLocalizedString(@"UPnP",nil);
            }
            break;
        }
        case 2:
        {
            if (self.smbDevices.count > 0)
            {
                sectionName = NSLocalizedString(@"Windows Shares (SMB/CIFS)",nil);
            }
            break;
        }
        default:
        {
            break;
        }
    }
    return sectionName;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * TableViewCellIdentifier = @"TableViewCell";
    static NSString * ServerCellIdentifier = @"ServerCell";
    static NSString * UPnPCellIdentifier = @"UPnPCell";
    UITableViewCell *cell = nil;
    
    switch (indexPath.section)
    {
        case 0:
        {
            if (indexPath.row != [self.accounts count])
            {
                ServerCell *serverCell = (ServerCell *)[tableView dequeueReusableCellWithIdentifier:ServerCellIdentifier];
                if (serverCell == nil)
                {
                    serverCell = [[ServerCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                   reuseIdentifier:ServerCellIdentifier];
                }
                
                // Remove long tap gesture recognizer if present
                NSArray *gestureList = [serverCell gestureRecognizers];
                for (id gesture in gestureList)
                {
                    if ([gesture isKindOfClass:[UILongPressGestureRecognizer class]])
                    {
                        [serverCell removeGestureRecognizer:gesture];
                        break;
                    }
                }
                
                // Tap recognizer
                UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                      action:@selector(longPressAction:)];
                [serverCell addGestureRecognizer:gesture];

                // Configure the cell...
                [serverCell setAccount:[self.accounts objectAtIndex:indexPath.row]];
                cell = serverCell;
            }
            else
            {
                // Last item, show the "Add server" cell
                cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:TableViewCellIdentifier];
                if (cell == nil)
                {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                             reuseIdentifier:TableViewCellIdentifier];
                }
                
                // Configure the cell...
                cell.textLabel.text = NSLocalizedString(@"Add new server", nil);
            }
            break;
        }
        case 1: // UPnP
        {
            cell = [tableView dequeueReusableCellWithIdentifier:UPnPCellIdentifier];
            if (cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                              reuseIdentifier:UPnPCellIdentifier];
            }
            // Get device info
            BasicUPnPDevice *device = _filteredUPNPDevices[indexPath.row];

            cell.textLabel.text = [device friendlyName];
            if ([device smallIcon])
            {
                cell.imageView.image = [device smallIcon];
            }
            else
            {
                cell.imageView.image = [UIImage imageNamed:@"upnp_small.png"];
            }

            cell.editingAccessoryType = UITableViewCellAccessoryNone;
            cell.showsReorderControl = NO;

            break;
        }
        case 2: // SMB/CIFS
        {
            ServerCell *serverCell = (ServerCell *)[tableView dequeueReusableCellWithIdentifier:ServerCellIdentifier];
            if (serverCell == nil)
            {
                serverCell = [[ServerCell alloc] initWithStyle:UITableViewCellStyleDefault
                                               reuseIdentifier:ServerCellIdentifier];
            }
            
            // Configure the cell...
            serverCell.editingAccessoryType = UITableViewCellAccessoryNone;
            serverCell.showsReorderControl = NO;

            UserAccount *account = [[UserAccount alloc] init];
            account.serverType = SERVER_TYPE_SAMBA;
            account.accountName = [NSString stringWithFormat:@"%@ (IP : %@)",[[self.smbDevices objectAtIndex:indexPath.row] objectForKey:@"hostname"],[[self.smbDevices objectAtIndex:indexPath.row] objectForKey:@"ip"]];
            [serverCell setAccount:account];
            cell = serverCell;
            break;
        }
        default:
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.sylver.NAStify"];
    switch (indexPath.section)
    {
        case 0: // Servers
        {
            if (indexPath.row != [self.accounts count])
            {
                FileItem *rootFolder = [[FileItem alloc] init];
                rootFolder.isDir = YES;
                rootFolder.path = @"/";
                rootFolder.objectIds = [NSArray arrayWithObject:kRootID];
                
                if ([[defaults objectForKey:kNASTifySettingBrowserType] integerValue] == kNASTifySettingBrowserTypeGrid)
                {
                    FileBrowserCollectionViewController *fileBrowserViewController = [[FileBrowserCollectionViewController alloc] initWithNibName:nil bundle:nil];
                    fileBrowserViewController.userAccount = [self.accounts objectAtIndex:indexPath.row];
                    fileBrowserViewController.currentFolder = rootFolder;
                    
                    [self.navigationController pushViewController:fileBrowserViewController animated:YES];
                }
                else
                {
                    FileBrowserTableViewController *fileBrowserViewController = [[FileBrowserTableViewController alloc] init];
                    fileBrowserViewController.userAccount = [self.accounts objectAtIndex:indexPath.row];
                    fileBrowserViewController.currentFolder = rootFolder;
                    
                    [self.navigationController pushViewController:fileBrowserViewController animated:YES];
                }
            }
            else
            {
                ServerTypeViewController * stc = [[ServerTypeViewController alloc] initWithStyle:UITableViewStyleGrouped];
                [self.navigationController pushViewController:stc animated:YES];
            }
            
            break;
        }
        case 1: // UPnP
        {
            BasicUPnPDevice *device = _filteredUPNPDevices[indexPath.row];
            if ([[device urn] isEqualToString:@"urn:schemas-upnp-org:device:MediaServer:1"])
            {
                MediaServer1Device *server = (MediaServer1Device*)device;
                
                UserAccount *account = [[UserAccount alloc] init];
                account.serverType = SERVER_TYPE_UPNP;
                account.serverObject = server;
                
                FileItem *rootFolder = [[FileItem alloc] init];
                rootFolder.isDir = YES;
                rootFolder.path = @"/";
                rootFolder.objectIds = [NSArray arrayWithObject:@"0"];
                
                if ([[defaults objectForKey:kNASTifySettingBrowserType] integerValue] == kNASTifySettingBrowserTypeGrid)
                {
                    FileBrowserCollectionViewController *fileBrowserViewController = [[FileBrowserCollectionViewController alloc] initWithNibName:nil bundle:nil];
                    fileBrowserViewController.userAccount = account;
                    fileBrowserViewController.currentFolder = rootFolder;
                    
                    [self.navigationController pushViewController:fileBrowserViewController animated:YES];
                }
                else
                {
                    FileBrowserTableViewController *fileBrowserViewController = [[FileBrowserTableViewController alloc] init];
                    fileBrowserViewController.userAccount = account;
                    fileBrowserViewController.currentFolder = rootFolder;
                    
                    [self.navigationController pushViewController:fileBrowserViewController animated:YES];
                }
            }
            break;
        }
        case 2: // SMB/CIFS
        {
            UserAccount *account = [[UserAccount alloc] init];
            account.serverType = SERVER_TYPE_SAMBA;
            account.server = [[self.smbDevices objectAtIndex:indexPath.row] objectForKey:@"hostname"];
            account.serverObject = [[self.smbDevices objectAtIndex:indexPath.row] objectForKey:@"group"];
            
            FileItem *rootFolder = [[FileItem alloc] init];
            rootFolder.isDir = YES;
            rootFolder.path = @"/";
            rootFolder.objectIds = [NSArray arrayWithObject:kRootID];
            
            if ([[defaults objectForKey:kNASTifySettingBrowserType] integerValue] == kNASTifySettingBrowserTypeGrid)
            {
                FileBrowserCollectionViewController *fileBrowserViewController = [[FileBrowserCollectionViewController alloc] initWithNibName:nil bundle:nil];
                fileBrowserViewController.userAccount = account;
                fileBrowserViewController.currentFolder = rootFolder;
                
                [self.navigationController pushViewController:fileBrowserViewController animated:YES];
            }
            else
            {
                FileBrowserTableViewController *fileBrowserViewController = [[FileBrowserTableViewController alloc] init];
                fileBrowserViewController.userAccount = account;
                fileBrowserViewController.currentFolder = rootFolder;
                
                [self.navigationController pushViewController:fileBrowserViewController animated:YES];
            }
            break;
        }
        default:
            break;
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (self.editing && indexPath.section == 0)
    {
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

#pragma mark - Notification Methods

- (void)addAccountNotification:(NSNotification*)notification
{
    if ([notification userInfo] == nil) return;
    
    if ([[notification userInfo] objectForKey:@"account"])
    {
        // Save new server
        [self.accounts addObject:[[notification userInfo] objectForKey:@"account"]];
        [self save];
        [self.tableView reloadData];
        if (self.accounts.count == 1)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Information", nil)
                                                                               message:NSLocalizedString(@"You can manage servers by performing a long tap on them",nil)
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * action) {
                                                                     [alert dismissViewControllerAnimated:YES completion:nil];
                                                                 }];
                [alert addAction:okAction];
                [self presentViewController:alert animated:YES completion:nil];
            });
        }
    }
}

- (void)updateAccountNotification:(NSNotification*)notification
{
    if ([notification userInfo] == nil) return;
    
    if (([[notification userInfo] objectForKey:@"account"]) && ([[notification userInfo] objectForKey:@"accountIndex"]))
    {
        // Update server
        NSInteger index = [[[notification userInfo] objectForKey:@"accountIndex"] intValue];
        [self.accounts removeObjectAtIndex:index];
        [self.accounts insertObject:[[notification userInfo] objectForKey:@"account"] atIndex:index];
        [self save];
        [self.tableView reloadData];
    }
    else if ([[notification userInfo] objectForKey:@"account"])
    {
        // Check that the account is existing in the context
        BOOL indexFound = NO;
        for (UserAccount *account in self.accounts)
        {
            if (account == [[notification userInfo] objectForKey:@"account"])
            {
                indexFound = YES;
                break;
            }
        }
        
        // Save updated information
        if (indexFound)
        {
            [self save];
            [self.tableView reloadData];
        }
    }
}

- (void)save
{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.sylver.NAStify"];
    [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:self.accounts] forKey:@"accounts"];
    [defaults synchronize];
}

#pragma mark - Long tap management

- (void)longPressAction:(UILongPressGestureRecognizer *)tapRecognizer
{
    if (tapRecognizer.state == UIGestureRecognizerStateBegan)
    {
        // Find corresponding cell
        NSIndexPath *indexPath;
        for (NSInteger j = 0; j < [self.tableView numberOfSections]; ++j)
        {
            for (NSInteger i = 0; i < [self.tableView numberOfRowsInSection:j]; ++i)
            {
                NSArray *gestureList = [[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:j]] gestureRecognizers];
                for (id gesture in gestureList)
                {
                    if ([gesture isEqual:tapRecognizer])
                    {
                        indexPath = [NSIndexPath indexPathForRow:i inSection:j];
                        break;
                    }
                }
                
            }
        }
        if (indexPath && (indexPath.row != NSNotFound) && (indexPath.section != NSNotFound))
        {
            if (indexPath.section == 0)
            {
                UserAccount *account = [self.accounts objectAtIndex:indexPath.row];
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:account.accountName
                                                                               message:NSLocalizedString(@"Action",nil)
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *editAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Edit",nil)
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {
                                                                       [self editServerAtIndexPath:indexPath];
                                                                       [alert dismissViewControllerAnimated:YES completion:nil];
                                                                   }];
                UIAlertAction *moveUpAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Move up in list",nil)
                                                                       style:UIAlertActionStyleDefault
                                                                     handler:^(UIAlertAction * action) {
                                                                         [self moveUpServerAtIndexPath:indexPath];
                                                                         [alert dismissViewControllerAnimated:YES completion:nil];
                                                                     }];
                UIAlertAction *moveDownAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Move down in list",nil)
                                                                         style:UIAlertActionStyleDefault
                                                                       handler:^(UIAlertAction * action) {
                                                                           [self moveDownServerAtIndexPath:indexPath];
                                                                           [alert dismissViewControllerAnimated:YES completion:nil];
                                                                       }];
                UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete",nil)
                                                                       style:UIAlertActionStyleDestructive
                                                                     handler:^(UIAlertAction * action) {
                                                                         [self deleteServerAtIndexPath:indexPath];
                                                                         [alert dismissViewControllerAnimated:YES completion:nil];
                                                                     }];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",nil)
                                                                       style:UIAlertActionStyleCancel
                                                                     handler:^(UIAlertAction * action) {
                                                                         // Do nothing
                                                                         [alert dismissViewControllerAnimated:YES completion:nil];
                                                                     }];
                [alert addAction:editAction];
                // If not first server, allow to move up
                if (indexPath.row > 0)
                {
                    [alert addAction:moveUpAction];
                }
                // If not last server, allow to move down
                if (indexPath.row < self.accounts.count - 1)
                {
                    [alert addAction:moveDownAction];
                }
                [alert addAction:deleteAction];
                [alert addAction:cancelAction];
                [self presentViewController:alert animated:YES completion:nil];
            }
        }
    }
}

- (void)moveUpServerAtIndexPath:(NSIndexPath *)indexPath
{
    UserAccount *accountToMove = [self.accounts objectAtIndex:indexPath.row];
    [self.accounts removeObjectAtIndex:indexPath.row];
    [self.accounts insertObject:accountToMove atIndex:indexPath.row - 1];
    [self save];
    // Update
    [self.tableView reloadData];
}

- (void)moveDownServerAtIndexPath:(NSIndexPath *)indexPath
{
    UserAccount *accountToMove = [self.accounts objectAtIndex:indexPath.row];
    [self.accounts removeObjectAtIndex:indexPath.row];
    [self.accounts insertObject:accountToMove atIndex:indexPath.row + 1];
    [self save];
    // Update
    [self.tableView reloadData];
}

- (void)deleteServerAtIndexPath:(NSIndexPath *)indexPath
{
    UserAccount *account = [self.accounts objectAtIndex:indexPath.row];

    // delete entries in keychain
    switch (account.serverType)
    {
#if 0
        case SERVER_TYPE_DROPBOX:
        {
            if (account.userName != nil)
            {
                // unlink account if it's a dropbox account
                [[DBSession sharedSession] unlinkUserId:account.userName];
            }
            break;
        }
        case SERVER_TYPE_GOOGLEDRIVE:
        {
            [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:account.uuid];
            break;
        }
#endif
        default:
        {
            [SSKeychain deletePasswordForService:account.uuid
                                         account:@"password"];
            [SSKeychain deletePasswordForService:account.uuid
                                         account:@"token"];
            [SSKeychain deletePasswordForService:account.uuid
                                         account:@"pubCert"];
            [SSKeychain deletePasswordForService:account.uuid
                                         account:@"privCert"];
            break;
        }
    }
    
    [self.accounts removeObjectAtIndex:indexPath.row];
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    [self save];
    // Update
    [self.tableView reloadData];
}

- (void)editServerAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case 0: // Servers
        {
            // Edit account
            UserAccount *account = [self.accounts objectAtIndex:indexPath.row];
            switch (account.serverType)
            {
                case SERVER_TYPE_WEBDAV:
                {
                    ServerSettingsWebDavViewController *svc = [[ServerSettingsWebDavViewController alloc] initWithStyle:UITableViewStyleGrouped
                                                                                                             andAccount:account
                                                                                                               andIndex:indexPath.row];
                    svc.userAccount = [self.accounts objectAtIndex:indexPath.row];
                    [self.navigationController pushViewController:svc animated:YES];
                    break;
                }
                case SERVER_TYPE_FTP:
                case SERVER_TYPE_SFTP:
                {
                    ServerSettingsFtpViewController *svc = [[ServerSettingsFtpViewController alloc] initWithStyle:UITableViewStyleGrouped
                                                                                                       andAccount:account
                                                                                                         andIndex:indexPath.row];
                    svc.userAccount = [self.accounts objectAtIndex:indexPath.row];
                    [self.navigationController pushViewController:svc animated:YES];
                    break;
                }
                case SERVER_TYPE_SYNOLOGY:
                {
                    ServerSettingsSynologyViewController *svc = [[ServerSettingsSynologyViewController alloc] initWithStyle:UITableViewStyleGrouped
                                                                                                                 andAccount:account
                                                                                                                   andIndex:indexPath.row];
                    svc.userAccount = [self.accounts objectAtIndex:indexPath.row];
                    [self.navigationController pushViewController:svc animated:YES];
                    break;
                }
                case SERVER_TYPE_OWNCLOUD:
                {
                    ServerSettingsOwnCloudViewController *svc = [[ServerSettingsOwnCloudViewController alloc] initWithStyle:UITableViewStyleGrouped
                                                                                                                 andAccount:account
                                                                                                                   andIndex:indexPath.row];
                    svc.userAccount = [self.accounts objectAtIndex:indexPath.row];
                    [self.navigationController pushViewController:svc animated:YES];
                    break;
                }
                case SERVER_TYPE_QNAP:
                {
                    ServerSettingsQnapViewController *svc = [[ServerSettingsQnapViewController alloc] initWithStyle:UITableViewStyleGrouped
                                                                                                         andAccount:account
                                                                                                           andIndex:indexPath.row];
                    svc.userAccount = [self.accounts objectAtIndex:indexPath.row];
                    [self.navigationController pushViewController:svc animated:YES];
                    break;
                }
                case SERVER_TYPE_FREEBOX_REVOLUTION:
                {
                    ServerSettingsFreeboxRevViewController *svc = [[ServerSettingsFreeboxRevViewController alloc] initWithStyle:UITableViewStyleGrouped
                                                                                                                     andAccount:account
                                                                                                                       andIndex:indexPath.row];
                    svc.userAccount = [self.accounts objectAtIndex:indexPath.row];
                    [self.navigationController pushViewController:svc animated:YES];
                    break;
                }
                case SERVER_TYPE_SAMBA:
                {
                    ServerSettingsSambaViewController *svc = [[ServerSettingsSambaViewController alloc] initWithStyle:UITableViewStyleGrouped
                                                                                                           andAccount:account
                                                                                                             andIndex:indexPath.row];
                    svc.userAccount = [self.accounts objectAtIndex:indexPath.row];
                    [self.navigationController pushViewController:svc animated:YES];
                    break;
                }
                default:
                {
                    // Nothing to do
                    break;
                }
            }
            break;
        }
    }
}

#pragma mark - Background management

- (void)handleEnteredBackground:(NSNotification *)notification
{
    [self stopUPNPDiscovery];
    [self stopNetbiosDiscovery];
}

- (void)handleBecomeActive:(NSNotification *)notification
{
    if (self.manager.reachabilityManager.networkReachabilityStatus == AFNetworkReachabilityStatusReachableViaWiFi)
    {
        [self performSelectorInBackground:@selector(startUPNPDiscovery) withObject:nil];
        [self performSelectorInBackground:@selector(startNetbiosDiscovery) withObject:nil];
    }
}

#pragma mark - uPnP support

- (void)startUPNPDiscovery
{
    if ((self.manager.reachabilityManager.networkReachabilityStatus != AFNetworkReachabilityStatusReachableViaWiFi) ||
        _udnpDiscoveryRunning)
    {
        return;
    }
    
    UPnPManager *managerInstance = [UPnPManager GetInstance];
    
    _UPNPdevices = [[managerInstance DB] rootDevices];
    
    if (_UPNPdevices.count > 0)
    {
        [self UPnPDBUpdated:nil];
    }
    
    [[managerInstance DB] addObserver:self];
    
    //Optional; set User Agent
    [[managerInstance SSDP] setUserAgentProduct:[NSString stringWithFormat:@"NAStify/%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]] andOS:[NSString stringWithFormat:@"tvOS/%@", [[UIDevice currentDevice] systemVersion]]];
    
    //Search for UPnP Devices
    [[managerInstance SSDP] startSSDP];
    [[managerInstance SSDP] notifySSDPAlive];
    _searchTimer = [NSTimer timerWithTimeInterval:10.0 target:self selector:@selector(performSSDPSearch) userInfo:nil repeats:YES];
    [_searchTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    [[NSRunLoop mainRunLoop] addTimer:_searchTimer forMode:NSRunLoopCommonModes];
    _udnpDiscoveryRunning = YES;
}

- (void)stopUPNPDiscovery
{
    if (_udnpDiscoveryRunning) {
        UPnPManager *managerInstance = [UPnPManager GetInstance];
        [[managerInstance SSDP] notifySSDPByeBye];
        [_searchTimer invalidate];
        _searchTimer = nil;
        [[managerInstance DB] removeObserver:self];
        [[managerInstance SSDP] stopSSDP];
        _udnpDiscoveryRunning = NO;
    }
}

- (void)performSSDPSearch
{
    UPnPManager *managerInstance = [UPnPManager GetInstance];
    [[managerInstance SSDP] searchSSDP];
    [[managerInstance SSDP] searchForMediaServer];
    [[managerInstance SSDP] SSDPDBUpdate];
}

//protocol UPnPDBObserver
- (void)UPnPDBWillUpdate:(UPnPDB*)sender
{
}

- (void)UPnPDBUpdated:(UPnPDB*)sender
{
    NSUInteger count = _UPNPdevices.count;
    BasicUPnPDevice *device;
    NSMutableArray *mutArray = [[NSMutableArray alloc] init];
    for (NSUInteger x = 0; x < count; x++) {
        device = _UPNPdevices[x];
        if ([[device urn] isEqualToString:@"urn:schemas-upnp-org:device:MediaServer:1"])
        {
            [mutArray addObject:device];
        }
    }
    _filteredUPNPDevices = nil;
    _filteredUPNPDevices = [NSArray arrayWithArray:mutArray];
    
    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
}

#pragma mark - SMB/CIFS

static void on_entry_added(void *p_opaque,
                           netbios_ns_entry *entry)
{
    struct in_addr addr;
    BOOL addServer = YES;
    addr.s_addr = netbios_ns_entry_ip(entry);
    
    ServersListViewController *c_self = (__bridge ServersListViewController *)(p_opaque);
    NSMutableArray *array = c_self.smbDevices;
    
    NSString *ipString = [NSString stringWithFormat:@"%s",inet_ntoa(addr)];
    NSString *hostname = [NSString stringWithFormat:@"%s",netbios_ns_entry_name(entry)];
    NSString *group = [NSString stringWithFormat:@"%s",netbios_ns_entry_group(entry)];
    
    // Check if server is not already present before adding it
    for (NSDictionary *server in array)
    {
        if (([[server objectForKey:@"ip"] isEqualToString:ipString]) &&
            ([[server objectForKey:@"hostname"] isEqualToString:hostname]) &&
            ([[server objectForKey:@"group"] isEqualToString:group]))
        {
            addServer = NO;
        }
    }
    if (addServer)
    {
        NSDictionary *serverDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    ipString, @"ip",
                                    hostname, @"hostname",
                                    group, @"group",
                                    nil];
        
        [array addObject:serverDict];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [c_self.tableView reloadData];
        });
    }
    
    NSLog(@"on_entry_added %@", array);
}

static void on_entry_removed(void *p_opaque,
                             netbios_ns_entry *entry)
{
    struct in_addr addr;
    addr.s_addr = netbios_ns_entry_ip(entry);
    
    ServersListViewController *c_self = (__bridge ServersListViewController *)(p_opaque);
    NSMutableArray *array = c_self.smbDevices;
    
    NSString *ipString = [NSString stringWithFormat:@"%s",inet_ntoa(addr)];
    NSString *hostname = [NSString stringWithFormat:@"%s",netbios_ns_entry_name(entry)];
    NSString *group = [NSString stringWithFormat:@"%s",netbios_ns_entry_group(entry)];

    for (NSDictionary *server in array)
    {
        if (([[server objectForKey:@"ip"] isEqualToString:ipString]) &&
            ([[server objectForKey:@"hostname"] isEqualToString:hostname]) &&
            ([[server objectForKey:@"group"] isEqualToString:group]))
        {
            // Remove this server from list
            [array removeObject:server];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [c_self.tableView reloadData];
            });
        }
    }
    NSLog(@"on_entry_removed %@", array);
}

- (void)startNetbiosDiscovery
{
    netbios_ns_discover_callbacks callbacks;
    
    if ((self.manager.reachabilityManager.networkReachabilityStatus != AFNetworkReachabilityStatusReachableViaWiFi) ||
        _netbiosDiscoveryRunning)
    {
        return;
    }
    
    [self.smbDevices removeAllObjects];
    _ns = netbios_ns_new();
    
    callbacks.p_opaque = (__bridge void *)self;
    callbacks.pf_on_entry_added = on_entry_added;
    callbacks.pf_on_entry_removed = on_entry_removed;
    
    NSLog(@"Discovering SMB/CIFS ...");
    if (!netbios_ns_discover_start(_ns,
                                   4, // broadcast every 4 sec
                                   &callbacks))
    {
        NSLog(@"Error while discovering local network\n");
    }
    _netbiosDiscoveryRunning = YES;
}

- (void)stopNetbiosDiscovery
{
    if (_netbiosDiscoveryRunning)
    {
        netbios_ns_discover_stop(_ns);
        _netbiosDiscoveryRunning = NO;
    }
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    // Unregister notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ADDACCOUNT" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UPDATEACCOUNT" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
}

@end
