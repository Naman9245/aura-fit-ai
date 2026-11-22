import 'package:aurafit/models/options.dart';
import 'package:drift/drift.dart';

/// Stores an option by its fixed [StoredOption.storage] string, the same
/// string the server's CHECK constraint allows.
class OptionConverter<T extends StoredOption> extends TypeConverter<T, String> {
  const OptionConverter(this.values);

  final List<T> values;

  @override
  T fromSql(String fromDb) => parseOption(values, fromDb);

  @override
  String toSql(T value) => value.storage;
}

/// Stores a calendar date, like a birthday or the day of a weigh-in, as
/// "2026-11-22", the form Postgres's `date` takes. A date has no time zone,
/// so it never moves a day when the phone's does.
///
/// Dates come back as local midnight; only the year, month and day count.
class DateConverter extends TypeConverter<DateTime, String> {
  const DateConverter();

  @override
  DateTime fromSql(String fromDb) {
    final [year, month, day] = fromDb.split('-').map(int.parse).toList();
    return DateTime(year, month, day);
  }

  @override
  String toSql(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
