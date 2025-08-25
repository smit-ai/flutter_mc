import 'package:flutter_gpu_shaders/build.dart';
import 'package:native_assets_cli/native_assets_cli.dart';

void main(List<String> args) async {
  await build(args, (config, output) async {
    await buildShaderBundleJson(
        buildInput: config,
        buildOutput: output,
        manifestFileName: 'my_renderer.shaderbundle.json');
  });
}