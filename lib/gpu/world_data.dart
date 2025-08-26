import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_gpu_demo/config.dart';
import 'package:flutter_gpu_demo/gpu/utils.dart';
import 'package:vector_math/vector_math_64.dart';

final chunkSize = 16;
final strength = 9;
final primaryStrength = strength * 2;
final primaryChunkScale = 2;
final levelHeight = ((primaryStrength + strength) / 2).toInt();
final maxHeight = primaryStrength + strength;
final temperature = 2;

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

  double getDirectionalVec(ChunkPosition position) {
    if (directionalVec.containsKey(position)) {
      return directionalVec[position]!;
    }
    final v = random.nextDouble() * 2 - 1; //(-1,1)
    directionalVec[position] = v;
    return v;
  }

  double getPrimaryDirectionalVec(ChunkPosition position) {
    if (primaryDirectionalVec.containsKey(position)) {
      return primaryDirectionalVec[position]!;
    }
    final v = random.nextDouble() * 2 - 1; //(-1,1)
    primaryDirectionalVec[position] = v;
    return v;
  }

  ChunkManager() {
    generateChunk(ChunkPosition(0, 0));
  }

  void generateChunk(ChunkPosition position, {VoidCallback? onComplete}) async {
    if (chunks.containsKey(position)) {
      return;
    }
    final chunk = Chunk(position, this);
    chunks[position] = chunk;
    // ChunkData data = Chunk.generate((position, chunk.directionalVec));
    ChunkData data = await compute(Chunk.generate, (
      position,
      chunk.directionalVec,
      chunk.primaryDirectionalVec,
      chunk.primaryDcx,
      chunk.primaryDcz,
    ));
    chunk.chunkData = data;
    onComplete?.call();
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
  (-1, -1, -1),
  (-1, -1, 0),
  (-1, -1, 1),
  (-1, 0, -1),
  (-1, 0, 0),
  (-1, 0, 1),
  (-1, 1, -1),
  (-1, 1, 0),
  (-1, 1, 1),
  (0, -1, -1),
  (0, -1, 0),
  (0, -1, 1),
  (0, 0, -1),
  (0, 0, 1),
  (0, 1, -1),
  (0, 1, 0),
  (0, 1, 1),
  (1, -1, -1),
  (1, -1, 0),
  (1, -1, 1),
  (1, 0, -1),
  (1, 0, 0),
  (1, 0, 1),
  (1, 1, -1),
  (1, 1, 0),
  (1, 1, 1),
];

int sign(double v) {
  if (v == 0) {
    return 0;
  }
  return v > 0 ? 1 : -1;
}

/// 检查是否为不透明
bool isOpaque(BlockType type) {
  return type != BlockType.none;
}

class Chunk {
  ChunkPosition position;
  ChunkManager chunkManager;
  late List<double> directionalVec; //右上，左上，左下，右下
  late List<double> primaryDirectionalVec;
  late int primaryDcx;
  late int primaryDcz;
  ChunkData? chunkData;

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

  bool _isOpaque(int x, int y, int z) {
    if (y < 0 || y >= maxHeight) {
      return false;
    }
    final data = chunkData!;
    if (!isValidXZ(x, y, z)) {
      final (dcx, dcz, xNew, zNew) = accessChunk(x, z);
      final chunkNewPosition = ChunkPosition(
        position.x + dcx,
        position.z + dcz,
      );
      if (chunkManager.isExists(chunkNewPosition)) {
        final chunkDataNew = chunkManager.chunks[chunkNewPosition]!.chunkData;
        if (chunkDataNew == null) {
          return true;
        }
        return isOpaque(chunkDataNew.data[xNew][y][zNew].type);
      }
      return true;
    } else {
      return isOpaque(data.data[x][y][z].type);
    }
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
        chunkData.data[x][levelHeight][z].type = BlockType.grass;
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
        );
        final vec = calculateDirectionalVec(x, z, directionalVec, chunkSize);
        final heightDelta = vec * strength;
        int height = (primaryHeightDelta + heightDelta+levelHeight).toInt();
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
