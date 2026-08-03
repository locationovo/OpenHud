// prefs/RootListController.m
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <AppList/AppList.h>
#import <notify.h>

static NSString *const kPrefsFile = @"/var/jb/var/mobile/Library/Preferences/com.yourepo.openhud.plist";
static NSString *const kKey = @"enabledBundleIDs";

@interface RootListController : PSListController
@property (nonatomic, strong) NSMutableArray *enabledIDs;
@property (nonatomic, strong) NSArray *allApps;
@end

@implementation RootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [NSMutableArray array];
        [self loadApps];
        [self buildSpecifiers];
    }
    return _specifiers;
}

- (void)loadApps {
    ALApplicationList *list = [ALApplicationList sharedApplicationList];
    self.allApps = [[list applicationsFilteredUsingPredicate:
        [NSPredicate predicateWithBlock:^BOOL(NSString *bid, NSDictionary *b) {
            return [b[@"ApplicationType"] isEqualToString:@"User"];
        }]] allKeys];
    self.allApps = [self.allApps sortedArrayUsingSelector:@selector(compare:)];
    self.enabledIDs = [NSMutableArray arrayWithArray:
        [[NSDictionary dictionaryWithContentsOfFile:kPrefsFile] objectForKey:kKey] ?: @[]];
}

- (void)buildSpecifiers {
    [_specifiers removeAllObjects];
    for (NSString *bid in self.allApps) {
        PSSpecifier *s = [PSSpecifier preferenceSpecifierNamed:[self nameForBundleID:bid]
            target:self set:@selector(setPreference:specifier:) get:@selector(readPreference:)
            detail:Nil cell:PSSwitchCell edit:Nil];
        [s setProperty:bid forKey:@"bid"];
        [_specifiers addObject:s];
    }
    PSSpecifier *add = [PSSpecifier preferenceSpecifierNamed:@"添加自定义应用..."
        target:self set:Nil get:Nil detail:Nil cell:PSButtonCell edit:Nil];
    add->action = @selector(addCustomApp);
    [_specifiers addObject:add];
}

- (NSString *)nameForBundleID:(NSString *)bid {
    ALApplicationList *list = [ALApplicationList sharedApplicationList];
    return [list valueForKey:@"displayName" forDisplayIdentifier:bid] ?: bid;
}

- (id)readPreference:(PSSpecifier *)specifier {
    return @([self.enabledIDs containsObject:[specifier propertyForKey:@"bid"]]);
}

- (void)setPreference:(id)value specifier:(PSSpecifier *)specifier {
    NSString *bid = [specifier propertyForKey:@"bid"];
    if ([value boolValue]) {
        if (![self.enabledIDs containsObject:bid]) [self.enabledIDs addObject:bid];
    } else {
        [self.enabledIDs removeObject:bid];
    }
    [self saveAndNotify];
}

- (void)addCustomApp {
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"添加自定义应用"
        message:@"输入 Bundle ID" preferredStyle:UIAlertControllerStyleAlert];
    [ac addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.placeholder = @"com.example.app";
    }];
    [ac addAction:[UIAlertAction actionWithTitle:@"添加" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSString *bid = ac.textFields.firstObject.text;
        if (bid.length > 0) {
            if (![self.enabledIDs containsObject:bid]) [self.enabledIDs addObject:bid];
            [self saveAndNotify];
            [self reloadSpecifiers];
        }
    }]];
    [ac addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:ac animated:YES completion:nil];
}

- (void)saveAndNotify {
    NSDictionary *dict = @{kKey: self.enabledIDs};
    [dict writeToFile:kPrefsFile atomically:YES];
    notify_post("com.yourepo.openhud/update");
}

@end
