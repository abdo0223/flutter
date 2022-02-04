// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import 'base/io.dart' as io;
import 'base/logger.dart';
import 'convert.dart';
import 'resident_runner.dart';

/// An implementation of the devtools launcher that uses `pub global activate` to
/// start a server instance.
class DevtoolsServerLauncher extends DevtoolsLauncher {
  DevtoolsServerLauncher({
    @required ProcessManager processManager,
    @required String dartExecutable,
    @required Logger logger,
  })  : _processManager = processManager,
        _dartExecutable = dartExecutable,
        _logger = logger;

  final ProcessManager _processManager;
  final String _dartExecutable;
  final Logger _logger;
  final Completer<void> _processStartCompleter = Completer<void>();

  io.Process _devToolsProcess;

  static final RegExp _serveDevToolsPattern =
      RegExp(r'Serving DevTools at ((http|//)[a-zA-Z0-9:/=_\-\.\[\]]+?)\.?$');

  @override
  Future<void> get processStart => _processStartCompleter.future;

  @override
  Future<void> launch(Uri vmServiceUri, {List<String> additionalArguments}) async {
    // Place this entire method in a try/catch that swallows exceptions because
    // this method is guaranteed not to return a Future that throws.
    try {
      _devToolsProcess = await _processManager.start(<String>[
        _dartExecutable,
        'devtools',
        '--no-launch-browser',
        if (vmServiceUri != null) '--vm-uri=$vmServiceUri',
        ...?additionalArguments,
      ]);
      _processStartCompleter.complete();
      final Completer<Uri> completer = Completer<Uri>();
      _devToolsProcess.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((String line) {
            final Match match = _serveDevToolsPattern.firstMatch(line);
            if (match != null) {
              final String url = match[1];
              completer.complete(Uri.parse(url));
            }
         });
      _devToolsProcess.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_logger.printError);
      devToolsUrl = await completer.future;
    } on Exception catch (e, st) {
      _logger.printError('Failed to launch DevTools: $e', stackTrace: st);
    }
  }

<<<<<<< HEAD
  Future<bool> _checkForActiveDevTools() async {
    // We are offline, and cannot activate DevTools, so check if the DevTools
    // package is already active.
    final io.ProcessResult _pubGlobalListProcess = await _processManager.run(<String>[
      _pubExecutable,
      'global',
      'list',
    ]);

    if (_pubGlobalListProcess.stdout.toString().contains('devtools ')) {
      return true;
    }
    return false;
  }

  /// Helper method to activate the DevTools pub package.
  ///
  /// Returns a bool indicating whether or not the package was successfully
  /// activated from pub.
  Future<bool> _activateDevTools() async {
    final DateTime now = DateTime.now();
    // Only attempt to activate DevTools twice a day.
    final bool shouldActivate =
        _persistentToolState.lastDevToolsActivationTime == null ||
        now.difference(_persistentToolState.lastDevToolsActivationTime).inHours >= 12;
    if (!shouldActivate) {
      return false;
    }

    final Status status = _logger.startProgress(
      'Activating Dart DevTools...',
    );
    try {
      final io.ProcessResult _devToolsActivateProcess = await _processManager
          .run(<String>[
        _pubExecutable,
        'global',
        'activate',
        'devtools'
      ]);
      if (_devToolsActivateProcess.exitCode != 0) {
        _logger.printError('Error running `pub global activate '
            'devtools`:\n${_devToolsActivateProcess.stderr}');
        return false;
      }
      _persistentToolState.lastDevToolsActivationTime = DateTime.now();
      return true;
    } on Exception catch (e, _) {
      _logger.printError('Error running `pub global activate devtools`: $e');
      return false;
    } finally {
      status.stop();
    }
  }

=======
>>>>>>> 5f105a6ca7a5ac7b8bc9b241f4c2d86f4188cf5c
  @override
  Future<DevToolsServerAddress> serve() async {
    if (activeDevToolsServer == null) {
      await launch(null);
    }
    return activeDevToolsServer;
  }

  @override
  Future<void> close() async {
    if (devToolsUrl != null) {
      devToolsUrl = null;
    }
    if (_devToolsProcess != null) {
      _devToolsProcess.kill();
      await _devToolsProcess.exitCode;
    }
  }
}
