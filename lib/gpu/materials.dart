import 'package:flutter_gpu_demo/gpu/utils.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:vector_math/vector_math.dart' as vm;
import 'package:flutter_gpu/gpu.dart' as gpu;

class BlinnPhongMaterial{
  final Vector3 ambient;
  final Vector3 diffuse;
  final Vector3 specular;
  final double shininess;
  BlinnPhongMaterial(this.ambient, this.diffuse, this.specular, this.shininess);
  static final grass=BlinnPhongMaterial(
    Vector3(0.5, 0.55, 0.5),   // 环境光：微微带绿色
    Vector3(0.2, 0.5, 0.2),    // 漫反射：鲜明的草绿色
    Vector3(0.1, 0.1, 0.1),    // 高光：草是哑光材质
    12.0,                       // 高光散射小，比较模糊
  );
  static final log= BlinnPhongMaterial(
    Vector3(0.5, 0.45, 0.3),// 环境光
    Vector3(0.25, 0.2, 0.15),  // 漫反射
    Vector3(0.1, 0.1, 0.1),    // 高光弱
    20.0,
  );
  static final leaf=BlinnPhongMaterial(
    Vector3(0.2, 0.3, 0.2),    // 环境光：暗绿色
    Vector3(0.2, 0.5, 0.2),    // 漫反射：中等绿色
    Vector3(0.05, 0.05, 0.05), // 高光极弱
    20.0,
  );
  static final water=BlinnPhongMaterial(
    Vector3(0.0, 0.0, 0.05),   // 环境光：淡蓝色
    Vector3(0.2, 0.3, 0.6),    // 漫反射：水的蓝色
    Vector3(0.5, 0.5, 0.5),    // 高光：水面有较强镜面反射
    48.0,                      // 高光锐利
  );
}
class LightMaterial{
  final String name;
  final Vector3 direction;
  final Vector3 ambient;
  final Vector3 diffuse;
  final Vector3 specular;
  final vm.Vector4 skyColor;
  LightMaterial(this.direction, this.ambient, this.diffuse, this.specular,this.name,this.skyColor);
  static final afternoon = LightMaterial(
    Vector3(-0.3, -1.0, -0.2),   // 光方向：略往下照
    Vector3(0.7, 0.7, 0.6),      // 环境光：中等灰白
    Vector3(0.7, 0.7, 0.6),      // 漫反射：明亮白光
    Vector3(1.0, 1.0, 1.0),      // 高光：强白光
    'afternoon',
    vm.Vector4(0.75, 0.85, 1.0, 1.0), // 天空蓝
  );
  static final sunset = LightMaterial(
    Vector3(-0.3, -0.1, -0.3),   // 光方向：更平，接近地平线
    Vector3(0.4, 0.35, 0.3),     // 环境光：微弱暖色
    Vector3(0.9, 0.4, 0.2),      // 漫反射：橙红色
    Vector3(1.0, 0.5, 0.3),      // 高光：偏暖的亮光
    'sunset',
    vm.Vector4(0.98, 0.55, 0.35, 1.0), // 橙红天空
  );
  static final morning = LightMaterial(
    Vector3(-0.4, -0.8, -0.2),   // 光方向：稍微斜，从左上斜下照
    Vector3(0.5, 0.55, 0.65),    // 环境光：淡蓝灰，冷调
    Vector3(0.9, 0.85, 0.7),     // 漫反射：柔和暖金白
    Vector3(1.0, 0.95, 0.8),     // 高光：暖白，不刺眼
    'morning',
    vm.Vector4(0.75, 0.85, 0.95, 1.0), // 清晨淡蓝天空
  );
  static final moonlight = LightMaterial(
    Vector3(0.2, -1.0, -0.3),    // 光方向：从右上斜下，柔和
    Vector3(0.2, 0.22, 0.3),     // 环境光：暗的蓝灰
    Vector3(0.3, 0.35, 0.5),     // 漫反射：淡淡的冷蓝光
    Vector3(0.6, 0.7, 0.9),      // 高光：清冷的偏蓝白
    'moonlight',
    vm.Vector4(0.05, 0.08, 0.15, 1.0), // 深蓝夜空
  );
  static final rainy = LightMaterial(
    Vector3(0.0, -1.0, 0.0),      // 光方向：近乎垂直向下，但不重要（散射为主）
    Vector3(0.4, 0.4, 0.45),      // 环境光：偏灰蓝
    Vector3(0.5, 0.5, 0.55),      // 漫反射：柔和低饱和灰白
    Vector3(0.6, 0.6, 0.65),      // 高光：不强烈，略灰
    'rainy',
    vm.Vector4(0.6, 0.65, 0.7, 1.0), // 天空：阴天灰蓝
  );
  static final bloodMoon = LightMaterial(
    Vector3(0.3, -0.9, -0.3),     // 光方向：斜下，像月光
    Vector3(0.1, 0.05, 0.05),     // 环境光：暗红
    Vector3(0.6, 0.1, 0.1),       // 漫反射：红光
    Vector3(0.9, 0.2, 0.2),       // 高光：血色亮光
    'blood moon',
    vm.Vector4(0.4, 0.05, 0.1, 1.0), // 天空：深红黑
  );
  static final apocalypse = LightMaterial(
    Vector3(-0.2, -0.6, -0.2),    // 光方向：低角度，黄沙漫天
    Vector3(0.4, 0.35, 0.2),      // 环境光：黄灰
    Vector3(1.0, 0.8, 0.2),       // 漫反射：刺眼黄光
    Vector3(1.0, 0.9, 0.5),       // 高光：耀眼白黄
    'apocalypse',
    vm.Vector4(0.9, 0.7, 0.3, 1.0),  // 天空：末日黄沙色
  );
  static final polarNight = LightMaterial(
    Vector3(-0.5, -0.8, -0.2),    // 光方向：斜向
    Vector3(0.05, 0.08, 0.15),    // 环境光：接近黑蓝
    Vector3(0.2, 0.3, 0.5),       // 漫反射：冷蓝紫
    Vector3(0.5, 0.7, 0.9),       // 高光：偏冷的亮蓝
    'polar night',
    vm.Vector4(0.1, 0.15, 0.25, 1.0),// 天空：深蓝黑
  );
  static final volcanic = LightMaterial(
    Vector3(0.0, -0.7, -0.3),     // 光方向：低角度，像岩浆反射的光
    Vector3(0.3, 0.15, 0.1),      // 环境光：暗红
    Vector3(1.0, 0.3, 0.1),       // 漫反射：强烈的橙红
    Vector3(1.0, 0.6, 0.2),       // 高光：炽烈橙黄
    'volcanic',
    vm.Vector4(0.9, 0.3, 0.1, 1.0),  // 天空：血红橙
  );
  static final voidLight = LightMaterial(
    Vector3(0.0, -0.5, -0.9),
    Vector3(0.05, 0.0, 0.1),     // 环境光：极暗紫黑
    Vector3(0.3, 0.0, 0.5),      // 漫反射：诡异紫色
    Vector3(0.8, 0.2, 1.0),      // 高光：强烈紫白
    'void',
    vm.Vector4(0.15, 0.0, 0.2, 1.0),// 天空：深紫黑
  );
  static final cyberpunk = LightMaterial(
    Vector3(-0.3, -0.6, -0.4),
    Vector3(0.1, 0.05, 0.2),     // 环境光：暗紫
    Vector3(0.5, 0.1, 0.8),      // 漫反射：粉紫霓虹
    Vector3(0.4, 0.8, 1.0),      // 高光：蓝白
    'cyberpunk',
    vm.Vector4(0.2, 0.05, 0.3, 1.0),// 天空：紫黑霓虹
  );
  static final nebula = LightMaterial(
    Vector3(-0.5, -0.5, -0.2),
    Vector3(0.1, 0.1, 0.2),       // 环境光：冷蓝
    Vector3(0.4, 0.2, 0.6),       // 漫反射：紫蓝
    Vector3(1.0, 0.6, 0.9),       // 高光：粉紫白
    'nebula',
    vm.Vector4(0.3, 0.15, 0.4, 1.0), // 天空：梦幻紫蓝
  );
  static final radioactive = LightMaterial(
    Vector3(-0.2, -0.7, -0.5),
    Vector3(0.05, 0.1, 0.05),     // 环境光：暗绿
    Vector3(0.3, 0.8, 0.3),       // 漫反射：诡异荧光绿
    Vector3(0.6, 1.0, 0.6),       // 高光：强烈的毒绿
    'radioactive',
    vm.Vector4(0.2, 0.4, 0.2, 1.0),  // 天空：阴森绿灰
  );
  static final eldritch = LightMaterial(
    Vector3(-0.4, -0.7, -0.3),
    Vector3(0.0, 0.1, 0.05),     // 环境光：阴冷绿
    Vector3(0.2, 0.6, 0.3),      // 漫反射：病态绿光
    Vector3(0.8, 0.3, 1.0),      // 高光：诡异紫白
    'eldritch',
    vm.Vector4(0.1, 0.2, 0.15, 1.0), // 天空：阴冷病绿
  );
  static final nether = LightMaterial(
    Vector3(0.0, -1.0, 0.0),
    Vector3(-0.1, -0.1, -0.1),  // 环境光：负光，反直觉
    Vector3(0.2, 0.0, 0.3),     // 漫反射：幽暗紫黑
    Vector3(0.9, 0.0, 0.0),     // 高光：猩红血光
    'nether',
    vm.Vector4(0.05, 0.0, 0.1, 1.0), // 天空：深紫黑
  );
}

class FogData {
  vm.Vector4 color;
  double start;
  double end;
  double heightCompression;//make the vertical direction fog more sparse
  FogData(this.color, this.start, this.end,this.heightCompression);
  List<double> toArray(){
    return <double>[
      ...color.storage,
      start,end,heightCompression,0
    ];
  }
}

class SunData {
  Vector3 color;
  Vector3 center;
  double edgeStart;
  double edgeEnd;
  SunData(this.color, this.center, this.edgeStart,this.edgeEnd);
  List<double> toArray(){
    return <double>[
      ...color.storage,0,
      ...center.storage,0,
      edgeStart,edgeEnd,0,0
    ];
  }
}

//buffered
class PhongMaterialBuffered {
  final gpu.BufferView data;
  PhongMaterialBuffered(this.data);
  static PhongMaterialBuffered from(
      BlinnPhongMaterial material,
      gpu.HostBuffer hostBuffer,
      ) {
    final list = <double>[
      ...material.ambient.storage,
      0,
      ...material.diffuse.storage,
      0,
      ...material.specular.storage,
      0,
      material.shininess,
      0,
      0,
      0,
    ];
    return PhongMaterialBuffered(hostBuffer.emplace(float32(list)));
  }
}

class LightMaterialBuffered {
  final gpu.BufferView data;
  final LightMaterial raw;
  LightMaterialBuffered(this.data, this.raw);
  static LightMaterialBuffered from(
      LightMaterial material,
      gpu.HostBuffer hostBuffer,
      ) {
    final list = <double>[
      ...material.direction.storage,
      0,
      ...material.ambient.storage,
      0,
      ...material.diffuse.storage,
      0,
      ...material.specular.storage,
      0,
    ];
    return LightMaterialBuffered(hostBuffer.emplace(float32(list)), material);
  }
}
