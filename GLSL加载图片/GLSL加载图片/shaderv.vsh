//顶点坐标
attribute vec4 position;
//纹理坐标（应为片元着色器无法接收到通过attribute传递的坐标信息，所以只能先传到顶点着色器然后桥接给片元着色器）
attribute vec2 textCoordinate;
//桥接纹理坐标参数
varying lowp vec2 varyTextCoord;

//这里有多少个顶点main函数就会执行多少次
void main()
{
    varyTextCoord = textCoordinate;
    //gl_Position内建变量赋值就好
    gl_Position = position;
}
