//
//  GLView.m
//  GLSL加载图片
//
//  Created by xzkj on 2020/7/31.
//  Copyright © 2020 TuDou. All rights reserved.
//

#import "GLView.h"
#import <OpenGLES/ES2/gl.h>

@interface GLView()

//在iOS和tvOS上绘制OpenGL ES内容的图层，继承与CALayer
@property(nonatomic,strong)CAEAGLLayer *myEagLayer;

//上下文
@property(nonatomic,strong)EAGLContext *myContext;

@property(nonatomic,assign)GLuint myColorRenderBuffer;
@property(nonatomic,assign)GLuint myColorFrameBuffer;

//自定义着色器id
@property(nonatomic,assign)GLuint myPrograme;

@end

@implementation GLView

-(void)layoutSubviews{
    
    //设置图层
    [self setupLayer];
    
    //设置上下文
    [self setupContext];
    
    //3.清空缓存区
    [self deleteRenderAndFrameBuffer];
    
    //4.设置RenderBuffer
    [self setupRenderBuffer];
    
    //5.设置FrameBuffer
    [self setupFrameBuffer];
    
    //6.开始绘制
    [self renderLayer];
    
    
}

-(void)setupContext{
    //指定OpenGL ES 渲染api版本
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    //创建上下文
    EAGLContext *context = [[EAGLContext alloc]initWithAPI:api];
    //判断是否创建成功
    if(!context){
        NSLog(@"Create context failed!");
        return;
    }
    //设置图形的上下文
    if(![EAGLContext setCurrentContext:context]){
        NSLog(@"setCurrentContext failed!");
        return;
    }
    //赋值上下文，将局部context变成全局的
    self.myContext = context;
    
}

+(Class)layerClass{
    return [CAEAGLLayer class];
}
-(void)setupLayer{
    //创建特殊图层
    //重写layerClass，将GLView返回的图层从CALayer替换成CAEAGLLayer
    self.myEagLayer = (CAEAGLLayer *)self.layer;
    
    //设置scale
    [self setContentScaleFactor:[[UIScreen mainScreen]scale]];
    
    //设置描述属性，这里设置不维持渲染内容以及颜色格式为RGBA8
    /*
     kEAGLDrawablePropertyRetainedBacking  表示绘图表面显示后，是否保留其内容。
     kEAGLDrawablePropertyColorFormat
         可绘制表面的内部颜色缓存区格式，这个key对应的值是一个NSString指定特定颜色缓存区对象。默认是kEAGLColorFormatRGBA8；
     
         kEAGLColorFormatRGBA8：32位RGBA的颜色，4*8=32位
         kEAGLColorFormatRGB565：16位RGB的颜色，
         kEAGLColorFormatSRGBA8：sRGB代表了标准的红、绿、蓝，即CRT显示器、LCD显示器、投影机、打印机以及其他设备中色彩再现所使用的三个基本色素。sRGB的色彩空间基于独立的色彩坐标，可以使色彩在不同的设备使用传输中对应于同一个色彩坐标体系，而不受这些设备各自具有的不同色彩坐标的影响。
     */
    
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:@false,kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat, nil];
}

//清空缓冲区
-(void)deleteRenderAndFrameBuffer{
    /*
    buffer分为frame buffer 和 render buffer2个大类。
    其中frame buffer 相当于render buffer的管理者。
    frame buffer object即称FBO。
    render buffer则又可分为3类。colorBuffer、depthBuffer、stencilBuffer。
    */
    glDeleteBuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
    glDeleteBuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
}

-(void)setupRenderBuffer{
    //定义一个缓冲区的ID
    GLuint buffer;
    
    //申请一个缓冲的的标志
    glGenRenderbuffers(1, &buffer);
    self.myColorRenderBuffer = buffer;
    
    //将标识符绑定到GL_RENDERBUFFER
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    
    //5.将可绘制对象drawable object's  CAEAGLLayer的存储绑定到OpenGL ES renderBuffer对象
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
    
}

-(void)setupFrameBuffer{
    //定义一个缓冲区ID
    GLuint buffer;
    
    //申请一个缓冲区的标志
    glGenFramebuffers(1, &buffer);
    self.myColorFrameBuffer = buffer;
    
    //绑定
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    
    /*生成帧缓存区之后，则需要将renderbuffer跟framebuffer进行绑定，
     调用glFramebufferRenderbuffer函数进行绑定到对应的附着点上，后面的绘制才能起作用
     */
    
    //将渲染缓存区myColorRenderBuffer 通过glFramebufferRenderbuffer函数绑定到 GL_COLOR_ATTACHMENT0上。
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBuffer);
    
}


//
-(void)renderLayer{
    //首先设置背景色
    glClearColor(0.3f, 0.6f, 0.6f, 1.0f);
    
    //清楚对应缓冲区
    glClear(GL_COLOR_BUFFER_BIT);
    
    //设置视口
    CGFloat scale = [[UIScreen mainScreen]scale];
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    
    //读取片元着色器和顶点着色器
    NSString * vertFile = [[NSBundle mainBundle]pathForResource:@"shaderv" ofType:@"vsh"];
    NSString * fragFile = [[NSBundle mainBundle]pathForResource:@"shaderf" ofType:@"fsh"];
    
    self.myPrograme = [self loadShaders:vertFile Withfrag:fragFile];
    
    //链接道程序
    glLinkProgram(self.myPrograme);
    GLint linkStatus; //链接状态
    glGetProgramiv(self.myPrograme, GL_LINK_STATUS, &linkStatus);
    if(linkStatus == GL_FALSE){
        //连接失败打印链接信息
        GLchar * message[512];
        glGetProgramInfoLog(self.myPrograme, sizeof(message), 0, &message[0]);
        NSString *messageString = [NSString stringWithUTF8String:message];
        NSLog(@"Program Link Error:%@",messageString);
        return;
    }
    
    //使用program
    glUseProgram(self.myPrograme);
    
    //设置顶点、纹理坐标
    //前3个是顶点坐标，后2个是纹理坐标
    GLfloat attrArr[] =
    {
        0.8f, -0.4f, -1.0f,     1.0f, 0.0f,
        -0.8f, 0.4f, -1.0f,     0.0f, 1.0f,
        -0.8f, -0.4f, -1.0f,    0.0f, 0.0f,
        
        0.8f, 0.4f, -1.0f,      1.0f, 1.0f,
        -0.8f, 0.4f, -1.0f,     0.0f, 1.0f,
        0.8f, -0.4f, -1.0f,     1.0f, 0.0f,
    };
    
    //处理顶点数据
    //1.定义顶点缓冲区
    GLuint attriBuffer;
    //2.申请缓冲区标识
    glGenBuffers(1, &attriBuffer);
    //3.绑定（将attriBuffer绑定到GL_ARRAY_BUFFER标识符上）
    glBindBuffer(GL_ARRAY_BUFFER, attriBuffer);
    //将顶点数据从CPU copy到gpu
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    //将顶点数据通过myPrograme中的传递到顶点着色程序的position
    //1.glGetAttribLocation,用来获取vertex attribute的入口的.
    //2.告诉OpenGL ES,通过glEnableVertexAttribArray，
    //3.最后数据是通过glVertexAttribPointer传递过去
    
    //(1)注意：第二参数字符串必须和shaderv.vsh中的输入变量：position保持一致
    GLuint position = glGetAttribLocation(self.myPrograme, "position");
    
    //(2).设置合适的格式从buffer里面读取数据
    glEnableVertexAttribArray(position);
    
    //(3).设置读取方式
    //参数1：index,顶点数据的索引
    //参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
    //参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
    //参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
    //参数5：stride,连续顶点属性之间的偏移量，默认为0；
    //参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
    
    //处理纹理数据
    GLuint textCoor = glGetAttribLocation(self.myPrograme, "textCoordinate");
    glEnableVertexAttribArray(textCoor);
    glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (float *)NULL + 3);
    
    //加载纹理
    [self setupTexture:@"daitu"];
    
    //设置纹理采样器sampler2D
    glUniform1i(glGetUniformLocation(self.myPrograme, "colorMap"), 0);
    
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    //从渲染缓冲区显示到屏幕上
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
    
    
}

//从图片中加载纹理
- (GLuint)setupTexture:(NSString *)fileName{
    //将UIImage转成CGImageRef
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    
    //判断图片是否获取成功
    if(!spriteImage){
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    //读取图片的大小
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    //获取图片字节数（宽乘高乘4（一个颜色值占用四字节））
    GLubyte * spriteData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte));
    
    //创建上下文
    /*
     参数1：data,指向要渲染的绘制图像的内存地址
     参数2：width,bitmap的宽度，单位为像素
     参数3：height,bitmap的高度，单位为像素
     参数4：bitPerComponent,内存中像素的每个组件的位数，比如32位RGBA，就设置为8
     参数5：bytesPerRow,bitmap的没一行的内存所占的比特数
     参数6：colorSpace,bitmap上使用的颜色空间  kCGImageAlphaPremultipliedLast：RGBA
     */
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);

    //在CGContextRef上--> 将图片绘制出来
    /*
     CGContextDrawImage 使用的是Core Graphics框架，坐标系与UIKit 不一样。UIKit框架的原点在屏幕的左上角，Core Graphics框架的原点在屏幕的左下角。
     CGContextDrawImage
     参数1：绘图上下文
     参数2：rect坐标
     参数3：绘制的图片
     */
    CGRect react = CGRectMake(0, 0, width, height);
    
    //使用默认方式绘制
    CGContextDrawImage(spriteContext, react, spriteImage);
    
    //画图完毕就释放上下文
    CGContextRelease(spriteContext);
    
    //绑定纹理到默认的纹理ID
    //如果只有一个纹理的话可以不用定义ID 然后激活，默认0是激活状态所以可以用0
    glBindTexture(GL_TEXTURE_2D, 0);
    
    //设置纹理属性
    /*
     参数1：纹理维度
     参数2：线性过滤、为s,t坐标设置模式
     参数3：wrapMode,环绕模式
     */
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    float fw = width, fh = height;
    
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
     glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    //释放spriteData
    free(spriteData);
    return 0;
    
}


/**
 创建一个顶点着色器对象和一个片元着色器对象
 将源代码连接到每个着色器对象
 编译着色器对象
 创建一个程序对象
 将编译后的着色器对象连接到程序对象
 */
-(GLuint)loadShaders:(NSString *)vert Withfrag:(NSString *)frag{
    //1.创建两个临时的着色器对象
    GLuint verShader,fragShader;
    //创建一个程序program
    GLuint program = glCreateProgram();
    //2.编译两个着色器
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    //3.创建最终程序(将编译后的着色器对象连接到程序对象)
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    //4.此时着色器已经添加到程序上了了已经不需要了所以释放
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    return program;
}

//编译shader
/**
 shader 着色器对象
 type 着色器类型
 file 着色器代码（就是一个字符串的路径）
 */
- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file{
    //1.先读取文件路径的字符串(就是着色器代码)
    NSString * content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    //转换一下字符串类型（OC字符串类型转成C++字符串类型）
    const GLchar *source = (GLchar *)[content UTF8String];
    
    //2.根据类型来创建着色器
    *shader = glCreateShader(type);
    
    //3.将着色的源码附着在着色器对象上面
    //参数1：shader,要编译的着色器对象 *shader
    //参数2：numOfStrings,传递的源码字符串数量 1个
    //参数3：strings,着色器程序的源码（真正的着色器程序源码）
    //参数4：lenOfStrings,长度，具有每个字符串长度的数组，或NULL，这意味着字符串是NULL终止的
    glShaderSource(*shader, 1, &source, NULL);
    
    //4.将着色器源码编译成目标代码
    glCompileShader(*shader);
    
}

@end
