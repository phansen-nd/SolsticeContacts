//
//  ContactTableViewCell.m
//  Solstice Contacts
//
//  Created by Patrick on 7/23/15.
//  Copyright (c) 2015 Patrick Hansen. All rights reserved.
//

#import "ContactTableViewCell.h"

@implementation ContactTableViewCell

@synthesize nameLabel;
@synthesize phoneLabel;
@synthesize thumbnailImageView;

- (void)awakeFromNib {
    thumbnailImageView.layer.cornerRadius = 3.0f;
    thumbnailImageView.clipsToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
