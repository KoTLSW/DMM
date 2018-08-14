//
//  ViewController.m
//  MK_TestingModel_Sample
//
//  Created by Michael on 16/11/10.
//  Copyright © 2016年 Michael. All rights reserved.
//

#import "ViewController.h"
#import "MK_Table.pch"
#import "MK_File.pch"
#import "MK_Alert.pch"
#import "MK_Timer.pch"
#import "AppDelegate.h"
#import "Agilent3458A.h"
#import "Agilent33210A.h"
#import "Param.h"
#import "InstantPudding_API_QT1.h"
#import "ORSSerialPort.h"
#import "Agilent34461A.h"
#import "Agilent34410A.h"
#import "AgilentTools.h"
#import <math.h>

static ViewController * selfClass=nil;

//SN:FG772050032j5L215

//sesorboard

//  28，30，29，62，
//  34，49，33


//Erbium
//172.22.111.17
//172.22.110.28
//172.22.110.18
//172.22.111.18

//程序描述
//********************************************************
//1.程序可控制 A  B  两款治具。
//2.向治具发送 get dev 指令根据返回数据进行区分治具款式
//3.返回包括字符 JHEF 为A款，JHE为B款，
//4.A款需要打开气缸（open cy），程序结束后关掉气缸（close cy），返回来均为ok，
//5.其余部分index = 3往后，相同





//********************************************************


@interface ViewController()<ORSSerialPortDelegate>

@end

@implementation ViewController
{
    //************ Device *************
    ORSSerialPort          * fixtureSerial;   //治具串口
    Agilent3458A           * agilent3458A;    //安捷伦万用表
    Agilent33210A          * agilent33210A;   //波形发生器
    Agilent34461A          * agilent34461A;   //万用表
    Agilent34410A          * aglient34410A;   //万用表
    AgilentTools           * aglientTools;    //安捷伦万用表
    
    
    //************* timer *************
    NSString *start_time;               //启动测试的时间
    NSString *end_time;                 //结束测试的时间
    NSString *cost_time;                //程序测试花费的时间
    NSThread * myThrad;                  // 自定义主线程
    
    //************ table **************
    Table *mk_table;                       // table类
    Plist *plist;                          // plist类
    Param *param;                          // param参数类
    NSMutableArray *itemArr;            // plist文件测试项数组
    Item *testItem ;
    NSString *itemResult; //每一个测试项的结果
    int index;                          // 测试流程下标
    int item_index;                     // 测试项下标
    int row_index;                      // table 每一行下标
    
    
    __weak IBOutlet NSTextField *bigTitleTF;
    __weak IBOutlet NSTextField *versionTF;
    __weak IBOutlet NSView *tab_View;               // 与storyboard 关联的 outline_Tab
    __unsafe_unretained IBOutlet NSTextView *logView_Info; //log_View 中显示的信息
    
    __unsafe_unretained IBOutlet NSTextView *FailItemView;
    
    
    //************ testItems ************
    NSMutableArray  *txtLogMutableArr;
    NSString        *agilentReadString;
    NSDictionary    *dic;
    NSString        *SonTestDevice;
    NSString        *SonTestCommand;
    int             delayTime;
    int             ct_cnt;                //记录cycle time定时器中断的次数
    
    NSMutableArray  *testResultArr;        // 返回的结果数组
    NSMutableArray  *testItemTitleArr;     //每个测试标题都加入数组中,生成数据文件要用到
    NSMutableArray  *testItemValueArr;     //每个测试结果都加入数组中,生成数据文件要用到
    NSMutableArray  *testItemMinLimitArr;  //每个测试项最小值数组
    NSMutableArray  *testItesmMaxLimitArr; //每个测试项最大值数组
    
    //************ right_Side_Window *************
    MKTimer *mkTimer;               //MK 定时器对象
    int testNum;                        //测试次数
    int passNum;                        //通过次数
    NSString    *testResultStr;     //测试结果
    
    
    
    
    __weak IBOutlet NSTextField *importSN;          //输入的sn
    __weak IBOutlet NSTextField *currentStateMsg;   //当前的状态信息
    __weak IBOutlet NSTextField *currentStateMsgBG;
    
    __weak IBOutlet NSTextField *testResult;        //测试结果
    
    __weak IBOutlet NSTextField *testFieldTimes;    //测试时间
    __weak IBOutlet NSTextField *testCount;         //测试次数
    
    __weak IBOutlet NSButton *PDCA_Btn;             //PDCA 按钮
    __weak IBOutlet NSButton *SFC_Btn;              //SFC  按钮
    
    __weak IBOutlet NSButton *S3T1Btn;
    
    
    __weak IBOutlet NSButton *S2T3Btn;
    
    
    __weak IBOutlet NSTextField *passNumInfoTF;
    __weak IBOutlet NSTextField *passNumCalculateTF;
    __weak IBOutlet NSTextField *failNumInfoTF;
    __weak IBOutlet NSTextField *failNumCalculateTF;
    __weak IBOutlet NSTextField *totalNumInfo;
    __weak IBOutlet NSTextField *fixtureID_TF;
    __weak IBOutlet NSTextField *stationID_TF;
    __unsafe_unretained IBOutlet NSTextView *SN_Collector;//sn 收集器
    
    
    
    
    //添加的属性===========5.10====chen
    BOOL          isUpLoadSFC;      //是否上传SFC
    BOOL          isUpLoadPDCA;     //是否上传PDCA
    
    BOOL          boolTotalResult;  //测试总结果
    BOOL          JHEA;
    
    //    PDCA         *pdca;             //PDCA对象
    
    BOOL         all_Pass;          //testPDCA
    NSString     *ReStaName;
    NSString     *ReStaID;
    BOOL debug_skip_pudding_error;
    
    NSMutableArray *failItemsArr;
    NSMutableArray *passItemsArr;
    
    
    //================09.08新增csv项，ListFailingTest 和 Error Descrition===============
    NSMutableString * ListFailingTest;
    NSMutableString * errorDescription;
    
    
    //testItem...
    double num;
    double number;
//    float  sun;
//    float Ave;
    

    
    //具中返回来的cp
    NSString *backStr;                      //从治具中返回来的值
    NSMutableString * appendString;         //从治具中返回来的字符
    
    NSMutableArray* logGlobalArray;
    //增加无限循环限制设定
    BOOL  unLimitTest;                               //无限循环设定
    
    //设置BOOL变量====================10.10
    BOOL  isReceive;                                 //是否接收数据
    NSString      *   station_Name;                  //plist文件中工站名称
    NSString      *   param_Name;                    //plist文件中参数的名称
    NSString      *   SNString;                      //输入的序列号SN
    BOOL          SN_BOOL;                           //验证SN

    
    
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
     param = [[Param alloc]init];
    
   
    appendString=[[NSMutableString alloc]initWithCapacity:10];
    ListFailingTest = [[NSMutableString alloc]initWithCapacity:10];
    errorDescription =[[NSMutableString  alloc]initWithCapacity:10];
    itemArr = [NSMutableArray arrayWithCapacity:0];
    txtLogMutableArr = [NSMutableArray arrayWithCapacity:0];
    passItemsArr = [NSMutableArray arrayWithCapacity:0];
    failItemsArr = [NSMutableArray arrayWithCapacity:0];
    testItemValueArr = [NSMutableArray arrayWithCapacity:0];
    testItemTitleArr = [NSMutableArray arrayWithCapacity:0];
    testItemMinLimitArr = [NSMutableArray arrayWithCapacity:0];
    testItesmMaxLimitArr = [NSMutableArray arrayWithCapacity:0];
    testResultArr  = [NSMutableArray arrayWithCapacity:0];
    logGlobalArray = [NSMutableArray arrayWithCapacity:10];

    
    mkTimer = [[MKTimer alloc] init];
    plist = [[Plist alloc] init];
    mk_table = [[Table alloc] init];
    
    
    //仪器仪表类
    agilent33210A =[[Agilent33210A alloc] init];
    agilent3458A =[[Agilent3458A alloc] init];
    agilent34461A=[[Agilent34461A alloc] init];
    aglient34410A=[[Agilent34410A alloc] init];
    aglientTools =[AgilentTools Instance];
    //通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectStationNoti:) name:@"changePlistFileNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectPDCA_SFC_LimitNoti:) name:@"PDCAButtonLimit_Notification" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(CancellPDCA_SFC_LimitNoti:) name:@"CancellButtonlimit_Notification" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(SetUnLimit_Notification:) name:@"TestUnLimit_Notification" object:nil];
    //selectOnCS
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectOnCS:) name:@"selectOnCS" object:nil];
    //selectOffCS
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectOffCS:) name:@"selectOffCS" object:nil];

    
    //控件状态
      logView_Info.editable = NO;
      PDCA_Btn.enabled = NO;
      SFC_Btn.enabled = NO;
      _startBtn.enabled =NO;
    S3T1Btn.hidden = YES;
    S2T3Btn.hidden = YES;
    
    
    //相关赋值
        boolTotalResult = NO;
        all_Pass = NO;
        unLimitTest=NO;
        SN_BOOL  = NO;
        JHEA = NO;
        item_index = 0;
        row_index = 0;
        index= 0;
        testNum = 0;
        passNum = 0;
        number  = 10;
//    sun = 0;
//    Ave = 0;
    
    
     station_Name = @"DMM";
     param_Name = @"Param";
    
     [param ParamRead:param_Name];
    
    //读取 plist 文件
    itemArr = [plist PlistRead:station_Name Key:@"AllItems"];
    mk_table = [mk_table init:tab_View DisplayData:itemArr];

    fixtureSerial=[ORSSerialPort serialPortWithPath:param.fixture_uart_port_name];
    fixtureSerial.baudRate=@B115200;
    fixtureSerial.delegate=self;
    

    
    [self redirectSTD:STDOUT_FILENO];  //冲定向log
    [self redirectSTD:STDERR_FILENO];
    

    if (param.isDebug)
    {
        bigTitleTF.stringValue = @"Debug Mode";
    }
    else
    {
        
        bigTitleTF.stringValue = param.sw_name;
        
        
    }
    versionTF.stringValue =[NSString stringWithFormat:@"Version: %@",param.sw_ver];
    
    stationID_TF.stringValue = param.sw_name;

    
    
    
    NSArray  *  arr =[aglientTools getUsbArray];
    for (NSString * agilentString in arr)
    {
        if ([agilentString containsString:@"0x0607"]||[agilentString containsString:@"0x2A8D"])
        {
            aglientTools.multimeter  = agilentString;
        }
    }
    

    //测试项线程
      myThrad = [[NSThread alloc] initWithTarget:self selector:@selector(Working) object:nil];
     [myThrad start];
    
    
    
    
}
//发sw on aa1 to dmm 指令
//TestCommand sw on aa1 to dmm
- (IBAction)S3T1:(id)sender {
    
    [self Fixture:fixtureSerial writeCommand:@"reset"];
    
    sleep(1);
    
    [self Fixture:fixtureSerial writeCommand:@"sw on aa1 to dmm"];
    sleep(1);
    
    NSLog(@"TestCommand sw on aa1 to dmm");
    
    //[self Fixture:fixtureSerial writeCommand:@"reset"];
    
}
 //发sw on bb1 to dmm指令

- (IBAction)S2T3:(id)sender {
    
    [self Fixture:fixtureSerial writeCommand:@"reset"];
    sleep(1);
    
    [self Fixture:fixtureSerial writeCommand:@"sw on bb1 to dmm"];
    sleep(1);
    
    //[self Fixture:fixtureSerial writeCommand:@"reset"];
    
    NSLog(@"TestCommand sw on bb1 to dmm");
    
}

-(void)selectPDCA_SFC_LimitNoti:(NSNotification *)noti
{
    PDCA_Btn.enabled = YES;
    SFC_Btn.enabled = YES;
}


-(void)CancellPDCA_SFC_LimitNoti:(NSNotification *)noti
{
    PDCA_Btn.state=YES;
    SFC_Btn.state= YES;
    PDCA_Btn.enabled = NO;
    SFC_Btn.enabled  = NO;
}

//无限循环限制设定
-(void)SetUnLimit_Notification:(NSNotification *)noti
{
    
    unLimitTest=YES;
}

-(void)selectOnCS:(NSNotification *)noti{

    S3T1Btn.hidden = NO;
    S2T3Btn.hidden = NO;

}
-(void)selectOffCS:(NSNotification *)noti{

    S3T1Btn.hidden = YES;
    S2T3Btn.hidden = YES;
   [self Fixture:fixtureSerial writeCommand:@"reset"];
    sleep(1);

}


-(void)selectStationNoti:(NSNotification *)noti
{
    if (plist == nil)
    {
        plist = [[Plist alloc] init];
    }
    
    if (mk_table == nil)
    {
        mk_table = [[Table alloc] init];
    }

    
    if ([noti.object isEqualToString:@"SersonBoard"] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentStationStatus"] isEqualToString:@"SersonBoard"])
    {
        NSLog(@"进入 SersonBoard 工站");
        stationID_TF.stringValue = @"Sensor Board";

        //读取 plist 文件
        itemArr = [plist PlistRead:@"SersonBoard" Key:@"AllItems"];
        mk_table = [mk_table init:tab_View DisplayData:itemArr];
        
    }
    
    if ([noti.object isEqualToString:@"CrownFlex"]|| [[[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentStationStatus"] isEqualToString:@"CrownFlex"])
    {
        NSLog(@"进入 CrownFlex 工站");
        stationID_TF.stringValue = @"Crown Flex";
        
        //读取 plist 文件
        itemArr = [plist PlistRead:@"CrownFlex" Key:@"AllItems"];
        mk_table = [mk_table init:tab_View DisplayData:itemArr];
        
    }
    
    if ([noti.object isEqualToString:@"Erbium"]|| [[[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentStationStatus"] isEqualToString:@"Erbium"])
    {
        NSLog(@"进入 Erbium 工站");
        stationID_TF.stringValue = @"Sensor Flex Sub Assembly";
        
        //读取 plist 文件
        itemArr = [plist PlistRead:@"Erbium" Key:@"AllItems"];
        mk_table = [mk_table init:tab_View DisplayData:itemArr];
        
    }
    
    //重新加载参数
    //获取沙盒中的工站和参数
    station_Name = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentStationStatus"];
    param_Name = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentParam"];
    [param ParamRead:param_Name];
    
    
}


//sn = 123456
//================================================
//测试动作流程
//================================================
-(void)Working
{
    
    if (testItem == nil)
    {
        testItem  = [[Item alloc] init];
    }
    
    while ([[NSThread currentThread] isCancelled]==NO) //线程未结束一直处于循环状态
    {
#pragma mark index=0 打开治具，串口通信
        //------------------------------------------------------------
        //index=0
        //------------------------------------------------------------
        
        
        if (index == 0)
        {
                [fixtureSerial open];
                BOOL uartConnect=NO;
                //Debug mode
                if (param.isDebug)
                {
                    uartConnect = YES;
                    index = 1;
                }
                else if([fixtureSerial isOpen])
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        currentStateMsg.stringValue=@"index=0,fixture connect ok!";
                        NSLog(@"index=0,fixture connect ok!");
                        
                        [currentStateMsg setTextColor:[NSColor blueColor]];
                    });
                    
                    [logGlobalArray addObject:[NSString stringWithFormat: @"%@: index=0,fixture connect ok!\n", [[GetTimeDay shareInstance] getLogTime]]];
                    
                    sleep(1);
                    NSLog(@"Time of send command of Fixture id%@",[[GetTimeDay shareInstance] getCurrentMinuteAndSecond]);
                    //fixtureID = [self getValueFromFixture_SendCommand:@"FIXTURE ID?"];
                    
                    
                    [self Fixture:fixtureSerial writeCommand:@"reset"];
                    
                    sleep(1);
                    
                    if ([[backStr uppercaseString ]containsString:@"OK"])
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            backStr = @"";
                            currentStateMsg.stringValue=@"index=1,fixture reset ok!";
                            
                            index = 1;
                        [currentStateMsg setTextColor:[NSColor blueColor]];
                        });
                        
                    }
                    
                    }
                else
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        currentStateMsg.stringValue=@"index=0,fixture connect fail!";
                        
                        [currentStateMsg setTextColor:[NSColor redColor]];
                    });
                    
                    [logGlobalArray addObject:[NSString stringWithFormat: @"%@: index=0,fixture connect fail!\n", [[GetTimeDay shareInstance] getLogTime]]];
                    
                    sleep(1);
                    
                }
            
        }
        
#pragma mark index=1  打开安捷伦万用表---GPIB通信
        // "USB0::0x0957::0x1507::MY57000142::INSTR",        32210A
        // "USB0::0x0957::0x0607::MY47017314::INSTR",        34410A
        // "USB0::0x2A8D::0x1301::MY53226586::INSTR"         34461A
        //------------------------------------------------------------
        //index=1
        //------------------------------------------------------------
        
        if (index==1)
        {
            BOOL agilent_isOpen;
            //Debug mode
            
            
            if (param.isDebug)
            {
                agilent_isOpen = YES;
            }
            else
            {
                if ([aglientTools.multimeter containsString:@"0x2A8D"]) {
                    
                    agilent_isOpen = [agilent34461A Find:nil andCommunicateType:Agilent34461A_MODE_USB_Type]&&[agilent34461A OpenDevice: nil andCommunicateType:Agilent34461A_MODE_USB_Type];
                }
                else if([aglientTools.multimeter containsString:@"0x0607"])
                {
                    agilent_isOpen = [aglient34410A Find:nil andCommunicateType:MODE_USB_Type]&&[aglient34410A OpenDevice:nil andCommunicateType:MODE_USB_Type];
                }
                else
                {
                    agilent_isOpen = [agilent3458A FindAndOpen:nil];
                    
                }
            }
            
            sleep(1);
            if (agilent_isOpen)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    currentStateMsg.stringValue=@"index=1,aglient connect ok!";
                    NSLog(@"index=1,aglient connect ok!");
                    [currentStateMsg setTextColor:[NSColor blueColor]];
                });
                
                [logGlobalArray addObject:[NSString stringWithFormat: @"%@: index=1,aglient connect ok!\n", [[GetTimeDay shareInstance] getLogTime]]];
            
                
                sleep(1);
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    
                    currentStateMsg.stringValue=@"index=1,Please Enter SN!";
                    
                    [currentStateMsg setTextColor:[NSColor redColor]];
                    _startBtn.enabled=YES;
                
                     index=1000;
                    NSLog(@"index = 1");
                });
                
               
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    currentStateMsg.stringValue=@"index=1,aglient3458 connect fail!";
                    NSLog(@"index=1,aglient connect fail!");
                    [currentStateMsg setTextColor:[NSColor redColor]];
                });
                
                [logGlobalArray addObject:[NSString stringWithFormat: @"%@: index=1,aglient connect fail!\n", [[GetTimeDay shareInstance] getLogTime]]];
            
                
            }
            

            
        }
#pragma mark index =2 start BTN 
        
        if (index == 2) {
            
            [self Fixture:fixtureSerial writeCommand:@"get dev"];
            
            sleep(1);
            
            if ([backStr containsString:@"JHEA"] || param.isDebug) {
                backStr = @"";
                
                while (YES) {
                    
                    [self Fixture:fixtureSerial writeCommand:@"open cy"];
                    [NSThread sleepForTimeInterval:0.5];
                    
                    if ([backStr containsString:@"ok"] || param.isDebug) {
                        
                        index = 3;
                        
                        JHEA = YES;
                        
                        break;
                        
                    }else{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            currentStateMsg.stringValue=@"index=2,device not in place!";
                            [currentStateMsg setTextColor:[NSColor redColor]];
                        });
                        
                        sleep(1);
                        
                    }
                    

                }
              
                
                
            }//backStr containsString:@"JHEF"
            else if ([backStr containsString:@"JHEB"]){
                //不带感应器，真空吸关闭,
                
                [self Fixture:fixtureSerial writeCommand:@"close vacuum"];
                
                [NSThread sleepForTimeInterval:0.5];
            
                index = 3;
            
            
            }else{
            
                dispatch_async(dispatch_get_main_queue(), ^{
                    currentStateMsg.stringValue=@"index=2,NO detecting device";
                    NSLog(@"index=2,NO detecting device!");
                    [currentStateMsg setTextColor:[NSColor redColor]];
                });
                sleep(1);
            
            }
            
            
            
           
        }
        
#pragma mark index=3  扫描SN
        //------------------------------------------------------------
        //index=3
        //------------------------------------------------------------
        if (index == 3)
        {
            
            sleep(1);
            [logGlobalArray addObject:[NSString stringWithFormat: @"%@: index=3 detectin SN ", [[GetTimeDay shareInstance] getLogTime]]];
            
            [self GetSFC_PDCAState];//获取是否上传的状态
            
            dispatch_async(dispatch_get_main_queue(), ^{
                //判断 SN 的规则
                if ([importSN.stringValue length]==17)
                {
                    [[NSUserDefaults standardUserDefaults] setObject:importSN.stringValue forKey:@"theSN"];
                    
                    if ([param.differentSNArray containsObject:[importSN.stringValue substringWithRange:NSMakeRange(11, 4)]])
                    {
                        //按照不同的 SN 导入不同的 Items
                        //读取 plist 文件
                        [mk_table ClearTable];
                        itemArr = [plist PlistRead:station_Name Key:@"AllItems_DiffSN"];
                        NSLog(@"%lu",(unsigned long)[itemArr count]);
                        
                        mk_table = [mk_table init:tab_View DisplayData:itemArr];
                        [[NSUserDefaults standardUserDefaults] setObject:@"AllItems_DiffSN" forKey:@"currentPlistKey"];
                        
                        currentStateMsg.stringValue = @"index=2,SN ok!";
                        NSLog(@"index=2,SN ok!");
                        
                       
                    }
                    else
                    {
                        //读取 plist 文件
                         [mk_table ClearTable];
                         [self UpdateTextView:@"\n\n" andClear:YES andTextView:FailItemView];
                         itemArr = [plist PlistRead:station_Name Key:@"AllItems"];
                         mk_table = [mk_table init:tab_View DisplayData:itemArr];
                         [[NSUserDefaults standardUserDefaults] setObject:@"AllItems" forKey:@"currentPlistKey"];
                         NSLog(@"打印当前的数值===============%lu",(unsigned long)[itemArr count]);
                      }
                    
                    [logGlobalArray addObject:[NSString stringWithFormat: @"%@: index=2,SN ok! \n", [[GetTimeDay shareInstance] getLogTime]]];
                    currentStateMsg.stringValue = @"index=2,SN ok!";
                    [currentStateMsg setTextColor:[NSColor blueColor]];
                    // sleep(1);
                    index=4;//进入正常测试中
                    NSLog(@"index=3");

                    
                   
                }
                else
                {
                    currentStateMsg.stringValue = @"index=2,SN error!";
                    [logGlobalArray addObject:[NSString stringWithFormat: @"%@: index=2,SN error! \n", [[GetTimeDay shareInstance] getLogTime]]];
                    [currentStateMsg setTextColor:[NSColor redColor]];
                }
            });
            //cycle_test,开始测试前清空tableView
            ct_cnt = 0;
            [logGlobalArray addObject:[NSString stringWithFormat: @"%@: index===2 after time %@\n", [[GetTimeDay shareInstance] getLogTime], [[GetTimeDay shareInstance] getCurrentTime]]];
            
        }
        
#pragma mark  index =4 等待双击启动
        //------------------------------------------------------------
        //index=4
        //------------------------------------------------------------
        if (index == 4)
        {
    
                //sleep(1);
                
               // if ([backStr containsString:@"start"]) {
                    
                    index =5;
//                }
//                else
//                {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        currentStateMsg.stringValue = @"index=3,请双击启动!";
//                        [currentStateMsg setTextColor:[NSColor redColor]];
//                    });
//                    
//                }
////
////            }
            
      }
        
        
    
#pragma mark index=5   SFC 检验 SN 是否过站
        //------------------------------------------------------------
        //index=5
        //------------------------------------------------------------
        if (index == 5)
        {
            //根据SFC状态，检验SN是否过站
            //            if (isUpLoadSFC)
            //            {
            //                [TestStep Instance].strSN=importSN.stringValue;
            //                if (![[TestStep Instance]StepSFC_CheckUploadSN:isUpLoadSFC])
            //                {
            //                    NSLog(@"index=6,SFC check fail");
            //                    currentStateMsg.stringValue = @"index=6,SFC check fail";
            //                    [currentStateMsg setTextColor:[NSColor redColor]];
            //                    sleep(1);
            //                }
            //                else
            //                {
            //                    NSLog(@"index=5,SFC No message");
            //                    currentStateMsg.stringValue = @"index=6,SFC No message";
            //                    [currentStateMsg setTextColor:[NSColor redColor]];
            //                    sleep(1);
            //                    index = 7;//进入正常测试中
            //                }
            //            }
            //            else
            //            {
            //            }
            sleep(1);
            NSLog(@"index=4,SFC No check!");
            [logGlobalArray addObject:[NSString stringWithFormat: @"%@: index=4,SFC No check!\n", [[GetTimeDay shareInstance] getLogTime]]];
            currentStateMsg.stringValue = @"index=4,SFC No check!";
            [currentStateMsg setTextColor:[NSColor redColor]];
            
            index = 6;
        }
        
#pragma mark index = 6
        
        //------------------------------------------------------------
        //index=6
        //------------------------------------------------------------
        if (index == 6)
        {
            [logGlobalArray addObject:[NSString stringWithFormat: @"%@: index=6 before time %@\n", [[GetTimeDay shareInstance] getLogTime], [[GetTimeDay shareInstance] getCurrentTime]]];
            dispatch_sync(dispatch_get_main_queue(), ^{
                _startBtn.enabled = NO;
                currentStateMsg.stringValue = @"index=6 running...";
                NSLog(@"index=6 running...");
                
                [currentStateMsg setTextColor:[NSColor blueColor]];
                testResult.stringValue = @"Running";
                testResult.backgroundColor = [NSColor greenColor];
            });
            
            [logGlobalArray addObject:[NSString stringWithFormat: @"%@: index=6 running...\n", [[GetTimeDay shareInstance] getLogTime]]];
            
            //========定时器开始========
            if (ct_cnt == 0)
            {
                /**
                 *  GCD 定时器
                 */
                [mkTimer setTimer:0.1];
                [mkTimer startTimerWithTextField:testFieldTimes];
                ct_cnt = 1;
            }
            //=========================
            
            //在这里加入测试的起始时间
            if (row_index == 0)
            {
                // NSLog(@"记录 pdca 的起始测试时间");
                start_time = [[GetTimeDay shareInstance] getFileTime];    //启动测试的时间,csv里面用
            }
            
            testItem = itemArr[item_index];
            NSLog(@"%@=========%@========%@",testItem.testName, testItem.value, itemArr[item_index]);
            [logGlobalArray addObject:[NSString stringWithFormat:@"%@: %@=========%@========%@\n",[[GetTimeDay shareInstance] getLogTime], testItem.testName, testItem.value, itemArr[item_index]]];
            
            
            //txt log
            [txtLogMutableArr addObject:[NSString stringWithFormat:@"\n\nStartTimer:%@\nTestName:%@\nUnit:%@\nLowerLimit:%@\nUpperLimit:%@\n",[[GetTimeDay shareInstance] getCurrentTime],testItem.testName,testItem.units,testItem.min,testItem.max]];
            
            //加载测试项
            BOOL boolResult = [self TestItem:testItem];
            
            
            //测试结果转为字符串格式
            if (boolResult == YES)
            {
                itemResult = @"PASS";
            }
            else
            {
                itemResult = @"FAIL";
            }
            //把测试结果加入到可变数组中
            [testResultArr addObject:itemResult];
            
            [logGlobalArray addObject:[NSString stringWithFormat: @"%@: index===7 after time %@\n", [[GetTimeDay shareInstance] getLogTime], [[GetTimeDay shareInstance] getCurrentTime]]];
            
            [mk_table flushTableRow:testItem RowIndex:row_index];
            
            //更新失败项内容
            if ([testItem.result isEqualToString:@"FAIL"]) {
                
                [self UpdateTextView:[NSString stringWithFormat:@"FailItem->TestName:%@\n",testItem.testName] andClear:NO andTextView:FailItemView];
                
                [ListFailingTest appendString:[NSString stringWithFormat:@":%@",testItem.testName]];
                
            }
            
            NSLog(@"index===5 ==== time %@",[[GetTimeDay shareInstance] getCurrentTime]);
            [logGlobalArray addObject:[NSString stringWithFormat: @"%@: index=== 5 ==== time %@\n", [[GetTimeDay shareInstance] getLogTime], [[GetTimeDay shareInstance] getCurrentTime]]];
            
            //给治具发送reset指令,收到 RESET_OK 后往下跑
            row_index++;
            item_index++;
            
            
            //走完测试流程,进入下一步
            if (item_index == itemArr.count)
            {
                //异步加载主线程显示,弹出啊 log_View
                dispatch_async(dispatch_get_main_queue(), ^{
                    //遍历测试结果,输出总测试结果
                    for (int i = 0; i< testResultArr.count; i++)
                    {
                        if ([testResultArr[i] containsString:@"FAIL"])
                        {
                            [testResult setStringValue:@"FAIL"];
                            testResult.backgroundColor = [NSColor redColor];
                            break;
                        }
                        else
                        {
                            [testResult setStringValue:@"PASS"];
                            testResult.backgroundColor = [NSColor greenColor];
                        }
                    }
                    
                    testResultStr = testResult.stringValue;
                    sleep(0.5);
                });
                
                
                index = 7;
            }
        }
        
#pragma mark index=7  上传pdca，生成本地数据报表
        //------------------------------------------------------------
        //index=7
        //------------------------------------------------------------
        if (index == 7)
        {
            //========定时器结束========
            [mkTimer endTimer];
            ct_cnt = 0;
            //========================
            
            
            //================09.08新增csv项，ListFailingTest 和 Error Descrition===============west

            errorDescription = [NSMutableString stringWithString:@"N/A"];
            dispatch_sync(dispatch_get_main_queue(), ^{
                currentStateMsg.stringValue = @"index=7 create log file...";
                NSLog(@"index=7 create log file...");
                [currentStateMsg setTextColor:[NSColor blueColor]];
            });
            
            [logGlobalArray addObject:[NSString stringWithFormat: @"%@: index=7 create log file...\n", [[GetTimeDay shareInstance] getLogTime]]];
            
            sleep(1);
            
            if([MK_FileCSV shareInstance]!= nil)       //生成本地数据报表
            {
                testNum++; //测试
                
                //文件夹路径
                NSString *currentPath=@"/vault";
                
                //测试结束并创建文件的时间
                end_time = [[GetTimeDay shareInstance] getFileTime];
                
                //产品 sn
                NSString *currentSN = importSN.stringValue;
                
                //创建总文件夹
                [[MK_FileFolder shareInstance] createOrFlowFolderWithCurrentPath:currentPath SubjectName:@"Emerald_Log"];
                
                //从 json 文件获取本机工站等信息, 拼接到主文件夹中
                NSString * jsonProductKey =[self getValueFromJsonFileWithKey:@"PRODUCT"];
                NSString * jsonStationTypeKey = [self getValueFromJsonFileWithKey:@"STATION_TYPE"];
                
                
                
                
                //创建对应不同工站的文件夹
                NSString *mainFolderName = [NSString stringWithFormat:@"%@_%@_Station_%@_%@",param.sw_name,param.sw_ver,jsonProductKey,jsonStationTypeKey];
                
                //NSLog(@"%@___+++++",jsonStationTypeKey);
                
                [[MK_FileFolder shareInstance] createOrFlowFolderWithCurrentPath:[NSString stringWithFormat:@"%@/DMM_Log/%@/",currentPath,[[GetTimeDay shareInstance] getCurrentDay]] SubjectName:[NSString stringWithFormat:@"%@/",mainFolderName]];
                
                
                
                NSString *mainfolderPath = [NSString stringWithFormat:@"%@/DMM_Log/%@/%@/",currentPath,[[GetTimeDay shareInstance] getCurrentDay],mainFolderName];;
                
                [[NSUserDefaults standardUserDefaults] setObject:mainfolderPath forKey:@"mainFolderPathKey"];
                
                [[NSUserDefaults standardUserDefaults] setObject:mainFolderName forKey:@"mainFolderNameKey"];
                
                
                //csv文件列表头,测试标题项遍历当前plisth文件的测试项(拼接),温湿度传感器
                NSString *min_Str;
                NSMutableString *minMutableStr;
                
                NSString *max_Str;
                NSMutableString *maxMutableStr;
                
                NSString *titleStr;
                NSMutableString *titleMutableStr;
                
                if (titleMutableStr == nil)
                {
                    titleMutableStr = [[NSMutableString alloc] init];
                }
                if (minMutableStr == nil)
                {
                    minMutableStr = [[NSMutableString alloc] init];
                }
                if (maxMutableStr == nil)
                {
                    maxMutableStr = [[NSMutableString alloc] init];
                }
                
                for (int i = 0; i< testItemTitleArr.count; i++)
                {
                    titleStr = [testItemTitleArr objectAtIndex:i];
                    
                    if (i==0)
                    {
                        [titleMutableStr appendString:[NSString stringWithFormat:@"%@",titleStr]];
                        [minMutableStr appendString:[NSString stringWithFormat:@","]];
                        [maxMutableStr appendString:[NSString stringWithFormat:@","]];
                    }else{
                        
                        [titleMutableStr appendString:[NSString stringWithFormat:@",%@",titleStr]];
                        
                        min_Str = [testItemMinLimitArr objectAtIndex:i];
                        [minMutableStr appendString:[NSString stringWithFormat:@",%@",min_Str]];
                        
                        max_Str = [testItesmMaxLimitArr objectAtIndex:i];
                        [maxMutableStr appendString:[NSString stringWithFormat:@",%@",max_Str]];
                        
                        
                    }
                }
                
                NSString *csvTitle = [NSString stringWithFormat:@"%@,SW_Version:%@\nSerialNumber,Test Pass/Fail Status,List of Failing Test,Error Description,StartTime, EndTime,%@\nUpper Limits---->,,,,,%@\nLower Limits---->,,,,,%@",param.sw_name,param.sw_ver,titleMutableStr,maxMutableStr,minMutableStr];
                
                //csv测试项内容,同上
                NSString *csvContentStr;
                NSMutableString *csvContentMutableStr;
                if (csvContentMutableStr == nil)
                {
                    csvContentMutableStr = [[NSMutableString alloc] init];
                }
                
                
                for (int i=0; i< testItemValueArr.count; i++)
                {
                    csvContentStr = [testItemValueArr objectAtIndex:i];
                    
                    if (i == 0) {
                        [csvContentMutableStr appendString:[NSString stringWithFormat:@"%@", csvContentStr]];
                    }else{
                        
                        [csvContentMutableStr appendString:[NSString stringWithFormat:@",%@", csvContentStr]];
                    }
                    
                }
                
                
                
                //创建 csv 总文件,并写入数据
                [[MK_FileCSV shareInstance] createOrFlowCSVFileWithFolderPath:mainfolderPath Sn:nil ListFail:ListFailingTest ErrorDescription:errorDescription TestItemStartTime:start_time TestItemEndTime:end_time TestItemContent:csvContentMutableStr TestItemTitle:csvTitle TestResult:testResultStr];
                
                //对应每个 SN 创建 csv 文件,并写入数据
                [[MK_FileCSV shareInstance] createOrFlowCSVFileWithFolderPath:[MK_FileFolder shareInstance].folderPath Sn:currentSN ListFail:ListFailingTest ErrorDescription:errorDescription TestItemStartTime:start_time TestItemEndTime:end_time TestItemContent:csvContentMutableStr TestItemTitle:csvTitle TestResult:testResultStr];
                
                
                //txt测试项内容,同上  txt log
                NSString *txtContentStr;
                NSMutableString *txtContentMutableStr;
                if (txtContentMutableStr == nil)
                {
                    txtContentMutableStr = [[NSMutableString alloc] init];
                }
                for (int i=0; i< txtLogMutableArr.count; i++)
                {
                    txtContentStr = [txtLogMutableArr objectAtIndex:i];
                    [txtContentMutableStr appendString:[NSString stringWithFormat:@"%@",txtContentStr]];
                }
                
                //创建 txt 文件,并写入数据
                [[MK_FileTXT shareInstance] createOrFlowTXTFileWithFolderPath:[MK_FileFolder shareInstance].folderPath Sn:currentSN TestItemStartTime:start_time TestItemEndTime:end_time TestItemContent:[NSString stringWithFormat:@"\nVersion:%@\nSerialNumber:%@\n%@",param.sw_ver,importSN.stringValue,txtContentMutableStr] TestResult:testResultStr];
                
            }
            
            
#pragma mark ------ 上传 PDCA
            if (isUpLoadPDCA)
            {
                NSLog(@"start to upload pdca");
                
                [logGlobalArray addObject:[NSString stringWithFormat: @"%@: start to upload pdca\n", [[GetTimeDay shareInstance] getLogTime]]];
                
                [self uploadPDCA_Feicui_2];
            }
            
#pragma mark ------ 上传 SFC
            if (isUpLoadSFC)
            {
                NSLog(@"上传SFC");
                [logGlobalArray addObject:@"上传SFC\n"];
                
            }
            
            index = 8;
        }
        
#pragma mark index=8 结束测试
        //------------------------------------------------------------
        //index=8
        //------------------------------------------------------------
        if (index == 8)
        {
            dispatch_sync(dispatch_get_main_queue(), ^{
                currentStateMsg.stringValue = @"index=8 endding!";
                NSLog(@"index=8 endding!");
                [logGlobalArray addObject:@"index=8 endding!\n"];
                [currentStateMsg setTextColor:[NSColor blueColor]];
            });
            sleep(1);
            [logGlobalArray addObject:[NSString stringWithFormat: @"%@: index=8 endding!\n", [[GetTimeDay shareInstance] getLogTime]]];
            //每次结束测试都刷新主界面
            
            if ([testResult.stringValue isEqualToString:@"PASS"])
            {
                passNum++;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                testCount.stringValue = [NSString stringWithFormat:@"%d/%d",passNum,testNum];
                totalNumInfo.stringValue = [NSString stringWithFormat:@"%d",testNum];
                
                passNumInfoTF.stringValue = [NSString stringWithFormat:@"%d",passNum];
                passNumCalculateTF.stringValue = [NSString stringWithFormat:@"%.2f%%",((double)passNum/(double)testNum)*100];
                
                failNumInfoTF.stringValue = [NSString stringWithFormat:@"%d",(testNum - passNum)];
                failNumCalculateTF.stringValue = [NSString stringWithFormat:@"%.2f%%",((double)(testNum-passNum)/(double)testNum)*100];
                
                //录入sn 收集器
                NSString *str1 = [NSString stringWithFormat:@"%@___%@__%@",[[NSUserDefaults standardUserDefaults]  objectForKey:@"theSN"],testResultStr,[[GetTimeDay shareInstance] getCurrentTime]];
                NSString *str2 = SN_Collector.string;
                 SN_Collector.string = [str2 stringByAppendingString:[NSString stringWithFormat:@"%@\n",str1]];
                [SN_Collector setTextColor:[NSColor blueColor]];
                
                if (!unLimitTest) {
                    
                    importSN.stringValue = @"";
                }

                
            });
            
            
            
            index=9;
        }
        
#pragma mark index=9  跳出循环
        //------------------------------------------------------------
        //index=9
        //------------------------------------------------------------
        if (index == 9)
        {
            
            //清除错误测试项和错误原因
            ListFailingTest = [NSMutableString stringWithString:@""];
            
            sleep(1);
            
            dispatch_sync(dispatch_get_main_queue(), ^{
            
                _startBtn.enabled =YES;
            });
            
            item_index = 0;
            row_index=0;
            if (param.isDebug)
            {
                index = 1000;
            }
            else
            {
            
                if (JHEA) {
                    
                    [self Fixture:fixtureSerial writeCommand:@"close cy"];
                    sleep(1);
                    if ([backStr containsString:@"ok"]) {
                        
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            currentStateMsg.stringValue = @"index=9 cylinder off";
                            NSLog(@"index=9 cylinder off");
                            [currentStateMsg setTextColor:[NSColor blueColor]];
                            JHEA = NO;
                        });

                    }else{
                    
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            currentStateMsg.stringValue = @"index=9 cylinder off Fail";
                            NSLog(@"index=9 cylinder off Fail");
                            [currentStateMsg setTextColor:[NSColor blueColor]];
                        });
                    
                    
                    
                    }
                }
            
                
                
                
                
                [self Fixture:fixtureSerial writeCommand:@"reset"];
                //[self whileLoopTest];
                sleep(1);
                dispatch_sync(dispatch_get_main_queue(), ^{
                    currentStateMsg.stringValue = @"index=9 reset FIX!";
                    NSLog(@"index=9 endding!");
                    [logGlobalArray addObject:@"index=9 reset FIX!"];
                    [currentStateMsg setTextColor:[NSColor blueColor]];
                    NSLog(@"index=9 reset FIX!");
                });
                
                [logGlobalArray removeAllObjects];
                
                [[backStr uppercaseString ]containsString:@"OK"];
                
                
                

            
            }
            
           
            
            
            
            //无限循环测试
            if (unLimitTest==YES)
            {
                 //sleep(2);
                index = 3;
                [mk_table ClearTable];
                [self UpdateTextView:@"\n\n" andClear:YES andTextView:FailItemView];
                [self removeDataFromArray];
                
            }else {
            
                index =1000;
            }
            
        }
#pragma mark index=1000 等待状态
        //------------------------------------------------------------
        //index=1000
        //------------------------------------------------------------
        if (index == 1000)
        {
            sleep(0.01);
        }
    }
}


//==================== 冲定向log ============================
- (void)redirectNotificationHandle:(NSNotification *)nf{
    NSData *data = [[nf userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if(logView_Info != nil)
    {
        NSRange range;
        range = NSMakeRange ([[logView_Info string] length], 0);
        [logView_Info replaceCharactersInRange: range withString: str];
        [logView_Info scrollRangeToVisible:range];
    }
    [[nf object] readInBackgroundAndNotify];
}

- (void)redirectSTD:(int )fd{
    
    NSPipe * pipe = [NSPipe pipe] ;
    NSFileHandle *pipeReadHandle = [pipe fileHandleForReading] ;
    dup2([[pipe fileHandleForWriting] fileDescriptor], fd) ;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(redirectNotificationHandle:)
                                                 name:NSFileHandleReadCompletionNotification
                                               object:pipeReadHandle] ;
    
    [pipeReadHandle readInBackgroundAndNotify];
}
//==================== 冲定向log ============================


//================================================
//测试项指令解析
//================================================
-(BOOL)TestItem:(Item*)testitem
{
    BOOL ispass=NO;
    
#pragma mark--------具体测试指令执行流程
    for (int i=0; i<[testitem.testAllCommand count]; i++)
    {
        //治具===================Fixture
        //波形发生器==============OscillDevice
        //安捷伦万用表============Aglient
        //延迟时间================SW
        dic=[testitem.testAllCommand objectAtIndex:i];
        SonTestDevice=dic[@"TestDevice"];
        SonTestCommand=dic[@"TestCommand"];
        delayTime = [dic[@"TestDelayTime"] floatValue]/1000;
        
        
        //**************************治具=Fixture
        if ([SonTestDevice isEqualToString:@"Fixture"])
        {
            
            if (param.isDebug)
            {
                
                backStr = @"debug";
            }
            else
            {
                appendString=[[NSMutableString alloc]initWithString:@""];
                
                int indexTime=0;
                while (YES)
                {
                    [self Fixture:fixtureSerial writeCommand:SonTestCommand];
                    NSLog(@"%@ send:>>%@",SonTestDevice,SonTestCommand);
                    
                    [logGlobalArray addObject:[NSString stringWithFormat: @"%@: %@ send:>>%@\n", [[GetTimeDay shareInstance] getLogTime],SonTestDevice,SonTestCommand]];
                    //[self whileLoopTest];
                    sleep(1);
                    
                    if ([[backStr uppercaseString ]containsString:@"OK"]||indexTime==[testitem.retryTimes intValue])
                    {
                        NSLog(@"%@ receive:<<%@",SonTestDevice,SonTestCommand);
                        [logGlobalArray addObject:[NSString stringWithFormat: @"%@: %@ receive:>>%@\n", [[GetTimeDay shareInstance] getLogTime],SonTestDevice,SonTestCommand]];
                        break;
                    }
                    
                    indexTime++;
                }
            }
            
        }
        
        //**************************波形发生器=WaveDevice
        else if ([SonTestDevice isEqualToString:@"WaveDevice"])
        {
            //获取频率
            NSString   * frequence =[self cutOutStringFromStr:SonTestCommand withDivisionString:@"_" andIndex:3];
            
            if ([SonTestCommand containsString:@"MODE_Sine"])
            {
                NSLog(@"print the waveDevice MODE_Sine");
                [logGlobalArray addObject:[NSString stringWithFormat: @"%@: print the waveDevice MODE_Sine\n", [[GetTimeDay shareInstance] getLogTime]]];
                [agilent33210A SetMessureMode:MODE_Sine andCommunicateType:Agilent33210A_USB_Type andFREQuency:frequence andVOLTage:param.waveVolt andOFFSet:param.waveOffset];
                
                
            }
            else if([SonTestCommand containsString:@"MODE_Square"])
            {
                NSLog(@"print the waveDevice MODE_Square");
                
                [logGlobalArray addObject:[NSString stringWithFormat: @"%@: print the waveDevice MODE_Square\n", [[GetTimeDay shareInstance] getLogTime]]];
                [agilent33210A SetMessureMode:MODE_Square andCommunicateType:Agilent33210A_USB_Type andFREQuency:frequence andVOLTage:@"1.8" andOFFSet:@"0"];
                
            }
            else if([SonTestCommand containsString:@"MODE_Ramp"])
            {
                NSLog(@"print the waveDevice MODE_Ramp");
                [logGlobalArray addObject:[NSString stringWithFormat: @"%@: print the waveDevice MODE_Ramp\n", [[GetTimeDay shareInstance] getLogTime]]];
                [agilent33210A SetMessureMode:MODE_Ramp andCommunicateType:Agilent33210A_USB_Type andFREQuency:frequence andVOLTage:param.waveVolt andOFFSet:param.waveOffset];
            }
            else if([SonTestCommand containsString:@"MODE_Pulse"])
            {
                NSLog(@"print the waveDevice MODE_Pulse");
                [logGlobalArray addObject:[NSString stringWithFormat: @"%@: print the waveDevice MODE_Pulse\n", [[GetTimeDay shareInstance] getLogTime]]];
                [agilent33210A SetMessureMode:MODE_Pulse andCommunicateType:Agilent33210A_USB_Type andFREQuency:frequence andVOLTage:param.waveVolt andOFFSet:param.waveOffset];
                
            }
            else if([SonTestCommand containsString:@"MODE_Noise"])
            {
                NSLog(@"print the waveDevice MODE_Noise");
                [logGlobalArray addObject:[NSString stringWithFormat: @"%@: print the waveDevice MODE_Noise\n", [[GetTimeDay shareInstance] getLogTime]]];
                [agilent33210A SetMessureMode:MODE_Noise andCommunicateType:Agilent33210A_USB_Type andFREQuency:frequence andVOLTage:param.waveVolt andOFFSet:param.waveOffset];
            }
            
            else//其它情况
            {
                NSLog(@"%@: %@ other condition",[[GetTimeDay shareInstance] getLogTime],SonTestDevice);
                [logGlobalArray addObject:[NSString stringWithFormat:@"%@ other condition\n",SonTestDevice]];
                
            }
            
            sleep(1);
            
        }
        
        //**************************万用表==Agilent或者Keithley
        else if ([SonTestDevice isEqualToString:@"Agilent"]||[SonTestDevice isEqualToString:@"Keithley"])
        {
            
            //0x2A8D      34461A;
            if ([aglientTools.multimeter containsString:@"0x2A8D"])
            {
                
                //万用表发送指令
                if ([SonTestCommand isEqualToString:@"DC Volt"])
                {
                    //直流电压测试
                    [agilent34461A SetMessureMode:Agilent34461A_MODE_VOLT_DC andCommunicateType:Agilent34461A_MODE_USB_Type];
                    NSLog(@"Aglient34461A set VOLT_DC");
                    [logGlobalArray addObject:[NSString stringWithFormat:@"%@: Aglient34461A set VOLT_DC\n",[[GetTimeDay shareInstance] getLogTime]]];
                    //如果是最后一项，新增加测试范围
                    if ([testItem.testName containsString:@"ESD_VOLTAGE"]) {
                        
                        [agilent34461A WriteLine:@":SENS:VOLT:DC:RANG 100" andCommunicateType:Agilent34461A_MODE_USB_Type];
                        
                    }
                
                }
                else if([SonTestCommand isEqualToString:@"AC Volt"])
                {
                    [agilent34461A SetMessureMode:Agilent34461A_MODE_VOLT_AC andCommunicateType:Agilent34461A_MODE_USB_Type];
                    NSLog(@"Aglient34461A set AC_Volt");
                    [logGlobalArray addObject:[NSString stringWithFormat:@"%@: Aglient34461A set AC_Volt\n",[[GetTimeDay shareInstance] getLogTime]]];
                }
                else if ([SonTestCommand isEqualToString:@"DC Current"])
                {
                    [agilent34461A SetMessureMode:Agilent34461A_MODE_CURR_DC andCommunicateType:Agilent34461A_MODE_USB_Type];
                    NSLog(@"Aglient34461A set DC_Current");
                    [logGlobalArray addObject:[NSString stringWithFormat:@"%@: Aglient34461A set DC_Current\n",[[GetTimeDay shareInstance] getLogTime]]];
                    
                }
                else if ([SonTestCommand isEqualToString:@"AC Current"])
                {
                    [agilent34461A SetMessureMode:Agilent34461A_MODE_CURR_AC andCommunicateType:Agilent34461A_MODE_USB_Type];
                    
                    NSLog(@"Aglient34461A set AC_Current");
                    [logGlobalArray addObject:[NSString stringWithFormat:@"%@: Aglient34461A set AC_Current\n",[[GetTimeDay shareInstance] getLogTime]]];
                }
                else if ([SonTestCommand containsString:@"RES"])//电阻分单位KΩ,MΩ,GΩ
                {
                    
                    [agilent34461A SetMessureMode:Agilent34461A_MODE_RES_2W andCommunicateType:Agilent34461A_MODE_USB_Type];
                    
                    NSLog(@"Aglient34461A set RES");
                    
                    [logGlobalArray addObject:[NSString stringWithFormat:@"%@: Aglient34461A set RES\n",[[GetTimeDay shareInstance] getLogTime]]];
                    
                }
                else if([SonTestCommand containsString:@"Read"])
                {
                    [agilent34461A WriteLine:@"READ?" andCommunicateType:Agilent34461A_MODE_USB_Type];
                    
                    sleep(0.5);
                    //FGR7442000RJ69X8F
                    if ([testitem.testName isEqualToString:@"ON S3-T1 TO DMM"] || [testitem.testName isEqualToString:@"ON S2-T3 TO DMM"] ) {
                        
                        NSLog(@"**************%@",testitem.testName);
                        
                        float sun = 0;
                        double numberS = 0;
                        
                        for (int i = 0; i < [param.number floatValue] ; i++) {
                            
                            [agilent34461A WriteLine:@"READ?" andCommunicateType:Agilent34461A_MODE_USB_Type];
                            
                    agilentReadString=[agilent34461A ReadData:16 andCommunicateType:Agilent34461A_MODE_USB_Type];
                            
                            numberS = [agilentReadString floatValue];
                            
                            NSLog(@"%d===%f",i,numberS);
                            
                            sun += numberS;
                            
                            //sleep([param.sleepTime floatValue]);
                            [NSThread sleepForTimeInterval:[param.sleepTime floatValue]];
                            
                        }
                        num = sun/[param.number floatValue];
                        
                        NSLog(@"num ===== %f",num);
                        
                        
                    }else{
                        
                    agilentReadString=[agilent34461A ReadData:16 andCommunicateType:Agilent34461A_MODE_USB_Type];
                    
                    num = [agilentReadString floatValue];
                    
                    }
                    
                    
                    if (param.isDebug)
                    {
                        //测试代码
                        agilentReadString = @"30.838383";
                        
                        num = [agilentReadString floatValue];
                    }
                    
                   // num = [agilentReadString floatValue];
                    
                }
                else
                {
                    NSLog(@"Other Situation");
                    [logGlobalArray addObject:[NSString stringWithFormat:@"%@: Other Situation\n",[[GetTimeDay shareInstance] getLogTime]]];
                }
            }
            else
            {
                //万用表发送指令
                if ([SonTestCommand isEqualToString:@"DC Volt"])
                {
                    //直流电压测试
                    [agilent3458A SetMessureMode:Agilent3458A_VOLT_DC];
                    NSLog(@"Aglient3458A set VOLT_DC");
                    [logGlobalArray addObject:[NSString stringWithFormat:@"%@: Aglient3458A set VOLT_DC\n",[[GetTimeDay shareInstance] getLogTime]]];
                }
                else if([SonTestCommand isEqualToString:@"AC Volt"])
                {
                    [agilent3458A SetMessureMode:Agilent3458A_VOLT_AC];
                    NSLog(@"Aglient3458A set AC_Volt");
                    [logGlobalArray addObject:[NSString stringWithFormat:@"%@: Aglient3458A set AC_Volt\n",[[GetTimeDay shareInstance] getLogTime]]];
                    
                }
                else if ([SonTestCommand isEqualToString:@"DC Current"])
                {
                    [agilent3458A SetMessureMode:Agilent3458A_CURR_DC];
                    NSLog(@"Aglient3458A set DC_Current");
                    [logGlobalArray addObject:[NSString stringWithFormat:@"%@: Aglient3458A set DC_Current\n",[[GetTimeDay shareInstance] getLogTime]]];
                    
                }
                else if ([SonTestCommand isEqualToString:@"AC Current"])
                {
                    [agilent3458A SetMessureMode:Agilent3458A_CURR_AC];
                    
                    NSLog(@"Aglient3458A set AC_Current");
                    
                    [logGlobalArray addObject:[NSString stringWithFormat:@"%@: Aglient3458A set AC_Current\n",[[GetTimeDay shareInstance] getLogTime]]];
                    
                }
                else if ([SonTestCommand containsString:@"RES"])//电阻分单位KΩ,MΩ,GΩ
                {
                    [agilent3458A SetMessureMode:Agilent3458A_RES_2W];
                    NSLog(@"Aglient3458A set RES");
                    [logGlobalArray addObject:[NSString stringWithFormat:@"%@: Aglient3458A set RES\n",[[GetTimeDay shareInstance] getLogTime]]];
                    
                }
                else if([SonTestCommand containsString:@"Read"])
                {
                    
                    [agilent3458A WriteLine:@"END"];
                    
                    if (param.isDebug)
                    {
                        //测试代码
                        agilentReadString = @"30.838383";
                    }
                    else
                    {
                        agilentReadString=[agilent3458A ReadData:16];
                        
                    }
                    
                    num = [agilentReadString floatValue];
                }
                else
                {
                    NSLog(@"Other Situation");
                    [logGlobalArray addObject:[NSString stringWithFormat:@"%@: Other Situation\n",[[GetTimeDay shareInstance] getLogTime]]];
                    
                }
            }
            
        }
        
        else if([SonTestDevice isEqualToString:@"SW"])
        {
            //延迟时间
            NSLog(@"delayTime: %d", delayTime);
            
            [logGlobalArray addObject:[NSString stringWithFormat:@"%@: delayTime: %d\n",[[GetTimeDay shareInstance] getLogTime], delayTime]];
            
            if (!param.isDebug) {
                
                sleep(delayTime);
            }
        }
        
        //txt log
        [txtLogMutableArr addObject:[NSString stringWithFormat:@"%@ send command %@\n",SonTestDevice,SonTestCommand]];
        NSLog(@"SubTestDevice %@=====SubTestCommand %@",SonTestDevice,SonTestCommand);
        [logGlobalArray addObject:[NSString stringWithFormat:@"%@: SubTestDevice %@=====SubTestCommand %@\n",[[GetTimeDay shareInstance] getLogTime],SonTestDevice,SonTestCommand]];
    }
    

    
#pragma mark--------最终显示在 table 的测试项值
    
    
    testitem.value = [NSString stringWithFormat:@"%.3f",num];

    if ([testitem.testName isEqualToString:@"ON S3-S2 TO DMM"] || [testitem.testName isEqualToString:@"ON S3-S1 TO DMM"] ||[testitem.testName isEqualToString:@"ON S2-S1 TO DMM"]) {
        
        if (num > 1e6) {
            
            testitem.value = @"99999";
            
        }
        
        
    }
    
#pragma mark--------相关单位进行换算
    //单位换算
    if ([testitem.units isEqualToString: @"mV"])
    {
        testitem.value = [NSString stringWithFormat:@"%.9f",[testitem.value floatValue]*1000];
    }
    
    if ([testitem.units isEqualToString:@"nA"])
    {
        testitem.value = [NSString stringWithFormat:@"%.9f",num*1000000000];
    }
    if ([testitem.units isEqualToString:@"uA"])
    {
        testitem.value = [NSString stringWithFormat:@"%.9f",num*1000000];
    }
    
    if ([testitem.units isEqualToString:@"A"] || [testitem.units isEqualToString:@"V"] || [testitem.units isEqualToString:@"OHM"])
    {
        testitem.value = [NSString stringWithFormat:@"%.9f",num];
    }
    if ([testitem.units isEqualToString:@"mΩ"])
    {
        testitem.value = [NSString stringWithFormat:@"%.9f",num*1000];
    }
    
    
    
    

#pragma mark--------对测试出来的结果进行判断和赋值
    //上下限值对比
    
    if ((([testitem.value floatValue]>=[testitem.min floatValue]&&[testitem.value floatValue]<=[testitem.max floatValue]) || ([testitem.max isEqualToString:@"--"]&&[testitem.value floatValue]>=[testitem.min floatValue]) || ([testitem.max isEqualToString:@"--"] && [testitem.min isEqualToString:@"--"]) || ([testitem.min isEqualToString:@"--"]&&[testitem.value floatValue]<=[testitem.max floatValue]))&&![testitem.value isEqualToString:@"inf"]&&![testitem.value isEqualToString:@"nan"])
    {
        testitem.result = @"PASS";
        testItem.messageError=nil;
        [passItemsArr addObject: @"PASS"];
        ispass = YES;
    }
    else
    {
        testitem.result = @"FAIL";
        testItem.messageError=[NSString stringWithFormat:@"%@Fail",testitem.testName];
        [failItemsArr addObject:@"FAIL"];
        ispass = NO;
    }
    
    
    if (all_Pass == YES)
    {
        testitem.result = @"PASS";
        testItem.messageError=nil;
        [passItemsArr addObject: @"PASS"];
        ispass = YES;
    }
    
    //txt log
    [txtLogMutableArr addObject:[NSString stringWithFormat:@"TestValue:%@\nTestResult:%@\nEndTimer:%@\n-------------------\n",testitem.value,testitem.result,[[GetTimeDay shareInstance] getCurrentTime]]];
    
    //每次的测试项与测试标题存入可变数组中
    if (testItem.value!=nil&&testItem.testName!=nil&&testItem.min!=nil&&testItem.max!=nil) {
        [testItemValueArr addObject:testItem.value];
        [testItemTitleArr addObject: testItem.testName];
        [testItemMinLimitArr  addObject:testItem.min];
        [testItesmMaxLimitArr addObject:testItem.max];
        
    }
    else
    {
        [testItemValueArr addObject:@""];
        [testItemTitleArr addObject:@""];
        [testItemMinLimitArr  addObject:@""];
        [testItesmMaxLimitArr addObject:@""];
    }
    
    return ispass;
}

-(void)refreshTheInfoBox
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        passNumInfoTF.stringValue = @"0";
        passNumCalculateTF.stringValue = @"0%";
        failNumInfoTF.stringValue = @"0";
        failNumCalculateTF.stringValue = @"0%";
        totalNumInfo.stringValue = @"0";
        testNum = 0;
        passNum = 0;
        testCount.stringValue = @"0/0";
        SN_Collector.string = @"";
    });
    
}

#pragma mark-----Button action

- (IBAction)clickToTestPDCA:(NSButton *)sender
{
    if (all_Pass == YES)
    {
        [sender setTitle:@"all_pass_YES"];
        all_Pass = NO;
        NSLog(@"all_pass status is NO");
        [logGlobalArray addObject:@"all_pass status is NO\n"];
        return;
    }
    if (all_Pass == NO)
    {
        [sender setTitle:@"all_pass_NO"];
        all_Pass = YES;
        NSLog(@"all_pass status is YES");
        [logGlobalArray addObject:@"all_pass status is YES\n"];
        return;
    }
}

- (IBAction)clickToRefreshInfoBox:(NSButton *)sender
{
    [self refreshTheInfoBox];
}



//开始按钮
- (IBAction)start_Button_Action:(NSButton *)sender
{
    //
    
        if (index == 1000)
        {
            NSLog(@"start the action!!");
            
            _startBtn.enabled =NO;
            
            //清除数组
            [passItemsArr removeAllObjects];
            [failItemsArr removeAllObjects];
            [testItemTitleArr removeAllObjects];
            [testItemValueArr removeAllObjects];
            [testItemMinLimitArr removeAllObjects];
            [testItesmMaxLimitArr removeAllObjects];
            [testResultArr removeAllObjects];
            
            
            index = 2;
        }
        else
        {
            NSLog(@"not readly !");
            return;
        }
        
    

}


- (IBAction)ClickUploadPDCAAction:(NSButton *)sender
{
    NSLog(@"点击上传 PDCA");
}

- (IBAction)clickUpLoadSFCAction:(NSButton *)sender
{
    NSLog(@"点击上传 SFC");
}


/**
 *  必须要清除本地的存储数据,否则可能导致文件创建失败
 */
//界面消失后取消线程
-(void)viewWillDisappear
{
    //=================
    [myThrad cancel];
    myThrad = nil;
    
    //主动释放掉
    [self closeAllDevice];
    
}

-(void)viewDidDisappear{
    
    [myThrad cancel];
    myThrad = nil;
    
    //主动释放掉
    [self closeAllDevice];
    
    
    
}


//获取按钮的状态
-(void)GetSFC_PDCAState
{
    dispatch_sync(dispatch_get_main_queue(),^{
        isUpLoadSFC=[SFC_Btn state]==1?YES:NO;
        isUpLoadPDCA=[PDCA_Btn state]==1?YES:NO;
    });
}

#pragma mark----PDCA相关
//================================================
//上传pdca
//================================================
-(NSString *)GetSpecStr:(NSString *)Original thestartStr:(NSString *)startStr theendStr:(NSString *)endStr
{
    
    if([startStr length]>0 && [Original rangeOfString:startStr].length)
    {
        int sP=(int)[Original rangeOfString:startStr].location;
        sP= sP + (int)[startStr length];
        Original=[Original substringFromIndex:sP];
    }
    if([endStr length]>0 && [Original rangeOfString:endStr].length)
    {
        int eL=(int)[Original rangeOfString:endStr].location;
        return [Original substringToIndex:eL];
    }
    
    return Original;
}

BOOL stringisnumber(NSString *stringvalues){
    
    NSString *temp;
    if ([stringvalues length]) {
        for(int i=0;i<[stringvalues length];i++){
            temp=[[stringvalues substringFromIndex:i] substringToIndex:1];
            if (![@"-1234567890." rangeOfString:temp].length) {
                return FALSE;
            }
        }
    }else {
        return FALSE;
    }
    return TRUE;
}


void handleReply( IP_API_Reply reply )
{
    if ( !IP_success( reply ) )
    {
        [selfClass showAlertMessage:@"Upload PDCA data error"];
         NSLog(@"Upload PDCA data error");
        //[logGlobalArray addObject:@"Upload PDCA data error\n"];
        
        //exit(-1);
    }
    IP_reply_destroy(reply);
}



-(void)uploadPDCA_Feicui_2
{
    /**
     * info :
     *  cfailItems     ----->    all the failItems
     *  param.sw_ver   ------>  we can get the param infomation form the (Param.plist) file, like this: param.sw_ver, param.isDebug...
     *  theSN   =   importSN.stringValue
     *  itemArr ---------> All test Items  , the way to get , itemArr = [plist PlistRead:@"Station_0" Key:@"AllItems"];
     *  testItem -------->  form Item class  ,  testItem = [itemArr objectAtIndex:i],we can get different testItem ; than we have all the item infomation like this : testItem.testName/ testItem.units / testItem.min / testItem.value /testItem.max / testItem.result
     *
     */
    
    NSError  * error;
    NSData  * data=[NSData dataWithContentsOfFile:@"/vault/data_collection/test_station_config/gh_station_info.json"];
    NSDictionary * jsonDic=[[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error] objectForKey:@"ghinfo"];
    ReStaName =[jsonDic objectForKey:@"STATION_TYPE"];
    
    NSLog(@"ReStaName====%@",ReStaName);
    
    NSMutableArray *cfailItems=[[NSMutableArray alloc] initWithArray:failItemsArr];
    NSString *theSN=[[NSString alloc] initWithString:importSN.stringValue];
    
    if ([theSN length]>17) {
        
        theSN = [theSN substringToIndex:17];
    }
    
    //------------------------------- nothing to change -------------------------------------------------
    
    IP_UUTHandle UID;
    Boolean APIcheck;
    IP_TestSpecHandle testSpec;
    
    IP_API_Reply reply = IP_UUTStart(&UID);
    
    if(!IP_success(reply))
    {
        [self showAlertMessage:[NSString stringWithCString:IP_reply_getError(reply) encoding:1]];
    }
    
    IP_reply_destroy(reply);
    
    //上传版本，软件名，版本等
    handleReply(IP_addAttribute( UID, IP_ATTRIBUTE_STATIONSOFTWAREVERSION, [ [NSString stringWithFormat:@"%@",param.sw_ver] cStringUsingEncoding:1]  ));
    handleReply(IP_addAttribute( UID, IP_ATTRIBUTE_STATIONSOFTWARENAME, [ReStaName cStringUsingEncoding:1]  ));
    handleReply(IP_addAttribute( UID, IP_ATTRIBUTE_STATIONLIMITSVERSION, [[NSString stringWithFormat:@"%@",param.sw_ver] cStringUsingEncoding:1]));
    
    handleReply(IP_addAttribute( UID, IP_ATTRIBUTE_SERIALNUMBER, [theSN cStringUsingEncoding:1] ));
    
    NSLog(@"param.sw_ver=====%@",param.sw_ver);
    
    NSString *raw_zip_folder = [[NSUserDefaults standardUserDefaults] objectForKey:@"folderPathKey"];
    
    //NSLog(@"打印===========raw_zip_folder%@",raw_zip_folder);
    
    NSString* log_path = [raw_zip_folder stringByAppendingString:[NSString stringWithFormat:@"/%@_log.txt", importSN.stringValue]];
    
    //NSLog(@"%@",logGlobalArray);
    
    NSMutableString* logGlobalTxt= [NSMutableString string];
    
    for (id obj in logGlobalArray) {
        
        [logGlobalTxt appendString:[NSString stringWithFormat:@"%@\n", obj]];
        
    }
    
    [logGlobalTxt writeToFile:log_path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    
    //------------ 压缩并上传文件到服务器------------------------------
    NSString *raw_data_folder = [[NSUserDefaults standardUserDefaults] objectForKey:@"mainFolderPathKey"];
    
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sh"];
    
    
//    NSString   * zipFileName =[self cutOutStringFromStr:raw_zip_folder withDivisionString:@"/" andIndex:6];
    
    NSString *zipFileName = [NSString stringWithFormat:@"%@",importSN.stringValue];
    
    
    

    
    NSString *cmd = [NSString stringWithFormat:@"cd %@; zip -r %@.zip %@",raw_data_folder,zipFileName,zipFileName];
    
    
    NSLog(@"============cmd: %@", cmd);
    
    [logGlobalArray addObject:[NSString stringWithFormat:@"%@: ============cmd: %@\n", [[GetTimeDay shareInstance] getLogTime],cmd]];
    
    NSArray *argument = [NSArray arrayWithObjects:@"-c", [NSString stringWithFormat:@"%@", cmd], nil];
    [task setArguments: argument];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    [task launch];
    
    
    NSString *ZIP_path = [NSString stringWithFormat:@"%@%@.zip",raw_data_folder,zipFileName];
    
    NSLog(@"ZIP_FilePath == %@",ZIP_path);
    
    [logGlobalArray addObject:[NSString stringWithFormat:@"%@: ZIP_FilePath == %@\n",[[GetTimeDay shareInstance] getLogTime],ZIP_path]];
    
    
    sleep(1);
    
    int FileCount = 0;
    
    while (true) {
        
        if([[NSFileManager defaultManager] fileExistsAtPath:ZIP_path]){
            
            NSLog(@"file has been existed");
            [logGlobalArray addObject:@"file has been existed"];
            
            break;
        }
        else
        {
            NSLog(@"file has been not existed");
            [logGlobalArray addObject:@"file has been not existed"];
            FileCount++;
            
            sleep(0.5);
            if (FileCount>=3) {
                break;
            }
            
        }
       
    }
    
    
    IP_addBlob(UID, [[[NSString stringWithFormat:@"%@_%@",param.sw_name,param.sw_ver] stringByAppendingString:@"_ZIP_Log"] cStringUsingEncoding:1], [ZIP_path cStringUsingEncoding:1]);
    NSLog(@"上传zip地址***%@***",ZIP_path);
    
    
    //==========================================================================================
    //----------------------- change the loop 2017.5.25 _MK ------------------------------------
    for(int i=0;i<[itemArr count];i++)
    {
        testItem = [itemArr objectAtIndex:i];
        //---------------------------------------
        NSString *testitemNameStr = testItem.testName;
        NSString *testitemMinStr = testItem.min;
        NSString *testitemMaxStr = testItem.max;
        NSString *testitemUnitStr = testItem.units;
        NSString *testitemValueStr = testItem.value;
        
        if ([testitemUnitStr isEqualToString:@"GΩ"])
        {
            testitemUnitStr = @"GOHM";
        }
        if ([testitemUnitStr isEqualToString:@"MΩ"])
        {
            testitemUnitStr = @"MOHM";
        }
        if ([testitemUnitStr isEqualToString:@"KΩ"])
        {
            testitemUnitStr = @"KOHM";
        }
        if ([testitemUnitStr isEqualToString:@"Ω"])
        {
            testitemUnitStr = @"OHM";
        }
        if ([testitemUnitStr isEqualToString:@"%"])
        {
            testitemUnitStr = @"PERCENT";
        }
        if ([testitemUnitStr isEqualToString:@"℃"])
        {
            testitemUnitStr = @"CELSIUS";
        }
        if ([testitemUnitStr isEqualToString:@"--"])
        {
            testitemUnitStr = @"N/A";
        }
        if(testitemMaxStr==nil || [testitemMaxStr isEqualToString:@"--"])
        {
            testitemMaxStr=@"N/A";
        }
        if(testitemMinStr==nil || [testitemMinStr isEqualToString:@"--"])
        {
            testitemMinStr=@"N/A";
        }
        
        testitemNameStr = [testitemNameStr stringByReplacingOccurrencesOfString:@" " withString:@""];
        testitemMinStr = [testitemMinStr stringByReplacingOccurrencesOfString:@" " withString:@""];
        testitemMaxStr = [testitemMaxStr stringByReplacingOccurrencesOfString:@" " withString:@""];
        testitemUnitStr = [testitemUnitStr stringByReplacingOccurrencesOfString:@" " withString:@""];
        testitemValueStr=[testitemValueStr stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        //------------------------------------------
        
        testSpec=IP_testSpec_create();
        
        //--------------------- title---------------------------
        APIcheck=IP_testSpec_setTestName(testSpec, [testitemNameStr cStringUsingEncoding:1], [testitemNameStr length]);
        
        //----------------- limits ------------------------------
        APIcheck=IP_testSpec_setLimits(testSpec, [testitemMinStr cStringUsingEncoding:1], [testitemMinStr length], [testitemMaxStr cStringUsingEncoding:1], [testitemMaxStr length]);
        
        //----------------- unit ---------------------------
        APIcheck=IP_testSpec_setUnits(testSpec, [testitemUnitStr cStringUsingEncoding:1], [testitemUnitStr length]);
        
        //----------------- priority --------------------------------
        APIcheck=IP_testSpec_setPriority(testSpec, IP_PRIORITY_REALTIME);
        
        IP_TestResultHandle puddingResult=IP_testResult_create();
        
        if(NSOrderedSame==[testitemValueStr compare:@"Pass" options:NSCaseInsensitiveSearch] || NSOrderedSame==[testitemValueStr compare:@"Fail" options:NSCaseInsensitiveSearch])
        {
            testitemValueStr=@"";
        }
        
        const char *value=[testitemValueStr cStringUsingEncoding:1];
        
        int valueLength=(int)[testitemValueStr length];
        
        int result=IP_FAIL;
        
        if([testItem.result isEqualToString:@"PASS"])
        {
            result=IP_PASS;
        }
        
        if (stringisnumber(testitemValueStr))
        {
            APIcheck=IP_testResult_setValue(puddingResult, value,valueLength);
        }
        
        APIcheck=IP_testResult_setResult(puddingResult, result);
        
        if(!result)
        {
            NSString *failDes=@"";
            
            //==========errorcode@errormessage================
            if([testItem.result length]==0)
            {
                failDes=[failDes stringByAppendingString:@"N/A" ];
            }
            
            else
            {
                failDes=[failDes stringByAppendingString:testItem.messageError];
            }
            
            failDes=[failDes stringByAppendingString:@","];
            
            APIcheck=IP_testResult_setMessage(puddingResult, [failDes cStringUsingEncoding:1], [failDes length]);
        }
        
        reply=IP_addResult(UID, testSpec, puddingResult);
        
        if(!IP_success(reply))
        {
            
            [self showAlertMessage:[NSString stringWithCString:IP_reply_getError(reply) encoding:1]];
        }
        
        IP_reply_destroy(reply);
        
        IP_testResult_destroy(puddingResult);
        
        IP_testSpec_destroy(testSpec);
    }
    
    //------------------------ nothing change --------------------------------------
    IP_API_Reply doneReply=IP_UUTDone(UID);
    if(!IP_success(doneReply)){
        [self showAlertMessage:[NSString stringWithCString:IP_reply_getError(doneReply) encoding:1]];
        
        //        exit(-1);
        IP_API_Reply amiReply = IP_amIOkay(UID, [importSN.stringValue cStringUsingEncoding:1]);
        if (!IP_success(amiReply))
        {
            IP_reply_destroy(amiReply);
        }
    }
    
    IP_reply_destroy(doneReply);
    
    IP_API_Reply commitReply;
    
    if([cfailItems count]>0)
    {
        commitReply=IP_UUTCommit(UID, IP_FAIL);
    }
    else
    {
        commitReply=IP_UUTCommit(UID, IP_PASS);
    }
    
    if(!IP_success(commitReply)){}
    IP_reply_destroy(commitReply);
    IP_UID_destroy(UID);
    
}






#pragma mark--------释放所有设备
-(void)closeAllDevice
{
    //主动释放掉
    [fixtureSerial close];
    [agilent33210A CloseDevice];
    [agilent3458A CloseDevice];
    [agilent34461A CloseDevice];
    
}


#pragma mark------------------串口代理方法
-(void)serialPort:(ORSSerialPort *)serialPort didReceiveData:(NSData *)data
{
    if (serialPort==fixtureSerial)
    {
        //NSString* str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        [appendString appendString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
        
        NSLog(@"打印返回的值%@",appendString);
        
        if ([appendString containsString:@"ok"]||[appendString containsString:@"start"])
        {
            backStr =appendString;
            NSLog(@"%@: fixtureSerial backStr : %@",[[GetTimeDay shareInstance] getLogTime], backStr);
            [logGlobalArray addObject:[NSString stringWithFormat:@"fixtureSerial backStr: %@\n",backStr]];
            
            appendString=[[NSMutableString alloc]initWithString:@""];
            
            isReceive = YES;
        }
        
    }

}



#pragma mark-----------------UpdateTextView

-(void)UpdateTextView:(NSString*)strMsg andClear:(BOOL)flagClearContent andTextView:(NSTextView *)textView
{
    if (flagClearContent)
    {
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [textView setString:@""];
                       });
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           if ([[textView string]length]>0)
                           {
                               [textView insertText:[NSString stringWithFormat:@"\n%@",strMsg]];;
                           }
                           else
                           {
                               [textView setString:[NSString stringWithFormat:@"\n\n%@",strMsg]];
                           }
                           
                           [textView setTextColor:[NSColor redColor]];
                       });
    }
}


#pragma mark-------提示框的内容
-(void)showAlertMessage:(NSString *)showMessage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSAlert *alert = [NSAlert new];
        alert.messageText = @"Comfirm";
        alert.informativeText = showMessage;
        [alert addButtonWithTitle:@"YES"];
        //第一种方式，以modal的方式出现
        [alert runModal];
    });
}



#pragma mark--------------------清空数组
-(void)removeDataFromArray
{
    [passItemsArr removeAllObjects];
    [failItemsArr removeAllObjects];
    [testItemTitleArr removeAllObjects];
    [testItemValueArr removeAllObjects];
    [testItemMinLimitArr removeAllObjects];
    [testItesmMaxLimitArr removeAllObjects];
    [testResultArr removeAllObjects];
    
}



#pragma mark--------------------ORSSerialPort串口中发送指令
-(void)Fixture:(ORSSerialPort *)serialPort writeCommand:(NSString *)command
{
    NSString * commandString =[NSString stringWithFormat:@"%@\r\n",command];
    NSData    * data =[commandString dataUsingEncoding:NSUTF8StringEncoding];
    [serialPort sendData:data];
}

#pragma mark---------------------cutOutStringFromStr
-(NSString  *)cutOutStringFromStr:(NSString *)Str withDivisionString:(NSString *)diviString andIndex:(int)chooseIndex
{
    
    NSString   * numStr;
    NSArray    *   numArray =[Str componentsSeparatedByString:diviString];
    if ([numArray count] >= chooseIndex) {
        
        numStr =[numArray objectAtIndex:chooseIndex-1];
    }
    
    //numStr  1000HZ 将HZ/M/G 用“”字符替代
    numStr = [numStr stringByReplacingOccurrencesOfString:@"HZ" withString:@""];
    numStr = [numStr stringByReplacingOccurrencesOfString:@"M" withString:@""];
    numStr = [numStr stringByReplacingOccurrencesOfString:@"G" withString:@""];
    
    return numStr.length>0?numStr:@"0";
}



-(NSString *)getValueFromFixture_SendCommand:(NSString *)str
{
    [self Fixture:fixtureSerial writeCommand:str];
    isReceive = NO;
    [self whileLoopTest];
    
    NSString * regexString;
    
    if([backStr containsString:@"\r\n"]){
        
        regexString = [backStr stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
        
        regexString = [[self parseTxt:regexString] objectAtIndex:0];
        
    }
    
    if ([regexString doubleValue]==0) {
        
        NSLog(@"打印返回来的值%@",regexString);
    }
    
    backStr = @"";
    
    return regexString;
}



-(double)getValueFromFixtureCP:(double)fixtureCp andINT:(int)CpNum
{
    double ZinValue;
    
    ZinValue = 1000000/(2*3.1415926*CpNum*fixtureCp);
    
    return ZinValue;
    
}


#pragma mark ----------getValueFromJsonFile
-(NSString *)getValueFromJsonFileWithKey:(NSString *)key
{
    
    NSError  * error;
    NSData  * data=[NSData dataWithContentsOfFile:@"/vault/data_collection/test_station_config/gh_station_info.json"];
    NSDictionary * jsonDic=[[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error] objectForKey:@"ghinfo"];

    return  [jsonDic objectForKey:key];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}



#pragma  mark----------循环等待，直到数据有返回
-(void)whileLoopTest
{
    while (!isReceive) {
        
        sleep(0.001);
        NSLog(@"++++++++");
        if (isReceive) {
            
             NSLog(@"------------");
            break;
        }
    }
    
    isReceive = NO;
   
}


#pragma mark --------------超时等待,直到有数据返回
-(void)receiveDataWithTimeOut:(float)time
{
    float  timeNum = time/10;
    float  timeadd = 0;
    while (!isReceive) {
        
        sleep(0.001);
        timeadd = timeadd + 0.001;
        
        if (isReceive||timeadd>=timeNum) {
            break;
        }
    }
    isReceive = NO;
    
}


#pragma mark---------------正则表达式
-(NSArray*)parseTxt:(NSString*)content{
    
    NSString* txtContent = [NSString stringWithFormat:@"%@", content];
    
    NSString* Pattern = @".*?\\?(.*?)\\*.*?";
    
    //NSString* Pattern = @"[0-9]";
    
    NSString *pattern = [NSString stringWithFormat:@"%@", Pattern];
    
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSArray *results = [regex matchesInString:txtContent options:0 range:NSMakeRange(0, txtContent.length)];
    
    NSMutableArray* stringArray = [[NSMutableArray alloc] init];
    
    if (results.count != 0) {
        for (NSTextCheckingResult* result in results) {
            for (int i=1; i<[result numberOfRanges]; i++)
            {
                [stringArray addObject:[txtContent substringWithRange:[result rangeAtIndex:i]]];
            }
        }
    }
    
    return stringArray;
}


@end
