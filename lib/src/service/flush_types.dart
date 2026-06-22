typedef SubmitHandler = Future<bool> Function(
    Map<String, dynamic> payload, int? id);

typedef FlushAllHandler = Future<bool> Function({
  SubmitHandler? submitHandler,
  bool skipFlushStateGuard,
});

typedef FlushOneHandler = Future<bool> Function(int id,
    {SubmitHandler? submitHandler, required bool skipFlushStateGuard});
