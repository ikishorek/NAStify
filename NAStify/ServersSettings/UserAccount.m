//
//  UserAccount.m
//  NAStify
//
//  Created by Sylver Bruneau.
//  Copyright (c) 2012 CodeIsALie. All rights reserved.
//

#import "UserAccount.h"

@implementation UserAccount

- (id)init
{
    self = [super init];
    if (self)
    {
        self.uuid = [NSString generateUUID];
        self.accountName = nil;
        self.serverType = SERVER_TYPE_UNKNOWN;
        self.authenticationType = AUTHENTICATION_TYPE_UNKNOWN;
        self.server = nil;
        self.port = nil;
        self.userName = nil;
        self.boolSSL = NO;
        self.acceptUntrustedCertificate = YES;
        self.encoding = nil;
        self.transfertMode = 0;
        self.settings = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self)
    {
        self.uuid =  [coder decodeObjectForKey:@"uuid"];
        self.accountName = [coder decodeObjectForKey:@"accountName"];
        self.serverType = [coder decodeIntForKey:@"serverType"];
        self.authenticationType = [coder decodeIntForKey:@"authenticationType"];
        self.server = [coder decodeObjectForKey:@"server"];
        self.port = [coder decodeObjectForKey:@"port"];
        self.userName = [coder decodeObjectForKey:@"userName"];
        self.boolSSL = [coder decodeBoolForKey:@"boolSSL"];
        self.acceptUntrustedCertificate = [coder decodeBoolForKey:@"acceptUntrustedCertificate"];
        self.encoding = [coder decodeObjectForKey:@"encoding"];
        self.transfertMode = [coder decodeIntForKey:@"transfertMode"];
        self.settings = [coder decodeObjectForKey:@"settings"];
        if ([coder decodeObjectForKey:@"settings"])
        {
            self.settings = [coder decodeObjectForKey:@"settings"];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.uuid forKey:@"uuid"];
    [coder encodeObject:self.accountName forKey:@"accountName"];
    [coder encodeInt:self.serverType forKey:@"serverType"];
    [coder encodeInt:self.authenticationType forKey:@"authenticationType"];
    [coder encodeObject:self.server forKey:@"server"];
    [coder encodeObject:self.port forKey:@"port"];
    [coder encodeObject:self.userName forKey:@"userName"];
    [coder encodeBool:self.boolSSL forKey:@"boolSSL"];
    [coder encodeBool:self.acceptUntrustedCertificate forKey:@"acceptUntrustedCertificate"];
    [coder encodeObject:self.encoding forKey:@"encoding"];
    [coder encodeInt:self.transfertMode forKey:@"transfertMode"];
    [coder encodeObject:self.settings forKey:@"settings"];
}

- (id)copyWithZone:(NSZone *)zone
{
    UserAccount *copy = [[[self class] allocWithZone: zone] init];
    copy.uuid = [self.uuid copyWithZone:zone];
    copy.accountName = [self.accountName copyWithZone:zone];
    copy.serverType = self.serverType;
    copy.authenticationType = self.authenticationType;
    copy.server = [self.server copyWithZone:zone];
    copy.port = [self.port copyWithZone:zone];
    copy.userName = [self.userName copyWithZone:zone];
    copy.boolSSL = self.boolSSL;
    copy.acceptUntrustedCertificate = self.acceptUntrustedCertificate;
    copy.encoding = [self.encoding copyWithZone:zone];
    copy.transfertMode = self.transfertMode;
    copy.settings = [self.settings copyWithZone:zone];
    return copy;
}

- (BOOL)shouldShowAds
{
    BOOL showAds = TRUE;
    switch (self.serverType)
    {
        case SERVER_TYPE_LOCAL:
        {
            showAds = FALSE;
            break;
        }
            
        default:
            break;
    }
    return showAds;
}

@end
