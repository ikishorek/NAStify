/**
 * @file MEGAAcountDetails.h
 * @brief Details about a MEGA account
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
#import <Foundation/Foundation.h>

typedef NS_ENUM (NSInteger, MEGAAccountType) {
    MEGAAccountTypeFree = 0,
    MEGAAccountTypeProI,
    MEGAAccountTypeProII,
    MEGAAccountTypeProIII
};

/**
 * @brief Details about a MEGA account.
 */
@interface MEGAAcountDetails : NSObject

/**
 * @brief Used storage for the account (in bytes).
 */
@property (readonly, nonatomic) NSNumber *storageUsed;

/**
 * @brief Maximum storage for the account (in bytes).
 */
@property (readonly, nonatomic) NSNumber *storageMax;

/**
 * @brief Used bandwidth for the account (in bytes).
 */
@property (readonly, nonatomic) NSNumber *transferOwnUsed;

/**
 * @brief Maximum available bandwidth for the account (in bytes).
 */
@property (readonly, nonatomic) NSNumber *transferMax;

/**
 * @brief PRO level of the MEGA account.
 *
 * Valid values are:
 * - MEGAAccountTypeFree = 0
 * - MEGAAccountTypeProI = 1
 * - MEGAAccountTypeProII = 2
 * - MEGAAccountTypeProIII = 3
 */
@property (readonly, nonatomic) MEGAAccountType type;

/**
 * @brief Creates a copy of this MEGAAcountDetails object.
 *
 * The resulting object is fully independent of the source MEGAAcountDetails,
 * it contains a copy of all internal attributes, so it will be valid after
 * the original object is deleted.
 *
 * You are the owner of the returned object.
 *
 * @return Copy of the MEGAAcountDetails object.
 */
- (instancetype)clone;

/**
 * @brief Get the used storage in for a node.
 *
 * Only root nodes are supported.
 *
 * @param handle Handle of the node to check.
 * @return Used storage (in bytes).
 * @see [MEGASdk rootNode], [MEGASdk rubbishNode], [MEGASdk inboxNode].
 */
- (NSNumber *)storageUsedForHandle:(uint64_t)handle;

/**
 * @brief Get the number of files in a node.
 *
 * Only root nodes are supported.
 *
 * @param handle Handle of the node to check.
 * @return Number of files in the node.
 * @see [MEGASdk rootNode], [MEGASdk rubbishNode], [MEGASdk inboxNode].
 */
- (NSNumber *)numberFilesForHandle:(uint64_t)handle;

/**
 * @brief Get the number of folders in a node.
 *
 * Only root nodes are supported.
 *
 * @param handle Handle of the node to check.
 * @return Number of folders in the node.
 * @see [MEGASdk rootNode], [MEGASdk rubbishNode], [MEGASdk inboxNode].
 */
- (NSNumber *)numberFoldersForHandle:(uint64_t)handle;

@end
