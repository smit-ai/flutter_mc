import 'package:flutter_gpu_demo/gpu/world_data.dart';
import 'package:statsfl/statsfl.dart';

import 'gpu/utils.dart';

Future ensureInitialize()async{
  await imageAssets.load();
}

final ChunkManager chunkManager=ChunkManager();
