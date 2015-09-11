//
//  ContactTableViewCell.h
//  Solstice Contacts
//
//  Created by Patrick on 7/23/15.
//  Copyright (c) 2015 Patrick Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContactTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *phoneLabel;
@property (nonatomic, weak) IBOutlet UIImageView *thumbnailImageView;

@end
