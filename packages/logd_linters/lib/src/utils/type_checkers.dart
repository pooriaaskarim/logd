// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

// ignore_for_file: comment_references

/// Shared [TypeChecker] constants for logd types.
///
/// All rules resolve logd types through these checkers to avoid repeated
/// reflection lookups during AST visits.
library;

import 'package:custom_lint_builder/custom_lint_builder.dart';

// ---------------------------------------------------------------------------
// Core Abstractions
// ---------------------------------------------------------------------------

/// Matches [Logger] from `package:logd`.
const loggerChecker = TypeChecker.fromName(
  'Logger',
  packageName: 'logd',
);

/// Matches [LogLevel] from `package:logd`.
const logLevelChecker = TypeChecker.fromName(
  'LogLevel',
  packageName: 'logd',
);

/// Matches [LogTag] from `package:logd`.
const logTagChecker = TypeChecker.fromName(
  'LogTag',
  packageName: 'logd',
);

/// Matches [LogMetadata] from `package:logd`.
const logMetadataChecker = TypeChecker.fromName(
  'LogMetadata',
  packageName: 'logd',
);

/// Matches [LogEntry] from `package:logd`.
const logEntryChecker = TypeChecker.fromName(
  'LogEntry',
  packageName: 'logd',
);

/// Matches [LogBuffer] from `package:logd`.
const logBufferChecker = TypeChecker.fromName(
  'LogBuffer',
  packageName: 'logd',
);

/// Matches [LoggerConfig] from `package:logd`.
const loggerConfigChecker = TypeChecker.fromName(
  'LoggerConfig',
  packageName: 'logd',
);

/// Matches [LoggerCache] from `package:logd`.
const loggerCacheChecker = TypeChecker.fromName(
  'LoggerCache',
  packageName: 'logd',
);

// ---------------------------------------------------------------------------
// Handler Layer
// ---------------------------------------------------------------------------

/// Matches [Handler] from `package:logd`.
const handlerChecker = TypeChecker.fromName(
  'Handler',
  packageName: 'logd',
);

/// Matches [LogFormatter] from `package:logd`.
const logFormatterChecker = TypeChecker.fromName(
  'LogFormatter',
  packageName: 'logd',
);

/// Matches [LogDecorator] from `package:logd`.
const logDecoratorChecker = TypeChecker.fromName(
  'LogDecorator',
  packageName: 'logd',
);

/// Matches [LogSink] from `package:logd`.
const logSinkChecker = TypeChecker.fromName(
  'LogSink',
  packageName: 'logd',
);

/// Matches [LogEngine] from `package:logd`.
const logEngineChecker = TypeChecker.fromName(
  'LogEngine',
  packageName: 'logd',
);

// ---------------------------------------------------------------------------
// Decorators
// ---------------------------------------------------------------------------

/// Matches [ContentDecorator] from `package:logd`.
const contentDecoratorChecker = TypeChecker.fromName(
  'ContentDecorator',
  packageName: 'logd',
);

/// Matches [StructuralDecorator] from `package:logd`.
const structuralDecoratorChecker = TypeChecker.fromName(
  'StructuralDecorator',
  packageName: 'logd',
);

/// Matches [VisualDecorator] from `package:logd`.
const visualDecoratorChecker = TypeChecker.fromName(
  'VisualDecorator',
  packageName: 'logd',
);

// ---------------------------------------------------------------------------
// Sinks
// ---------------------------------------------------------------------------

/// Matches [PrintSink] from `package:logd`.
const printSinkChecker = TypeChecker.fromName(
  'PrintSink',
  packageName: 'logd',
);

/// Matches [ConsoleSink] from `package:logd`.
const consoleSinkChecker = TypeChecker.fromName(
  'ConsoleSink',
  packageName: 'logd',
);

/// Matches [FileSink] from `package:logd`.
const fileSinkChecker = TypeChecker.fromName(
  'FileSink',
  packageName: 'logd',
);

/// Matches [NetworkSink] from `package:logd`.
const networkSinkChecker = TypeChecker.fromName(
  'NetworkSink',
  packageName: 'logd',
);

/// Matches [IsolateSink] from `package:logd`.
const isolateSinkChecker = TypeChecker.fromName(
  'IsolateSink',
  packageName: 'logd',
);

/// Matches [NativeIsolateSink] from `package:logd`.
const nativeIsolateSinkChecker = TypeChecker.fromName(
  'NativeIsolateSink',
  packageName: 'logd',
);

// ---------------------------------------------------------------------------
// Semantic IR / Pipeline
// ---------------------------------------------------------------------------

/// Matches [LogPipelineFactory] from `package:logd`.
const logPipelineFactoryChecker = TypeChecker.fromName(
  'LogPipelineFactory',
  packageName: 'logd',
);

/// Matches [LogDocument] from `package:logd`.
const logDocumentChecker = TypeChecker.fromName(
  'LogDocument',
  packageName: 'logd',
);

/// Matches [LogNode] from `package:logd`.
const logNodeChecker = TypeChecker.fromName(
  'LogNode',
  packageName: 'logd',
);
