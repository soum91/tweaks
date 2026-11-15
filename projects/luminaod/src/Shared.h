#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <sys/sysctl.h>
#import <notify.h>
#define LA_PREFS @"/var/mobile/Library/Preferences/com.soum91.luminaod.plist"
#define LA_STATUS @"/var/mobile/Library/Caches/com.soum91.luminaod/status.plist"
#define LA_NOTIFY "com.soum91.luminaod.changed"
static NSString *LAModel(void) { char s[128]={0}; size_t n=sizeof(s); sysctlbyname("hw.machine",s,&n,NULL,0); return @(s); }
static BOOL LATarget(void) { return [LAModel() isEqual:@"iPhone14,3"] && [UIDevice.currentDevice.systemVersion isEqual:@"16.1.1"]; }
static NSDictionary *LARead(void) { return [NSDictionary dictionaryWithContentsOfFile:LA_PREFS] ?: @{}; }
static BOOL LAEnabled(NSDictionary *p) { return p[@"Enabled"] ? [p[@"Enabled"] boolValue] : YES; }
static NSInteger LAMode(NSDictionary *p) { return [p[@"Mode"] integerValue]; } // 0 native, 1 live lock screen
static BOOL LAWrite(NSDictionary *p) { BOOL ok=[p writeToFile:LA_PREFS atomically:YES]; if(ok) notify_post(LA_NOTIFY); return ok; }
static NSString *LAVersion(void) { NSDictionary *i=[NSDictionary dictionaryWithContentsOfFile:@"/var/jb/Applications/LuminAOD.app/Info.plist"]; return [NSString stringWithFormat:@"%@ (%@)",i[@"CFBundleShortVersionString"] ?: @"unknown", i[@"CFBundleVersion"] ?: @"unknown"]; }
