#import "AppDelegate.h"
#import "MDController.h"

@interface AppDelegate ()
@property (strong) NSStatusItem *statusItem;
@property (strong) MDController *controller;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)note {
  self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
  self.controller = [[MDController alloc] init];
  [self refresh];

  NSMenu *menu = [[NSMenu alloc] init];
  [menu addItemWithTitle:@"Quit Container Tools for Mavericks"
                  action:@selector(terminate:) keyEquivalent:@"q"];
  [self.statusItem setMenu:menu];
}

- (void)refresh {
  NSString *state = [self.controller currentState];
  NSImage *icon = [self iconForState:state];
  icon.template = YES;
  [self.statusItem setImage:icon];
  [self.statusItem setToolTip:[@"Docker: " stringByAppendingString:state]];
}

// A simple template icon drawn in code (no asset files): filled disc = running,
// ring = stopped/other. Later tasks add working/attention variants.
- (NSImage *)iconForState:(NSString *)state {
  NSImage *img = [NSImage imageWithSize:NSMakeSize(18, 18) flipped:NO
      drawingHandler:^BOOL(NSRect r) {
    NSBezierPath *p = [NSBezierPath bezierPathWithOvalInRect:NSInsetRect(r, 3, 3)];
    [[NSColor blackColor] set];
    if ([state isEqualToString:@"running"]) { [p fill]; }
    else { p.lineWidth = 1.5; [p stroke]; }
    return YES;
  }];
  return img;
}

@end
