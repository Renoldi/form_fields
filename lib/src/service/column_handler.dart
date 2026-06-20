/// ColumnHandler defines how to process a column's value on write and how to
/// cleanup when rows are deleted. Implementations live in separate helpers
/// (e.g. `payload_handler.dart`) to keep concerns separated.
abstract class ColumnHandler {
  /// Called before insert/update. Should return the value to be stored
  /// in the database (e.g., a filename) and may perform side-effects like
  /// writing files.
  Future<dynamic> onWrite(String table, String column, dynamic value);

  /// Called before the row is deleted. [row] contains the full row values as
  /// returned from the DB query. Implementations should cleanup any side
  /// effects (e.g., delete files).
  Future<void> onDelete(String table, String column, Map<String, dynamic> row);
}
