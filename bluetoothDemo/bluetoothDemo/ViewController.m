//
//  ViewController.m
//  bluetoothDemo
//
//  Created by hao123 on 16/4/20.
//  Copyright © 2016年 SCU. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>{
    
    CBCentralManager *manager; // 蓝牙管理器
    
    CBPeripheral *connectedPeripheral; // 已连接的设备
    
    
    NSMutableArray *peripheralsArray; // 保存搜索到的设备
    
    NSMutableDictionary *macAdressDict; // 保存蓝牙地址
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.title = @"蓝牙搜索工具";
    [self createButtonsUI];
    
    //设置主设备的委托,CBCentralManagerDelegate
    manager = [[CBCentralManager alloc]initWithDelegate:self queue:dispatch_get_main_queue()];
    
    peripheralsArray = [[NSMutableArray alloc]init];
    
    macAdressDict = [NSMutableDictionary dictionary];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 * 创建搜索按钮
 */
-(void)createButtonsUI{
    
    NSArray *array = [NSArray arrayWithObjects:@"重新搜索",@"停止搜索",@"断开连接", nil];
    
    for ( int i = 0; i < array.count; i++ ) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];

        btn.frame = CGRectMake(30*i+60*i+30, 60, 80, 44);
        [btn setTitle:array[i] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        btn.backgroundColor = [UIColor grayColor];
        btn.tag = i;
        
        [btn addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
    }
}

-(void)buttonClick:(UIButton*)btn{
    
    switch (btn.tag) {
        case 0: // 开始搜索
            [peripheralsArray removeAllObjects];
            [macAdressDict removeAllObjects];
            connectedPeripheral = nil;
            
            [manager scanForPeripheralsWithServices:nil options:nil];

            break;
            
        case 1: // 停止搜索
            [manager stopScan];
            break;
            
        case 2: // 断开连接
            if (connectedPeripheral != nil) {
                [manager cancelPeripheralConnection:connectedPeripheral];
            }
            break;
            
        default:
            break;
    }
}

#pragma mark - bluetooth

-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            NSLog(@">>>CBCentralManagerStateUnknown");
            break;
        case CBCentralManagerStateResetting:
            NSLog(@">>>CBCentralManagerStateResetting");
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@">>>CBCentralManagerStateUnsupported");
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@">>>CBCentralManagerStateUnauthorized");
            break;
        case CBCentralManagerStatePoweredOff:
            NSLog(@">>>CBCentralManagerStatePoweredOff");
            break;
        case CBCentralManagerStatePoweredOn:
            NSLog(@">>>CBCentralManagerStatePoweredOn");
            //开始扫描周围的外设
            
            [central scanForPeripheralsWithServices:nil options:nil];
            
            break;
        default:
            break;
    }
    
}

//扫描到设备会进入方法
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    
    NSLog(@"当扫描到设备:%@",peripheral.name);
    
    // 保存扫描到的设备
    if (![peripheralsArray containsObject:peripheral]) {
        [peripheralsArray addObject:peripheral];
    }
    
    //保存mac地址
    NSLog(@"---advertisementData = %@,rssi = %@",advertisementData,RSSI);
    
    if(![macAdressDict objectForKey:peripheral.identifier.UUIDString]) {
        [macAdressDict setObject:advertisementData forKey:peripheral.identifier.UUIDString];
    }

    [self.tableview reloadData];
}


//连接到Peripherals-失败
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@">>>连接到名称为（%@）的设备-失败,原因:%@",[peripheral name],[error localizedDescription]);
}

//Peripherals断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@">>>外设连接断开连接 %@: %@\n", [peripheral name], [error localizedDescription]);
    
    if (connectedPeripheral == peripheral) {
        connectedPeripheral = nil;
    }
    
    [_tableview reloadData];
    
}
//连接到Peripherals-成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@">>>连接到名称为（%@）的设备-成功",peripheral.name);
    //设置的peripheral委托CBPeripheralDelegate
    [peripheral setDelegate:self];
    
    //扫描外设Services，成功后会进入方法：-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    [peripheral discoverServices:nil];
    
    connectedPeripheral = peripheral;
    [_tableview reloadData];
}


#pragma mark - tableview
-(UITableView *)tableview{
    if (_tableview == nil) {
        _tableview = [[UITableView alloc] initWithFrame:CGRectMake(0, 110, self.view.frame.size.width, self.view.frame.size.height-110) style:UITableViewStylePlain];
        _tableview.delegate = self;
        _tableview.dataSource = self;
        [self.view addSubview:_tableview];
    }
    
    return _tableview;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return  peripheralsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *identifier = @"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    
    CBPeripheral *peripheral = peripheralsArray[indexPath.row];
    cell.textLabel.text = peripheral.name ? peripheral.name : @"unKnow"; // 设备名
    
    //获取mac地址
    NSDictionary *advertisementData = [macAdressDict objectForKey:peripheral.identifier.UUIDString];
    NSData *macAdress = [advertisementData objectForKey:CBAdvertisementDataManufacturerDataKey];
    cell.detailTextLabel.text  = [NSString stringWithFormat:@"mac:%@",macAdress];
    
    if (peripheral == connectedPeripheral) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else{
        cell.accessoryType = UITableViewCellAccessoryNone;

    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    CBPeripheral *peripheral = peripheralsArray[indexPath.row];
    [manager connectPeripheral:peripheral options:nil]; // 连接蓝牙
    
    NSLog(@"identify = %@",peripheral.identifier);
}




@end
