//
//  TabBar.m
//  Cordova Plugin
//
//  Created by Lifetime.com.eg Technical Team (Amr Hossam / Emad ElShafie) on 6 January 2016.
//  Copyright (c) 2016 Lifetime.com.eg. All rights reserved.
//

#import <objc/runtime.h>
#import "TabBar.h"
#import <UIKit/UINavigationBar.h>
#import <QuartzCore/QuartzCore.h>

@implementation TabBar
#ifndef __IPHONE_3_0
@synthesize webView;
#endif

- (void) pluginInitialize {
    
    UIWebView *uiwebview = nil;
    if ([self.webView isKindOfClass:[UIWebView class]]) {
        uiwebview = ((UIWebView*)self.webView);
    }
    tabBarItems = [[NSMutableDictionary alloc] initWithCapacity:5];
    
    // -----------------------------------------------------------------------
    // This code block is the same for both the navigation and tab bar plugin!
    // -----------------------------------------------------------------------
    
    // The original web view frame must be retrieved here. On iPhone, it would be 0,0,320,460 for example. Since
    // Cordova seems to initialize plugins on the first call, there is a plugin method init() that has to be called
    // in order to make Cordova call *this* method. If someone forgets the init() call and uses the navigation bar
    // and tab bar plugins together, these values won't be the original web view frame and layout will be wrong.
    originalWebViewFrame = uiwebview.frame;
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(orientationChanged:)
     name:UIDeviceOrientationDidChangeNotification
     object:[UIDevice currentDevice]];
    
    navBarHeight = 44.0f;
    tabBarHeight = 48.0f;
    tabBarAtBottom = true;
    
}

- (void) orientationChanged:(NSNotification *)note
{
    UIDevice * device = note.object;
    switch(device.orientation)
    {
        case UIDeviceOrientationPortrait:
            NSLog(@"NavBar Orientation Changed to portrait");
            [self correctWebViewFrame];
            break;
            
        case UIDeviceOrientationPortraitUpsideDown:
            NSLog(@"NavBar Orientation Changed to upsidedown");
            [self correctWebViewFrame];
            break;
            
        default:
            NSLog(@"NavBar Orientation Changed to landscape");
            float statusBarHeight = 20.0f;
            [self correctWebViewFrame];
            break;
    };
    
}

-(void)correctWebViewFrame
{
    if(!tabBar)
    return;
    
    const bool tabBarShown = !tabBar.hidden;
    bool navBarShown = false;
    
    UIView *parent = [tabBar superview];
    for(UIView *view in parent.subviews)
    if([view isMemberOfClass:[UINavigationBar class]])
    {
        navBarShown = !view.hidden;
        break;
    }
    
    // -----------------------------------------------------------------------------
    // IMPORTANT: Below code is the same in both the navigation and tab bar plugins!
    // -----------------------------------------------------------------------------
    
    
    
    currentDeviceOrientation = [[UIDevice currentDevice] orientation];
    
    BOOL isLandscape = [UIApplication sharedApplication].statusBarOrientation == (UIInterfaceOrientationLandscapeLeft | UIInterfaceOrientationLandscapeRight);
    BOOL isPortrait = [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait;
    
    CGFloat left, right, top, bottom;
    
    left = [UIScreen mainScreen].bounds.origin.x;
    right = left + [UIScreen mainScreen].bounds.size.width;
    
    if (@available(iOS 11.0, *)) {
        top = [UIScreen mainScreen].bounds.origin.y;
        if (isPortrait) bottom = top + [UIScreen mainScreen].bounds.size.height;
        else bottom = top + [UIScreen mainScreen].bounds.size.height;
    } else {
        top = [UIScreen mainScreen].bounds.origin.y + 20.0f;
        bottom = top + [UIScreen mainScreen].bounds.size.height - 20.0f;
    }
    
    if (isLandscape) NSLog(@"TabBar Current Orientation: Landscape");
    if (isPortrait) NSLog(@"TabBar Current Orientation: Portrait");
    
    if(navBarShown)
    top += navBarHeight;
    
    if(tabBarShown)
    {
        if(tabBarAtBottom) {
            if (isPortrait)
                bottom -= ( tabBarHeight + [[self webView] superview].safeAreaInsets.bottom - 10.0f);
            else
                bottom -= ( tabBarHeight + [[self webView] superview].safeAreaInsets.bottom - 25.0f);
        }
        else
        top += tabBarHeight;
    }
    
    CGRect webViewFrame;
    
    if (@available(iOS 11.0, *)) {
        webViewFrame = CGRectMake(left, top, right - left, bottom - top);
    } else {
        webViewFrame = CGRectMake(left, top, right - left, bottom - top);
    }
    
    // set the webview's parent background to dark blue
    self.webView.superview.backgroundColor = [UIColor colorWithRed:29.0/255.0 green:42.0/255.0 blue:59.0/255.0 alpha:1.0];
    [self.webView setFrame:webViewFrame];
    
    // -----------------------------------------------------------------------------
    CGFloat iphonexfix = 0.0f;
    // NOTE: Following part again for tab bar plugin only
    if (@available(iOS 11.0, *)) {
        if ([[self webView] superview].safeAreaInsets.bottom > 0) {
            if (isPortrait)
                iphonexfix = 25.0f;
            else
                iphonexfix = 10.0f;
        }
        else
            iphonexfix = 0.0f;
    }
    
    
    if(tabBarShown)
    {
        if(tabBarAtBottom)
        [tabBar setFrame:CGRectMake(left, [UIScreen mainScreen].bounds.origin.y + [UIScreen mainScreen].bounds.size.height - tabBarHeight - iphonexfix, right - left, tabBarHeight + iphonexfix )];
        
        else
        [tabBar setFrame:CGRectMake(left, [UIScreen mainScreen].bounds.origin.y, right - left, tabBarHeight)];
        
        NSLog(@"Screen height: %f", webViewFrame.size.height);
    }
}

- (UIColor*)colorStringToColor:(NSString*)colorStr
{
    NSArray *rgba = [colorStr componentsSeparatedByString:@","];
    return [UIColor colorWithRed:[[rgba objectAtIndex:0] intValue]/255.0f
                           green:[[rgba objectAtIndex:1] intValue]/255.0f
                            blue:[[rgba objectAtIndex:2] intValue]/255.0f
                           alpha:[[rgba objectAtIndex:3] intValue]/255.0f];
}

/**
 * Create a native tab bar at either the top or the bottom of the display.
 */
- (void)create:(CDVInvokedUrlCommand*)command
{
    if (tabBar) return;
    NSLog(@"Create TabBar");
    tabBar = [UITabBar new];
    [tabBar sizeToFit];
    tabBar.delegate = self;
    tabBar.multipleTouchEnabled   = NO;
    tabBar.autoresizesSubviews    = YES;
    tabBar.hidden                 = YES;
    tabBar.userInteractionEnabled = YES;
    tabBar.opaque = YES;
    tabBar.barStyle = UIBarStyleDefault;
    
    //[tabBar setBarTintColor:[UIColor colorWithRed:218.0/255.0 green:33.0/255.0 blue:39.0/255.0 alpha:1.0]];
    [tabBar setTintColor:[UIColor colorWithRed:218.0/255.0 green:33.0/255.0 blue:39.0/255.0 alpha:1.0]];
        
    [tabBar setBackgroundColor:[UIColor colorWithRed:20.0/255.0 green:70.0/255.0 blue:130.0/255.0 alpha:1.0]];
    
    //[tabBar setSelectedImageTintColor:[UIColor redColor]];
    [tabBar setSelectedImageTintColor:[UIColor colorWithRed:80.0/255.0 green:150.0/255.0 blue:255.0/255.0 alpha:1.0]];
    
    self.webView.superview.autoresizesSubviews = YES;
    
    [self.webView.superview addSubview:tabBar];
}

-(void) init:(CDVInvokedUrlCommand*)command
{
    // Dummy function, see initWithWebView
}

/**
 * Show the tab bar after its been created.
 * @brief show the tab bar
 * @param arguments unused
 * @param options used to indicate options for where and how the tab bar should be placed
 * - \c height integer indicating the height of the tab bar (default: \c 49)
 * - \c position specifies whether the tab bar will be placed at the \c top or \c bottom of the screen (default: \c bottom)
 */
- (void)show:(CDVInvokedUrlCommand*)command
{
    if (!tabBar)
        [self create:nil];
    NSLog(@"Show TabBar");
    // if we are calling this again when its shown, reset
    if (!tabBar.hidden)
        return;
    NSLog(@"Show TabBar222");
    const id options = [command argumentAtIndex:0];
    
    if(options && options != [NSNull null])
    {
        id tabBarHeightOpt = [options objectForKey:@"height"];
        id positionOpt = [options objectForKey:@"position"];
        
        if(tabBarHeightOpt && tabBarHeightOpt != [NSNull null])
            tabBarHeight = [tabBarHeightOpt floatValue];
        
        if([positionOpt isKindOfClass:[NSString class]])
            tabBarAtBottom = ![positionOpt isEqualToString:@"top"];
    }
    NSLog(@"Show TabBar333");
    tabBar.tabBarAtBottom = tabBarAtBottom;
    
    if(tabBarHeight == 0)
        tabBarHeight = 49.0f;
    
    tabBar.hidden = NO;
    tabBar.alpha = 1;
    NSLog(@"Show TabBar444");
    [self correctWebViewFrame];
}

/**
 * Resize the tab bar (this should be called on orientation change)
 * @brief resize the tab bar on rotation
 * @param arguments unused
 * @param options unused
 */
- (void)resize:(CDVInvokedUrlCommand*)command
{
    [self correctWebViewFrame];
}

/**
 * Hide the tab bar
 * @brief hide the tab bar
 * @param arguments unused
 * @param options unused
 */
- (void)hide:(CDVInvokedUrlCommand*)command
{
    
    if (tabBar.hidden) return;
    NSLog(@"HIDE TABBAR");
    if (!tabBar)
        [self create:nil];
    
    [UIView animateWithDuration:0.5 animations:^() {
        tabBar.alpha = 0;
        tabBar.hidden = YES;
        
    } completion:^(BOOL finished) {
        
        [self correctWebViewFrame];
    }];
    
}

/**
 * Create a new tab bar item for use on a previously created tab bar.  Use ::showTabBarItems to show the new item on the tab bar.
 *
 * If the supplied image name is one of the labels listed below, then this method will construct a tab button
 * using the standard system buttons.  Note that if you use one of the system images, that the \c title you supply will be ignored.
 * - <b>Tab Buttons</b>
 *   - tabButton:More
 *   - tabButton:Favorites
 *   - tabButton:Featured
 *   - tabButton:TopRated
 *   - tabButton:Recents
 *   - tabButton:Contacts
 *   - tabButton:History
 *   - tabButton:Bookmarks
 *   - tabButton:Search
 *   - tabButton:Downloads
 *   - tabButton:MostRecent
 *   - tabButton:MostViewed
 * @brief create a tab bar item
 * @param arguments Parameters used to create the tab bar
 *  -# \c name internal name to refer to this tab by
 *  -# \c title title text to show on the tab, or null if no text should be shown
 *  -# \c image image filename or internal identifier to show, or null if now image should be shown
 *  -# \c tag unique number to be used as an internal reference to this button
 * @param options Options for customizing the individual tab item
 *  - \c badge value to display in the optional circular badge on the item; if nil or unspecified, the badge will be hidden
 */
- (void)createItem:(CDVInvokedUrlCommand*)command
{
    if (!tabBar)
        [self create:nil];
    
    const id options = [command argumentAtIndex:4];
    
    NSString  *name      = [command argumentAtIndex:0];
    NSString  *title     = [command argumentAtIndex:1];
    NSString  *imageName = [command argumentAtIndex:2];
    int tag              = [[command argumentAtIndex:3] intValue];
    
    UITabBarItem *item = nil;
    if ([imageName length] > 0)
    {
        UITabBarSystemItem systemItem = -1;
        if ([imageName isEqualToString:@"tabButton:More"])       systemItem = UITabBarSystemItemMore;
        else if ([imageName isEqualToString:@"tabButton:Favorites"])  systemItem = UITabBarSystemItemFavorites;
        else if ([imageName isEqualToString:@"tabButton:Featured"])   systemItem = UITabBarSystemItemFeatured;
        else if ([imageName isEqualToString:@"tabButton:TopRated"])   systemItem = UITabBarSystemItemTopRated;
        else if ([imageName isEqualToString:@"tabButton:Recents"])    systemItem = UITabBarSystemItemRecents;
        else if ([imageName isEqualToString:@"tabButton:Contacts"])   systemItem = UITabBarSystemItemContacts;
        else if ([imageName isEqualToString:@"tabButton:History"])    systemItem = UITabBarSystemItemHistory;
        else if ([imageName isEqualToString:@"tabButton:Bookmarks"])  systemItem = UITabBarSystemItemBookmarks;
        else if ([imageName isEqualToString:@"tabButton:Search"])     systemItem = UITabBarSystemItemSearch;
        else if ([imageName isEqualToString:@"tabButton:Downloads"])  systemItem = UITabBarSystemItemDownloads;
        else if ([imageName isEqualToString:@"tabButton:MostRecent"]) systemItem = UITabBarSystemItemMostRecent;
        else if ([imageName isEqualToString:@"tabButton:MostViewed"]) systemItem = UITabBarSystemItemMostViewed;
        if (systemItem != -1)
            item = [[UITabBarItem alloc] initWithTabBarSystemItem:systemItem tag:tag];
    }
    
    if (item == nil)
        item = [[UITabBarItem alloc] initWithTitle:title image:[UIImage imageNamed:imageName] tag:tag];
    
    if(options && options != [NSNull null])
    {
        id badgeOpt = [options objectForKey:@"badge"];
        
        if(badgeOpt && badgeOpt != [NSNull null])
            item.badgeValue = [badgeOpt stringValue];
    }
    
    [tabBarItems setObject:item forKey:name];
}


/**
 * Update an existing tab bar item to change its badge value.
 * @brief update the badge value on an existing tab bar item
 * @param arguments Parameters used to identify the tab bar item to update
 *  -# \c name internal name used to represent this item when it was created
 * @param options Options for customizing the individual tab item
 *  - \c badge value to display in the optional circular badge on the item; if nil or unspecified, the badge will be hidden
 */
- (void)updateItem:(CDVInvokedUrlCommand*)command
{
    if (!tabBar)
        [self create:nil];
    
    const NSDictionary *options = [command argumentAtIndex:1];
    
    if(!options)
    {
        NSLog(@"Missing options parameter in tabBar.updateItem");
        return;
    }
    
    NSString  *name = [command argumentAtIndex:0];
    UITabBarItem *item = [tabBarItems objectForKey:name];
    if(item)
    {
        id badgeOpt = [options objectForKey:@"badge"];
        
        if(badgeOpt && badgeOpt != [NSNull null])
            item.badgeValue = [NSString stringWithFormat:@"%@", badgeOpt];
        else
            item.badgeValue = nil;
    }
}

/**
 *
 */
- (void)removeItem:(CDVInvokedUrlCommand*)command
{
    if (!tabBar)
        [self create:nil];
  
    NSString *name      = [command argumentAtIndex:0];

    [tabBarItems removeObjectForKey:name];
}

/**
 * Show previously created items on the tab bar
 * @brief show a list of tab bar items
 * @param arguments the item names to be shown
 * @param options dictionary of options, notable options including:
 *  - \c animate indicates that the items should animate onto the tab bar
 * @see createItem
 * @see create
 */
- (void)showItems:(CDVInvokedUrlCommand*)command
{
    NSLog(@"Show Items");
    if (!tabBar)
        [self create:nil];
    NSLog(@"Arguments: %@", [command argumentAtIndex:0]);
    int i, count = [[command argumentAtIndex:0] count];
    NSLog(@"arguments: %d", count);
    //NSDictionary *options = nil;
    
    NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:MAX(count - 1, 1)];
    
    for(i = 0; i < count; ++i)
    {
        
        NSString *itemName = [[command argumentAtIndex:0] objectAtIndex:i];
        UITabBarItem *item = [tabBarItems objectForKey:itemName];
        if(item)
            [items addObject:item];
        else
            NSLog(@"Cannot show tab with unknown tag '%@'", itemName);
    }
    
    //BOOL animateItems = YES;
    //if(options && [options objectForKey:@"animate"])
    //animateItems = [(NSString*)[options objectForKey:@"animate"] boolValue];
    [tabBar setItems:items animated:NO];
}

/**
 * Manually select an individual tab bar item, or nil for deselecting a currently selected tab bar item.
 * @brief manually select a tab bar item
 * @param arguments the name of the tab bar item to select
 * @see createItem
 * @see showItems
 */
- (void)selectItem:(CDVInvokedUrlCommand*)command
{
    if (!tabBar)
        [self create:nil];
    
    NSString *itemName = [command argumentAtIndex:0];
    UITabBarItem *item = [tabBarItems objectForKey:itemName];
    if(item)
    {
        // Not called automatically when selectItem is called manually
        [self tabBar:tabBar didSelectItem:item];
        
        tabBar.selectedItem = item;
    }
    else
        tabBar.selectedItem = nil;
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    NSString * jsCallBack = [NSString stringWithFormat:@"tabbar.onItemSelected(%d);", item.tag];
    NSLog(@"Item Selected with tab: %ld", (long)item.tag);
    
    UIWebView *uiwebview = nil;
    if ([self.webView isKindOfClass:[UIWebView class]]) {
        uiwebview = ((UIWebView*)self.webView);
    }
    //[uiwebview stringByEvaluatingJavaScriptFromString:jsCallBack];
    
    [self.commandDelegate evalJs:jsCallBack];
    
}

@end


@implementation UIView (NavBarCompat)

- (void)setTabBarAtBottom:(bool)tabBarAtBottom
{
    objc_setAssociatedObject(self, @"NavBarCompat_tabBarAtBottom", [NSNumber numberWithBool:tabBarAtBottom], OBJC_ASSOCIATION_COPY);
}

- (bool)tabBarAtBottom
{
    return [(objc_getAssociatedObject(self, @"NavBarCompat_tabBarAtBottom")) boolValue];
}

@end

