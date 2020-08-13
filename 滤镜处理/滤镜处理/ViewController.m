//
//  ViewController.m
//  滤镜处理
//
//  Created by xzkj on 2020/8/12.
//  Copyright © 2020 TuDou. All rights reserved.
//

#import "ViewController.h"
#import <GLKit/GLKit.h>

#define FHEIGHT [UIScreen mainScreen].bounds.size.height
#define FWIDTH [UIScreen mainScreen].bounds.size.width

typedef struct {
    GLKVector3 positionCoord; // (X, Y, Z)
    GLKVector2 textureCoord; // (U, V)
} SenceVertex;

@interface ViewController ()

//顶点、纹理数组
@property (nonatomic, assign) SenceVertex *vertices;

//上下文
@property (nonatomic, strong)EAGLContext * myContext;

//着色器ID
@property (nonatomic, assign) GLuint program;

//顶点缓冲区
@property (nonatomic, assign) GLuint vertexBuffer;

//纹理id
@property (nonatomic, assign) GLuint textureID;

// 用于刷新屏幕
@property (nonatomic, strong) CADisplayLink *displayLink;
// 开始的时间戳
@property (nonatomic, assign) NSTimeInterval startTimeInterval;


@end

@implementation ViewController

//释放
- (void)dealloc {
    //1.上下文释放
    if ([EAGLContext currentContext] == self.myContext) {
        [EAGLContext setCurrentContext:nil];
    }
    //顶点缓存区释放
    if (_vertexBuffer) {
        glDeleteBuffers(1, &_vertexBuffer);
        _vertexBuffer = 0;
    }
    //顶点数组释放
    if (_vertices) {
        free(_vertices);
        _vertices = nil;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // 移除 displayLink
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //控制器view
    [self setupControlView];
    
    //滤镜初始化
    [self filterInit];
    
    [self startFilerAnimation];
    
    // Do any additional setup after loading the view.
}


// 开始一个滤镜动画
- (void)startFilerAnimation {
    //1.判断displayLink 是否为空
    //CADisplayLink 定时器
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
    //2. 设置displayLink 的方法
    self.startTimeInterval = 0;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(timeAction)];
    
    //3.将displayLink 添加到runloop 运行循环
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop]
                           forMode:NSRunLoopCommonModes];
}

//2. 动画
- (void)timeAction {
    //DisplayLink 的当前时间撮
    if (self.startTimeInterval == 0) {
        self.startTimeInterval = self.displayLink.timestamp;
    }
    //使用program
    glUseProgram(self.program);
    //绑定buffer
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexBuffer);
    
    // 传入时间
    CGFloat currentTime = self.displayLink.timestamp - self.startTimeInterval;
    GLuint time = glGetUniformLocation(self.program, "Time");
    glUniform1f(time, currentTime);
    
    // 清除画布
    glClear(GL_COLOR_BUFFER_BIT);
    glClearColor(1, 1, 1, 1);
    
    // 重绘
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    //渲染到屏幕上
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
}





-(void)setupControlView{
    NSArray * styleButton = @[@"原图",@"原图",@"原图",@"原图",@"原图",@"原图",@"原图",@"原图"];
    UIScrollView * backView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, FHEIGHT - 150, FWIDTH, 90)];
    backView.contentSize = CGSizeMake(styleButton.count * 85, 90);
    backView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:backView];
    
    for(int i = 0; i < styleButton.count; i ++){
        UIButton * button = [[UIButton alloc]initWithFrame:CGRectMake(5 * (i + 1) + 80 * i, 5, 80, 80)];
        button.tag = i;
        button.backgroundColor = [UIColor blackColor];
        [button setTitle:styleButton[i] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(onClickButton:) forControlEvents:UIControlEventTouchUpInside];
        [backView addSubview:button];
    }
}

-(void)onClickButton:(id)sender{
    UIButton * button = (UIButton *)sender;
    switch (button.tag) {
        case 0:
        {}
            break;
            
        default:
            break;
    }
}

-(void)filterInit{
    self.myContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES3];
    [EAGLContext setCurrentContext:self.myContext];
    
    //2.开辟顶点数组内存空间
    self.vertices = malloc(sizeof(SenceVertex) * 4);
    
    //3.初始化顶点(0,1,2,3)的顶点坐标以及纹理坐标
    self.vertices[0] = (SenceVertex){{-1, 1, 0}, {0, 1}};
    self.vertices[1] = (SenceVertex){{-1, -1, 0}, {0, 0}};
    self.vertices[2] = (SenceVertex){{1, 1, 0}, {1, 1}};
    self.vertices[3] = (SenceVertex){{1, -1, 0}, {1, 0}};
    
    //创建图层
    CAEAGLLayer * layer = [[CAEAGLLayer alloc]init];
    layer.frame = CGRectMake(0, 100, FWIDTH, FWIDTH);
    layer.contentsScale = [UIScreen mainScreen].scale;
    [self.view.layer addSublayer:layer];
    
    //绑定缓冲区
    [self bindRenderLayer:layer];
    
    UIImage *image = [UIImage imageNamed:@"daitu3"];
    
    self.textureID = [self createTextureWithImage:image];
    
    //设置视口
    glViewport(0, 0, [self drawableWidth], [self drawableHeight]);
    
    //设置顶点缓冲区
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    GLsizeiptr bufferSizeBytes = sizeof(SenceVertex) * 4;
    glBufferData(GL_ARRAY_BUFFER, bufferSizeBytes, self.vertices, GL_STATIC_DRAW);
    
    //设置默认着色器
    [self setupNormalShaderProgram];
    //将顶点缓存保存，退出时才释放
    self.vertexBuffer = vertexBuffer;
    
    
}

-(void)setupNormalShaderProgram{
    //设置着色器程序
    [self setupShaderProgramWithName:@"Normal"];
}

// 初始化着色器程序
- (void)setupShaderProgramWithName:(NSString *)name{
    GLuint program = [self linkProgram:name];
    
    //use Program
    glUseProgram(program);
    
    //3. 获取Position,Texture,TextureCoords 的索引位置
    GLuint positionSlot = glGetAttribLocation(program, "Position");
    GLuint textureSlot = glGetUniformLocation(program, "Texture");
    GLuint textureCoordsSlot = glGetAttribLocation(program, "TextureCoords");
    
    //激活纹理,绑定纹理ID
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.textureID);
    
    //传入纹理sample
    glUniform1i(textureSlot, 0);
    
    //6.打开positionSlot 属性并且传递数据到positionSlot中(顶点坐标)
    glEnableVertexAttribArray(positionSlot);
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, positionCoord));
    
    //7.打开textureCoordsSlot 属性并传递数据到textureCoordsSlot(纹理坐标)
    glEnableVertexAttribArray(textureCoordsSlot);
    glVertexAttribPointer(textureCoordsSlot, 2, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, textureCoord));
    
    //8.保存program,界面销毁则释放
    self.program = program;
}

//绑定缓冲区（渲染缓冲区和帧缓冲区）
- (void)bindRenderLayer:(CALayer <EAGLDrawable> *)layer {
    //1.渲染缓存区,帧缓存区对象
    GLuint renderBuffer;
    GLuint frameBuffer;
    
    //2.获取帧渲染缓存区名称,绑定渲染缓存区以及将渲染缓存区与layer建立连接
    glGenRenderbuffers(1, &renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderBuffer);
    
}

//从图片中加载纹理
- (GLuint)createTextureWithImage:(UIImage *)image{
    CGImageRef cgImageRef = image.CGImage;
    if(!cgImageRef){
        NSLog(@"Failed to load image");
        exit(1);
    }
    GLuint width = (GLuint)CGImageGetWidth(cgImageRef);
    GLuint height = (GLuint)CGImageGetHeight(cgImageRef);

    CGRect rect = CGRectMake(0, 0, width, height);

    //获取图片的额颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    //获取图片的字节数  宽*高*4
    void *imageData = malloc(width * height * 4);

    //4.创建上下文
    /*
     参数1：data,指向要渲染的绘制图像的内存地址
     参数2：width,bitmap的宽度，单位为像素
     参数3：height,bitmap的高度，单位为像素
     参数4：bitPerComponent,内存中像素的每个组件的位数，比如32位RGBA，就设置为8
     参数5：bytesPerRow,bitmap的没一行的内存所占的比特数
     参数6：colorSpace,bitmap上使用的颜色空间  kCGImageAlphaPremultipliedLast：RGBA
     */
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

    //将图片翻转
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, rect);

    //对图片进行重新绘制，得到一张新的解压缩后的位图
    CGContextDrawImage(context, rect, cgImageRef);

    //设置图片纹理属性
    GLuint textureID;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);

    //载入纹理2D数据
    /*
    参数1：纹理模式，GL_TEXTURE_1D、GL_TEXTURE_2D、GL_TEXTURE_3D
    参数2：加载的层次，一般设置为0
    参数3：纹理的颜色值GL_RGBA
    参数4：宽
    参数5：高
    参数6：border，边界宽度
    参数7：format
    参数8：type
    参数9：纹理数据
    */
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);

    //设置纹理属性
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    //绑定纹理
    /*
     参数1：纹理维度
     参数2：纹理ID,因为只有一个纹理，给0就可以了。
     */
    glBindTexture(GL_TEXTURE_2D, 0);

    //释放context,imageData
    CGContextRelease(context);
    free(imageData);

    return textureID;
}




#pragma mark ----- 链接着色器
/**
 fileName: glsl 文件名称
 */
-(GLuint)linkProgram:(NSString *)fileName{
    //编译着色器
    GLuint vertexShader = [self compileShaderWithName:fileName type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShaderWithName:fileName type:GL_FRAGMENT_SHADER];
    
    //将着色器附着到program
    GLuint program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    
    //链接程序
    glLinkProgram(program);
    
    //检查链接状态
    GLuint linkStatus;
    glGetProgramiv(program, GL_LINK_STATUS, &linkStatus);
    if(!linkStatus){
        //链接失败
        GLchar message[512];
        glGetProgramInfoLog(program, sizeof(message), 0, &message[0]);
        NSAssert(NO, [NSString stringWithUTF8String:message]);
        exit(1);
    }
    return program;
}
#pragma mark ----- 编译着色器程序
- (GLuint)compileShaderWithName:(NSString *)name type:(GLenum)shaderType{
    NSString * shaderPath = [[NSBundle mainBundle] pathForResource:name ofType:shaderType == GL_VERTEX_SHADER ? @"vsh":@"fsh"];
    NSString * shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:nil];
    if(!shaderString){
        NSAssert(NO, @"读取shader失败");
        exit(1);
    }
    //创建shader
    GLuint shader = glCreateShader(shaderType);
    //获取shader Source
    const char *shaderStringUTF8 =[shaderString UTF8String];
    int length = (int)[shaderString length];
    glShaderSource(shader, 1, &shaderStringUTF8, &length);
    //编译shader
    glCompileShader(shader);
    
    //检查编译是否成功
    GLint compileSuccess;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compileSuccess);
    if(compileSuccess == GL_FALSE){
        //编译失败
        GLuint message[512];
        glGetShaderInfoLog(shader, sizeof(message), 0, &message[0]);
        NSString * messageString = [NSString stringWithUTF8String:message];
        NSAssert(NO, messageString);
        exit(1);
    }
    return shader;
}

//获取缓冲区的宽和高
-(GLint)drawableWidth{
    GLint backintWidth;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backintWidth);
    return backintWidth;
}

-(GLint)drawableHeight{
    GLint backingHeight;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    return backingHeight;
}

@end
