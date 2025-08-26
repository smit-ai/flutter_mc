import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'dart:typed_data';

ByteData float32(List<double> values) {
  return Float32List.fromList(values).buffer.asByteData();
}

ByteData uint16(List<int> values) {
  return Uint16List.fromList(values).buffer.asByteData();
}

ByteData uint32(List<int> values) {
  return Uint32List.fromList(values).buffer.asByteData();
}

ByteData float32Mat(Matrix4 matrix) {
  return Float32List.fromList(matrix.storage).buffer.asByteData();
}

void setColorBlend(gpu.RenderPass pass){
  pass.setColorBlendEnable(true);
  pass.setColorBlendEquation(gpu.ColorBlendEquation(
      colorBlendOperation: gpu.BlendOperation.add,
      sourceColorBlendFactor: gpu.BlendFactor.one,
      destinationColorBlendFactor: gpu.BlendFactor.oneMinusSourceAlpha,
      alphaBlendOperation: gpu.BlendOperation.add,
      sourceAlphaBlendFactor: gpu.BlendFactor.one,
      destinationAlphaBlendFactor: gpu.BlendFactor.oneMinusSourceAlpha));
}

final cubeVertices=float32(<double>[
  -1, -1, -1,  //
  1, -1, -1,  //
  1, 1, -1,  //
  -1, 1, -1,  //
  -1, -1, 1,  //
  1, -1, 1,  //
  1, 1, 1,  //
  -1, 1, 1,  //
]);
final cubeVerticesWithTexCoords=float32(<double>[
  -1, -1, -1, 0, 1,  //
  1, -1, -1, 1, 1,  //
  1, 1, -1, 1, 0,  //
  -1, 1, -1, 0, 0,  //
  -1, -1, 1, 0, 1,  //
  1, -1, 1, 1, 1,  //
  1, 1, 1, 1, 0,  //
  -1, 1, 1, 0, 0,  //
]);
final cubeIndices=uint16(<int>[
  0, 1, 3, 3, 1, 2, //
  1, 5, 2, 2, 5, 6, //
  5, 4, 6, 6, 4, 7, //
  4, 0, 7, 7, 0, 3, //
  3, 2, 7, 7, 2, 6, //
  4, 5, 0, 0, 5, 1, //
]);
// 定义纹理图集UV分区常量（三等分）
const double topUVStart = 0.0;
const double topUVEnd = 1/3;
const double sideUVStart = 1/3;
const double sideUVEnd = 2/3;
const double bottomUVStart = 2/3;
const double bottomUVEnd = 1.0;


const double radius=0.5;
// 草方块顶点数据列表
// 每个顶点包含: x, y, z, 法线x, 法线y, 法线z, uvX, uvY
final List<double> blockVertices = [
  // 前面（侧面纹理）+z
  -radius, -radius,  radius,  0.0,  0.0,  1.0,  sideUVStart, 1.0,
  -radius,  radius,  radius,  0.0,  0.0,  1.0,  sideUVStart, 0.0,
  radius,  radius,  radius,  0.0,  0.0,  1.0,  sideUVEnd,   0.0,
  radius,  radius,  radius,  0.0,  0.0,  1.0,  sideUVEnd,   0.0,
  radius, -radius,  radius,  0.0,  0.0,  1.0,  sideUVEnd,   1.0,
  -radius, -radius,  radius,  0.0,  0.0,  1.0,  sideUVStart, 1.0,

  // 后面（侧面纹理）-z
  -radius, -radius, -radius,  0.0,  0.0, -1.0,  sideUVStart, 1.0,
  radius, -radius, -radius,  0.0,  0.0, -1.0,  sideUVEnd,   1.0,
  radius,  radius, -radius,  0.0,  0.0, -1.0,  sideUVEnd,   0.0,
  radius,  radius, -radius,  0.0,  0.0, -1.0,  sideUVEnd,   0.0,
  -radius,  radius, -radius,  0.0,  0.0, -1.0,  sideUVStart, 0.0,
  -radius, -radius, -radius,  0.0,  0.0, -1.0,  sideUVStart, 1.0,

  // 左面（侧面纹理）-x
  -radius,  radius,  radius, -1.0,  0.0,  0.0,  sideUVStart, 0.0,
  -radius, -radius,  radius, -1.0,  0.0,  0.0,  sideUVStart, 1.0,
  -radius, -radius, -radius, -1.0,  0.0,  0.0,  sideUVEnd,   1.0,
  -radius, -radius, -radius, -1.0,  0.0,  0.0,  sideUVEnd,   1.0,
  -radius,  radius, -radius, -1.0,  0.0,  0.0,  sideUVEnd,   0.0,
  -radius,  radius,  radius, -1.0,  0.0,  0.0,  sideUVStart, 0.0,

  // 右面（侧面纹理）+x
  radius,  radius,  radius,  1.0,  0.0,  0.0,  sideUVStart, 0.0,
  radius,  radius, -radius,  1.0,  0.0,  0.0,  sideUVEnd,   0.0,
  radius, -radius, -radius,  1.0,  0.0,  0.0,  sideUVEnd,   1.0,
  radius, -radius, -radius,  1.0,  0.0,  0.0,  sideUVEnd,   1.0,
  radius, -radius,  radius,  1.0,  0.0,  0.0,  sideUVStart, 1.0,
  radius,  radius,  radius,  1.0,  0.0,  0.0,  sideUVStart, 0.0,

  // 顶部（草纹理）+y
  radius,  radius,  -radius,  0.0,  1.0,  0.0,  topUVEnd, 0.0,
  radius,  radius,  radius,  0.0,  1.0,  0.0,  topUVEnd,   1.0,
  -radius,  radius,  -radius,  0.0,  1.0,  0.0,  topUVStart,   0.0,
  radius,  radius,  radius,  0.0,  1.0,  0.0,  topUVEnd,   1.0,
  -radius,  radius,  radius,  0.0,  1.0,  0.0,  topUVStart, 1.0,
  -radius,  radius, -radius,  0.0,  1.0,  0.0,  topUVStart, 0.0,

  // 底部（泥土纹理）-y
  -radius, -radius, -radius,  0.0, -1.0,  0.0,  bottomUVStart, 0.0,
  -radius, -radius,  radius,  0.0, -1.0,  0.0,  bottomUVStart, 1.0,
  radius, -radius,  radius,  0.0, -1.0,  0.0,  bottomUVEnd,   1.0,
  radius, -radius,  radius,  0.0, -1.0,  0.0,  bottomUVEnd,   1.0,
  radius, -radius, -radius,  0.0, -1.0,  0.0,  bottomUVEnd,   0.0,
  -radius, -radius, -radius,  0.0, -1.0,  0.0,  bottomUVStart, 0.0,
];
final List<int> oneFaceIndex=[0,1,2,3,4,5];
final List<int> emptyFaceIndex=[];
List<int> faceWithOffset(int offset){
  return oneFaceIndex.map((e) => e+offset*6).toList();
}
final zDirection=[faceWithOffset(1),emptyFaceIndex,faceWithOffset(0)];
final xDirection=[faceWithOffset(2),emptyFaceIndex,faceWithOffset(3)];
final yDirection=[faceWithOffset(5),emptyFaceIndex,faceWithOffset(4)];
final entries=blockVertices.length/8;
List<double> getBlockVertices(double dx,double dy,double dz){

  final vericesClone=List<double>.from(blockVertices);
  for(int i=0;i<entries;i++){
    vericesClone[i*8+0]+=dx;
    vericesClone[i*8+1]+=dy;
    vericesClone[i*8+2]+=dz;
  }
  return vericesClone;
}
final blockVerticesByte=float32(blockVertices);
final double scale=0.5;
final scaleMatrix=Matrix4.diagonal3(Vector3(scale,scale,scale));
final upDirection = Vector3(0, 1, 0);
Matrix4 translation(double dx,double dy,double dz){
  return Matrix4.identity()..setEntry(0,3,dx)..setEntry(1,3,dy)..setEntry(2,3,dz);
}
class BufferWidthLength{
  gpu.BufferView bufferView;
  int length;
  BufferWidthLength(this.bufferView, this.length);
}

class ImageProcessor {
  // 从本地资源加载PNG并获取像素数组
  static Future<Image> loadFromAssets(String assetPath) async {
      // 加载资源文件
      final ByteData data = await rootBundle.load(assetPath);
      // 解码图片数据
      final Uint8List bytes = data.buffer.asUint8List();
      final completer = Completer<Image>();
      decodeImageFromList(bytes, (image) {
        completer.complete(image);
      });
      return await completer.future;
  }

  // 将Image对象转换为像素数组(RGBA格式)
  static Future<ByteData> getPixelArray(Image image) async {
    // 创建像素数据缓冲区
    final ByteData? byteData = await image.toByteData(
      format: ImageByteFormat.rawRgba, // 指定RGBA格式
    );
    return byteData!;
  }
}
class ImageData{
  final ByteData data;
  final int width;
  final int height;
  ImageData(this.data, this.width, this.height);
  static Future<ImageData> fromImage(Image image)async{
    return ImageData(await ImageProcessor.getPixelArray(image), image.width, image.height);
  }
  static Future<ImageData> fromAsset(String assetPath)async{
    final image=await ImageProcessor.loadFromAssets(assetPath);
    return ImageData(await ImageProcessor.getPixelArray(image), image.width, image.height);
  }
}
class ImageAssets{
  late ImageData mainImage;
  late ImageData grass;
  Future load()async{
    mainImage=await ImageData.fromAsset('assets/main.png');
    grass=await ImageData.fromAsset('assets/grass.png');
  }
}
final imageAssets=ImageAssets();


String vecToString(Vector3 vec3){
  return '(${vec3.x.toStringAsFixed(1)},${vec3.y.toStringAsFixed(1)},${vec3.z.toStringAsFixed(1)})';
}

// 在WorldRender类外部或工具类中添加
bool frustumContainsSphere(Matrix4 viewProj, Vector3 center, double radius) {
  // 提取视锥体平面
  final List<Vector4> planes = [];
  // 左平面
  planes.add(Vector4(
    viewProj[3] + viewProj[0],
    viewProj[7] + viewProj[4],
    viewProj[11] + viewProj[8],
    viewProj[15] + viewProj[12],
  ));
  // 右平面
  planes.add(Vector4(
    viewProj[3] - viewProj[0],
    viewProj[7] - viewProj[4],
    viewProj[11] - viewProj[8],
    viewProj[15] - viewProj[12],
  ));
  // 下平面
  planes.add(Vector4(
    viewProj[3] + viewProj[1],
    viewProj[7] + viewProj[5],
    viewProj[11] + viewProj[9],
    viewProj[15] + viewProj[13],
  ));
  // 上平面
  planes.add(Vector4(
    viewProj[3] - viewProj[1],
    viewProj[7] - viewProj[5],
    viewProj[11] - viewProj[9],
    viewProj[15] - viewProj[13],
  ));
  // 近平面
  planes.add(Vector4(
    viewProj[3] + viewProj[2],
    viewProj[7] + viewProj[6],
    viewProj[11] + viewProj[10],
    viewProj[15] + viewProj[14],
  ));
  // 远平面
  planes.add(Vector4(
    viewProj[3] - viewProj[2],
    viewProj[7] - viewProj[6],
    viewProj[11] - viewProj[10],
    viewProj[15] - viewProj[14],
  ));

  // 归一化平面
  for (var plane in planes) {
    final length = sqrt(plane.x*plane.x + plane.y*plane.y + plane.z*plane.z);
    plane /= length;
  }

  // 检查球是否在所有平面内部
  for (var plane in planes) {
    final distance = plane.x*center.x + plane.y*center.y + plane.z*center.z + plane.w;
    if (distance < -radius) {
      return false; // 球在平面外部
    }
  }
  return true;
}