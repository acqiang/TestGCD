//
//  ViewController.m
//  testGCD
//
//  Created by qiang on 16/3/9.
//  Copyright © 2016年 acqiang. All rights reserved.
//

#import "ViewController.h"

@interface ViewController (){
    dispatch_queue_t ticketQueue;
}
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) UIImage *image1;
@property (nonatomic, strong) UIImage *image2;


@property (nonatomic, strong) NSThread *thread1;
@property (nonatomic, strong) NSThread *thread2;
@property (nonatomic, strong) NSThread *thread3;
/**
 *  剩余票数
 */
@property (nonatomic, assign) NSInteger leftTicketCount;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.leftTicketCount = 50;
    ticketQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.thread1 = [[NSThread alloc] initWithTarget:self selector:@selector(saleTicket2) object:nil];
    self.thread1.name = @"1号窗口";
    
    self.thread2 = [[NSThread alloc] initWithTarget:self selector:@selector(saleTicket2) object:nil];
    self.thread2.name = @"2号窗口";
    
    self.thread3 = [[NSThread alloc] initWithTarget:self selector:@selector(saleTicket2) object:nil];
    self.thread3.name = @"3号窗口";
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    //    [self testGCDForApply];
//    [self testGCDSafe];
    [self testGCDQueueGroup];
    
}

/**
 *  主队列(不能用---会卡死)
 *  例1
 */
- (void)testSyncMainQueue
{
    NSLog(@"download之前----%@",[NSThread currentThread]);
    
    // 1.主队列(添加到主队列中的任务，都会自动放到主线程中去执行)
    dispatch_queue_t queue = dispatch_get_main_queue();
    
    // 2.添加 任务 到主队列中 异步 执行
    dispatch_sync(queue, ^{
        NSLog(@"-----download1---%@", [NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"-----download2---%@", [NSThread currentThread]);
    });
    
    
    NSLog(@"download之后----%@",[NSThread currentThread]);
}

/**
 *  异步执行
 *  串行执行（一个任务执行完毕后再执行下一个任务）
 *  会创建线程，一般只开1条线程
 ＊ 例2
 */
- (void)testAsyncSerialQueue
{
    // 1.创建一个串行队列
    dispatch_queue_t queue = dispatch_queue_create("testAsync.SerialQueue", NULL);
    
    NSLog(@"download之前----%@",[NSThread currentThread]);
    // 2.异步执行
    dispatch_async(queue, ^{
        
        NSLog(@"sync download之前----%@",[NSThread currentThread]);
        
        dispatch_sync(queue, ^{
            NSLog(@"sync download----%@",[NSThread currentThread]);
        });
        
        NSLog(@"sync download之后----%@",[NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"async download2----%@",[NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"async download3----%@",[NSThread currentThread]);
    });
    NSLog(@"async download 之后----%@",[NSThread currentThread]);
}

/**
 *   异步执行（最常用）
 *  并发队列
 *  会创建线程，一般同时开多条
 *  例3
 */
- (void)testAsyncGlobalQueue
{
    // 并发队列
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    //异步 执行
    dispatch_async(queue, ^{
        NSLog(@"-----download1---%@", [NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"-----download2---%@", [NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"-----download3---%@", [NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"-----download4---%@", [NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"-----download5---%@", [NSThread currentThread]);
    });
}


/**
 *  并发队列，同步执行
 *  串行执行（一个任务执行完毕后再执行下一个任务）
 *  不会创建线程
 *  并发队列失去了并发的功能
 *  例4
 */
- (void)testSyncGlobalQueue
{
    // 并发队列
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    // 同步执行
    dispatch_sync(queue, ^{
        NSLog(@"-----download1---%@", [NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"-----download2---%@", [NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"-----download3---%@", [NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"-----download4---%@", [NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"-----download5---%@", [NSThread currentThread]);
    });
}

/**
 *  串行队列，同步执行
 *  不会创建线程
 *  串行执行（一个任务执行完毕后再执行下一个任务）
 *  例5
 */
- (void)testSyncSerialQueue
{
    //串行队列
    dispatch_queue_t queue = dispatch_queue_create("testSync.SerialQueue", NULL);
    
    //同步执行
    dispatch_sync(queue, ^{
        NSLog(@"-----download1---%@", [NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"-----download2---%@", [NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"-----download3---%@", [NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"-----download4---%@", [NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"-----download5---%@", [NSThread currentThread]);
    });
}



/** 1.分别下载2张图片：大图片、LOGO
 *  2.合并2张图片
 *  3.显示到一个imageView身上
 */
-(void)testGCDQueueGroup{
    {
        // 1.队列组
        dispatch_group_t group = dispatch_group_create();
        // 创建队列
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        // 2.使用队列组的异步方法，下载库里的图片
        __block UIImage *image1 = nil;
        dispatch_group_async(group, queue, ^{
            NSURL *url1 = [NSURL URLWithString:@"http://i2.hoopchina.com.cn/u/1306/04/318/17056318/62affa38_530x.jpg"];
            NSData *data1 = [NSData dataWithContentsOfURL:url1];
            image1 = [UIImage imageWithData:data1];
        });
        
        // 3.使用队列组的异步方法，下载百度的logo
        __block UIImage *image2 = nil;
        dispatch_group_async(group, queue, ^{
            NSURL *url2 = [NSURL URLWithString:@"http://su.bdimg.com/static/superplus/img/logo_white_ee663702.png"];
            NSData *data2 = [NSData dataWithContentsOfURL:url2];
            image2 = [UIImage imageWithData:data2];
        });
        
        // 4.合并图片 (保证执行完组里面的所有任务之后，再执行notify函数里面的block)
        dispatch_group_notify(group, queue, ^{
            // 开启一个位图上下文
            UIGraphicsBeginImageContextWithOptions(image1.size, NO, 0.0);
            
            // 绘制第1张图片
            CGFloat image1W = image1.size.width;
            CGFloat image1H = image1.size.height;
            [image1 drawInRect:CGRectMake(0, 0, image1W, image1H)];
            
            // 绘制第2张图片
            CGFloat image2W = image2.size.width * 0.5;
            CGFloat image2H = image2.size.height * 0.5;
            CGFloat image2Y = image1H - image2H;
            [image2 drawInRect:CGRectMake(0, image2Y, image2W, image2H)];
            
            // 得到上下文中的图片
            UIImage *fullImage = UIGraphicsGetImageFromCurrentImageContext();
            
            // 结束上下文
            UIGraphicsEndImageContext();
            
            // 5.回到主线程显示图片
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = fullImage;
            });
        });
    }
}


-(void)testGCDBarrierAsync{
    NSLog(@"begin ---%@",[NSThread currentThread]);
    dispatch_queue_t queue = dispatch_queue_create("testGCD.BarrierAsync", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:2];
        NSLog(@"dispatch_async1");
    });
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:5];
        NSLog(@"dispatch_async2");
    });
    dispatch_barrier_async(queue, ^{
        NSLog(@"dispatch_barrier_async");
        [NSThread sleepForTimeInterval:5];
        
    });
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:1];
        NSLog(@"dispatch_async3");
    });
}

-(void)testGCDBarrierSync{
    NSLog(@"begin ---%@",[NSThread currentThread]);
    dispatch_queue_t queue = dispatch_queue_create("testGCD.BarrierSync", DISPATCH_QUEUE_CONCURRENT);
    dispatch_sync(queue, ^{
        [NSThread sleepForTimeInterval:2];
        NSLog(@"dispatch_Sync1");
    });
    dispatch_sync(queue, ^{
        [NSThread sleepForTimeInterval:5];
        NSLog(@"dispatch_Sync2");
    });
    dispatch_barrier_sync(queue, ^{
        NSLog(@"dispatch_barrier_Sync");
        [NSThread sleepForTimeInterval:5];
        
    });
    dispatch_sync(queue, ^{
        [NSThread sleepForTimeInterval:3];
        NSLog(@"dispatch_Sync3");
    });
}

-(void)testGCDForApply{
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_apply(5, queue, ^(size_t index) {
        // 执行5次
        NSLog(@"testGCDForApply");
    });
}

/**线程安全例子
 
 */
-(void)testGCDSafe{
    [self.thread1 start];
    [self.thread2 start];
    [self.thread3 start];
}

/**
 *  卖票，互斥锁
 */
- (void)saleTicket
{
    while (1) {
        // ()小括号里面放的是锁对象
        @synchronized(self) { // 开始加锁
            NSInteger count = self.leftTicketCount;
            if (count > 0) {
                [NSThread sleepForTimeInterval:0.05];
                
                self.leftTicketCount = count - 1;
                NSLog(@"线程名:%@,售出1,剩余票数是:%ld,",[[NSThread currentThread] name],(long)self.leftTicketCount);
            } else {
                return; // 退出循环
            }
        } // 解锁
    }
}

- (void)saleTicket2
{
    while (1) {
        dispatch_sync(ticketQueue, ^{
            NSInteger count = self.leftTicketCount;
            if (count > 0) {
                
                [NSThread sleepForTimeInterval:0.05];
                
                self.leftTicketCount = self.leftTicketCount = count - 1;;
                NSLog(@"线程名:%@,售出1,剩余票数是:%ld,",[[NSThread currentThread] name],(long)self.leftTicketCount);
            }else{
                return ;
            }
        });
    }
}

@end
