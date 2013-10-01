// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  integration("detects an ordering dependency cycle", () {
    d.dir("foo", [
      d.pubspec({
        "name": "foo",
        "version": "1.0.0",
        "transformers": ["myapp/transformer"],
        "dependencies": {'myapp': {'path': '../myapp'}}
      })
    ]).create();

    d.dir("bar", [
      d.pubspec({
        "name": "bar",
        "version": "1.0.0",
        "dependencies": {'foo': {'path': '../foo'}}
      }),
      d.dir("lib", [
        d.file("transformer.dart", dartTransformer('bar')),
      ])
    ]).create();

    d.dir("baz", [
      d.pubspec({
        "name": "baz",
        "version": "1.0.0",
        "transformers": ["bar/transformer"],
        "dependencies": {'bar': {'path': '../bar'}}
      })
    ]).create();

    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "dependencies": {'baz': {'path': '../baz'}}
      }),
      d.dir("lib", [
        d.file("transformer.dart", dartTransformer('myapp')),
      ])
    ]).create();

    createLockFile('myapp', sandbox: ['foo', 'bar', 'baz'], pkg: ['barback']);

    // Use port 0 to get an ephemeral port.
    var process = startPub(args: ["serve", "--port=0", "--hostname=127.0.0.1"]);
    process.shouldExit(1);
    expect(process.remainingStderr(), completion(equals(
        "Transformer cycle detected:\n"
        "  bar depends on foo\n"
        "  foo is transformed by myapp/transformer\n"
        "  myapp depends on baz\n"
        "  baz is transformed by bar/transformer")));
  });
}