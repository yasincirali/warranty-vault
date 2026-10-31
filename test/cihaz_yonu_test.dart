import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// v1 ships for iPhone only, upright only (Rafım Ar-Ge 31 Oct): sideways the
// cabinet shrank to a strip, the iPad layout was unfinished, and an iPad
// build needs iPad screenshots. Apple lets an app add iPad later but never
// drop it, so this is locked before the first release.
void main() {
  test('the Xcode project targets iPhone only', () {
    final pbx = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final families = RegExp(r'TARGETED_DEVICE_FAMILY = ([^;]+);').allMatches(pbx).map((m) => m.group(1)).toSet();
    expect(families, {'1'});
  });

  test('Info.plist allows portrait only and has no iPad orientation list', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, isNot(contains('UISupportedInterfaceOrientations~ipad')));
    expect(plist, isNot(contains('Landscape')));
    expect(plist, contains('UIInterfaceOrientationPortrait'));
  });

  test('the app locks portrait on Android too', () {
    expect(File('lib/main.dart').readAsStringSync(), contains('DeviceOrientation.portraitUp'));
  });
}
