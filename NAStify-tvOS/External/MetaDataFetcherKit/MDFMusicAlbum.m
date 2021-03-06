/*****************************************************************************
 * MDFMusicAlbum.m
 *****************************************************************************
 * Copyright (C) 2015 Felix Paul Kühne
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#import "MDFMusicAlbum.h"

@implementation MDFMusicAlbum

- (NSString *)description
{
    return [NSString stringWithFormat:@"%s: name:'%@', Hatchet-ID:%li, artwork %@, medium artist images %@, large artist images %@",
            __PRETTY_FUNCTION__,
            self.name,
            (long)self.hatchetAlbumID,
            self.artworkImage,
            self.mediumSizedArtistImages,
            self.largeSizedArtistImages];
}

@end
