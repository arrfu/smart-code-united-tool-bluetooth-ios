//
//  ViewController.h
//  bluetoothDemo
//
//  Created by hao123 on 16/4/20.
//  Copyright © 2016年 SCU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController : UIViewController<CBCentralManagerDelegate,CBPeripheralDelegate>

@property (nonatomic,strong)UITableView *tableview;
@end

