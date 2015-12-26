//
//  NAStifyConstants.h
//  NAStify
//
//  Created by Sylver Bruneau.
//  Copyright © 2015 CodeIsALie. All rights reserved.
//

#ifndef NAStifyConstants_h
#define NAStifyConstants_h

#define kVLCSettingPasscodeKey @"Passcode"
#define kVLCSettingPasscodeOnKey @"PasscodeProtection"
#define kVLCSettingContinueAudioInBackgroundKey @"BackgroundAudioPlayback"
#define kVLCSettingStretchAudio @"audio-time-stretch"
#define kVLCSettingStretchAudioOnValue @"1"
#define kVLCSettingStretchAudioOffValue @"0"
#define kVLCSettingTextEncoding @"subsdec-encoding"
#define kVLCSettingTextEncodingDefaultValue @"Windows-1252"
#define kVLCSettingSkipLoopFilter @"avcodec-skiploopfilter"
#define kVLCSettingSkipLoopFilterNone @(0)
#define kVLCSettingSkipLoopFilterNonRef @(1)
#define kVLCSettingSkipLoopFilterNonKey @(3)
#define kVLCSettingSaveHTTPUploadServerStatus @"isHTTPServerOn"
#define kVLCSettingSubtitlesFont @"quartztext-font"
#define kVLCSettingSubtitlesFontDefaultValue @"Helvetica Neue"
#define kVLCSettingSubtitlesFontSize @"quartztext-rel-fontsize"
#define kVLCSettingSubtitlesFontSizeDefaultValue @"16"
#define kVLCSettingSubtitlesBoldFont @"quartztext-bold"
#define kVLCSettingSubtitlesBoldFontDefaultValue @NO
#define kVLCSettingSubtitlesFontColor @"quartztext-color"
#define kVLCSettingSubtitlesFontColorDefaultValue @"16777215"
#define kVLCSettingSubtitlesFilePath @"sub-file"
#define kVLCSettingDeinterlace @"deinterlace"
#define kVLCSettingDeinterlaceDefaultValue @(0)
#define kVLCSettingNetworkCaching @"network-caching"
#define kVLCSettingNetworkCachingDefaultValue @(999)
#define kVLCSettingVolumeGesture @"EnableVolumeGesture"
#define kVLCSettingPlayPauseGesture @"EnablePlayPauseGesture"
#define kVLCSettingBrightnessGesture @"EnableBrightnessGesture"
#define kVLCSettingSeekGesture @"EnableSeekGesture"
#define kVLCSettingCloseGesture @"EnableCloseGesture"
#define kVLCSettingVariableJumpDuration @"EnableVariableJumpDuration"
#define kVLCSettingVideoFullscreenPlayback @"AlwaysUseFullscreenForVideo"
#define kVLCSettingContinuePlayback @"ContinuePlayback"
#define kVLCSettingContinueAudioPlayback @"ContinueAudioPlayback"
#define kVLCSettingFTPTextEncoding @"ftp-text-encoding"
#define kVLCSettingFTPTextEncodingDefaultValue @(5) // ISO Latin 1
#define kVLCSettingPlaybackSpeedDefaultValue @"playback-speed"
#define kVLCSettingEqualizerProfile @"EqualizerProfile"
#define kVLCSettingEqualizerProfileDefaultValue @(0)
#define kVLCSettingPlaybackForwardSkipLength @"playback-forward-skip-length"
#define kVLCSettingPlaybackForwardSkipLengthDefaultValue @(60)
#define kVLCSettingPlaybackBackwardSkipLength @"playback-forward-skip-length"
#define kVLCSettingPlaybackBackwardSkipLengthDefaultValue @(60)

#define kVLCShowRemainingTime @"show-remaining-time"
#define kVLCRecentURLs @"recent-urls"
#define kVLCPrivateWebStreaming @"private-streaming"
#define kVLChttpScanSubtitle @"http-scan-subtitle"

#define kVLCFTPServer @"ftp-server"
#define kVLCFTPLogin @"ftp-login"
#define kVLCFTPPassword @"ftp-pass"
#define kVLCLastFTPServer @"last-ftp-server"
#define kVLCLastFTPLogin @"last-ftp-login"
#define kVLCLastFTPPassword @"last-ftp-pass"

#define kVLCPLEXServer @"plex-server"
#define kVLCPLEXPort @"plex-port"
#define kVLCLastPLEXServer @"last-plex-server"
#define kVLCLastPLEXPort @"last-plex-port"
#define kVLCPLEXLogin @"plex-login"
#define kVLCPLEXPassword @"plex-password"

#define kVLCSettingLastUsedSubtitlesSearchLanguage @"kVLCSettingLastUsedSubtitlesSearchLanguage"

#define kSupportedFileExtensions @"\\.(3gp|3gp|3gp2|3gpp|amv|asf|avi|axv|divx|dv|flv|f4v|gvi|gxf|m1v|m2p|m2t|m2ts|m2v|m4v|mks|mkv|moov|mov|mp2v|mp4|mpeg|mpeg1|mpeg2|mpeg4|mpg|mpv|mt2s|mts|mxf|mxg|nsv|nuv|oga|ogg|ogm|ogv|ogx|spx|ps|qt|rec|rm|rmvb|tod|ts|tts|vlc|vob|vro|webm|wm|wmv|wtv|xesc)$"
#define kSupportedSubtitleFileExtensions @"\\.(srt|sub|cdg|idx|utf|ass|ssa|aqt|jss|psb|rt|smi|txt|smil)$"
#define kSupportedAudioFileExtensions @"\\.(aac|aiff|aif|amr|aob|ape|axa|caf|flac|it|m2a|m4a|m4b|mka|mlp|mod|mp1|mp2|mp3|mpa|mpc|mpga|oga|ogg|oma|opus|rmi|s3m|spx|tta|voc|vqf|wav|w64|wma|wv|xa|xm)$"

#define kBlobHash @"521923d214b9ae628da7987cf621e94c4afdd726"

#define kNASTifySettingPlayerType       @"VideoPlayerType"
#define kNASTifySettingPlayerTypeInternal           0
#define kNASTifySettingPlayerTypeExternal           1
#define kNASTifySettingInternalPlayer   @"VideoPlayer"
#define kNASTifySettingInternalPlayerTypeQTVLC      0
#define kNASTifySettingInternalPlayerTypeVLCOnly    1
#define kNASTifySettingExternalPlayer   @"ExternalVideoPlayer"
#define kNASTifySettingExternalPlayerType   @"ExternalVideoPlayerType"
#define kNASTifySettingExternalPlayerTypeVlc        0
#define kNASTifySettingExternalPlayerTypeAceplayer  1
#define kNASTifySettingExternalPlayerTypeGplayer    2
#define kNASTifySettingExternalPlayerTypeOplayer    3
#define kNASTifySettingExternalPlayerTypeGoodplayer 4
#define kNASTifySettingExternalPlayerTypePlex       5

#define kNASTifySettingBrowserShowGCast     @"BrowserShowGCast"
#define kNASTifySettingPlayerType           @"VideoPlayerType"
#define kNASTifySettingPlayerTypeInternal           0
#define kNASTifySettingPlayerTypeExternal           1
#define kNASTifySettingInternalPlayer       @"VideoPlayer"
#define kNASTifySettingInternalPlayerTypeQTVLC      0
#define kNASTifySettingInternalPlayerTypeVLCOnly    1
#define kNASTifySettingExternalPlayer       @"ExternalVideoPlayer"
#define kNASTifySettingExternalPlayerType   @"ExternalVideoPlayerType"
#define kNASTifySettingExternalPlayerTypeVlc        0
#define kNASTifySettingExternalPlayerTypeAceplayer  1
#define kNASTifySettingExternalPlayerTypeGplayer    2
#define kNASTifySettingExternalPlayerTypeOplayer    3
#define kNASTifySettingExternalPlayerTypeGoodplayer 4
#define kNASTifySettingExternalPlayerTypePlex       5
#define kNASTifySettingBrowserType          @"BrowserType"
#define kNASTifySettingBrowserTypeGrid              0
#define kNASTifySettingBrowserTypeLine              1
#define kNASTifySettingAllowDelete          @"AllowDelete"

#endif /* NAStifyConstants_h */
