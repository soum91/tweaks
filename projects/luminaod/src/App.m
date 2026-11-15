#import "Shared.h"
#import <dlfcn.h>
#import <signal.h>
#import <errno.h>
#import <sys/stat.h>

@interface LAReport : UIViewController
@property NSString *report;
@end
@implementation LAReport
- (void)viewDidLoad { [super viewDidLoad]; self.title=@"Diagnostics"; self.view.backgroundColor=UIColor.systemBackgroundColor; UITextView *v=[[UITextView alloc] initWithFrame:self.view.bounds]; v.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight; v.editable=NO; v.selectable=YES; v.font=[UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular]; v.text=self.report; [self.view addSubview:v]; self.navigationItem.rightBarButtonItems=@[[[UIBarButtonItem alloc] initWithTitle:@"Share" style:0 target:self action:@selector(share:)],[[UIBarButtonItem alloc] initWithTitle:@"Save" style:0 target:self action:@selector(save:)],[[UIBarButtonItem alloc] initWithTitle:@"Copy" style:0 target:self action:@selector(copy:)]]; }
- (void)alert:(NSString *)s { UIAlertController *a=[UIAlertController alertControllerWithTitle:s message:nil preferredStyle:1]; [a addAction:[UIAlertAction actionWithTitle:@"OK" style:0 handler:nil]]; [self presentViewController:a animated:YES completion:nil]; }
- (NSURL *)file { NSURL *u=[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"LuminAOD-diagnostics.txt"]]; NSError *e=nil; if(![self.report writeToURL:u atomically:YES encoding:NSUTF8StringEncoding error:&e]) { [self alert:e.localizedDescription]; return nil; } return u; }
- (void)copy:(id)sender { UIPasteboard.generalPasteboard.string=self.report; [self alert:[UIPasteboard.generalPasteboard.string isEqual:self.report]?@"Copied and verified":@"Copy failed. Use Share, Save, or select the text."]; }
- (void)share:(UIBarButtonItem *)sender { NSURL *u=[self file]; if(!u) return; UIActivityViewController *c=[[UIActivityViewController alloc] initWithActivityItems:@[u] applicationActivities:nil]; c.popoverPresentationController.barButtonItem=sender; [self presentViewController:c animated:YES completion:nil]; }
- (void)save:(id)sender { NSURL *u=[self file]; if(u) [self presentViewController:[[UIDocumentPickerViewController alloc] initForExportingURLs:@[u] asCopy:YES] animated:YES completion:nil]; }
@end

@interface LAFields : UITableViewController <UISearchResultsUpdating>
@property NSMutableDictionary *values;
@property NSArray<NSString *> *keys;
@property UISearchController *search;
@end
@interface LAHome : UITableViewController
@property NSMutableDictionary *prefs;
@property NSDictionary *status;
@property NSTimer *timer;
@end
static void Alert(UIViewController *c,NSString *s,NSString *m) { UIAlertController *a=[UIAlertController alertControllerWithTitle:s message:m preferredStyle:1]; [a addAction:[UIAlertAction actionWithTitle:@"OK" style:0 handler:nil]]; [c presentViewController:a animated:YES completion:nil]; }
static id RawAnswer(NSString *key) { static CFTypeRef(*copy)(CFStringRef); static dispatch_once_t once; dispatch_once(&once,^{ copy=dlsym(dlopen("/usr/lib/libMobileGestalt.dylib",RTLD_NOW),"MGCopyAnswer"); }); return copy ? CFBridgingRelease(copy((__bridge CFStringRef)key)) : nil; }
@implementation LAFields
- (void)viewDidLoad { [super viewDidLoad]; self.title=@"MobileGestalt Editor"; self.values=[NSMutableDictionary dictionary];
    // Read-only discovery. No writes to any MobileGestalt cache anywhere.
    NSString *base=@"/var/containers/Shared/SystemGroup";
    for(NSString *group in [NSFileManager.defaultManager contentsOfDirectoryAtPath:base error:nil]) if([group containsString:@"mobilegestalt"]) { NSString *path=[base stringByAppendingPathComponent:[group stringByAppendingPathComponent:@"Library/Caches/com.apple.MobileGestalt.plist"]]; NSDictionary *cache=[NSDictionary dictionaryWithContentsOfFile:path]; if([cache[@"CacheExtra"] isKindOfClass:NSDictionary.class]) [self.values addEntriesFromDictionary:cache[@"CacheExtra"]]; }
    self.values[@"DeviceSupportsAlwaysOnTime"]=RawAnswer(@"DeviceSupportsAlwaysOnTime") ?: @"Unavailable";
    [self.values addEntriesFromDictionary:LARead()[@"Overrides"] ?: @{}]; self.search=[[UISearchController alloc] initWithSearchResultsController:nil]; self.search.searchResultsUpdater=self; self.search.obscuresBackgroundDuringPresentation=NO; self.navigationItem.searchController=self.search; self.definesPresentationContext=YES; self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add:)]; [self updateSearchResultsForSearchController:self.search]; }
- (void)updateSearchResultsForSearchController:(UISearchController *)c { NSString *q=c.searchBar.text ?: @""; self.keys=[[self.values.allKeys filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *k,id b){ return !q.length || [k localizedCaseInsensitiveContainsString:q] || [[self.values[k] description] localizedCaseInsensitiveContainsString:q]; }]] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]; [self.tableView reloadData]; }
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return self.keys.count; }
- (NSString *)tableView:(UITableView *)t titleForFooterInSection:(NSInteger)s { return @"Changes override answers only inside SpringBoard and Settings while this tweak is injected. CacheExtra is read only. Boolean, integer, real and string values are supported. Respring after editing. Native mode owns its AlwaysOnTime flag. Unknown keys may have no effect."; }
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)p { UITableViewCell *c=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil]; NSString *k=self.keys[p.row]; c.textLabel.text=k; c.textLabel.font=[UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular]; c.detailTextLabel.text=[self.values[k] description]; c.detailTextLabel.numberOfLines=2; c.accessoryType=UITableViewCellAccessoryDisclosureIndicator; return c; }
- (void)add:(id)sender { [self edit:nil]; }
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)p { [self edit:self.keys[p.row]]; }
- (void)edit:(NSString *)key {
    UIAlertController *a=[UIAlertController alertControllerWithTitle:@"Runtime capability override" message:@"Enter a key and value. Saving does not modify the system cache." preferredStyle:1];
    [a addTextFieldWithConfigurationHandler:^(UITextField *f){f.placeholder=@"Key name or obfuscated key"; f.text=key; f.autocapitalizationType=0; f.autocorrectionType=UITextAutocorrectionTypeNo;}];
    [a addTextFieldWithConfigurationHandler:^(UITextField *f){f.placeholder=@"Value"; f.text=key ? [self.values[key] description] : @"true"; f.autocapitalizationType=0; f.autocorrectionType=UITextAutocorrectionTypeNo;}];
    [a addAction:[UIAlertAction actionWithTitle:@"Cancel" style:1 handler:nil]];
    for(NSString *type in @[@"Boolean",@"Integer",@"Real",@"String"]) [a addAction:[UIAlertAction actionWithTitle:[@"Save as " stringByAppendingString:type] style:0 handler:^(UIAlertAction *action){
        NSString *k=[a.textFields[0].text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet],*v=a.textFields[1].text ?: @""; if(!k.length) { Alert(self,@"Key required",nil); return; }
        id value=v; BOOL valid=YES;
        if([type isEqual:@"Boolean"]) { NSString *b=v.lowercaseString; valid=[@[@"true",@"false",@"yes",@"no",@"1",@"0"] containsObject:b]; value=@([@[@"true",@"yes",@"1"] containsObject:b]); }
        else if([type isEqual:@"Integer"]) { NSScanner *s=[NSScanner scannerWithString:v]; long long n=0; valid=[s scanLongLong:&n] && s.isAtEnd; value=@(n); }
        else if([type isEqual:@"Real"]) { NSScanner *s=[NSScanner scannerWithString:v]; double n=0; valid=[s scanDouble:&n] && s.isAtEnd && isfinite(n); value=@(n); }
        if(!valid) { Alert(self,@"Invalid value",[@"Enter a valid " stringByAppendingString:type]); return; }
        NSMutableDictionary *p=[LARead() mutableCopy],*overrides=[p[@"Overrides"] mutableCopy] ?: [NSMutableDictionary dictionary]; overrides[k]=value; p[@"Overrides"]=overrides;
        if(!LAWrite(p)) { Alert(self,@"Save failed",@"Check permissions for the LuminAOD preferences file."); return; } self.values[k]=value; [self updateSearchResultsForSearchController:self.search]; Alert(self,@"Override saved",@"Use Respring in LuminAOD to refresh cached answers.");
    }]];
    if(key && LARead()[@"Overrides"][key]) [a addAction:[UIAlertAction actionWithTitle:@"Remove override" style:2 handler:^(UIAlertAction *x){ NSMutableDictionary *p=[LARead() mutableCopy],*o=[p[@"Overrides"] mutableCopy]; [o removeObjectForKey:key]; p[@"Overrides"]=o; if(!LAWrite(p)) { Alert(self,@"Save failed",nil); return; } self.values[key]=RawAnswer(key) ?: @"Original / unavailable"; [self.tableView reloadData]; }]];
    [self presentViewController:a animated:YES completion:nil];
}
@end
@implementation LAHome
- (void)viewDidLoad { [super viewDidLoad]; self.title=@"LuminAOD"; self.navigationController.navigationBar.prefersLargeTitles=YES; self.tableView.backgroundColor=UIColor.systemGroupedBackgroundColor; }
- (void)viewWillAppear:(BOOL)a { [super viewWillAppear:a]; [self reload]; __weak typeof(self) weak=self; self.timer=[NSTimer scheduledTimerWithTimeInterval:3 repeats:YES block:^(NSTimer *t){[weak reload];}]; }
- (void)viewWillDisappear:(BOOL)a { [super viewWillDisappear:a]; [self.timer invalidate]; self.timer=nil; }
- (void)reload { self.prefs=[LARead() mutableCopy]; self.status=[NSDictionary dictionaryWithContentsOfFile:LA_STATUS] ?: @{}; [self.tableView reloadData]; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)t { return 5; }
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return ((NSInteger[]){2,1,2,3,1})[s]; }
- (NSString *)tableView:(UITableView *)t titleForHeaderInSection:(NSInteger)s { return @[@"Always-On Display",@"Runtime MobileGestalt",@"Live status",@"Manage",@"Installed version"][s]; }
- (NSString *)tableView:(UITableView *)t titleForFooterInSection:(NSInteger)s {
    if(s==0) return LATarget() ? @"Native pipeline unlocks iOS 16's AOD gates. It is experimental on the 13 Pro Max: visible output and flipbook support need device testing. Live Lock Screen uses Apple's real screen at low brightness and consumes more power. Respring after changing mode. No 1 Hz hardware emulation." : @"Unsupported device or OS. Hooks only run on iPhone 13 Pro Max with iOS 16.1.1.";
    if(s==1) return @"Edit capability answers in memory. No system cache is modified. Original answers return when tweak injection is disabled.";
    if(s==2) return @"Reported enabled is software state, not proof that the display remains visible. Status expires after 20 seconds.";
    if(s==3) return @"Live mode: tap to restore brightness; press the side button again to keep the screen off. Low Power Mode, serious heat, face-down and proximity release its screen hold. Sleep Focus and Watch-away detection are not implemented in live mode. Rebooting without re-jailbreaking disables injection.";
    return nil;
}
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)p {
    UITableViewCell *c=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil]; c.textLabel.numberOfLines=2; c.detailTextLabel.numberOfLines=2;
    if(p.section==0 && p.row==0) { c.textLabel.text=@"Enabled"; UISwitch *sw=[UISwitch new]; sw.on=LAEnabled(self.prefs); [sw addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventValueChanged]; c.accessoryView=sw; }
    else if(p.section==0) { c.textLabel.text=@"Mode"; c.detailTextLabel.text=LAMode(self.prefs)==0?@"Native pipeline":@"Live Lock Screen"; c.accessoryType=1; }
    else if(p.section==1) { c.textLabel.text=@"Browse and edit keys"; c.detailTextLabel.text=[NSString stringWithFormat:@"%lu overrides",(unsigned long)[self.prefs[@"Overrides"] count]]; c.accessoryType=1; }
    else if(p.section==2 && p.row==0) { c.textLabel.text=@"SpringBoard"; NSDate *date=self.status[@"timestamp"]; BOOL fresh=[date isKindOfClass:NSDate.class] && -date.timeIntervalSinceNow<20; c.detailTextLabel.text=fresh ? ([self.status[@"liveActive"] boolValue]?@"Live screen active":([self.status[@"nativeEnabledReported"] boolValue]?@"Native reports enabled":@"Loaded; AOD not reported")) : @"No recent status; respring"; }
    else if(p.section==2) { c.textLabel.text=@"Native visible AOD"; c.detailTextLabel.text=@"Device test required"; }
    else if(p.section==3) { c.textLabel.text=@[@"Respring",@"View / export diagnostics",@"Disable and clear overrides"][p.row]; c.accessoryType=1; }
    else { c.textLabel.text=@"LuminAOD"; c.detailTextLabel.text=LAVersion(); }
    return c;
}
- (void)toggle:(UISwitch *)s { self.prefs[@"Enabled"]=@(s.on); if(!LAWrite(self.prefs)) Alert(self,@"Save failed",nil); else Alert(self,@"Saved",@"Respring to refresh native AOD capabilities."); }
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)p {
    [t deselectRowAtIndexPath:p animated:YES];
    if(p.section==0 && p.row==1) { UIAlertController *a=[UIAlertController alertControllerWithTitle:@"Display mode" message:@"Native uses Apple's AOD pipeline. Live Lock Screen keeps the original lock screen awake at 3% brightness." preferredStyle:1]; for(NSInteger i=0;i<2;i++) [a addAction:[UIAlertAction actionWithTitle:i==0?@"Native pipeline (experimental)":@"Live Lock Screen" style:0 handler:^(UIAlertAction *x){ self.prefs[@"Mode"]=@(i); if(LAWrite(self.prefs)) { [self reload]; Alert(self,@"Mode saved",@"Respring before testing the new mode."); } else Alert(self,@"Save failed",nil); }]]; [a addAction:[UIAlertAction actionWithTitle:@"Cancel" style:1 handler:nil]]; [self presentViewController:a animated:YES completion:nil]; }
    else if(p.section==1) [self.navigationController pushViewController:[[LAFields alloc] initWithStyle:UITableViewStyleInsetGrouped] animated:YES];
    else if(p.section==3 && p.row==0) [self respring];
    else if(p.section==3 && p.row==1) { LAReport *r=[LAReport new]; NSString *text=[NSString stringWithFormat:@"LuminAOD %@\nDevice: %@\niOS: %@\nTarget supported: %@\nNative visible AOD: UNVERIFIED\n\n%@\n\nOverrides (keys only): %@\n",LAVersion(),LAModel(),UIDevice.currentDevice.systemVersion,LATarget()?@"yes":@"no",self.status,[self.prefs[@"Overrides"] allKeys] ?: @[]]; r.report=text; [self.navigationController pushViewController:r animated:YES]; }
    else if(p.section==3 && p.row==2) { NSDictionary *p=@{@"Enabled":@NO,@"Mode":@0,@"Overrides":@{}}; if(LAWrite(p)) { [self reload]; Alert(self,@"Disabled; overrides cleared",@"Respring to restore cached native capability answers. The on-disk MobileGestalt cache has never been changed."); } else Alert(self,@"Save failed",nil); }
}
- (void)respring {
    // SpringBoard and this unsandboxed jailbreak app both run as mobile. Only
    // signal the PID obtained from the kernel process table, never a shell.
    int mib[]={CTL_KERN,KERN_PROC,KERN_PROC_ALL,0}; size_t len=0;
    if(sysctl(mib,4,NULL,&len,NULL,0)!=0) { Alert(self,@"Cannot list processes",@(strerror(errno))); return; }
    struct kinfo_proc *list=malloc(len); if(!list) return;
    if(sysctl(mib,4,list,&len,NULL,0)!=0) { free(list); Alert(self,@"Cannot list processes",@(strerror(errno))); return; }
    pid_t pid=0; for(size_t i=0;i<len/sizeof(*list);i++) if(strcmp(list[i].kp_proc.p_comm,"SpringBoard")==0) {pid=list[i].kp_proc.p_pid;break;} free(list);
    if(pid<=1 || kill(pid,SIGTERM)!=0) Alert(self,@"Respring failed",@"Use Dopamine's Restart SpringBoard action.");
}
@end
@interface LADelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic,strong) UIWindow *window;
@end
@implementation LADelegate
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)opts { self.window=[[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds]; self.window.rootViewController=[[UINavigationController alloc] initWithRootViewController:[[LAHome alloc] initWithStyle:UITableViewStyleInsetGrouped]]; [self.window makeKeyAndVisible]; return YES; }
@end
int main(int argc,char **argv) { @autoreleasepool { return UIApplicationMain(argc,argv,nil,NSStringFromClass(LADelegate.class)); } }
