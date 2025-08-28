import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_gpu_demo/gpu/world_data.dart';
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:package_info_plus/package_info_plus.dart';
import 'gpu/utils.dart';

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
late HostBuffer _hostBuffer;
LightMaterialBuffered selectedLighting=afternoon;
void useLighting(LightMaterialBuffered lighting){
  selectedLighting=lighting;
  rebuildTargetFlag=true;
}
int viewDistance=4;

