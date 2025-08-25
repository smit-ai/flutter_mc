import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_gpu_demo/config.dart';

final chunkSize = 16;
final strength = 9;
final levelHeight = 10;
final maxHeight = 20;

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
      ChunkPosition(x+1, z + 1),
      ChunkPosition(x + 1, z),
      ChunkPosition(x -1, z - 1),
      ChunkPosition(x - 1, z+1),
    ];
  }
}

class ChunkManager {
  Map<ChunkPosition, Chunk> chunks = {};
  Map<ChunkPosition,double> directionalVec={};
  double getDirectionalVec(ChunkPosition position){
    if(directionalVec.containsKey(position)){
      return directionalVec[position]!;
    }
    final v=random.nextDouble() * 2 - 1;//(-1,1)
    directionalVec[position]=v;
    return v;
  }

  ChunkManager() {
    generateChunk(ChunkPosition(0, 0));
  }

  void generateChunk(ChunkPosition position) async {
    if (chunks.containsKey(position)) {
      return;
    }
    final chunk = Chunk(position, this);
    chunks[position] = chunk;
    ChunkData data = Chunk.generate((position, chunk.directionalVec));
    // ChunkData data=await compute(Chunk.generate,(position,chunk.directionalVec));
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

enum BlockType { grass, log, leave, none }

final random = Random();
double getOppo(double v){
  if(v==0){
    return 1919810;
  }
  final v2=1/v;
  if(v2.isInfinite || v2.isNaN){
    return 1919810;
  }
  return v2;
}
class Chunk {
  ChunkPosition position;
  ChunkManager chunkManager;
  late List<double> directionalVec; //右上，左上，左下，右下
  ChunkData? chunkData;

  bool isVisible(int x,int y,int z){
    final data=chunkData!;
    throw new Exception("not implemented");
  }

  static double calculateDirectionalVec(
    int x,
    int z,
    List<double> directionalVec,
  ) {
    // assert(directionalVec.length==4,"vec length must be 4");
    final MaxChunkPos=chunkSize-1;
    final d1 = _distance(x, z, MaxChunkPos, MaxChunkPos);
    final d2 = _distance(x, z, MaxChunkPos, 0);
    final d3 = _distance(x, z, 0, 0);
    final d4 = _distance(x, z, 0, MaxChunkPos);

    final w1=getOppo(d1);
    final w2=getOppo(d2);
    final w3=getOppo(d3);
    final w4=getOppo(d4);

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
    directionalVec=[
      chunkManager.getDirectionalVec(ChunkPosition(position.x+1, position.z+1)),
      chunkManager.getDirectionalVec(ChunkPosition(position.x+1, position.z)),
      chunkManager.getDirectionalVec(ChunkPosition(position.x, position.z)),
      chunkManager.getDirectionalVec(ChunkPosition(position.x, position.z+1)),
    ];
  }

  static ChunkData generateTest((ChunkPosition, List<double>) params) {
    ChunkData chunkData = ChunkData();
    for (int x = 0; x < chunkSize; x += 2) {
      for (int z = 0; z < chunkSize; z += 2) {
        chunkData.data[x][levelHeight][z].type = BlockType.grass;
      }
    }
    return chunkData;
  }

  static ChunkData generate((ChunkPosition, List<double>) params) {
    final (position, directionalVec) = params;
    ChunkData chunkData = ChunkData();
    //generate chunk
    for (var x = 0; x < chunkSize; x++) {
      for (var z = 0; z < chunkSize; z++) {
        final vec=calculateDirectionalVec(x, z, directionalVec);
        int height =(vec * strength + levelHeight).toInt();
        for (var y = 0; y < height; y++) {
          if (0 <= y && y < maxHeight) {
            chunkData.data[x][y][z].type = BlockType.grass;
          }
        }
      }
    }
    //done
    return chunkData;
  }
}

class ChunkData {
  List<List<List<BlockData>>> data = List.generate(
    chunkSize,

    (i) => List.generate(
      maxHeight,
      (j) => List.generate(chunkSize, (k) => BlockData(), growable: false),
      growable: false,
    ),
    growable: false,
  );
}

class BlockData {
  BlockType type = BlockType.none;
}
