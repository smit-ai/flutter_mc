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
  Vector3 cameraPosition = Vector3(0, 0, 0);
  double horizonRotate = 0.0;
  double verticalRotate = 0.0;
  int viewDistance= kDebugMode?1:2;
  //resource
  late gpu.RenderPipeline _pipeline;
  late gpu.Texture _sampledTexture;
  late gpu.HostBuffer _transients;
  Matrix4? _perspectiveMatrix;
  Size? _lastSize;
  WorldRender(this.cameraPosition, this.horizonRotate, this.verticalRotate){
    //shader
    final vertexShader = shaderLibrary["BaseVertex"]!;
    final fragmentShader = shaderLibrary["BaseFragment"]!;
    //pipeline
    _pipeline = gpu.gpuContext.createRenderPipeline(
      vertexShader,
      fragmentShader,
    );
    //texture
    final mainImg=imageAssets.grass;
    _sampledTexture = gpu.gpuContext.createTexture(
        gpu.StorageMode.hostVisible, mainImg.width, mainImg.height,
        enableShaderReadUsage: true
    );
    _sampledTexture.overwrite(mainImg.data);
    //buffer
    _transients = gpu.gpuContext.createHostBuffer();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width.toInt();
    final height = size.height.toInt();
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


    final vertices = _transients.emplace(blockVertices);
    // final indices = transients.emplace(cubeIndices);
    pass.bindVertexBuffer(vertices, 36);
    // pass.bindIndexBuffer(indices, gpu.IndexType.int16, 36);

    //cull
    pass.setCullMode(gpu.CullMode.backFace);


    final texSlot = _pipeline.fragmentShader.getUniformSlot('tex');
    pass.bindTexture(texSlot, _sampledTexture);

    //uniform
    final frameInfoSlot = _pipeline.vertexShader.getUniformSlot('FrameInfo');
    final persp = _perspectiveMatrix!;
    final focusDirection = Vector3(
      cos(horizonRotate) * cos(verticalRotate),
      sin(verticalRotate),
      -sin(horizonRotate) * cos(verticalRotate),
    );
    final view = makeViewMatrix(cameraPosition, focusDirection+cameraPosition, upDirection);
    final pvs=persp*view;
    //calc chunk
    final x=cameraPosition.x/chunkSize;
    final z=cameraPosition.z/chunkSize;

    for(int chunkDistanceX=-viewDistance;chunkDistanceX<=viewDistance;chunkDistanceX++){
      for(int chunkDistanceZ=-viewDistance;chunkDistanceZ<=viewDistance;chunkDistanceZ++){
        final chunkPosition=ChunkPosition(x.floor()+chunkDistanceX, z.floor()+chunkDistanceZ);
        if(chunkManager.isExists(chunkPosition)){
          final chunk=chunkManager.chunks[chunkPosition]!;
          final chunkData=chunk.chunkData;
          if(chunkData!=null){
            final (chunkDx,chunkDz)=chunkPosition.toWorldIndex();
            for(int x=0;x<chunkSize;x++){
              for(int z=0;z<chunkSize;z++){
                for(int y=0;y<maxHeight;y++){
                  final block=chunkData.data[x][y][z];
                  //draw
                  if(block.type==BlockType.grass){
                    final trans=translation(x+chunkDx.toDouble(), y.toDouble(), z+chunkDz.toDouble());
                    final mvp = _transients.emplace(
                      float32Mat(
                        pvs *trans,
                      ),
                    );
                    pass.bindUniform(frameInfoSlot, mvp);
                    pass.draw();
                  }
                }
              }
            }
          }
        }else{
          //request
          chunkManager.generateChunk(chunkPosition);
        }
      }
    }
    commandBuffer.submit();
    final image = renderTexture.asImage();
    canvas.drawImage(image, Offset(0, 0), Paint());
  }



  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}


