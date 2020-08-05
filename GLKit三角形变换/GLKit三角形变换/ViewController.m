//
//  ViewController.m
//  GLKit三角形变换
//
//  Created by xzkj on 2020/8/5.
//  Copyright © 2020 TuDou. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property(nonatomic, strong)GLKBaseEffect *mEffect;
@property (nonatomic, strong)EAGLContext *mContext;

@property(nonatomic, assign)int count;

//旋转的度数
@property(nonatomic, assign)float xDegree;
@property(nonatomic, assign)float yDegree;
@property(nonatomic, assign)float zDegree;

//是否旋转
@property (nonatomic, assign) BOOL XB;
@property (nonatomic, assign) BOOL YB;
@property (nonatomic, assign) BOOL ZB;

@end

@implementation ViewController
{
    dispatch_source_t timer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupContext];
    [self render];
    // Do any additional setup after loading the view.
}

-(void)render{
    GLfloat attrArr[] =
    {
        -0.5f, 0.5f, 0.0f,      1.0f, 0.0f, 1.0f,       0.0f, 1.0f,//左上
        0.5f, 0.5f, 0.0f,       1.0f, 0.0f, 1.0f,       1.0f, 1.0f,//右上
        -0.5f, -0.5f, 0.0f,     1.0f, 1.0f, 1.0f,       0.0f, 0.0f,//左下

        0.5f, -0.5f, 0.0f,      1.0f, 1.0f, 1.0f,       1.0f, 0.0f,//右下
        0.0f, 0.0f, 1.0f,       0.0f, 1.0f, 0.0f,       0.5f, 0.5f,//顶点
    };
    
    //2.绘图索引
    GLuint indices[] =
    {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };
    self.count = sizeof(indices)/sizeof(GLuint);
    
    GLuint buffer;
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    //将顶点数据copy到gpu
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    //将索引数据拷贝到gpu
    GLuint index;
    glGenBuffers(1, &index);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_DYNAMIC_DRAW);
    
    //开启通道并设置数据读取方式
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT) * 8, NULL);
    
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT) * 8, (float *)NULL + 3);
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT) * 8, (float *)NULL + 6);
    
    //读取纹理
    NSString *filePath = [[NSBundle mainBundle]pathForResource:@"daitu" ofType:@"jpg"];
    NSDictionary * option = [[NSDictionary alloc]initWithObjectsAndKeys:@"1",GLKTextureLoaderOriginBottomLeft, nil];
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:option error:nil];
    
    self.mEffect = [[GLKBaseEffect alloc]init];
    self.mEffect.texture2d0.enabled = GL_TRUE;
    self.mEffect.texture2d0.name = textureInfo.name;
    
    CGSize size = self.view.frame.size;
    //纵横比
    float aspect = fabs(size.width/size.height);
    GLKMatrix4 projextionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90.0), aspect, 0.1, 100.0f);
    self.mEffect.transform.projectionMatrix = projextionMatrix;
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0, 0, -2);
    self.mEffect.transform.modelviewMatrix = modelViewMatrix;
    
    //定时器: -> GCD
    double seconds = 0.1;
    timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC, 0.0);
    dispatch_source_set_event_handler(timer, ^{

        self.xDegree += 0.1f * self.XB;
        self.yDegree += 0.1f * self.YB;
        self.zDegree += 0.1f * self.ZB;

    });
    dispatch_resume(timer);
    
}



//设置上下文
-(void)setupContext{
    self.mContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES3];
    GLKView * view = (GLKView *)self.view;
    view.context = self.mContext;
    //设置颜色缓冲区
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    //设置深度缓冲区
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    [EAGLContext setCurrentContext:self.mContext];
    
    //开启深度测试
    glEnable(GL_DEPTH_TEST);
    
}

//更新的代理方法（）
-(void)update{
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0, 0, -2.5);
    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, self.xDegree);
    modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, self.yDegree);
    modelViewMatrix = GLKMatrix4RotateZ(modelViewMatrix, self.zDegree);
    
    self.mEffect.transform.modelviewMatrix = modelViewMatrix;
}

//绘制代理方法
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    //清屏设置背景色
    glClearColor(0, 0, 0, 1);
    //清除缓冲区
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    //准备绘制
    [self.mEffect prepareToDraw];
    glDrawElements(GL_TRIANGLES, self.count, GL_UNSIGNED_INT, 0);
}

- (IBAction)X:(id)sender {
    _XB = !_XB;
}

- (IBAction)Y:(id)sender {
    _YB = !_YB;
}

- (IBAction)Z:(id)sender {
    _ZB = !_ZB;
}
@end
