[![pub package](https://img.shields.io/pub/v/buxing.svg)](https://pub.dev/packages/buxing)
[![Build Status](https://github.com/mgenware/buxing/workflows/Build/badge.svg)](https://github.com/mgenware/buxing/actions)

An HTTP file downloader packed with many features -> resumable downloads, multiple connections, buffering, auto-retry, etc.

## Features

- Resumable downloads.
- Supports multiple connections.
- Auto buffering for less disk writes.
- Auto HTTP connection retry via the builtin `RetryClient`.

## Usage

Install and import this package:

```sh
import 'package:buxing/buxing.dart';
```

### A simple task

```dart
void main() async {
  var task = Task(
      Uri.parse('https://golang.org/dl/go1.17.3.src.tar.gz'), 'go1.17.3.src.tar.gz');
  await task.start();
}
```

### Progress reporting

Progress events are raised through `Task.onProgress`:

```dart
task.onProgress = (prog) => print(prog.transferred / prog.total);
```

### Multiple connections

To enable multiple connections, set the optional `worker` param in constructor and pass a `ParallelWorker`.

```dart
var task = Task(Uri.parse('https://golang.org/dl/go1.17.3.src.tar.gz'),
    'go1.17.3.src.tar.gz',
    worker: ParallelWorker()); // A `ParallelWorker` enables multiple connections.
```

By default `ParallelWorker` manages concurrency by itself, you can explicitly set the number of concurrent connections:

```dart
ParallelWorker(concurrency: 10)
```

### Buffer size

> The defaults are, 200 KB for a single-connection task, 50 KB per connection for a multi-connection task.

To set the buffer size:

```dart
// Single-connection task
var task = Task(Uri.parse('URL'), 'FILE',
    worker: Worker(bufferSize: 100000)); // 100 KB

// Multi-connection task.
var task = Task(Uri.parse('URL'), 'FILE',
    worker: ParallelWorker(bufferSize: 100000)); // 100 KB
```

### Logging

To enable logging, set the `logger` field:

```dart
var task = Task(Uri.parse('https://golang.org/dl/go1.17.3.src.tar.gz'),
    'downloads/go1.17.3.src.tar.gz',
    logger: Logger(level: LogLevel.info));
```

Log levels:

```dart
enum LogLevel { verbose, info, warning, error }
```
