import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gpu_demo/config.dart';
import 'package:flutter_gpu_demo/gpu/utils.dart';
import 'package:flutter_gpu_demo/gpu/world_data.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:vector_math/vector_math.dart' as vm;
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'materials.dart';
import 'shaders.dart';
import 'dart:ui' as ui;
import 'dart:developer' as developer;

class WorldRender extends CustomPainter {
  VoidCallback onTerrainGenerated;
  Vector3 cameraPosition = Vector3(0, 0, 0);
  double horizonRotate = 0.0;
  double verticalRotate = 0.0;
  double renderRatio;
  MediaQueryData mediaQueryData;

  //resource
  late gpu.RenderPipeline _blockPipeline;
  late gpu.RenderPipeline _sunPipeline;

  late gpu.Texture _grassTexture;
  late gpu.Texture _logTexture;
  late gpu.Texture _leafTexture;
  late gpu.Texture _waterTexture;
  final samplerOptions = gpu.SamplerOptions(mipFilter: gpu.MipFilter.linear);
  //buffer
  late gpu.HostBuffer _hostBuffer;
  late gpu.HostBuffer _transient;

  Matrix4? _perspectiveMatrix;

  Size? _lastSize;
  //uniform
  late gpu.UniformSlot _frameInfoSlot;
  late gpu.UniformSlot _texSlot;
  late gpu.UniformSlot _viewPosSlot;
  //sun
  late gpu.UniformSlot _sunFrameInfoSlot;
  late gpu.UniformSlot _sunColorSlot;
  //lighting
  late gpu.UniformSlot _lightSlot;
  //material
  late gpu.UniformSlot _materialSlot;
  //fog
  late gpu.UniformSlot _fogSlot;
  //instance
  late PhongMaterialBuffered _grassMaterial;
  late PhongMaterialBuffered _logMaterial;
  late PhongMaterialBuffered _leafMaterial;
  late PhongMaterialBuffered _waterMaterial;
  gpu.BufferView? _fogBufferView;

  late double dpr;

  final ValueNotifier<int> notifier;
  WorldRender(
    this.cameraPosition,
    this.horizonRotate,
    this.verticalRotate,
    this.onTerrainGenerated,
    this.mediaQueryData,
    this.renderRatio,
    this.notifier,
  ) : super(repaint: notifier) {
    dpr = mediaQueryData.devicePixelRatio * renderRatio;
    //shader
    final vertexShader = shaderLibrary["BaseVertex"]!;
    final fragmentShader = shaderLibrary["BaseFragment"]!;
    final sunVertexShader = shaderLibrary["SunVertex"]!;
    final sunFragmentShader = shaderLibrary["SunFragment"]!;
    //pipeline
    _blockPipeline = gpu.gpuContext.createRenderPipeline(
      vertexShader,
      fragmentShader,
    );
    _sunPipeline = gpu.gpuContext.createRenderPipeline(
      sunVertexShader,
      sunFragmentShader,
    );
    //uniform
    _frameInfoSlot = _blockPipeline.vertexShader.getUniformSlot('FrameInfo');
    _texSlot = _blockPipeline.fragmentShader.getUniformSlot('tex');
    _viewPosSlot = _blockPipeline.fragmentShader.getUniformSlot('CameraBlock');
    _lightSlot = _blockPipeline.fragmentShader.getUniformSlot('LightBlock');
    _materialSlot = _blockPipeline.fragmentShader.getUniformSlot(
      'MaterialBlock',
    );
    _fogSlot = _blockPipeline.fragmentShader.getUniformSlot('FogBlock');
    //sun
    _sunFrameInfoSlot = _sunPipeline.vertexShader.getUniformSlot('FrameInfo');
    _sunColorSlot = _sunPipeline.fragmentShader.getUniformSlot('SunBlock');
    //texture
    final grassImg = imageAssets.grass;
    _grassTexture = gpu.gpuContext.createTexture(
      gpu.StorageMode.hostVisible,
      grassImg.width,
      grassImg.height,
      enableShaderReadUsage: true,
    );
    _grassTexture.overwrite(grassImg.data);
    final logImg = imageAssets.log;
    _logTexture = gpu.gpuContext.createTexture(
      gpu.StorageMode.hostVisible,
      logImg.width,
      logImg.height,
      enableShaderReadUsage: true,
    );
    _logTexture.overwrite(logImg.data);
    final leafImg = imageAssets.leaf;
    _leafTexture = gpu.gpuContext.createTexture(
      gpu.StorageMode.hostVisible,
      leafImg.width,
      leafImg.height,
      enableShaderReadUsage: true,
    );
    _leafTexture.overwrite(leafImg.data);
    final waterImg = imageAssets.water;
    _waterTexture = gpu.gpuContext.createTexture(
      gpu.StorageMode.hostVisible,
      waterImg.width,
      waterImg.height,
      enableShaderReadUsage: true,
    );
    _waterTexture.overwrite(waterImg.data);
    //buffer
    _hostBuffer = gpu.gpuContext.createHostBuffer();
    _transient = gpu.gpuContext.createHostBuffer();
    //material
    _grassMaterial = PhongMaterialBuffered.from(
      BlinnPhongMaterial.grass,
      _hostBuffer,
    );
    _logMaterial = PhongMaterialBuffered.from(
      BlinnPhongMaterial.log,
      _hostBuffer,
    );
    _leafMaterial = PhongMaterialBuffered.from(
      BlinnPhongMaterial.leaf,
      _hostBuffer,
    );
    _waterMaterial = PhongMaterialBuffered.from(
      BlinnPhongMaterial.water,
      _hostBuffer,
    );
  }
  void setLightingMaterial(
    gpu.RenderPass pass,
    LightMaterialBuffered material,
  ) {
    pass.bindUniform(_lightSlot, material.data);
  }

  void setMaterial(gpu.RenderPass pass, PhongMaterialBuffered material) {
    pass.bindUniform(_materialSlot, material.data);
  }

  ChunkBufferView? getChunkFaceBuffer(ChunkPosition position) {
    //if it's cached, return it
    final chunk = chunkManager.chunks[position]!;
    final res = chunk.chunkBufferView;
    if (res != null) {
      return res;
    }
    final buffer = _calculateChunkBuffer(chunk);
    if (buffer != null) {
      chunk.chunkBufferView = buffer;
    }
    return buffer;
  }

  void _buildFogBuffer() {
    final far = ((viewDistance) * chunkSize);
    final fogData = FogData(
      selectedLighting.raw.skyColor,
      far * fogStart,
      far * fogEnd,
      fogHeightCompression,
    );
    _fogBufferView = _hostBuffer.emplace(float32(fogData.toArray()));
  }

  ChunkBufferView? _calculateChunkBuffer(Chunk chunk) {
    if (chunk.chunkData == null) {
      return null;
    }
    if (!chunkManager.isChunkWarpAvailable(chunk.position)) {
      return null;
    }
    final chunkData = chunk.chunkData!;
    final log = <double>[];
    final leaf = <double>[];
    final grass = <double>[];
    final water = <double>[];
    for (int x = 0; x < chunkSize; x++) {
      for (int z = 0; z < chunkSize; z++) {
        for (int y = 0; y < maxHeight; y++) {
          final block = chunkData.dataXzy[x][z][y];
          final blockType = block.type;
          if (blockType == BlockType.air) {
            continue;
          }
          final faces = chunk.allVisibleFaces(x, y, z);
          if (faces.isEmpty) {
            continue;
          }
          if (blockType == BlockType.log) {
            log.addAll(faces);
          } else if (blockType == BlockType.leaf) {
            leaf.addAll(faces);
          } else if (blockType == BlockType.grass) {
            grass.addAll(faces);
          } else if (blockType == BlockType.water) {
            water.addAll(faces);
          }
        }
      }
    }
    final res = ChunkBufferView(
      grass: BufferWithLength(
        (_hostBuffer.emplace(float32(grass))),
        (grass.length / itemsPerVertex).toInt(),
      ),
      log: BufferWithLength(
        (_hostBuffer.emplace(float32(log))),
        (log.length / itemsPerVertex).toInt(),
      ),
      leaf: BufferWithLength(
        (_hostBuffer.emplace(float32(leaf))),
        (leaf.length / itemsPerVertex).toInt(),
      ),
      water: BufferWithLength(
        (_hostBuffer.emplace(float32(water))),
        (water.length / itemsPerVertex).toInt(),
      ),
    );
    return res;
  }

  final chunkRadius =
      sqrt(chunkSize * chunkSize / 2.0 + maxHeight * maxHeight / 4.0) +
      itemsPerVertex; // 区块对角线一半
  bool isChunkVisible(ChunkPosition pos, Matrix4 viewProj) {
    final chunkCenter = Vector3(
      (pos.x * chunkSize + chunkSize / 2).toDouble(),
      maxHeight / 2,
      (pos.z * chunkSize + chunkSize / 2).toDouble(),
    );

    return frustumContainsSphere(viewProj, chunkCenter, chunkRadius);
  }

  void configRenderPass(gpu.RenderPass pass) {
    pass.setDepthWriteEnable(true);
    pass.setDepthCompareOperation(gpu.CompareFunction.less);
    setColorBlend(pass);
  }

  ui.Image? image;
  gpu.RenderTarget? _renderTarget;
  late gpu.Texture _renderTexture;
  late gpu.Texture _depthTexture;
  @override
  void paint(Canvas canvas, Size size) {
    try {
      _paint(size);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        developer.log("paint error!:$e\n$stackTrace");
      }
    }
    if (image != null) {
      canvas.scale(1 / dpr, 1 / dpr);
      canvas.drawImage(image!, Offset.zero, Paint());
    }
  }

  void buildRenderTarget(int width, int height) {
    //texture
    _renderTexture = gpu.gpuContext.createTexture(
      gpu.StorageMode.devicePrivate,
      width,
      height,
      enableRenderTargetUsage: true,
      sampleCount: 1,
      enableShaderReadUsage: true,
      coordinateSystem: gpu.TextureCoordinateSystem.renderToTexture,
    );

    _depthTexture = gpu.gpuContext.createTexture(
      gpu.StorageMode.deviceTransient,
      width,
      height,
      format: gpu.gpuContext.defaultDepthStencilFormat,
      enableRenderTargetUsage: true,
      coordinateSystem: gpu.TextureCoordinateSystem.renderToTexture,
    );
    onlyBuildRenderTarget();
  }

  void onlyBuildRenderTarget() {
    //target
    _renderTarget = gpu.RenderTarget.singleColor(
      gpu.ColorAttachment(
        texture: _renderTexture,
        clearValue: selectedLighting.raw.skyColor,
      ),
      depthStencilAttachment: gpu.DepthStencilAttachment(
        texture: _depthTexture,
        depthClearValue: 1,
      ),
    );
  }

  void _paint(Size size) {
    final width = (size.width * dpr).toInt();
    final height = (size.height * dpr).toInt();
    // 仅在尺寸变化时更新透视矩阵,target
    if (_perspectiveMatrix == null ||
        _renderTarget == null ||
        size != _lastSize) {
      _perspectiveMatrix = makePerspectiveMatrix(
        fov * (3.141592653589793 / 180.0),
        size.aspectRatio,
        0.01,
        1000,
      );
      _lastSize = size;
      buildRenderTarget(width, height);
    } else if (rebuildTargetFlag) {
      onlyBuildRenderTarget();
    }
    rebuildTargetFlag = false;
    //build fog
    if (_fogBufferView == null || rebuildFogBufferFlag) {
      _buildFogBuffer();
    }
    rebuildFogBufferFlag = false;

    //command buffer
    final commandBuffer = gpu.gpuContext.createCommandBuffer();
    //pass
    final pass = commandBuffer.createRenderPass(_renderTarget!);
    configRenderPass(pass);


    final persp = _perspectiveMatrix!;
    final focusDirection = Vector3(
      cos(horizonRotate) * cos(verticalRotate),
      sin(verticalRotate),
      -sin(horizonRotate) * cos(verticalRotate),
    );

    final view = makeViewMatrix(
      cameraPosition,
      focusDirection + cameraPosition,
      upDirection,
    );
    final pvs = persp * view;
    final mvp = _transient.emplace(float32Mat(pvs));
    //----------- sun -----------------
    //use sun pipeline
    pass.bindPipeline(_sunPipeline);
    pass.setCullMode(gpu.CullMode.none);
    final (sunVertices, sunCenter) = calculateSunVertex(
      cameraPosition,
      selectedLighting.raw.direction,
      sunDistance,
      sunRadius,
    );
    final sunData = SunData(
      selectedLighting.raw.specular,
      sunCenter,
      sunRadius*sunBlurStart,
      sunRadius*sunBlurEnd,
    );
    //bind vertex
    //uniform
    pass.bindVertexBuffer(_transient.emplace(float32(sunVertices)), 6);
    pass.bindUniform(_sunFrameInfoSlot, mvp);
    pass.bindUniform(
      _sunColorSlot,
      _transient.emplace(float32(sunData.toArray())),
    );
    pass.draw();
    //---------------- sun end ----------------------



    //use block pipeline
    pass.bindPipeline(_blockPipeline);
    //uniform
    pass.bindUniform(_frameInfoSlot, mvp);
    final viewPos = _transient.emplace(float32(cameraPosition.storage));
    pass.bindUniform(_viewPosSlot, viewPos);
    setLightingMaterial(pass, selectedLighting);
    //bind fog
    pass.bindUniform(_fogSlot, _fogBufferView!);

    //calc chunk
    final int x = ((cameraPosition.x + radius) / chunkSize).floor();
    final int z = ((cameraPosition.z + radius) / chunkSize).floor();
    //leaves
    List<BufferWithLength> leaves = [];
    //water
    List<BufferWithLength> water = [];
    //cull
    pass.setCullMode(gpu.CullMode.backFace);
    final chunkViewRadiusSquared = pow(viewDistance + 1, 2);
    for (
      int chunkDistanceX = -viewDistance;
      chunkDistanceX <= viewDistance;
      chunkDistanceX++
    ) {
      final zRange = sqrt(
        chunkViewRadiusSquared - chunkDistanceX * chunkDistanceX,
      ).floor();
      for (
        int chunkDistanceZ = -zRange;
        chunkDistanceZ <= zRange;
        chunkDistanceZ++
      ) {
        final chunkPosition = ChunkPosition(
          x + chunkDistanceX,
          z + chunkDistanceZ,
        );
        if (!isChunkVisible(chunkPosition, pvs)) {
          continue;
        }
        final chunk = chunkManager.chunks[chunkPosition];
        if (chunk != null) {
          chunkManager.ensureChunkWarp(
            chunkPosition,
            onComplete: onTerrainGenerated,
          );
          final buffer = getChunkFaceBuffer(chunkPosition);
          if (buffer != null) {
            //grass
            setMaterial(pass, _grassMaterial);
            pass.bindTexture(_texSlot, _grassTexture, sampler: samplerOptions);
            pass.bindVertexBuffer(buffer.grass.bufferView, buffer.grass.length);
            pass.draw();
            //log
            setMaterial(pass, _logMaterial);
            pass.bindTexture(_texSlot, _logTexture, sampler: samplerOptions);
            pass.bindVertexBuffer(buffer.log.bufferView, buffer.log.length);
            pass.draw();
            //leaf
            leaves.add(buffer.leaf);
            //water
            water.add(buffer.water);
          }
        } else {
          //request
          chunkManager.requestGenerateChunk(
            chunkPosition,
            onComplete: onTerrainGenerated,
          );
        }
      }
    }
    pass.setCullMode(gpu.CullMode.none);
    //draw water
    void drawWater(){
      setMaterial(pass, _waterMaterial);
      pass.bindTexture(_texSlot, _waterTexture, sampler: samplerOptions);
      for (final water in water) {
        pass.bindVertexBuffer(water.bufferView, water.length);
        pass.draw();
      }
    }
    //draw leaves
    void drawLeaves(){
      setMaterial(pass, _leafMaterial);
      pass.bindTexture(_texSlot, _leafTexture, sampler: samplerOptions);
      for (final leaf in leaves) {
        pass.bindVertexBuffer(leaf.bufferView, leaf.length);
        pass.draw();
      }
    }
    if(cameraPosition.y<waterLevel){
      drawLeaves();
      drawWater();
    }else{
      drawWater();
      drawLeaves();
    }

    commandBuffer.submit(
      completionCallback: (state) {
        _transient.reset();
        final old = image;
        image = _renderTexture.asImage();
        old?.dispose();
      },
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
