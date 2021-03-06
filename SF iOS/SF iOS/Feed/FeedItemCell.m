//
//  FeedItemCell.m
//  SF iOS
//
//  Created by Amit Jain on 7/31/17.
//  Copyright © 2017 Amit Jain. All rights reserved.
//

#import "FeedItemCell.h"
#import "UIStackView+ConvenienceInitializer.h"
#import "UIColor+SFiOSColors.h"

NS_ASSUME_NONNULL_BEGIN
@interface FeedItemCell ()

@property (nonatomic) UIStackView *containerStack;
@property (nonatomic) UIView *detailStackContainer;
@property (nonatomic) UILabel *timeLabel;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *subtitleLabel;
@property (nonatomic) UIStackView *itemImageStack;
@property (nonatomic) UIImageView *coverImageView;

@end
NS_ASSUME_NONNULL_END

@implementation FeedItemCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setup];
    }
    return self;
}

- (CGRect)contentFrame {
    UIView *superView = [self superview];
    if (!superView) {
        return CGRectZero;
    }
    
    return [superView convertRect:self.detailStackContainer.frame fromView:self.containerStack];
}

- (CGSize)coverImageSize {
    return self.itemImageStack.bounds.size;
}

//MARK: - Configuration

- (void)configureWithFeedItem:(FeedItem *)item {
    self.timeLabel.text = item.dateString;
    self.timeLabel.alpha =  item.isActive ? 1 : 0.2;
    
    self.titleLabel.text = item.title;
    self.subtitleLabel.attributedText = item.subtitle;
}

- (void)setCoverToImage:(UIImage *)image {
    self.coverImageView.image = image;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if (@available(iOS 11.0, *)) {
        // set using corner mask API
    } else {
      UIBezierPath *path = [UIBezierPath
          bezierPathWithRoundedRect:self.coverImageView.bounds
                  byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
                        cornerRadii:CGSizeMake(15, 15)];

      CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
      maskLayer.frame = self.coverImageView.bounds;
      maskLayer.path = path.CGPath;

      self.coverImageView.layer.mask = maskLayer;
    }
}

//MARK: - Setup

- (void)setup {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.contentView.backgroundColor = [UIColor whiteColor];
    
    [self setupContainerStack];
    
    self.timeLabel = [UILabel new];
    self.timeLabel.font = [UIFont systemFontOfSize:34 weight:UIFontWeightBold];
    self.titleLabel.textColor = [UIColor blackColor];
    [self.timeLabel setTranslatesAutoresizingMaskIntoConstraints:false];
    [self.containerStack addArrangedSubview:self.timeLabel];
    
    [self setupDetailsStack];
}

- (void)setupContainerStack {
  self.containerStack = [[UIStackView alloc]
      initWithArrangedSubviews:nil
                          axis:UILayoutConstraintAxisVertical
                  distribution:UIStackViewDistributionFill
                     alignment:UIStackViewAlignmentFill
                       spacing:13
                       margins:UIEdgeInsetsMake(0, 20, 40, 20)];
  [self.contentView addSubview:self.containerStack];
  [self.containerStack setTranslatesAutoresizingMaskIntoConstraints:false];
  [[self.containerStack.leftAnchor
      constraintEqualToAnchor:self.contentView.leftAnchor] setActive:true];
  [[self.containerStack.rightAnchor
      constraintEqualToAnchor:self.contentView.rightAnchor] setActive:true];
  [[self.containerStack.topAnchor
      constraintEqualToAnchor:self.contentView.topAnchor] setActive:true];
  [[self.containerStack.bottomAnchor
      constraintEqualToAnchor:self.contentView.bottomAnchor] setActive:true];
}

- (void)setupDetailsStack {
    CGFloat cornerRadius = 15;
    
    self.coverImageView = [UIImageView new];
    self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.coverImageView.backgroundColor = [UIColor alabaster];
    
    if (@available(iOS 11.0, *)) {
        self.coverImageView.layer.cornerRadius = cornerRadius;
        self.coverImageView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    } else {
        // round in layoutSubviews:
    }
    
    self.coverImageView.clipsToBounds = true;
    self.coverImageView.translatesAutoresizingMaskIntoConstraints = false;
    [self.coverImageView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];

    self.itemImageStack = [[UIStackView alloc]
        initWithArrangedSubviews:@[ self.coverImageView ]
                            axis:UILayoutConstraintAxisVertical
                    distribution:UIStackViewDistributionFill
                       alignment:UIStackViewAlignmentFill
                         spacing:0
                         margins:UIEdgeInsetsZero];
    self.itemImageStack.translatesAutoresizingMaskIntoConstraints = false;
    
    self.titleLabel = [UILabel new];
    self.titleLabel.font = [UIFont systemFontOfSize:28 weight:UIFontWeightSemibold];
    self.titleLabel.textColor = [UIColor blackColor];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = false;
    
    self.subtitleLabel = [UILabel new];
    self.subtitleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    self.subtitleLabel.textColor = [UIColor abbey];
    self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = false;

    UIStackView *titleStack = [[UIStackView alloc]
        initWithArrangedSubviews:@[ self.subtitleLabel, self.titleLabel ]
                            axis:UILayoutConstraintAxisVertical
                    distribution:UIStackViewDistributionEqualSpacing
                       alignment:UIStackViewAlignmentLeading
                         spacing:6
                         margins:UIEdgeInsetsMake(19, 19, 19, 19)];
    [titleStack
     setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh
     forAxis:UILayoutConstraintAxisVertical];

    UIStackView *detailsStack = [[UIStackView alloc]
        initWithArrangedSubviews:@[ self.itemImageStack, titleStack ]
                            axis:UILayoutConstraintAxisVertical
                    distribution:UIStackViewDistributionFill
                       alignment:UIStackViewAlignmentFill
                         spacing:0
                         margins:UIEdgeInsetsZero];
    detailsStack.translatesAutoresizingMaskIntoConstraints = false;
    
    self.detailStackContainer = [UIView new];
    self.detailStackContainer.backgroundColor = [UIColor whiteColor];
    self.detailStackContainer.layer.cornerRadius = 15;
    self.detailStackContainer.layer.shadowOpacity = 0.22;
    self.detailStackContainer.layer.shadowRadius = 14;
    self.detailStackContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    self.detailStackContainer.layer.shadowOffset = CGSizeMake(0, 12);
    self.detailStackContainer.clipsToBounds = false;
    self.detailStackContainer.translatesAutoresizingMaskIntoConstraints = false;
    [self.detailStackContainer addSubview:detailsStack];
    [detailsStack.leftAnchor constraintEqualToAnchor:self.detailStackContainer.leftAnchor].active = true;
    [detailsStack.rightAnchor constraintEqualToAnchor:self.detailStackContainer.rightAnchor].active = true;
    [detailsStack.topAnchor constraintEqualToAnchor:self.detailStackContainer.topAnchor].active = true;
    [detailsStack.bottomAnchor constraintEqualToAnchor:self.detailStackContainer.bottomAnchor].active = true;
    
    [self.containerStack addArrangedSubview:self.detailStackContainer];
}

@end

