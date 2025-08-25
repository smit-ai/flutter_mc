import 'package:flutter_gpu/gpu.dart' as gpu;

const String _kShaderBundlePath =
    'build/shaderbundles/my_renderer.shaderbundle';

// 这是 Flutter GPU 着色器运行时库的单例 getter
gpu.ShaderLibrary? _shaderLibrary;
gpu.ShaderLibrary get shaderLibrary {
  if (_shaderLibrary != null) {
    return _shaderLibrary!;
  }
  _shaderLibrary = gpu.ShaderLibrary.fromAsset(_kShaderBundlePath);
  if (_shaderLibrary != null) {
    return _shaderLibrary!;
  }

  throw Exception("加载着色器包失败！($_kShaderBundlePath)");
}
gpu.Shader loadShader(String name){
  return shaderLibrary.shaders_[name]!;
}
