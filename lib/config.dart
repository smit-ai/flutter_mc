import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_gpu_demo/gpu/world_data.dart';
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:package_info_plus/package_info_plus.dart';
import 'gpu/utils.dart';
import 'package:vector_math/vector_math_64.dart';

late PackageInfo packageInfo;
Future ensureInitialized()async{
  await imageAssets.load();
  packageInfo = await PackageInfo.fromPlatform();
}
void ensureInitializedGpuResource(){
  _hostBuffer= gpu.gpuContext.createHostBuffer();
  afternoon=LightMaterialBuffered.from(LightMaterial.afternoon,_hostBuffer);
  sunset=LightMaterialBuffered.from(LightMaterial.sunset,_hostBuffer);
  moonlight=LightMaterialBuffered.from(LightMaterial.moonlight,_hostBuffer);
  morning=LightMaterialBuffered.from(LightMaterial.morning,_hostBuffer);
  rainy=LightMaterialBuffered.from(LightMaterial.rainy,_hostBuffer);
  bloodMoon=LightMaterialBuffered.from(LightMaterial.bloodMoon,_hostBuffer);
  volcanic=LightMaterialBuffered.from(LightMaterial.volcanic,_hostBuffer);
  polarNight=LightMaterialBuffered.from(LightMaterial.polarNight,_hostBuffer);
  apocalypse=LightMaterialBuffered.from(LightMaterial.apocalypse,_hostBuffer);
  radioactive=LightMaterialBuffered.from(LightMaterial.radioactive,_hostBuffer);
  nebula=LightMaterialBuffered.from(LightMaterial.nebula,_hostBuffer);
  cyberpunk=LightMaterialBuffered.from(LightMaterial.cyberpunk,_hostBuffer);
  voidLight=LightMaterialBuffered.from(LightMaterial.voidLight,_hostBuffer);
  eldritch=LightMaterialBuffered.from(LightMaterial.eldritch,_hostBuffer);
  nether=LightMaterialBuffered.from(LightMaterial.nether,_hostBuffer);
}
final ChunkManager chunkManager=ChunkManager();

double renderRatio=0.5;

//lighting
bool rebuildTargetFlag=false;
late LightMaterialBuffered afternoon;
late LightMaterialBuffered sunset;
late LightMaterialBuffered moonlight;
late LightMaterialBuffered morning;
late LightMaterialBuffered rainy;
late LightMaterialBuffered bloodMoon;
late LightMaterialBuffered volcanic;
late LightMaterialBuffered polarNight;
late LightMaterialBuffered apocalypse;
late LightMaterialBuffered radioactive;
late LightMaterialBuffered nebula;
late LightMaterialBuffered cyberpunk;
late LightMaterialBuffered voidLight;
late LightMaterialBuffered eldritch;
late LightMaterialBuffered nether;


late HostBuffer _hostBuffer;
LightMaterialBuffered selectedLighting=afternoon;
void useLighting(LightMaterialBuffered lighting){
  selectedLighting=lighting;
  rebuildTargetFlag=true;
  rebuildFogBufferFlag=true;
}
int _viewDistance=4;
int get viewDistance{
  return _viewDistance;
}
void setViewDistance(int distance){
  _viewDistance=distance;
  rebuildFogBufferFlag=true;
}
//fog
bool rebuildFogBufferFlag=false;// fog,lighting,view-distance need rebuild fog buffer
double fogStart=0.9;
double fogEnd=1.1;
double fogHeightCompression=0.2;

//player
Vector3 cameraPosition = Vector3(2, levelHeight * 1.5, 2);
double horizonRotate = 2.4;
double verticalRotate = -0.6;

//ui
bool displayDetail=true;
double controlPaneButtonSize=70;

