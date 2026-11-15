#import "Shared.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>
#import <CoreMotion/CoreMotion.h>

// Exact selectors cross-checked against iOS 16.0 runtime headers. Never patch
// display-mode integers, raw device-tree properties, or persisted MG caches.
typedef void (*LAHookMessage)(Class,SEL,IMP,IMP *);
typedef void (*LAHookFunction)(void *,void *,void **);
static LAHookMessage HookMessage;
static NSDictionary *prefs;
static NSMutableArray *events;
static NSMutableSet *installed;
static BOOL inSpringBoard;
static BOOL Native(void) { @synchronized(installed) { return LAEnabled(prefs) && LAMode(prefs)==0; } }
static BOOL Live(void) { @synchronized(installed) { return LAEnabled(prefs) && LAMode(prefs)==1; } }
static void Note(NSString *s) { @synchronized(events) { [events addObject:[NSString stringWithFormat:@"%@: %@",NSDate.date,s]]; if(events.count>60) [events removeObjectAtIndex:0]; } }
static id Send(id o, NSString *s) { SEL sel=NSSelectorFromString(s); return [o respondsToSelector:sel] ? ((id(*)(id,SEL))objc_msgSend)(o,sel) : nil; }
static BOOL Bool(id o,NSString *s) { SEL sel=NSSelectorFromString(s); return [o respondsToSelector:sel] && ((BOOL(*)(id,SEL))objc_msgSend)(o,sel); }
static id Backlight(void) { return Send(NSClassFromString(@"SBBacklightController"),@"sharedInstance"); }
static id Lock(void) { return Send(NSClassFromString(@"SBLockScreenManager"),@"sharedInstance"); }
static BOOL Locked(void) { return Bool(Lock(),@"isUILocked"); }

static id Override(CFStringRef key) {
    if(!key) return nil;
    @synchronized(installed) {
        if(!LAEnabled(prefs)) return nil;
        NSString *k=(__bridge NSString *)key;
        // This is the iOS 16-era key. The iOS 18 Display/Vibrancy keys are
        // deliberately not presented as iOS 16 capability fixes.
        if(Native() && ([k isEqual:@"DeviceSupportsAlwaysOnTime"] || [k isEqual:@"j8/Omm6s1lsmTDFsXjsBfA"])) return @YES;
        return prefs[@"Overrides"][k];
    }
}
static CFTypeRef (*origCopy)(CFStringRef);
static Boolean (*origBool)(CFStringRef);
static CFTypeRef Copy(CFStringRef key) { id v=Override(key); return v ? CFBridgingRetain(v) : origCopy(key); }
static Boolean GetBool(CFStringRef key) { id v=Override(key); return v && [v isKindOfClass:NSNumber.class] ? [v boolValue] : origBool(key); }

static BOOL (*origSupport)(id,SEL);
static BOOL Support(id o,SEL s) { return Native() ? YES : origSupport(o,s); }
static BOOL (*origForce)(id,SEL);
static BOOL Force(id o,SEL s) { return Native() ? YES : origForce(o,s); }
static BOOL (*origEnable)(id,SEL);
static BOOL Enable(id o,SEL s) { return Native() ? YES : origEnable(o,s); }
static BOOL (*origOSSupport)(id,SEL);
static BOOL OSSupport(id o,SEL s) { return Native() ? YES : origOSSupport(o,s); }
static void (*origCBResult)(id,SEL,NSInteger,id);
static void CBResult(id o,SEL s,NSInteger mode,id error) { Note([NSString stringWithFormat:@"CoreBrightness display mode %ld completion: %@",(long)mode,error ?: @"no reported error"]); origCBResult(o,s,mode,error); }
static void (*origFlipResult)(id,SEL,NSInteger,id);
static void FlipResult(id o,SEL s,NSInteger state,id error) { Note([NSString stringWithFormat:@"Flipbook state %ld completion: %@",(long)state,error ?: @"no reported error"]); origFlipResult(o,s,state,error); }

static BOOL Install(NSString *name,NSString *selector,BOOL meta,IMP imp,IMP *orig,const char *ret,unsigned count) {
    NSString *key=[NSString stringWithFormat:@"%@ %@ %@",meta?@"+":@"-",name,selector];
    @synchronized(installed) { if([installed containsObject:key]) return YES; }
    Class c=NSClassFromString(name); if(meta) c=object_getClass(c);
    Method m=c ? class_getInstanceMethod(c,NSSelectorFromString(selector)) : NULL;
    if(!m) return NO;
    char result[64]; method_getReturnType(m,result,sizeof(result));
    if(strcmp(result,ret) || method_getNumberOfArguments(m)!=count) { Note([@"ABI mismatch: " stringByAppendingString:key]); return NO; }
    HookMessage(c,NSSelectorFromString(selector),imp,orig);
    @synchronized(installed) { [installed addObject:key]; }
    Note([@"Installed " stringByAppendingString:key]); return YES;
}
static void InstallNative(void) {
    if(!HookMessage) return;
    Install(@"SBBacklightPlatformProvider",@"deviceSupportsAlwaysOn",YES,(IMP)Support,(IMP *)&origSupport,@encode(BOOL),2);
    Install(@"SBAlwaysOnDefaults",@"forceAndromedaSupport",NO,(IMP)Force,(IMP *)&origForce,@encode(BOOL),2);
    Install(@"SBAlwaysOnDefaults",@"enableAlwaysOn",NO,(IMP)Enable,(IMP *)&origEnable,@encode(BOOL),2);
    Install(@"BLSHBacklightOSInterfaceProvider",@"deviceSupportsAlwaysOn",NO,(IMP)OSSupport,(IMP *)&origOSSupport,@encode(BOOL),2);
    Install(@"BLSHBacklightOSInterfaceProvider",@"didCompleteTransitionToDisplayMode:withError:",NO,(IMP)CBResult,(IMP *)&origCBResult,@encode(void),4);
    Install(@"BLSHBacklightOSInterfaceProvider",@"didCompleteSwitchToFlipbookState:withError:",NO,(IMP)FlipResult,(IMP *)&origFlipResult,@encode(void),4);
}

// Fallback uses the real live Cover Sheet, never a screenshot or custom clock.
// It cannot reproduce Andromeda hardware/1 Hz/AP-sleep behavior. Native mode
// never invokes this controller or prevents idle sleep.
@interface LALiveController : NSObject <UIGestureRecognizerDelegate>
@property BOOL active, heldOff, waking, savedProximity;
@property float previousBrightness;
@property NSTimer *timer;
@property CMMotionManager *motion;
@property BOOL faceDown;
@property (weak) UIView *cover;
@property (weak) UITapGestureRecognizer *tap;
@property (weak) id idle;
- (void)tick;
- (void)stop;
@end
static LALiveController *live;
@implementation LALiveController
- (BOOL)allowed {
    return Live() && Locked() && !NSProcessInfo.processInfo.lowPowerModeEnabled && NSProcessInfo.processInfo.thermalState<NSProcessInfoThermalStateSerious && !UIDevice.currentDevice.proximityState && !self.faceDown;
}
- (void)idleHold:(BOOL)hold {
    SEL s=NSSelectorFromString(hold?@"addIdleTimerDisabledAssertionReason:":@"removeIdleTimerDisabledAssertionReason:");
    if([self.idle respondsToSelector:s]) ((void(*)(id,SEL,id))objc_msgSend)(self.idle,s,@"com.soum91.luminaod.live");
}
- (void)stop {
    if(!self.active) return;
    self.active=NO; [self idleHold:NO];
    UIScreen.mainScreen.brightness=self.previousBrightness;
    if(self.tap) [self.cover removeGestureRecognizer:self.tap];
    self.tap=nil; self.cover=nil;
    id b=Backlight(); SEL s=NSSelectorFromString(@"allowIdleSleep"); if([b respondsToSelector:s]) ((void(*)(id,SEL))objc_msgSend)(b,s);
    Note(@"Live lock screen ended; brightness and idle assertion restored");
}
- (void)wake:(UITapGestureRecognizer *)tap { [self stop]; self.heldOff=YES; }
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldReceiveTouch:(UITouch *)touch { [self stop]; self.heldOff=YES; return NO; }
- (void)begin {
    if(self.active || ![self allowed]) return;
    id cover=Send(Lock(),@"coverSheetViewController");
    UIView *view=[cover isKindOfClass:UIViewController.class] ? ((UIViewController *)cover).viewIfLoaded : nil;
    if(!view.window || !self.idle || !Bool(cover,@"isMainPageVisible")) { Note(@"Live mode deferred: Cover Sheet or idle controller unavailable"); return; }
    self.active=YES; self.cover=view; self.previousBrightness=UIScreen.mainScreen.brightness;
    [self idleHold:YES];
    SEL s=NSSelectorFromString(@"preventIdleSleep"); id b=Backlight(); if([b respondsToSelector:s]) ((void(*)(id,SEL))objc_msgSend)(b,s);
    float brightness=[prefs[@"Brightness"] floatValue]; if(brightness<=0) brightness=.03;
    UIScreen.mainScreen.brightness=fminf(.15f,fmaxf(.01f,brightness));
    UITapGestureRecognizer *tap=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(wake:)]; tap.cancelsTouchesInView=NO; tap.delegate=self; [view addGestureRecognizer:tap]; self.tap=tap;
    Note(@"Live lock screen active (not native low-power AOD)");
}
- (void)tick {
    if(![self allowed]) { [self stop]; return; }
    // Never keep camera, passcode, Wallet, Control Center, or an app awake.
    id cs=Send(Lock(),@"coverSheetViewController");
    for(NSString *selector in @[@"isPasscodeLockVisible",@"isInlinePasscodeLockVisible",@"_isPresentingModalRemoteContent",@"_isPresentingDismissableRemoteContent"]) if(Bool(cs,selector)) { [self stop]; self.heldOff=YES; return; }
    if(!Bool(cs,@"isMainPageVisible")) { [self stop]; self.heldOff=YES; return; }
}
@end
static id (*origIdleInit)(id,SEL,id);
static id IdleInit(id o,SEL s,id cover) { id result=origIdleInit(o,s,cover); live.idle=result; return result; }
static void (*origDismiss)(id,SEL,id);
static void WillPasscode(id o,SEL s,id cs) { [live stop]; live.heldOff=YES; origDismiss(o,s,cs); }
static void Status(void) {
    if(!inSpringBoard) return;
    id b=Send(NSClassFromString(@"BLSBacklight"),@"sharedBacklight");
    NSMutableDictionary *status=[@{@"installedVersion":LAVersion(),@"target":LAModel(),@"os":UIDevice.currentDevice.systemVersion,@"enabled":@(LAEnabled(prefs)),@"mode":@(LAMode(prefs)),@"nativeEnabledReported":@(Bool(b,@"isAlwaysOnEnabled")),@"liveActive":@(live.active),@"locked":@(Locked()),@"hardwareAODVerified":@NO,@"timestamp":NSDate.date} mutableCopy];
    if([b respondsToSelector:NSSelectorFromString(@"backlightState")]) status[@"backlightState"]=@(((NSInteger(*)(id,SEL))objc_msgSend)(b,NSSelectorFromString(@"backlightState")));
    if([b respondsToSelector:NSSelectorFromString(@"flipbookState")]) status[@"flipbookState"]=@(((NSInteger(*)(id,SEL))objc_msgSend)(b,NSSelectorFromString(@"flipbookState")));
    @synchronized(installed) { status[@"hooks"]=installed.allObjects; }
    @synchronized(events) { status[@"events"]=[events copy]; }
    [NSFileManager.defaultManager createDirectoryAtPath:LA_STATUS.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:nil];
    [status writeToFile:LA_STATUS atomically:YES];
}
__attribute__((constructor)) static void Start(void) { @autoreleasepool {
    if(!LATarget()) return;
    prefs=LARead(); events=[NSMutableArray array]; installed=[NSMutableSet set];
    inSpringBoard=[NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.springboard"];
    // Dopamine/ElleKit exposes the substrate compatibility functions.
    void *handle=dlopen("/var/jb/usr/lib/libsubstrate.dylib",RTLD_NOW);
    if(!handle) handle=dlopen("/var/jb/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate",RTLD_NOW);
    if(!handle) handle=dlopen("/var/jb/usr/lib/libellekit.dylib",RTLD_NOW);
    HookMessage=(LAHookMessage)dlsym(handle?:RTLD_DEFAULT,"MSHookMessageEx");
    LAHookFunction hookFunction=(LAHookFunction)dlsym(handle?:RTLD_DEFAULT,"MSHookFunction");
    if(!HookMessage || !hookFunction) Note(@"Hook engine unavailable: install/repair ElleKit and respring");
    void *mg=dlopen("/usr/lib/libMobileGestalt.dylib",RTLD_NOW);
    if(hookFunction && mg) {
        void *copy=dlsym(mg,"MGCopyAnswer"), *boolean=dlsym(mg,"MGGetBoolAnswer");
        if(copy) { hookFunction(copy,(void *)Copy,(void **)&origCopy); [installed addObject:@"MGCopyAnswer"]; }
        if(boolean) { hookFunction(boolean,(void *)GetBool,(void **)&origBool); [installed addObject:@"MGGetBoolAnswer"]; }
    }
    int token; notify_register_dispatch(LA_NOTIFY,&token,dispatch_get_main_queue(),^(int t){ @synchronized(installed) { prefs=LARead(); } [live stop]; live.heldOff=NO; Note(@"Preferences reloaded; respring required for cached native capabilities"); Status(); });
    if(!inSpringBoard) return;
    InstallNative();
    live=[LALiveController new];
    Install(@"SBDashBoardIdleTimerController",@"initWithCoverSheetViewController:",NO,(IMP)IdleInit,(IMP *)&origIdleInit,@encode(id),3);
    Install(@"SBLockScreenManager",@"coverSheetViewControllerWillPresentInlinePasscode:",NO,(IMP)WillPasscode,(IMP *)&origDismiss,@encode(void),3);
    dispatch_async(dispatch_get_main_queue(),^{
        live.savedProximity=UIDevice.currentDevice.proximityMonitoringEnabled;
        if(Live()) UIDevice.currentDevice.proximityMonitoringEnabled=YES;
        live.motion=[CMMotionManager new];
        
        int blankToken; notify_register_dispatch("com.apple.springboard.hasBlankedScreen",&blankToken,dispatch_get_main_queue(),^(int t){
            uint64_t blank=0; if(notify_get_state(t,&blank)!=NOTIFY_STATUS_OK) return;
            if(!Live()) return;
            if(blank) {
                if(live.active) { [live stop]; live.heldOff=YES; return; }
                if(live.heldOff || live.waking || ![live allowed]) return;
                live.waking=YES;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC/3),dispatch_get_main_queue(),^{
                    if([live allowed] && !live.heldOff) { id b=Backlight(); SEL s=NSSelectorFromString(@"turnOnScreenFullyWithBacklightSource:"); if([b respondsToSelector:s]) ((void(*)(id,SEL,NSInteger))objc_msgSend)(b,s,0); }
                    live.waking=NO;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC/2),dispatch_get_main_queue(),^{ if(!live.heldOff) [live begin]; });
                });
            } else if(!live.waking) { live.heldOff=NO; }
        });
        __block NSUInteger ticks=0;
        live.timer=[NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer *timer){
            InstallNative();
            if(!Locked()) { [live stop]; live.heldOff=NO; }
            if(UIDevice.currentDevice.proximityMonitoringEnabled != (Live() || live.savedProximity)) UIDevice.currentDevice.proximityMonitoringEnabled=Live() || live.savedProximity;
            if(Live() && live.motion.accelerometerAvailable && !live.motion.accelerometerActive) {
                live.motion.accelerometerUpdateInterval=1; [live.motion startAccelerometerUpdatesToQueue:NSOperationQueue.mainQueue withHandler:^(CMAccelerometerData *data,NSError *error){ if(data) live.faceDown=data.acceleration.z>.65; }];
            } else if(!Live() && live.motion.accelerometerActive) { [live.motion stopAccelerometerUpdates]; live.faceDown=NO; }
            [live tick]; if(++ticks%5==0) Status();
        }];
        Note(@"Loaded. Native pipeline is experimental on iPhone14,3; reported enabled is not proof of visible AOD"); Status();
    });
} }
