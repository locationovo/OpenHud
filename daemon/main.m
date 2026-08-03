// daemon/main.m
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/sysctl.h>
#include <libproc.h>
#include <notify.h>
#include <CoreFoundation/CoreFoundation.h>

#define PREFS_PATH  "/var/jb/var/mobile/Library/Preferences/com.locationovo.openhud.plist"
#define FILTER_PATH "/var/jb/Library/MobileSubstrate/DynamicLibraries/OpenHud.plist"

static void write_filter(CFArrayRef bundleIDs) {
    CFMutableDictionaryRef filter = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFMutableDictionaryRef filterInner = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(filterInner, CFSTR("Bundles"), bundleIDs ?: CFArrayCreate(NULL, NULL, 0, NULL));
    CFDictionarySetValue(filter, CFSTR("Filter"), filterInner);
    CFURLRef url = CFURLCreateWithFileSystemPath(NULL, CFSTR(FILTER_PATH), kCFURLPOSIXPathStyle, false);
    CFWriteStreamRef stream = CFWriteStreamCreateWithFile(NULL, url);
    CFWriteStreamOpen(stream);
    CFPropertyListWrite(filter, stream, kCFPropertyListXMLFormat_v1_0, 0, NULL);
    CFWriteStreamClose(stream);
    CFRelease(stream); CFRelease(url); CFRelease(filterInner); CFRelease(filter);
}

static CFArrayRef read_prefs(void) {
    CFURLRef url = CFURLCreateWithFileSystemPath(NULL, CFSTR(PREFS_PATH), kCFURLPOSIXPathStyle, false);
    CFReadStreamRef stream = CFReadStreamCreateWithFile(NULL, url);
    if (!stream) { CFRelease(url); return NULL; }
    CFReadStreamOpen(stream);
    CFPropertyListRef plist = CFPropertyListCreateWithStream(NULL, stream, 0, kCFPropertyListImmutable, NULL, NULL);
    CFReadStreamClose(stream);
    CFRelease(stream); CFRelease(url);
    if (!plist) return NULL;
    CFArrayRef arr = CFDictionaryGetValue(plist, CFSTR("enabledBundleIDs"));
    if (arr) CFRetain(arr);
    CFRelease(plist);
    return arr;
}

static CFArrayRef running_bundle_ids(void) {
    CFMutableArrayRef result = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
    int mib[] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    size_t len = 0;
    sysctl(mib, 4, NULL, &len, NULL, 0);
    struct kinfo_proc *procs = malloc(len);
    sysctl(mib, 4, procs, &len, NULL, 0);
    int count = (int)(len / sizeof(struct kinfo_proc));
    for (int i = 0; i < count; i++) {
        pid_t pid = procs[i].kp_proc.p_pid;
        if (pid <= 0) continue;
        char path[PROC_PIDPATHINFO_MAXSIZE];
        if (proc_pidpath(pid, path, sizeof(path)) <= 0) continue;
        if (strstr(path, "/var/containers/Bundle/Application/") == NULL) continue;
        char *app = strstr(path, ".app/");
        if (!app) continue;
        *app = '\0';
        char infoPath[PROC_PIDPATHINFO_MAXSIZE];
        snprintf(infoPath, sizeof(infoPath), "%s.app/Info.plist", path);
        CFURLRef u = CFURLCreateWithFileSystemPath(NULL, CFSTR(infoPath), kCFURLPOSIXPathStyle, false);
        CFReadStreamRef s = CFReadStreamCreateWithFile(NULL, u);
        CFRelease(u);
        if (!s) continue;
        CFReadStreamOpen(s);
        CFPropertyListRef pl = CFPropertyListCreateWithStream(NULL, s, 0, kCFPropertyListImmutable, NULL, NULL);
        CFReadStreamClose(s); CFRelease(s);
        if (!pl) continue;
        CFStringRef bid = CFDictionaryGetValue(pl, CFSTR("CFBundleIdentifier"));
        if (bid) CFArrayAppendValue(result, bid);
        CFRelease(pl);
    }
    free(procs);
    return result;
}

static void check_running_and_alert(CFArrayRef enabled) {
    if (!enabled || CFArrayGetCount(enabled) == 0) return;
    CFArrayRef running = running_bundle_ids();
    CFMutableArrayRef needRestart = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
    for (CFIndex i = 0; i < CFArrayGetCount(enabled); i++) {
        CFStringRef bid = CFArrayGetValueAtIndex(enabled, i);
        for (CFIndex j = 0; j < CFArrayGetCount(running); j++) {
            if (CFEqual(bid, CFArrayGetValueAtIndex(running, j))) {
                CFArrayAppendValue(needRestart, bid);
                break;
            }
        }
    }
    if (CFArrayGetCount(needRestart) > 0) {
        CFStringRef msg = CFStringCreateWithFormat(NULL, NULL, CFSTR("请重启以下应用以启用Metal HUD：\n%@"), needRestart);
        CFUserNotificationDisplayNotice(0, kCFUserNotificationStopAlertLevel, NULL, NULL, NULL,
            CFSTR("OpenHud"), msg, CFSTR("确定"));
        CFRelease(msg);
    }
    CFRelease(needRestart);
    CFRelease(running);
}

static void update_filter(void) {
    CFArrayRef prefs = read_prefs();
    write_filter(prefs);
    if (prefs) check_running_and_alert(prefs);
    if (prefs) CFRelease(prefs);
}

int main(void) {
    update_filter();
    int token;
    notify_register_dispatch("com.locationovo.openhud/update", &token,
        dispatch_get_main_queue(), ^(int t) { update_filter(); });
    dispatch_main();
    return 0;
}
