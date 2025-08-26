import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gpu_demo/config.dart';
import 'package:flutter_gpu_demo/gpu/utils.dart';
import 'package:flutter_gpu_demo/gpu/world_data.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'shaders.dart';



class WorldRender extends CustomPainter {
  VoidCallback onMapGenerated;
  Vector3 cameraPosition = Vector3(0, 0, 0);
  double horizonRotate = 0.0;
  double verticalRotate = 0.0;
  double renderRatio;
  int viewDistance= 2;
  MediaQueryData mediaQueryData;

  //resource
  late gpu.RenderPipeline _pipeline;
  late gpu.Texture _sampledTexture;
  late gpu.HostBuffer _hostBuffer;
  Matrix4? _perspectiveMatrix;
  Size? _lastSize;
  late gpu.UniformSlot _frameInfoSlot;
  late gpu.UniformSlot _texSlot;
  late gpu.UniformSlot _translationSlot;
  late double dpr;
  late List<List<List<BufferWidthLength>>> faceBufferViews;
  late gpu.BufferView vertices;

  final ValueNotifier<int> notifier;
  WorldRender(this.cameraPosition, this.horizonRotate, this.verticalRotate,
      this.onMapGenerated, this.mediaQueryData, this.renderRatio,
      this.notifier) :super(repaint: notifier) {
    dpr = mediaQueryData.devicePixelRatio * renderRatio;
    //shader
    final vertexShader = shaderLibrary["BaseVertex"]!;
    final fragmentShader = shaderLibrary["BaseFragment"]!;
    //pipeline
    _pipeline = gpu.gpuContext.createRenderPipeline(
      vertexShader,
      fragmentShader,
    );
    _frameInfoSlot = _pipeline.vertexShader.getUniformSlot('FrameInfo');
    _texSlot = _pipeline.fragmentShader.getUniformSlot('tex');
    _translationSlot = _pipeline.vertexShader.getUniformSlot('Translation');
    //texture
    final mainImg=imageAssets.grass;
    _sampledTexture = gpu.gpuContext.createTexture(
        gpu.StorageMode.hostVisible, mainImg.width, mainImg.height,
        enableShaderReadUsage: true
    );
    _sampledTexture.overwrite(mainImg.data);
    //buffer
    _hostBuffer = gpu.gpuContext.createHostBuffer();
    vertices = _hostBuffer.emplace(blockVerticesByte);
    //gen face buffer
    faceBufferViews = List.generate(3, (x) =>
        List.generate(3, (y) =>
            List.generate(
                3, (z) {
              List<int> indices = [];
              indices.addAll(xDirection[x]);
              indices.addAll(yDirection[y]);
              indices.addAll(zDirection[z]);
              return BufferWidthLength(
                  _hostBuffer.emplace(uint16(indices)), indices.length);
            }, growable: false),
            growable: false), growable: false);

  }
  final chunkRadius = sqrt(chunkSize*chunkSize /2.0+maxHeight*maxHeight/4.0)+8; // 区块对角线一半
  bool isChunkVisible(ChunkPosition pos, Matrix4 viewProj) {
    final chunkCenter = Vector3(
      (pos.x * chunkSize + chunkSize/2).toDouble(),
      maxHeight/2,
      (pos.z * chunkSize + chunkSize/2).toDouble(),
    );

    return frustumContainsSphere(viewProj, chunkCenter, chunkRadius);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final width = (size.width*dpr).toInt();
    final height = (size.height*dpr).toInt();
    // 仅在尺寸变化时更新透视矩阵
    if (_perspectiveMatrix == null || size != _lastSize) {
      _perspectiveMatrix = makePerspectiveMatrix(
        60 * (3.141592653589793 / 180.0),
        size.aspectRatio,
        0.01,
        100
      );
      _lastSize = size;
    }
    //texture
    final renderTexture = gpu.gpuContext.createTexture(
      gpu.StorageMode.devicePrivate,
      width,
      height,
      enableRenderTargetUsage: true,
      sampleCount: 1,
      enableShaderReadUsage: true,
      coordinateSystem: gpu.TextureCoordinateSystem.renderToTexture,
    );

    final depthTexture = gpu.gpuContext.createTexture(
      gpu.StorageMode.deviceTransient,
      width,
      height,
      format: gpu.gpuContext.defaultDepthStencilFormat,
      enableRenderTargetUsage: true,
      coordinateSystem: gpu.TextureCoordinateSystem.renderToTexture,
    );
    //target
    final renderTarget = gpu.RenderTarget.singleColor(
      gpu.ColorAttachment(texture: renderTexture),
      depthStencilAttachment: gpu.DepthStencilAttachment(
        texture: depthTexture,
        depthClearValue: 1,
      ),
    );
    //command buffer
    final commandBuffer = gpu.gpuContext.createCommandBuffer();
    //pass
    final pass = commandBuffer.createRenderPass(renderTarget);
    pass.bindPipeline(_pipeline);
    pass.setDepthWriteEnable(true);
    pass.setDepthCompareOperation(gpu.CompareFunction.less);



    pass.bindVertexBuffer(vertices, 36);
    // final indices = transients.emplace(cubeIndices);

    // pass.bindIndexBuffer(indices, gpu.IndexType.int16, 36);

    //cull
    pass.setCullMode(gpu.CullMode.backFace);

    pass.bindTexture(_texSlot, _sampledTexture);

    //uniform

    final persp = _perspectiveMatrix!;
    final focusDirection = Vector3(
      cos(horizonRotate) * cos(verticalRotate),
      sin(verticalRotate),
      -sin(horizonRotate) * cos(verticalRotate),
    );
    final transient = gpu.gpuContext.createHostBuffer();
    final view = makeViewMatrix(cameraPosition, focusDirection+cameraPosition, upDirection);
    final pvs=persp*view;
    final mvp = transient.emplace(
      float32Mat(
        pvs,
      ),
    );
    pass.bindUniform(_frameInfoSlot, mvp);
    //calc chunk
    final int x=((cameraPosition.x+radius)/chunkSize).floor();
    final int  z=((cameraPosition.z+radius)/chunkSize).floor();


    // final List<double> mergedVertices = [];
    // int count=0;

    for(int chunkDistanceX=-viewDistance;chunkDistanceX<=viewDistance;chunkDistanceX++){
      for(int chunkDistanceZ=-viewDistance;chunkDistanceZ<=viewDistance;chunkDistanceZ++){
        final chunkPosition=ChunkPosition(x+chunkDistanceX, z+chunkDistanceZ);
        if(chunkManager.isExists(chunkPosition)){
          final chunk=chunkManager.chunks[chunkPosition]!;
          if(!(x==chunkPosition.x&&z==chunkPosition.z)){
            //not current chunk
            if(!isChunkVisible(chunkPosition, pvs)){
              continue;//can not see this chunk, skip
            }
          }
          final chunkData=chunk.chunkData;

          if(chunkData!=null){
            final (chunkDx,chunkDz)=chunkPosition.toWorldIndex();
            for(int x=0;x<chunkSize;x++){
              for(int z=0;z<chunkSize;z++){
                for(int y=0;y<maxHeight;y++){
                  final block=chunkData.data[x][y][z];
                  if(block.type==BlockType.none){
                    continue;
                  }
                  //check visible face
                  // final (dx,dy,dz)=chunk.visibleFaces(x, y, z, cameraPosition);
                  // if(dx==0 && dy==0 && dz==0){
                  //   continue;
                  // }
                  // final currentIndices=faceBufferViews[dx+1][dy+1][dz+1];
                  // pass.bindIndexBuffer(currentIndices.bufferView, gpu.IndexType.int16, currentIndices.length);

                  if(!chunk.isBlockVisible(x, y, z, cameraPosition)){
                    continue;
                  }
                  //draw
                  if(block.type==BlockType.grass){
                    // mergedVertices.addAll(getBlockVertices(x+chunkDx.toDouble(), y.toDouble(), z+chunkDz.toDouble()));
                    // count++;
                    final trans=translation(x+chunkDx.toDouble(), y.toDouble(), z+chunkDz.toDouble());
                    final t = transient.emplace(float32Mat(trans,),);
                    pass.bindUniform(_translationSlot, t);
                    pass.draw();
                  }
                }
              }
            }
          }
        }else{
          //request
          chunkManager.generateChunk(chunkPosition,onComplete: onMapGenerated);
        }
      }
    }

    // final vertices = _transients.emplace(float32(mergedVertices));
    // pass.bindVertexBuffer(vertices, count*36);
    // final mvp = _transients.emplace(
    //   float32Mat(
    //     pvs ,
    //   ),
    // );
    // pass.bindUniform(frameInfoSlot, mvp);
    // pass.draw();

    commandBuffer.submit();
    final image = renderTexture.asImage();
    canvas.scale(1/dpr, 1/dpr);
    canvas.drawImage(image, Offset.zero, Paint());
  }



  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}


