// SheepctMenu.mm — Menu UIKit cho mod sheepct (iOS, Objective-C++ / ARC), ban 2.
//
// Cach mo: sau khi .dylib duoc nap, mot nut tron "S" hien noi tren man hinh game.
//   - Keo nut de doi vi tri, tha ra nut tu dinh vao mep gan nhat. Cham nhe vao
//     nut de mo / dong bang menu (co hieu ung muot, khong bat/tat dot ngot).
//   - Trong bang menu: phan "So luong muon add" o tren cung, roi moi hang tinh
//     nang + cong tac UISwitch, roi nut "Bat tat ca" / "Tat tat ca" o chan bang.
//   - Nut "X" o goc tren phai cua bang chi dong bang menu, nut tron van con.
//
// Sua cho muot / het treo o man hinh game (vi du popup xac thuc cua game):
//   - Cua so menu KHONG tro thanh key window, cua so goc cua game van giu key,
//     nen ban phim / o nhap cua game khong bi cuop.
//   - View nen trong suot va xuyen cham: chi nut tron va bang menu nhan cham,
//     cham o cho khac xuyen xuong game ben duoi.
//   - Mo/dong bang bang animation spring, nut tron co hieu ung nhan nho khi cham.
//
// GIOI HAN QUAN TRONG: cac cong tac va so luong chi doi co / gia tri trong mod
// (ModEnvironment trong mod.cpp). Phan ap dung that — offset, hook, ghi bo nho
// game — KHONG co trong ban nay, nen bat cong tac cung chua lam tien/vang
// trong game thay doi. Menu nay chi la giao dien + co + so luong.
//
// Build: file nay phai duoc build kem mod.cpp voi -fobjc-arc va cac framework
// UIKit, Foundation, QuartzCore, CoreGraphics (xem build_ios.sh / workflow).

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#include <cmath>

#include "SheepctFeatures.h"

static const CGFloat kQuantitySectionHeight = 176.0;
static const CGFloat kRowHeight = 58.0;

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
@interface SheepctMenuController : UIViewController <UITextFieldDelegate>

@property (nonatomic, strong) UIButton *floatingButton;
@property (nonatomic, strong) UIView *panel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray<UISwitch *> *switches;
@property (nonatomic, strong) UILabel *amountLabel;
@property (nonatomic, strong) UISlider *amountSlider;
@property (nonatomic, strong) UIStepper *amountStepper;
@property (nonatomic, strong) UITextField *amountField;
@property (nonatomic, assign) CGPoint panStartCenter;
@property (nonatomic, assign) CGFloat panMovedDistance;
@property (nonatomic, assign) BOOL panelVisible;
@property (nonatomic, assign) BOOL panelAnimating;
@property (nonatomic, assign) BOOL syncingAmountControls;

- (void)togglePanel;
- (void)refreshSwitches;
- (void)updateStatusLabel;
- (void)applyAddAmount:(long long)amount updateField:(BOOL)updateField;
- (NSString *)formattedAmount:(long long)amount;

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
    self.panelAnimating = NO;
    self.syncingAmountControls = NO;
    [self buildFloatingButton];
    [self buildPanel];
    [self refreshSwitches];
    [self updateStatusLabel];
    [self applyAddAmount:SheepctAddAmount() updateField:YES];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutOverlay];
}

// --- Nut tron noi -----------------------------------------------------------

- (void)buildFloatingButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    // Vi tri mac dinh: mep phai, khoang 1/3 tu tren xuong, tranh nut dong
    // cua cac popup o goc tren phai cua game.
    CGFloat startY = fmax(180.0, self.view.bounds.size.height * 0.32);
    button.frame = CGRectMake(self.view.bounds.size.width - 76.0, startY, 60.0, 60.0);
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
        // Nhan nho nhe khi bat dau keo, de biet nut da nhan cham.
        [UIView animateWithDuration:0.12 animations:^{
            self.floatingButton.transform = CGAffineTransformMakeScale(0.92, 0.92);
        }];
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [gesture translationInView:view];
        self.panMovedDistance += fabs(translation.x) + fabs(translation.y);
        CGPoint center = self.panStartCenter;
        center.x += translation.x;
        center.y += translation.y;
        CGFloat half = 30.0;
        center.x = fmax(half, fmin(view.bounds.size.width - half, center.x));
        center.y = fmax(half, fmin(view.bounds.size.height - half, center.y));
        self.floatingButton.center = center;
    } else if (gesture.state == UIGestureRecognizerStateEnded ||
               gesture.state == UIGestureRecognizerStateCancelled) {
        [UIView animateWithDuration:0.18 animations:^{
            self.floatingButton.transform = CGAffineTransformIdentity;
        }];
        if (self.panMovedDistance < 10.0) {
            // Cham nhe -> mo/dong menu.
            [self togglePanel];
        } else {
            // Keo xong -> dinh nut vao mep gan nhat, muot bang spring.
            CGFloat half = 30.0;
            CGFloat targetX = (self.floatingButton.center.x < view.bounds.size.width / 2.0)
                                  ? half
                                  : view.bounds.size.width - half;
            CGPoint target = CGPointMake(targetX, self.floatingButton.center.y);
            [UIView animateWithDuration:0.30
                                  delay:0
                 usingSpringWithDamping:0.75
                  initialSpringVelocity:0.4
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 self.floatingButton.center = target;
                             }
                             completion:nil];
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
    panel.alpha = 0;
    [self.view addSubview:panel];
    self.panel = panel;

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

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    scrollView.showsVerticalScrollIndicator = YES;
    scrollView.alwaysBounceVertical = YES;
    scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    [panel addSubview:scrollView];
    self.scrollView = scrollView;

    UIView *contentView = [[UIView alloc] initWithFrame:CGRectZero];
    contentView.tag = 1005;
    [scrollView addSubview:contentView];

    [self buildQuantitySectionInView:contentView];

    const CGFloat rowHeight = kRowHeight;
    std::size_t count = SheepctFeatureCount();
    for (std::size_t i = 0; i < count; i++) {
        SheepctFeatureInfo info = SheepctFeatureAt(i);
        UIView *row = [[UIView alloc] initWithFrame:CGRectMake(0, kQuantitySectionHeight + i * rowHeight,
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

        UIView *line = [[UIView alloc] initWithFrame:CGRectZero];
        line.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.08];
        line.tag = 2102;
        [row addSubview:line];
    }
    contentView.frame = CGRectMake(0, 0, 10,
                                   kQuantitySectionHeight + count * rowHeight);
    scrollView.contentSize = contentView.frame.size;

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
    noteLabel.text = @"Công tắc và số lượng chỉ đổi cờ/giá trị trong mod. Phần ghi bộ nhớ game chưa có trong bản này.";
    noteLabel.font = [UIFont systemFontOfSize:11.0];
    noteLabel.textColor = [UIColor colorWithWhite:0.60 alpha:1.0];
    noteLabel.numberOfLines = 2;
    noteLabel.textAlignment = NSTextAlignmentCenter;
    noteLabel.tag = 1008;
    [panel addSubview:noteLabel];
}

// --- Phan so luong muon add: thanh keo + o nhap + nut mau -------------------

- (void)buildQuantitySectionInView:(UIView *)contentView {
    UIView *section = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, kQuantitySectionHeight)];
    section.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.05];
    section.tag = 3000;
    [contentView addSubview:section];

    UILabel *sectionTitle = [[UILabel alloc] initWithFrame:CGRectZero];
    sectionTitle.text = @"SỐ LƯỢNG MUỐN ADD";
    sectionTitle.font = [UIFont boldSystemFontOfSize:12.0];
    sectionTitle.textColor = [UIColor colorWithRed:0.45 green:0.75 blue:1.0 alpha:1.0];
    sectionTitle.tag = 3001;
    [section addSubview:sectionTitle];

    UILabel *amountLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    amountLabel.text = @"1,000";
    amountLabel.font = [UIFont boldSystemFontOfSize:24.0];
    amountLabel.textColor = [UIColor whiteColor];
    amountLabel.textAlignment = NSTextAlignmentRight;
    amountLabel.tag = 3002;
    [section addSubview:amountLabel];
    self.amountLabel = amountLabel;

    UILabel *amountHint = [[UILabel alloc] initWithFrame:CGRectZero];
    amountHint.text = @"Áp dụng chung cho các mục Add: tiền, vàng, cỏ, vé, xu, điểm.";
    amountHint.font = [UIFont systemFontOfSize:11.0];
    amountHint.textColor = [UIColor colorWithWhite:0.65 alpha:1.0];
    amountHint.tag = 3003;
    [section addSubview:amountHint];

    // Thanh keo: 1 .. 100.000. Muon so lon hon thi dung o nhap hoac nut mau.
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectZero];
    slider.minimumValue = 1;
    slider.maximumValue = 100000;
    slider.value = 1000;
    slider.minimumTrackTintColor = [UIColor colorWithRed:0.10 green:0.45 blue:0.95 alpha:1.0];
    slider.tag = 3004;
    [slider addTarget:self
               action:@selector(amountSliderChanged:)
     forControlEvents:UIControlEventValueChanged];
    [section addSubview:slider];
    self.amountSlider = slider;

    // Stepper - / + , moi lan nhan doi 100.
    UIStepper *stepper = [[UIStepper alloc] initWithFrame:CGRectZero];
    stepper.minimumValue = 1;
    stepper.maximumValue = 1000000;
    stepper.stepValue = 100;
    stepper.value = 1000;
    stepper.tag = 3005;
    [stepper addTarget:self
                action:@selector(amountStepperChanged:)
      forControlEvents:UIControlEventValueChanged];
    [section addSubview:stepper];
    self.amountStepper = stepper;

    // O nhap so chinh xac, ban phim so.
    UITextField *field = [[UITextField alloc] initWithFrame:CGRectZero];
    field.text = @"1000";
    field.font = [UIFont systemFontOfSize:15.0];
    field.textColor = [UIColor whiteColor];
    field.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.10];
    field.layer.cornerRadius = 8.0;
    field.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.18].CGColor;
    field.layer.borderWidth = 1.0;
    field.keyboardType = UIKeyboardTypeNumberPad;
    field.textAlignment = NSTextAlignmentCenter;
    field.placeholder = @"Nhập số lượng";
    field.delegate = self;
    field.tag = 3006;
    [field addTarget:self
              action:@selector(amountFieldChanged:)
    forControlEvents:UIControlEventEditingChanged];
    [field addTarget:self
              action:@selector(amountFieldFinished:)
    forControlEvents:UIControlEventEditingDidEnd];
    [section addSubview:field];
    self.amountField = field;

    // Nut mau: 100 / 1K / 10K / 100K / 1M.
    const long long presets[5] = {100, 1000, 10000, 100000, 1000000};
    const char *presetTitles[5] = {"100", "1K", "10K", "100K", "1M"};
    for (int i = 0; i < 5; i++) {
        UIButton *preset = [UIButton buttonWithType:UIButtonTypeSystem];
        [preset setTitle:[NSString stringWithUTF8String:presetTitles[i]]
                forState:UIControlStateNormal];
        preset.titleLabel.font = [UIFont boldSystemFontOfSize:13.0];
        [preset setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        preset.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.12];
        preset.layer.cornerRadius = 8.0;
        preset.tag = 3010 + i;
        // Luu so luong vao accessibilityValue de ham xu ly doc lai.
        preset.accessibilityValue = [NSString stringWithFormat:@"%lld", presets[i]];
        [preset addTarget:self
                   action:@selector(amountPresetTapped:)
         forControlEvents:UIControlEventTouchUpInside];
        [section addSubview:preset];
    }

    UIView *line = [[UIView alloc] initWithFrame:CGRectZero];
    line.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.10];
    line.tag = 3007;
    [section addSubview:line];
}

- (NSString *)formattedAmount:(long long)amount {
    static NSNumberFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
        formatter.groupingSeparator = @",";
        formatter.groupingSize = 3;
    });
    return [formatter stringFromNumber:@(amount)];
}

- (void)applyAddAmount:(long long)amount updateField:(BOOL)updateField {
    if (self.syncingAmountControls) return;
    self.syncingAmountControls = YES;
    SheepctSetAddAmount(amount);
    long long stored = SheepctAddAmount();
    self.amountLabel.text = [self formattedAmount:stored];
    self.amountSlider.value = (float)fmin((double)stored, 100000.0);
    self.amountStepper.value = fmin((double)stored, 1000000.0);
    if (updateField && ![self.amountField isFirstResponder]) {
        self.amountField.text = [NSString stringWithFormat:@"%lld", stored];
    } else if (updateField) {
        self.amountField.text = [NSString stringWithFormat:@"%lld", stored];
    }
    self.syncingAmountControls = NO;
}

- (void)amountSliderChanged:(UISlider *)sender {
    [self.amountField resignFirstResponder];
    // Lam tron theo buoc 10 cho keo muot, khong nhay so le lien tuc.
    long long amount = (long long)llround(sender.value / 10.0) * 10;
    if (amount < 1) amount = 1;
    [self applyAddAmount:amount updateField:YES];
}

- (void)amountStepperChanged:(UIStepper *)sender {
    [self applyAddAmount:(long long)llround(sender.value) updateField:YES];
}

- (void)amountFieldChanged:(UITextField *)sender {
    NSString *digits = [[sender.text componentsSeparatedByCharactersInSet:
                         [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                        componentsJoinedByString:@""];
    if (digits.length == 0) return;
    long long amount = (long long)[digits longLongValue];
    if (amount < 1) return;
    // Chi cap nhat gia tri + nhan, khong ghi de lai o nhap khi dang go.
    SheepctSetAddAmount(amount);
    self.amountLabel.text = [self formattedAmount:SheepctAddAmount()];
    self.amountSlider.value = (float)fmin((double)amount, 100000.0);
    self.amountStepper.value = fmin((double)amount, 1000000.0);
}

- (void)amountFieldFinished:(UITextField *)sender {
    [self amountFieldChanged:sender];
    [self applyAddAmount:SheepctAddAmount() updateField:YES];
    [sender resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)amountPresetTapped:(UIButton *)sender {
    long long amount = (long long)[sender.accessibilityValue longLongValue];
    if (amount < 1) amount = 1;
    [self applyAddAmount:amount updateField:YES];
    // Phim an muot khi chon nut mau.
    [UIView animateWithDuration:0.10
                     animations:^{
                         sender.transform = CGAffineTransformMakeScale(0.92, 0.92);
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.12 animations:^{
                             sender.transform = CGAffineTransformIdentity;
                         }];
                     }];
}

// --- Bo cuc ------------------------------------------------------------------

- (void)layoutOverlay {
    CGRect bounds = self.view.bounds;
    CGFloat margin = 16.0;

    if (self.floatingButton) {
        CGRect frame = self.floatingButton.frame;
        frame.origin.x = fmax(8.0, fmin(bounds.size.width - frame.size.width - 8.0,
                                       frame.origin.x));
        frame.origin.y = fmax(8.0, fmin(bounds.size.height - frame.size.height - 8.0,
                                       frame.origin.y));
        if (!CGRectEqualToRect(frame, self.floatingButton.frame)) {
            self.floatingButton.frame = frame;
        }
    }

    CGFloat panelWidth = fmin(bounds.size.width - 2 * margin, 360.0);
    CGFloat panelHeight = fmin(bounds.size.height - 120.0, 580.0);
    CGRect panelFrame = CGRectMake((bounds.size.width - panelWidth) / 2.0,
                                   (bounds.size.height - panelHeight) / 2.0,
                                   panelWidth, panelHeight);
    if (!CGRectEqualToRect(panelFrame, self.panel.frame)) {
        self.panel.frame = panelFrame;
    }

    const CGFloat headerHeight = 58.0;
    const CGFloat footerHeight = 86.0;

    UIView *titleLabel = [self.panel viewWithTag:1001];
    titleLabel.frame = CGRectMake(16, 12, panelWidth - 70, 24);
    UIView *subtitleLabel = [self.panel viewWithTag:1002];
    subtitleLabel.frame = CGRectMake(16, 36, panelWidth - 70, 16);
    self.statusLabel.frame = CGRectMake(panelWidth - 150, 14, 100, 18);
    self.statusLabel.textAlignment = NSTextAlignmentRight;
    UIView *closeButton = [self.panel viewWithTag:1004];
    closeButton.frame = CGRectMake(panelWidth - 44, 12, 30, 30);

    self.scrollView.frame = CGRectMake(0, headerHeight, panelWidth,
                                       panelHeight - headerHeight - footerHeight);
    UIView *contentView = [self.scrollView viewWithTag:1005];
    const CGFloat rowHeight = kRowHeight;
    contentView.frame = CGRectMake(0, 0, panelWidth,
                                   kQuantitySectionHeight + SheepctFeatureCount() * rowHeight);
    self.scrollView.contentSize = contentView.frame.size;

    // Phan so luong.
    UIView *section = [contentView viewWithTag:3000];
    section.frame = CGRectMake(0, 0, panelWidth, kQuantitySectionHeight);
    UIView *sectionTitle = [section viewWithTag:3001];
    sectionTitle.frame = CGRectMake(16, 10, 180, 16);
    self.amountLabel.frame = CGRectMake(panelWidth - 166, 6, 150, 30);
    UIView *amountHint = [section viewWithTag:3003];
    amountHint.frame = CGRectMake(16, 30, panelWidth - 32, 14);
    self.amountSlider.frame = CGRectMake(16, 52, panelWidth - 32 - 62, 30);
    self.amountStepper.frame = CGRectMake(panelWidth - 16 - 94, 52, 94, 30);
    self.amountField.frame = CGRectMake(16, 90, panelWidth - 32, 36);
    for (int i = 0; i < 5; i++) {
        UIView *preset = [section viewWithTag:3010 + i];
        CGFloat presetWidth = (panelWidth - 32 - 4 * 8) / 5.0;
        preset.frame = CGRectMake(16 + i * (presetWidth + 8), 134, presetWidth, 30);
    }
    UIView *sectionLine = [section viewWithTag:3007];
    sectionLine.frame = CGRectMake(0, kQuantitySectionHeight - 1, panelWidth, 1);

    for (std::size_t i = 0; i < SheepctFeatureCount(); i++) {
        UIView *row = [contentView viewWithTag:2000 + (NSInteger)i];
        if (!row) continue;
        row.frame = CGRectMake(0, kQuantitySectionHeight + i * rowHeight, panelWidth, rowHeight);
        UIView *nameLabel = [row viewWithTag:2100];
        nameLabel.frame = CGRectMake(16, 8, panelWidth - 80, 20);
        UIView *detailLabel = [row viewWithTag:2101];
        detailLabel.frame = CGRectMake(16, 30, panelWidth - 80, 16);
        UISwitch *toggle = (UISwitch *)[row viewWithTag:(NSInteger)i];
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
    if (self.panelAnimating) return;
    self.panelAnimating = YES;
    BOOL willShow = !self.panelVisible;
    self.panelVisible = willShow;
    if (willShow) {
        [self refreshSwitches];
        [self updateStatusLabel];
        [self applyAddAmount:SheepctAddAmount() updateField:YES];
        [self.view bringSubviewToFront:self.panel];
        self.panel.hidden = NO;
        self.panel.alpha = 0;
        self.panel.transform = CGAffineTransformMakeScale(0.94, 0.94);
        [UIView animateWithDuration:0.28
                              delay:0
             usingSpringWithDamping:0.82
              initialSpringVelocity:0.5
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.panel.alpha = 1;
                             self.panel.transform = CGAffineTransformIdentity;
                         }
                         completion:^(BOOL finished) {
                             self.panelAnimating = NO;
                         }];
    } else {
        [UIView animateWithDuration:0.20
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.panel.alpha = 0;
                             self.panel.transform = CGAffineTransformMakeScale(0.96, 0.96);
                         }
                         completion:^(BOOL finished) {
                             self.panel.hidden = YES;
                             self.panel.transform = CGAffineTransformIdentity;
                             [self.view bringSubviewToFront:self.floatingButton];
                             self.panelAnimating = NO;
                         }];
    }
}

@end

// ---------------------------------------------------------------------------
// Hien menu: thu lai neu game chua co cua so (toi da 60 lan, moi lan 0.5s).
// Cua so menu khong tro thanh key window, de khong cuop ban phim / o nhap
// cua game (vi du popup xac thuc VTC) va khong lam game bi treo o man hinh do.
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

    UIWindow *previousKeyWindow = app.keyWindow;
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
    // Chi hien cua so, KHONG goi makeKeyAndVisible, de cua so game van la key.
    window.hidden = NO;
    if (previousKeyWindow != nil) {
        [previousKeyWindow makeKeyWindow];
    }
    gSheepctWindow = window;
    gSheepctMenuController = controller;
    NSLog(@"[sheepct] Da hien nut menu noi.");
}

void SheepctShowMenu() {
    dispatch_async(dispatch_get_main_queue(), ^{
        SheepctTryShowMenu(0);
    });
}
