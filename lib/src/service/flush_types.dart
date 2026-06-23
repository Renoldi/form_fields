typedef SubmitHandler = Future<bool> Function(
    Map<String, dynamic> payload, int? id);

/// Background task handler signature compatible with the package's
/// background/foreground adapter callbacks: `(taskName, inputData) -> Future<bool>`.
typedef BackgroundTaskHandler = Future<bool> Function(
    String task, Map<String, dynamic>? inputData);

typedef FlushAllHandler = Future<bool> Function({
  SubmitHandler? submitHandler,
  bool skipFlushStateGuard,
});

typedef FlushOneHandler = Future<bool> Function(int id,
    {SubmitHandler? submitHandler, required bool skipFlushStateGuard});
