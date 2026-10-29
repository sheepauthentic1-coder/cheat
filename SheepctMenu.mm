// SheepctMenu.mm — Menu UIKit cho mod sheepct (iOS, Objective-C++ / ARC).
//
// Cach mo: sau khi .dylib duoc nap, mot nut tron "S" hien noi tren man hinh game.
//   - Keo nut de doi vi tri. Cham nhe vao nut de mo / dong bang menu.
//   - Trong bang menu, moi hang la mot tinh nang + cong tac UISwitch.
//   - Nut "Bat tat ca" / "Tat tat ca" o chan bang doi toan bo cong tac mot luc.
//   - Nut "X" o goc tren phai cua bang chi dong bang menu, nut tron van con.
//
// GIOI HAN QUAN TRONG: cac cong tac chi doi co (flag) trong ModEnvironment
// trong mod.cpp. Phan ap dung that — offset, hook, ghi bo nho game — KHONG co
// trong ban nay, nen bat cong tac cung chua lam tien/vang trong game thay doi.
// Menu nay chi la giao dien + co, de sau nay gan phan xu ly that vao.
//
// Build: file nay phai duoc build kem mod.cpp voi -fobjc-arc va cac framework
// UIKit, Foundation, QuartzCore, CoreGraphics (xem build_ios.sh / workflow).

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#include <cmath>

#include "SheepctFeatures.h"

// ---------------------------------------------------------------------------
// View trong suot, chi nhan cham o dung cho nut tron / bang menu, con lai
// cham se xuyen qua de game ben duoi van nhan duoc.
// ---------------------------------------------------------------------------
@interface SheepctPassthroughView : UIView
@end

@implementation SheepctPassthroughView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    return (hit == self) ? nil : hit;
}
@end

// ---------------------------------------------------------------------------
// View controller giu nut tron + bang menu.
// ---------------------------------------------------------------------------
@interface SheepctMenuController : UIViewController

@property (nonatomic, strong) UIButton *floatingButton;
@property (nonatomic, strong) UIView *panel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray<UISwitch *> *switches;
@property (nonatomic, assign) CGPoint panStartCenter;
@property (nonatomic, assign) CGFloat panMovedDistance;
@property (nonatomic, assign) BOOL panelVisible;

- (void)togglePanel;
- (void)refreshSwitches;
- (void)updateStatusLabel;

@end

@implementation SheepctMenuController

- (void)loadView {
    SheepctPassthroughView *root =
        [[SheepctPassthroughView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    root.backgroundColor = [UIColor clearColor];
    self.view = root;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.switches = [NSMutableArray array];
    self.panelVisible = NO;
    [self buildFloatingButton];
    [self buildPanel];
    [self refreshSwitches];
    [self updateStatusLabel];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutOverlay];
}

// --- Nut tron noi -----------------------------------------------------------

- (void)buildFloatingButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(self.view.bounds.size.width - 76.0, 120.0, 60.0, 60.0);
    button.layer.cornerRadius = 30.0;
    button.layer.masksToBounds = NO;
    button.backgroundColor = [UIColor colorWithRed:0.10 green:0.45 blue:0.95 alpha:0.95];
    button.layer.borderColor = [UIColor whiteColor].CGColor;
    button.layer.borderWidth = 2.0;
    button.layer.shadowColor = [UIColor blackColor].CGColor;
    button.layer.shadowOpacity = 0.35;
    button.layer.shadowRadius = 8.0;
    button.layer.shadowOffset = CGSizeMake(0, 3);
    [button setTitle:@"S" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:26.0];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.accessibilityLabel = @"Mo menu sheepct";

    UIPanGestureRecognizer *pan =
        [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(handleFloatingPan:)];
    [button addGestureRecognizer:pan];
    [self.view addSubview:button];
    self.floatingButton = button;
}

- (void)handleFloatingPan:(UIPanGestureRecognizer *)gesture {
    UIView *view = self.view;
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.panStartCenter = self.floatingButton.center;
        self.panMovedDistance = 0;
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [gesture translationInView:view];
        self.panMovedDistance += fabs(translation.x) + fabs(translation.y);
        CGPoint center = self.panStartCenter;
        center.x += translation.x;
        center.y += translation.y;
        // Giu nut trong man hinh, chừa le 30.
        CGFloat half = 30.0;
        center.x = fmax(half, fmin(view.bounds.size.width - half, center.x));
        center.y = fmax(half, fmin(view.bounds.size.height - half, center.y));
        self.floatingButton.center = center;
    } else if (gesture.state == UIGestureRecognizerStateEnded ||
               gesture.state == UIGestureRecognizerStateCancelled) {
        // Keo it hon 10 diem thi tinh la cham nhe -> mo/dong menu.
        if (self.panMovedDistance < 10.0) {
            [self togglePanel];
        }
    }
}

// --- Bang menu ---------------------------------------------------------------

- (void)buildPanel {
    UIView *panel = [[UIView alloc] initWithFrame:CGRectZero];
    panel.backgroundColor = [UIColor colorWithWhite:0.07 alpha:0.97];
    panel.layer.cornerRadius = 18.0;
    panel.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.18].CGColor;
    panel.layer.borderWidth = 1.0;
    panel.layer.shadowColor = [UIColor blackColor].CGColor;
    panel.layer.shadowOpacity = 0.45;
    panel.layer.shadowRadius = 16.0;
    panel.layer.shadowOffset = CGSizeMake(0, 6);
    panel.hidden = YES;
    [self.view addSubview:panel];
    self.panel = panel;

    // Tieu de.
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.text = @"sheepct";
    titleLabel.font = [UIFont boldSystemFontOfSize:20.0];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.tag = 1001;
    [panel addSubview:titleLabel];

    UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    subtitleLabel.text = @"Menu mod  •  Ban quyen: sheepct";
    subtitleLabel.font = [UIFont systemFontOfSize:12.0];
    subtitleLabel.textColor = [UIColor colorWithWhite:0.75 alpha:1.0];
    subtitleLabel.tag = 1002;
    [panel addSubview:subtitleLabel];

    UILabel *statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    statusLabel.text = @"Dang bat: 0/0";
    statusLabel.font = [UIFont boldSystemFontOfSize:12.0];
    statusLabel.textColor = [UIColor colorWithRed:0.35 green:0.85 blue:0.55 alpha:1.0];
    statusLabel.tag = 1003;
    [panel addSubview:statusLabel];
    self.statusLabel = statusLabel;

    // Nut dong bang (chi an bang, nut tron van con).
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [closeButton setTitle:@"✕" forState:UIControlStateNormal];
    closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
    [closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeButton.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.12];
    closeButton.layer.cornerRadius = 15.0;
    closeButton.tag = 1004;
    [closeButton addTarget:self
                    action:@selector(togglePanel)
          forControlEvents:UIControlEventTouchUpInside];
    closeButton.accessibilityLabel = @"Dong bang menu";
    [panel addSubview:closeButton];

    // Vung cuon chua cac hang tinh nang.
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    scrollView.showsVerticalScrollIndicator = YES;
    scrollView.alwaysBounceVertical = YES;
    [panel addSubview:scrollView];
    self.scrollView = scrollView;

    UIView *contentView = [[UIView alloc] initWithFrame:CGRectZero];
    contentView.tag = 1005;
    [scrollView addSubview:contentView];

    // Moi hang: ten + mo ta ben trai, cong tac ben phai.
    const CGFloat rowHeight = 58.0;
    std::size_t count = SheepctFeatureCount();
    for (std::size_t i = 0; i < count; i++) {
        SheepctFeatureInfo info = SheepctFeatureAt(i);
        UIView *row = [[UIView alloc] initWithFrame:CGRectMake(0, i * rowHeight,
                                                              10, rowHeight)];
        row.tag = 2000 + (NSInteger)i;
        if (i % 2 == 1) {
            row.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.04];
        }
        [contentView addSubview:row];

        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        nameLabel.text = [NSString stringWithUTF8String:info.title];
        nameLabel.font = [UIFont boldSystemFontOfSize:15.0];
        nameLabel.textColor = [UIColor whiteColor];
        nameLabel.tag = 2100;
        [row addSubview:nameLabel];

        UILabel *detailLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        detailLabel.text = [NSString stringWithUTF8String:info.detail];
        detailLabel.font = [UIFont systemFontOfSize:12.0];
        detailLabel.textColor = [UIColor colorWithWhite:0.70 alpha:1.0];
        detailLabel.tag = 2101;
        [row addSubview:detailLabel];

        UISwitch *toggle = [[UISwitch alloc] initWithFrame:CGRectZero];
        toggle.onTintColor = [UIColor colorWithRed:0.15 green:0.70 blue:0.40 alpha:1.0];
        toggle.tag = (NSInteger)i;
        toggle.on = SheepctFeatureEnabled(i);
        [toggle addTarget:self
                   action:@selector(featureSwitchChanged:)
         forControlEvents:UIControlEventValueChanged];
        toggle.accessibilityLabel = nameLabel.text;
        [row addSubview:toggle];
        [self.switches addObject:toggle];

        // Duong ke ngan cach.
        UIView *line = [[UIView alloc] initWithFrame:CGRectZero];
        line.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.08];
        line.tag = 2102;
        [row addSubview:line];
    }
    contentView.frame = CGRectMake(0, 0, 10, count * rowHeight);
    scrollView.contentSize = contentView.frame.size;

    // Chan bang: 2 nut bat/tat tat ca + ghi chu gioi han.
    UIButton *enableAllButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [enableAllButton setTitle:@"Bật tất cả" forState:UIControlStateNormal];
    enableAllButton.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
    [enableAllButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    enableAllButton.backgroundColor = [UIColor colorWithRed:0.15 green:0.60 blue:0.35 alpha:1.0];
    enableAllButton.layer.cornerRadius = 10.0;
    enableAllButton.tag = 1006;
    [enableAllButton addTarget:self
                        action:@selector(enableAllTapped)
              forControlEvents:UIControlEventTouchUpInside];
    [panel addSubview:enableAllButton];

    UIButton *disableAllButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [disableAllButton setTitle:@"Tắt tất cả" forState:UIControlStateNormal];
    disableAllButton.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
    [disableAllButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    disableAllButton.backgroundColor = [UIColor colorWithRed:0.70 green:0.25 blue:0.25 alpha:1.0];
    disableAllButton.layer.cornerRadius = 10.0;
    disableAllButton.tag = 1007;
    [disableAllButton addTarget:self
                         action:@selector(disableAllTapped)
               forControlEvents:UIControlEventTouchUpInside];
    [panel addSubview:disableAllButton];

    UILabel *noteLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    noteLabel.text = @"Công tắc chỉ đổi cờ trong mod. Phần ghi bộ nhớ game chưa có trong bản này.";
    noteLabel.font = [UIFont systemFontOfSize:11.0];
    noteLabel.textColor = [UIColor colorWithWhite:0.60 alpha:1.0];
    noteLabel.numberOfLines = 2;
    noteLabel.textAlignment = NSTextAlignmentCenter;
    noteLabel.tag = 1008;
    [panel addSubview:noteLabel];
}

- (void)layoutOverlay {
    CGRect bounds = self.view.bounds;
    CGFloat margin = 16.0;

    // Nut tron: giu trong man hinh neu xoay may / doi kich thuoc.
    if (self.floatingButton) {
        CGRect frame = self.floatingButton.frame;
        frame.origin.x = fmax(8.0, fmin(bounds.size.width - frame.size.width - 8.0,
                                       frame.origin.x));
        frame.origin.y = fmax(8.0, fmin(bounds.size.height - frame.size.height - 8.0,
                                       frame.origin.y));
        self.floatingButton.frame = frame;
    }

    // Bang menu: rong toi da 360, cao toi da man hinh tru 120, can giua.
    CGFloat panelWidth = fmin(bounds.size.width - 2 * margin, 360.0);
    CGFloat panelHeight = fmin(bounds.size.height - 120.0, 560.0);
    self.panel.frame = CGRectMake((bounds.size.width - panelWidth) / 2.0,
                                  (bounds.size.height - panelHeight) / 2.0,
                                  panelWidth, panelHeight);

    CGRect panelBounds = self.panel.bounds;
    const CGFloat headerHeight = 58.0;
    const CGFloat footerHeight = 86.0;

    UIView *titleLabel = [self.panel viewWithTag:1001];
    titleLabel.frame = CGRectMake(16, 12, panelWidth - 70, 24);
    UIView *subtitleLabel = [self.panel viewWithTag:1002];
    subtitleLabel.frame = CGRectMake(16, 36, panelWidth - 70, 16);
    // statusLabel nam gon trong header, ben phai tieu de.
    self.statusLabel.frame = CGRectMake(panelWidth - 150, 14, 100, 18);
    self.statusLabel.textAlignment = NSTextAlignmentRight;
    UIView *closeButton = [self.panel viewWithTag:1004];
    closeButton.frame = CGRectMake(panelWidth - 44, 12, 30, 30);

    self.scrollView.frame = CGRectMake(0, headerHeight, panelWidth,
                                       panelHeight - headerHeight - footerHeight);
    UIView *contentView = [self.scrollView viewWithTag:1005];
    const CGFloat rowHeight = 58.0;
    contentView.frame = CGRectMake(0, 0, panelWidth,
                                   SheepctFeatureCount() * rowHeight);
    self.scrollView.contentSize = contentView.frame.size;

    for (std::size_t i = 0; i < SheepctFeatureCount(); i++) {
        UIView *row = [contentView viewWithTag:2000 + (NSInteger)i];
        if (!row) continue;
        row.frame = CGRectMake(0, i * rowHeight, panelWidth, rowHeight);
        UIView *nameLabel = [row viewWithTag:2100];
        nameLabel.frame = CGRectMake(16, 8, panelWidth - 80, 20);
        UIView *detailLabel = [row viewWithTag:2101];
        detailLabel.frame = CGRectMake(16, 30, panelWidth - 80, 16);
        UISwitch *toggle = (UISwitch *)[row viewWithTag:(NSInteger)i];
        // UISwitch duoc tim bang tag cua chinh no trong row; neu khong thay,
        // lay tu mang switches da luu.
        if (![toggle isKindOfClass:[UISwitch class]]) {
            toggle = self.switches[(NSUInteger)i];
        }
        CGSize switchSize = toggle.intrinsicContentSize;
        toggle.frame = CGRectMake(panelWidth - 16 - switchSize.width,
                                  (rowHeight - switchSize.height) / 2.0,
                                  switchSize.width, switchSize.height);
        UIView *line = [row viewWithTag:2102];
        line.frame = CGRectMake(16, rowHeight - 1, panelWidth - 32, 1);
    }

    UIView *enableAllButton = [self.panel viewWithTag:1006];
    enableAllButton.frame = CGRectMake(16, panelHeight - footerHeight + 8,
                                       (panelWidth - 48) / 2.0, 38);
    UIView *disableAllButton = [self.panel viewWithTag:1007];
    disableAllButton.frame = CGRectMake(32 + (panelWidth - 48) / 2.0,
                                        panelHeight - footerHeight + 8,
                                        (panelWidth - 48) / 2.0, 38);
    UIView *noteLabel = [self.panel viewWithTag:1008];
    noteLabel.frame = CGRectMake(16, panelHeight - footerHeight + 52,
                                 panelWidth - 32, 30);
    (void)panelBounds;
}

// --- Xu ly cong tac ----------------------------------------------------------

- (void)featureSwitchChanged:(UISwitch *)sender {
    std::size_t index = (std::size_t)sender.tag;
    SheepctSetFeatureEnabled(index, sender.isOn);
    [self updateStatusLabel];
}

- (void)enableAllTapped {
    [self setAllFeaturesEnabled:YES];
}

- (void)disableAllTapped {
    [self setAllFeaturesEnabled:NO];
}

- (void)setAllFeaturesEnabled:(BOOL)enabled {
    for (NSUInteger i = 0; i < self.switches.count; i++) {
        UISwitch *toggle = self.switches[i];
        [toggle setOn:enabled animated:YES];
        SheepctSetFeatureEnabled((std::size_t)i, enabled);
    }
    [self updateStatusLabel];
}

- (void)refreshSwitches {
    for (NSUInteger i = 0; i < self.switches.count; i++) {
        self.switches[i].on = SheepctFeatureEnabled((std::size_t)i);
    }
}

- (void)updateStatusLabel {
    std::size_t count = SheepctFeatureCount();
    std::size_t enabled = 0;
    for (std::size_t i = 0; i < count; i++) {
        if (SheepctFeatureEnabled(i)) enabled++;
    }
    self.statusLabel.text = [NSString stringWithFormat:@"Đang bật: %zu/%zu",
                             enabled, count];
}

- (void)togglePanel {
    self.panelVisible = !self.panelVisible;
    self.panel.hidden = !self.panelVisible;
    if (self.panelVisible) {
        [self refreshSwitches];
        [self updateStatusLabel];
        [self.view bringSubviewToFront:self.panel];
    } else {
        [self.view bringSubviewToFront:self.floatingButton];
    }
}

@end

// ---------------------------------------------------------------------------
// Hien menu: thu lai neu game chua co cua so (toi da 60 lan, moi lan 0.5s).
// ---------------------------------------------------------------------------
static UIWindow *gSheepctWindow = nil;
static SheepctMenuController *gSheepctMenuController = nil;

static void SheepctTryShowMenu(int attempt) {
    if (attempt > 60) {
        NSLog(@"[sheepct] Khong tim thay cua so game de hien menu.");
        return;
    }
    UIApplication *app = [UIApplication sharedApplication];
    BOOL hasWindow = (app.keyWindow != nil) || (app.windows.count > 0);
    if (!hasWindow) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
                           SheepctTryShowMenu(attempt + 1);
                       });
        return;
    }

    if (gSheepctWindow != nil) {
        gSheepctWindow.hidden = NO;
        return;
    }

    UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in app.connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                window.windowScene = (UIWindowScene *)scene;
                break;
            }
        }
    }
    window.windowLevel = UIWindowLevelAlert + 100;
    window.backgroundColor = [UIColor clearColor];
    SheepctMenuController *controller = [[SheepctMenuController alloc] init];
    window.rootViewController = controller;
    window.hidden = NO;
    gSheepctWindow = window;
    gSheepctMenuController = controller;
    NSLog(@"[sheepct] Da hien nut menu noi.");
}

void SheepctShowMenu() {
    dispatch_async(dispatch_get_main_queue(), ^{
        SheepctTryShowMenu(0);
    });
}
