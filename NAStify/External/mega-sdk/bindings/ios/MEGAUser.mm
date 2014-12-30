/**
 * @file MEGAUser.mm
 * @brief Represents an user in MEGA
 *
 * (c) 2013-2014 by Mega Limited, Auckland, New Zealand
 *
 * This file is part of the MEGA SDK - Client Access Engine.
 *
 * Applications using the MEGA API must present a valid application key
 * and comply with the the rules set forth in the Terms of Service.
 *
 * The MEGA SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * @copyright Simplified (2-clause) BSD License.
 *
 * You should have received a copy of the license along with this
 * program.
 */
#import "MEGAUser.h"
#import "megaapi.h"

using namespace mega;

@interface MEGAUser ()

@property MegaUser *megaUser;
@property BOOL cMemoryOwn;

@end

@implementation MEGAUser

- (instancetype)initWithMegaUser:(MegaUser *)megaUser cMemoryOwn:(BOOL)cMemoryOwn {
    self = [super init];
    
    if (self != nil) {
        _megaUser = megaUser;
        _cMemoryOwn = cMemoryOwn;
    }
    
    return self;
}

- (void)dealloc {
    if (self.cMemoryOwn) {
        delete _megaUser;
    }
}

- (instancetype)clone {
    return self.megaUser ? [[MEGAUser alloc] initWithMegaUser:self.megaUser->copy() cMemoryOwn:YES] : nil;
}

- (MegaUser *)getCPtr {
    return self.megaUser;
}

- (NSString *)email{
    if (!self.megaUser) return nil;
    
    return self.megaUser ? [[NSString alloc] initWithUTF8String:self.megaUser->getEmail()] : nil;
}

- (MEGAUserVisibility)access {
    return (MEGAUserVisibility) (self.megaUser ? self.megaUser->getVisibility() : ::mega::MegaUser::VISIBILITY_UNKNOWN);
}

- (NSDate *)timestamp {
    return self.megaUser ? [[NSDate alloc] initWithTimeIntervalSince1970:self.megaUser->getTimestamp()] : nil;
}

@end
