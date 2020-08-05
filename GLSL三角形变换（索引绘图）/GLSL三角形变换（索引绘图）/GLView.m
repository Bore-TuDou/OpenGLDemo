//
//  GLView.m
//  GLSL三角形变换（索引绘图）
//
//  Created by xzkj on 2020/8/4.
//  Copyright © 2020 TuDou. All rights reserved.
//

#import "GLView.h"
#import <OpenGLES/ES2/gl.h>
#import "GLESMath.h"
#import "GLESUtils.h"

@interface GLView()

@property(nonatomic, strong)CAEAGLLayer * myEagLayer;
@property(nonatomic, strong)EAGLContext * myContent;

@property(nonatomic,assign)GLuint myColorRenderBuffer;
@property(nonatomic,assign)GLuint myColorFrameBuffer;

@property(nonatomic,assign)GLuint myVertices;
@property(nonatomic,assign)GLuint myProgram;


@end

@implementation GLView
{
    float xDegree;
    float yDegree;
    float zDegree;
    BOOL bX;
    BOOL bY;
    BOOL bZ;
    NSTimer* myTimer;
}

- (IBAction)X:(id)sender {
    //开启定时器
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    //更新的是X还是Y
    bX = !bX;
}
- (IBAction)Y:(id)sender {
    //开启定时器
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    //更新的是X还是Y
    bY = !bY;
}
- (IBAction)Z:(id)sender {
    //开启定时器
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    //更新的是X还是Y
    bZ = !bZ;
}

-(void)reDegree
{
    //如果停止X轴旋转，X = 0则度数就停留在暂停前的度数.
    //更新度数
    xDegree += bX * 5;
    yDegree += bY * 5;
    zDegree += bZ * 5;
    //重新渲染
    [self render];
    
}


-(void)layoutSubviews{
    //1.设置图层
    [self setupLayer];
    
    //2.设置上下文
    [self setupContext];
    
    //3.清空缓存区
    [self deletBuffer];
    
    //4.设置renderBuffer;
    [self setupRenderBuffer];
    
    //5.设置frameBuffer
    [self setupFrameBuffer];
    
    //6.绘制
    [self render];
}

+(Class)layerClass{
    return [CAEAGLLayer class];
}

-(void)setupLayer{
    self.myEagLayer = (CAEAGLLayer *)self.layer;
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    self.myEagLayer.drawableProperties = [[NSDictionary alloc]initWithObjectsAndKeys:@(false),kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat, nil];
}

-(void)setupContext{
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES3;
    EAGLContext * content = [[EAGLContext alloc]initWithAPI:api];
    if(!content){
        NSLog(@"content init failed");
        return;
    }
    if(![EAGLContext setCurrentContext:content]){
        NSLog(@"content set failed");
    }
    self.myContent = content;
}

-(void)deletBuffer{
    glDeleteFramebuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
    glDeleteRenderbuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
}

-(void)setupRenderBuffer{
    GLuint buffer;
    glGenRenderbuffers(1, &buffer);
    self.myColorRenderBuffer = buffer;
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    [self.myContent renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
}

-(void)setupFrameBuffer{
    GLuint buffer;
    glGenFramebuffers(1, &buffer);
    self.myColorFrameBuffer = buffer;
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBuffer);
}

-(void)render{
    //清屏颜色
    glClearColor(0.f, 0.f, 0.f, 1.f);
    //清楚颜色缓冲区
    glClear(GL_COLOR_BUFFER_BIT);
    
    //设置视口
    GLfloat scale = [[UIScreen mainScreen] scale];
    CGRect react = self.frame;
    glViewport(react.origin.x * scale, react.origin.y * scale, react.size.width * scale, react.size.height * scale);
    
    //拿到着色器程序并连接
    NSString * vertFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"glsl"];
    NSString * fragFile = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"glsl"];
    
    if(self.myProgram){
        glDeleteProgram(self.myProgram);
        self.myProgram = 0;
    }
    
    self.myProgram = [self loadShader:vertFile frag:fragFile];
    
    //链接着色器程序
    glLinkProgram(self.myProgram);
    GLint linkStatus;
    glGetProgramiv(self.myProgram, GL_LINK_STATUS, &linkStatus);
    if(linkStatus == GL_FALSE){
        GLchar * message[512];
        glGetProgramInfoLog(self.myProgram, sizeof(message), 0, &message[0]);
        NSString * msg = [NSString stringWithUTF8String:message];
        NSLog(@"Error %@",msg);
        return;
    }
    glUseProgram(self.myProgram);
    
    //创建顶点数组和索引数组
    //(1)顶点数组 前3顶点值（x,y,z），后3位颜色值(RGB)
    GLfloat attrArr[] =
    {
        -0.5f, 0.5f, 0.0f,      0.0f, 0.0f, 0.5f,       0.0f, 1.0f,//左上
        0.5f, 0.5f, 0.0f,       0.0f, 0.5f, 0.0f,       1.0f, 1.0f,//右上
        -0.5f, -0.5f, 0.0f,     0.5f, 0.0f, 1.0f,       0.0f, 0.0f,//左下
        0.5f, -0.5f, 0.0f,      0.0f, 0.0f, 0.5f,       1.0f, 0.0f,//右下
        0.0f, 0.0f, 1.0f,       1.0f, 1.0f, 1.0f,       0.5f, 0.5f,//顶点
    };
    
    //(2).索引数组
    GLuint indices[] =
    {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };
    
    //判断顶点缓冲区是否为空，如果是空则申请一个缓冲区的标识
    if(self.myVertices == 0){
        glGenBuffers(1, &_myVertices);
    }
    
    //处理顶点数据：
    //首先绑定到GL_ARRAY_BUFFER标识符上
    glBindBuffer(GL_ARRAY_BUFFER, _myVertices);
    //然后将顶点数据冲cpu 赋值到 gpu
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    //将顶点数据通过myProgram中的传递到顶点着色器程序的position
    //1.glGetAttribLocation,用来获取vertex attribute的入口的.
    //2.告诉OpenGL ES,通过glEnableVertexAttribArray，
    //3.最后数据是通过glVertexAttribPointer传递过去的。
    //注意：第二参数字符串必须和shaderv.vsh中的输入变量：position保持一致
    GLuint position = glGetAttribLocation(self.myProgram, "position");
    
    //打开position通道
    glEnableVertexAttribArray(position);
    
    //设置读取方式
    //参数1：index,顶点数据的索引
    //参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
    //参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
    //参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
    //参数5：stride,连续顶点属性之间的偏移量，默认为0；
    //参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT)*8, NULL);
    
    //处理顶点的颜色值
    GLuint positionColor = glGetAttribLocation(self.myProgram, "positionColor");
    glEnableVertexAttribArray(positionColor);
    glVertexAttribPointer(positionColor, 3, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT) * 8, (float *)NULL + 3);
    
    GLuint textColor = glGetAttribLocation(self.myProgram, "textColor");
    glEnableVertexAttribArray(textColor);
    glVertexAttribPointer(textColor, 2, GL_FLOAT, GL_FALSE, sizeof(GL_FALSE) * 8, (float *)NULL + 6);
    
    //载入对应纹理
    [self setupTexture:@"daitu"];
    //对应的纹理id传入到片元着色器
    glUniform1i(glGetUniformLocation(self.myProgram, "colorMap"), 0);
    
    
    //设置投影矩阵和模型视图矩阵并传递到着色其中
    GLuint projectionMatrixSlot = glGetUniformLocation(self.myProgram, "projectionMatrix");
    GLuint modelViewMatrixSlot = glGetUniformLocation(self.myProgram, "modelViewMatrix");
    
    float width = self.frame.size.width;
    float height = self.frame.size.height;
    
    //创建一个4x4投影举证
    KSMatrix4 _projectionMatrix;
    
    //获取单元举证
    ksMatrixLoadIdentity(&_projectionMatrix);
    
    //纵横比
    float aspect = width/height;
    
    //获取透视矩阵
    /*
     参数1：矩阵
     参数2：视角，度数为单位
     参数3：纵横比
     参数4：近平面距离
     参数5：远平面距离
     参考PPT
     */
    //透视变换，视角30°
    ksPerspective(&_projectionMatrix, 30.0, aspect, 5.0f, 20.0f);
    
    //将投影矩阵传递到顶点着色器
    /*
    void glUniformMatrix4fv(GLint location,  GLsizei count,  GLboolean transpose,  const GLfloat *value);
    参数列表：
    location:指要更改的uniform变量的位置
    count:更改矩阵的个数
    transpose:是否要转置矩阵，并将它作为uniform变量的值。必须为GL_FALSE
    value:执行count个元素的指针，用来更新指定uniform变量
    */
    glUniformMatrix4fv(projectionMatrixSlot, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
    
    //创建一个模型视图矩阵
    KSMatrix4 _modelViewMatrix;
    //同样的加载一个单元矩阵
    ksMatrixLoadIdentity(&_modelViewMatrix);
    
    //沿着z平移-10；
    ksTranslate(&_modelViewMatrix, 0, 0, -10.f);
    
    //创建一个旋转举证
    KSMatrix4 _rotationMatrix;
    //压栈单元举证
    ksMatrixLoadIdentity(&_rotationMatrix);
    //旋转
    ksRotate(&_rotationMatrix, xDegree, 1.0, 0.0, 0.0);
    ksRotate(&_rotationMatrix, yDegree, 0.0, 1.0, 0.0);
    ksRotate(&_rotationMatrix, zDegree, 0.0, 0.0, 1.0);
    
    //变换矩阵相乘
    ksMatrixMultiply(&_modelViewMatrix, &_rotationMatrix, &_modelViewMatrix);
    
    //将模型视图矩阵传递到顶点着色器
    glUniformMatrix4fv(modelViewMatrixSlot, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
    
    //开启正背面剔除
    glEnable(GL_CULL_FACE);
    
    //使用索引绘图
    /*
     void glDrawElements(GLenum mode,GLsizei count,GLenum type,const GLvoid * indices);
     参数列表：
     mode:要呈现的画图的模型
                GL_POINTS
                GL_LINES
                GL_LINE_LOOP
                GL_LINE_STRIP
                GL_TRIANGLES
                GL_TRIANGLE_STRIP
                GL_TRIANGLE_FAN
     count:绘图个数
     type:类型
             GL_BYTE
             GL_UNSIGNED_BYTE
             GL_SHORT
             GL_UNSIGNED_SHORT
             GL_INT
             GL_UNSIGNED_INT
     indices：绘制索引数组

     */
    glDrawElements(GL_TRIANGLES, sizeof(indices) / sizeof(indices[0]), GL_UNSIGNED_INT, indices);
    
    //要求本地窗口系统显示OpenGL ES渲染<目标>
    [self.myContent presentRenderbuffer:GL_RENDERBUFFER];
    
    
    
}

//从图片中加载纹理
- (GLuint)setupTexture:(NSString *)fileName{
    CGImageRef spriteImage = (CGImageRef)[UIImage imageNamed:fileName].CGImage;
    if(!spriteImage){
        NSLog(@"图片加载失败");
        return 0;
    }
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    //获取图片的字节数(宽*高*4（RGBA）)
    GLubyte * spriteData = (GLubyte *)calloc(width * height * 4, sizeof(GLubyte));
    
    //创建上下文
    /*
    参数1：data,指向要渲染的绘制图像的内存地址
    参数2：width,bitmap的宽度，单位为像素
    参数3：height,bitmap的高度，单位为像素
    参数4：bitPerComponent,内存中像素的每个组件的位数，比如32位RGBA，就设置为8
    参数5：bytesPerRow,bitmap的没一行的内存所占的比特数
    参数6：colorSpace,bitmap上使用的颜色空间
    参数7：kCGImageAlphaPremultipliedLast：RGBA
    */
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width * 4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);

    
    //在CGContextRef上--> 将图片绘制出来
    CGRect rect = CGRectMake(0, 0, width, height);
    
    CGContextTranslateCTM(spriteContext, 0, height);
    CGContextScaleCTM(spriteContext, 1.0, -1.0);
    CGContextDrawImage(spriteContext, rect, spriteImage);
    
    //使用默认方式绘制
    CGContextDrawImage(spriteContext, rect, spriteImage);
    
    //绘制完成后释放上下文
    CGContextRelease(spriteContext);
    
    //绑定纹理到默认的纹理id
    glBindTexture(GL_TEXTURE_2D, 0);
    
    //设置纹理属性
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    float fw = width, fh = height;
    
    //载入纹理
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    //释放spriteData
    free(spriteData);
    return 0;
}

-(GLuint)loadShader:(NSString *)vert frag:(NSString *)frag{
    //创建两个临时变量（顶点着色器和片元着色器）
    GLuint vshader,fshader;
    //创建一个program
    GLuint program = glCreateProgram();
    //编译着色器代码
    [self compileShader:&vshader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fshader type:GL_FRAGMENT_SHADER file:frag];
    
    //将着色器附加在程序上
    glAttachShader(program, vshader);
    glAttachShader(program, fshader);
    
    //附加到程序之后就可以删除着色器了（因为已经没有用了）
    glDeleteShader(vshader);
    glDeleteShader(fshader);
    
    return program;
}

//链接shader
-(void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file{
    //读取文件中的字符串并转换成C语言字符串
    NSString * content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    const GLchar * source = (GLchar *)[content UTF8String];
    
    //根据type创建着色器
    *shader = glCreateShader(type);
    
    //将顶点着色器源码附加到着色器对象上。
    glShaderSource(*shader, 1, &source, NULL);
    
    //将做色漆源代码编译成目标代码
    glCompileShader(*shader);
}
@end
