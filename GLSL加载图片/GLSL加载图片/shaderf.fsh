//首先定义所有的顶点信息都是高精度的
precision highp float;
//用来接收顶点着色器传递的参数（切记参数要和顶点着色器声明的一样）
varying lowp vec2 varyTextCoord;
//接收客户端传递的纹理信息（其实就是每个像素的颜色值）
uniform sampler2D colorMap;

//这里又多少个像素点就会执行所少次
void main()
{
    gl_FragColor = texture2D(colorMap, varyTextCoord);
}
