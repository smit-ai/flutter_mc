import 'package:flutter/material.dart';

import '../config.dart';

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      spacing: 20,
      children: [
        Text('Flutter MC',textScaler: TextScaler.linear(2),),
        Text("Using Flutter GPU API & Impeller Engine"),
        Text("Made By 57U"),
        Text("Open Source: https://github.com/57UU/flutter_mc"),
        Text("Version: $version($buildNumber)"),
      ],
    );
  }
}
