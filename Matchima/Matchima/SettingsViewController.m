//
//  SettingsViewController.m
//  Matchima
//
//  Created by Mukhtar Yusuf on 8/29/17.
//  Copyright © 2017 Mukhtar Yusuf. All rights reserved.
//

#import "SettingsViewController.h"
#import "DefaultsKeysAndValues.h"
#import "NotificationNames.h"

@interface SettingsViewController()
@property (strong, nonatomic) NSUserDefaults *userDefaults;
@property (strong, nonatomic) NSDictionary *settings;
@property (strong, nonatomic) NSDictionary *menuColor;

@property (weak, nonatomic) IBOutlet UISwitch *woodThemeSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *darkThemeSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *classicThemeSwitch;

@end

@implementation SettingsViewController
- (IBAction)dismissViewController:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)selectWoodTheme:(id)sender {//If switch is already selected, keep it selected and do nothing
    UISwitch *touchedSwitch = (UISwitch *)sender;
    
    if(!touchedSwitch.isOn){
        NSLog(@"In wood settings is on");
        touchedSwitch.on = YES;
    }else{
        self.darkThemeSwitch.on = NO;
        self.classicThemeSwitch.on = NO;
        
        [self.userDefaults setObject:@YES forKey:WOOD_THEME];
        [self.userDefaults setObject:@NO forKey:DARK_THEME];
        [self.userDefaults setObject:@NO forKey:CLASSIC_THEME];
        [self.userDefaults synchronize];
        [self updateSettings];
        [self.userDefaults synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SETTINGS_CHANGED_NOTIFICATION object:self];
    }
}
- (IBAction)selectDarkTheme:(id)sender {
    UISwitch *touchedSwitch = (UISwitch *)sender;
    
    if(!touchedSwitch.isOn){
        touchedSwitch.on = YES;
    }else{
        self.woodThemeSwitch.on = NO;
        self.classicThemeSwitch.on = NO;
        
        [self.userDefaults setObject:@NO forKey:WOOD_THEME];
        [self.userDefaults setObject:@YES forKey:DARK_THEME];
        [self.userDefaults setObject:@NO forKey:CLASSIC_THEME];
        [self.userDefaults synchronize];
        [self updateSettings];
        [self.userDefaults synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SETTINGS_CHANGED_NOTIFICATION object:self];
    }

}
- (IBAction)selectClassicTheme:(id)sender {
    UISwitch *touchedSwitch = (UISwitch *)sender;
    
    if(!touchedSwitch.isOn){
        touchedSwitch.on = YES;
    }else{
        self.woodThemeSwitch.on = NO;
        self.darkThemeSwitch.on = NO;
        
        [self.userDefaults setObject:@NO forKey:WOOD_THEME];
        [self.userDefaults setObject:@NO forKey:DARK_THEME];
        [self.userDefaults setObject:@YES forKey:CLASSIC_THEME];
        [self.userDefaults synchronize];
        [self updateSettings];
        [self.userDefaults synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SETTINGS_CHANGED_NOTIFICATION object:self];
    }
}

//--Helper Methods--
#pragma mark Helper Methods
- (void)setUpSwitches{
    self.woodThemeSwitch.on = [[self.userDefaults objectForKey:WOOD_THEME] boolValue];
    self.darkThemeSwitch.on = [[self.userDefaults objectForKey:DARK_THEME] boolValue];
    self.classicThemeSwitch.on = [[self.userDefaults objectForKey:CLASSIC_THEME] boolValue];
}

- (void)updateSettings{
    if([[self.userDefaults objectForKey:WOOD_THEME] boolValue]){
        self.settings = @{
                      HAS_BACKGROUND_IMAGE : @YES,
                      BACKGROUND_IMAGE : WOOD_BACKGROUND,
                      CARDBACK_IMAGE : CARDBACK,
                      MENU_COLOR : self.menuColor
                      };
    }else if([[self.userDefaults objectForKey:DARK_THEME] boolValue]){
        self.settings = @{
                      HAS_BACKGROUND_IMAGE : @YES,
                      BACKGROUND_IMAGE : DARK_BACKGROUND,
                      CARDBACK_IMAGE : CARDBACK_DARK,
                      MENU_COLOR : self.menuColor
                      };
    }
    else if([[self.userDefaults objectForKey:CLASSIC_THEME] boolValue]){
        self.settings = @{
                      HAS_BACKGROUND_IMAGE : @NO,
                      BACKGROUND_IMAGE : NO_BACKGROUND,
                      CARDBACK_IMAGE : CARDBACK,
                      MENU_COLOR : self.menuColor
                      };
    }
    [self.userDefaults setObject:self.settings forKey:SETTINGS];
}

//--Getters and Setters--
#pragma mark Getters and Setters
- (NSUserDefaults *)userDefaults{
    if(!_userDefaults)
        _userDefaults = [NSUserDefaults standardUserDefaults];
    
    return _userDefaults;
}

- (NSDictionary *)settings{
    if(!_settings)
        _settings = [self.userDefaults objectForKey:SETTINGS];
    
    return _settings;
}

#warning Consider adding number values to header file
- (NSDictionary *)menuColor{
    _menuColor = @{
                   RED : @118,
                   GREEN : @67,
                   BLUE : @0,
                   ALPHA : @0.35
                   };
    
    return _menuColor;
}

//--View Controller Lifecycle
#pragma mark View Controller Lifecycle

- (void)viewDidLoad{
    [super viewDidLoad];
    
    [self setUpSwitches];
}

@end
