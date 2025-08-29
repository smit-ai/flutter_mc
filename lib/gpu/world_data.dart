import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_gpu_demo/config.dart';
import 'package:flutter_gpu_demo/gpu/utils.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:vector_math/vector_math.dart' as vm;

final chunkSize = 16;
final strength = 10;
final primaryStrength = strength * 2;
final primaryChunkScale = 2;
final levelHeight = primaryStrength + strength ;
final waterLevel=(levelHeight*2/3).toInt();
final maxHeight = (primaryStrength + strength)*2+5;
final temperature = 3;

class ChunkPosition {
  int x;
  int z;

  ChunkPosition(this.x, this.z);

  @override
  String toString() {
    return 'ChunkPosition($x, $z)';
  }

  (int, int) toWorldIndex() {
    return (x * chunkSize, z * chunkSize);
  }

  @override
  int get hashCode => x << 16 + z;

  @override
  bool operator ==(Object other) =>
      other is ChunkPosition && other.x == x && other.z == z;

  List<ChunkPosition> getAround() {
    return [
      ChunkPosition(x, z + 1),
      ChunkPosition(x + 1, z),
      ChunkPosition(x, z - 1),
      ChunkPosition(x - 1, z),
    ];
  }

  List<ChunkPosition> getAroundCorner() {
    return [
      ChunkPosition(x + 1, z + 1),
      ChunkPosition(x + 1, z),
      ChunkPosition(x - 1, z - 1),
      ChunkPosition(x - 1, z + 1),
    ];
  }
}

class ChunkManager {
  Map<ChunkPosition, Chunk> chunks = {};
  Map<ChunkPosition, double> directionalVec = {};
  Map<ChunkPosition, double> primaryDirectionalVec = {};

  static double _getVecCommon(ChunkPosition position,Map<ChunkPosition,double> source){
    if (source.containsKey(position)) {
      return source[position]!;
    }
    if(random.nextDouble()<0.5){
      //从众
      double nearV=0;
      int count=0;
      final around=position.getAround();
      for(final p in around){
        final near=source[p];
        if(near!=null){
          nearV+=near;
          count++;
        }
      }
      if(count>0){
        final v= random.nextDouble()*sign(nearV);
        source[position] = v;
        return v;
      }
      //rollback to random
    }
    final v = random.nextDouble() * 2 - 1; //(-1,1)
    source[position] = v;
    return v;
  }
  double getDirectionalVec(ChunkPosition position) {
    return _getVecCommon(position, directionalVec);
  }

  double getPrimaryDirectionalVec(ChunkPosition position) {
    return _getVecCommon(position, primaryDirectionalVec);
  }

  ChunkManager() {
    requestGenerateChunk(ChunkPosition(0, 0));
  }
  void ensureChunkWarp(ChunkPosition position, {VoidCallback? onComplete})async{
    final tasks=<Future>[];
    for(final p in position.getAround()){
      tasks.add(_generateChunk(p));
    }
    await Future.wait(tasks);
    onComplete?.call();
  }
  bool isChunkWarpAvailable(ChunkPosition position){
    for(final p in position.getAround()){
      final chunk=chunks[p];
      if(chunk==null){
        return false;
      }
      if(chunk.chunkData==null){
        return false;
      }
    }
    return true;
  }

  void requestGenerateChunk(ChunkPosition position, {VoidCallback? onComplete}) async {
    final tasks=<Future>[_generateChunk(position)];
    for(final p in position.getAround()){
      tasks.add(_generateChunk(p));
    }
    await Future.wait(tasks);
    onComplete?.call();
  }
  Future _generateChunk(ChunkPosition position)async{
    if (chunks.containsKey(position)) {
      return;
    }
    final chunk = Chunk(position, this);
    chunks[position] = chunk;
    //async
    ChunkData data = await compute(Chunk.generate, (
      position,
      chunk.directionalVec,
      chunk.primaryDirectionalVec,
      chunk.primaryDcx,
      chunk.primaryDcz,
      ));
    //sync
    // ChunkData data = Chunk.generate((
    //   position,
    //   chunk.directionalVec,
    //   chunk.primaryDirectionalVec,
    //   chunk.primaryDcx,
    //   chunk.primaryDcz,
    //   ));
    chunk.chunkData = data;
  }

  bool isExists(ChunkPosition position) {
    return chunks.containsKey(position);
  }
}

int abs(int x) {
  return x < 0 ? -x : x;
}

double _distance(int x1, int y1, int x2, int y2) {
  // return abs(x1 - x2) + abs(y1 - y2);
  return sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
}

const double invalid = double.nan;

enum BlockType { grass, log, leaf, air,water }

final random = Random();

double getOppo(double v) {
  if (v == 0) {
    return 1919810;
  }
  final v2 = 1 / v;
  if (v2.isInfinite || v2.isNaN) {
    return 1919810;
  }
  return v2;
}

final List<(int, int, int)> around = [
  (-1, 0, 0),
  (1, 0, 0),
  (0, -1, 0),
  (0, 1, 0),
  (0, 0, -1),
  (0, 0, 1),
];

int sign(double v) {
  if (v == 0) {
    return 0;
  }
  return v > 0 ? 1 : -1;
}

/// 检查是否为不透明
bool isOpaque(BlockType type) {
  if(type==BlockType.leaf||type==BlockType.air||type==BlockType.water){
    return false;
  }
  return true;
}
bool isOpaqueCustom(BlockType type,BlockType viewAsOpaque) {
  if(type==viewAsOpaque){
    return true;
  }
  return isOpaque(type);
}
/// 检查是否有点不透明
bool isLittleOpaque(BlockType type) {
  if(type==BlockType.air){
    return false;
  }
  return true;
}
/// 检查是否为半透明
bool isTranslucent(BlockType type) {
  if(type==BlockType.water){
    return true;
  }
  if(type==BlockType.leaf){
    return true;
  }
  return false;
}

class Chunk {
  ChunkPosition position;
  ChunkManager chunkManager;
  late List<double> directionalVec; //右上，左上，左下，右下
  late List<double> primaryDirectionalVec;
  late int primaryDcx;
  late int primaryDcz;
  ChunkData? chunkData;
  ChunkBufferView? chunkBufferView;
  @override
  int get hashCode => position.hashCode;
  @override
  bool operator ==(Object other) {
    if(other is Chunk){
      return position==other.position;
    }
    return false;
  }


  static bool isValidXZ(int x, int y, int z) {
    return x >= 0 && x < chunkSize && z >= 0 && z < chunkSize;
  }

  static (int dcx, int dcz, int x, int z) accessChunk(int x, int z) {
    int dcx = 0;
    int dcz = 0;
    if (x < 0) {
      dcx = -1;
      x += chunkSize;
    } else if (x >= chunkSize) {
      dcx = 1;
      x -= chunkSize;
    }
    if (z < 0) {
      dcz = -1;
      z += chunkSize;
    } else if (z >= chunkSize) {
      dcz = 1;
      z -= chunkSize;
    }
    return (dcx, dcz, x, z);
  }

  /// whether the block is opaque
  bool _isOpaque(int x, int y, int z,{BlockType? viewAsOpaque}) {
    if (y < 0 || y >= maxHeight) {
      return false;
    }
    var translucentFunc=isOpaque;
    if(viewAsOpaque!=null){
      translucentFunc=(type)=>isOpaqueCustom(type, viewAsOpaque);
    }
    final data = chunkData!;
    if (!isValidXZ(x, y, z)) {
      final (dcx, dcz, xNew, zNew) = accessChunk(x, z);//try access other chunk
      final chunkNewPosition = ChunkPosition(
        position.x + dcx,
        position.z + dcz,
      );
      final chunkNew=chunkManager.chunks[chunkNewPosition];
      if (chunkNew!=null) {
        final chunkDataNew = chunkNew.chunkData;
        if (chunkDataNew == null) {
          return true;
        }
        return translucentFunc(chunkDataNew.dataXzy[xNew][zNew][y].type);
      }else{//the other chunk is not generated
        return false;
      }
    } else {
      return translucentFunc(data.dataXzy[x][z][y].type);
    }
  }
  ///with translation
  List<double> allVisibleFaces(int x,int y,int z){
    final blockType=chunkData!.dataXzy[x][z][y].type;
    final res=<double>[];
    for(int i=0;i<6;i++){
      final (dx,dy,dz) = around[i];
      if(!_isOpaque(x+dx, y+dy, z+dz,viewAsOpaque: isTranslucent(blockType)?blockType:null)){
        final face=faceWithTranslation(blockVerticesFaces[i], position.x*chunkSize+x, y, position.z*chunkSize+z);
        res.addAll(face);
      }
    }
    return res;
  }

  (int,int,int) visibleFaces(int x, int y, int z, Vector3 cameraPos) {
    final (cx, cz) = position.toWorldIndex();
    final blockPos = Vector3(
      x.toDouble() + cx,
      y.toDouble(),
      z.toDouble() + cz,
    );
    final direction = cameraPos - blockPos;
    var dx = sign(direction.x);
    var dy = sign(direction.y);
    var dz = sign(direction.z);

    if (_isOpaque(x + dx, y, z)) {
      dx=0;
    }
    if (_isOpaque(x, y + dy, z)) {
      dy=0;
    }
    if (_isOpaque(x, y, z + dz)) {
      dz=0;
    }
    return (dx,dy,dz);
  }
  bool isBlockVisible(int x, int y, int z, Vector3 cameraPos) {
    final (cx,cz)=position.toWorldIndex();
    final blockPos = Vector3(x.toDouble() + cx, y.toDouble(), z.toDouble() + cz);
    final direction = cameraPos - blockPos;
    final dx=sign(direction.x);
    final dy=sign(direction.y);
    final dz=sign(direction.z);

    if(_isOpaque(x+dx, y, z)&&_isOpaque(x, y+dy, z)&&_isOpaque(x, y, z+dz)){
      return false;
    }
    return true;
  }

  static double calculateDirectionalVec(
    int x,
    int z,
    List<double> directionalVec,
    int chunkSize,
  ) {
    // assert(directionalVec.length==4,"vec length must be 4");
    final maxChunkPos = chunkSize - 1;
    final d1 = _distance(x, z, maxChunkPos, maxChunkPos);
    final d2 = _distance(x, z, maxChunkPos, 0);
    final d3 = _distance(x, z, 0, 0);
    final d4 = _distance(x, z, 0, maxChunkPos);

    final w1 = pow(getOppo(d1), temperature);
    final w2 = pow(getOppo(d2), temperature);
    final w3 = pow(getOppo(d3), temperature);
    final w4 = pow(getOppo(d4), temperature);

    final total = w1 + w2 + w3 + w4;
    double result =
        (w1) * directionalVec[0] +
        (w2) * directionalVec[1] +
        (w3) * directionalVec[2] +
        (w4) * directionalVec[3];
    result /= total;
    return result;
  }

  Chunk(this.position, this.chunkManager) {
    directionalVec = [
      chunkManager.getDirectionalVec(
        ChunkPosition(position.x + 1, position.z + 1),
      ),
      chunkManager.getDirectionalVec(ChunkPosition(position.x + 1, position.z)),
      chunkManager.getDirectionalVec(ChunkPosition(position.x, position.z)),
      chunkManager.getDirectionalVec(ChunkPosition(position.x, position.z + 1)),
    ];
    final primaryX = (position.x / primaryChunkScale).floor();
    final primaryZ = (position.z / primaryChunkScale).floor();
    primaryDirectionalVec = [
      chunkManager.getDirectionalVec(ChunkPosition(primaryX + 1, primaryZ + 1)),
      chunkManager.getDirectionalVec(ChunkPosition(primaryX + 1, primaryZ)),
      chunkManager.getDirectionalVec(ChunkPosition(primaryX, primaryZ)),
      chunkManager.getDirectionalVec(ChunkPosition(primaryX, primaryZ + 1)),
    ];
    primaryDcx = position.x - primaryX * primaryChunkScale;
    primaryDcz = position.z - primaryZ * primaryChunkScale;
  }

  static ChunkData generateTest((ChunkPosition, List<double>) params) {
    ChunkData chunkData = ChunkData();
    for (int x = 0; x < chunkSize; x += 2) {
      for (int z = 0; z < chunkSize; z += 2) {
        chunkData.dataXzy[x][z][levelHeight].type = BlockType.grass;
      }
    }
    return chunkData;
  }

  static ChunkData generate(
    (
      ChunkPosition position,
      List<double> directionalVec,
      List<double> primaryDirectionalVec,
      int primaryDcx,
      int primaryDcz,
    )
    params,
  ) {
    final (
      position,
      directionalVec,
      primaryDirectionalVec,
      primaryDcx,
      primaryDcz,
    ) = params;
    ChunkData chunkData = ChunkData();
    //generate chunk
    final primaryDx = primaryDcx * chunkSize;
    final primaryDz = primaryDcz * chunkSize;
    final primaryChunkSize = chunkSize * primaryChunkScale;
    for (var x = 0; x < chunkSize; x++) {
      for (var z = 0; z < chunkSize; z++) {
        //primary height delta
        final primaryHeightDelta = calculateDirectionalVec(
          x + primaryDx,
          z + primaryDz,
          primaryDirectionalVec,
          primaryChunkSize,
        )*primaryStrength;
        final vec = calculateDirectionalVec(x, z, directionalVec, chunkSize);
        final heightDelta = vec * strength;
        int height = (primaryHeightDelta + heightDelta+levelHeight).toInt();
        for (var y = 0; y < height; y++) {
          if (0 <= y && y < maxHeight) {
            chunkData.dataXzy[x][z][y].type = BlockType.grass;
          }
        }
        //gen water
        for(int y=height;y<waterLevel;y++){
          chunkData.dataXzy[x][z][y].type=BlockType.water;
        }
        final treeRadius=2;
        final treeRadius2=1;
        final isTotalInChunk=treeRadius<=x&&x<chunkSize-treeRadius
            &&treeRadius<=z&&z<chunkSize-treeRadius;
        if(isTotalInChunk && height>=waterLevel && random.nextDouble()<0.01){
          //gen tree
          final treeHeight=random.nextInt(3)+2;
          final treeUp=height+treeHeight;
          for(var y=height;y<min(maxHeight,treeUp);y++){
            chunkData.trySet(x, y, z, BlockType.log);
          }

          final treeLeafHeight1=2;
          for(int dx=-treeRadius;dx<=treeRadius;dx++){
            for(int dz=-treeRadius;dz<=treeRadius;dz++){
              for(int dy=0;dy<treeLeafHeight1;dy++){
                chunkData.trySet(x+dx, treeUp+dy, z+dz, BlockType.leaf);
              }
            }
          }

          for(int dx=-treeRadius2;dx<=treeRadius2;dx++){
            for(int dz=-treeRadius2;dz<=treeRadius2;dz++){
              chunkData.trySet(x+dx, treeUp+treeLeafHeight1, z+dz, BlockType.leaf);
            }
          }
          chunkData.trySet(x, treeUp+treeLeafHeight1+1, z, BlockType.leaf);
          chunkData.trySet(x+1, treeUp+treeLeafHeight1+1, z, BlockType.leaf);
          chunkData.trySet(x-1, treeUp+treeLeafHeight1+1, z, BlockType.leaf);
          chunkData.trySet(x, treeUp+treeLeafHeight1+1, z+1, BlockType.leaf);
          chunkData.trySet(x, treeUp+treeLeafHeight1+1, z-1, BlockType.leaf);
          chunkData.trySet(x, treeUp, z, BlockType.log);
        }
      }
    }
    //done
    return chunkData;
  }


}

class ChunkData {
  List<List<List<BlockData>>> dataXzy = List.generate(
    chunkSize,
    (i) => List.generate(
      chunkSize,
      (j) => List.generate(maxHeight, (k) => BlockData(), growable: false),
      growable: false,
    ),
    growable: false,
  );
  void trySet(int x,int y,int z,BlockType type){
    if(0<=x&&x<chunkSize&&0<=y&&y<maxHeight&&0<=z&&z<chunkSize){
      dataXzy[x][z][y].type=type;
    }
  }
}

class BlockData {
  BlockType type = BlockType.air;
}
