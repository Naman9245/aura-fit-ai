// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles
    with TableInfo<$ProfilesTable, ProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    check: () => id.equals(1),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> birthDate =
      GeneratedColumn<String>(
        'birth_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ProfilesTable.$converterbirthDate);
  @override
  late final GeneratedColumnWithTypeConverter<Sex?, String> sex =
      GeneratedColumn<String>(
        'sex',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Sex?>($ProfilesTable.$convertersexn);
  static const VerificationMeta _heightCmMeta = const VerificationMeta(
    'heightCm',
  );
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
    'height_cm',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ActivityLevel, String>
  activityLevel = GeneratedColumn<String>(
    'activity_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ActivityLevel>($ProfilesTable.$converteractivityLevel);
  @override
  late final GeneratedColumnWithTypeConverter<DietType?, String> dietType =
      GeneratedColumn<String>(
        'diet_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DietType?>($ProfilesTable.$converterdietTypen);
  @override
  late final GeneratedColumnWithTypeConverter<TrainingPlace?, String>
  trainingPlace = GeneratedColumn<String>(
    'training_place',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<TrainingPlace?>($ProfilesTable.$convertertrainingPlacen);
  @override
  late final GeneratedColumnWithTypeConverter<Experience?, String> experience =
      GeneratedColumn<String>(
        'experience',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Experience?>($ProfilesTable.$converterexperiencen);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    dirty,
    id,
    birthDate,
    sex,
    heightCm,
    activityLevel,
    dietType,
    trainingPlace,
    experience,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('height_cm')) {
      context.handle(
        _heightCmMeta,
        heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta),
      );
    } else if (isInserting) {
      context.missing(_heightCmMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileRow(
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      birthDate: $ProfilesTable.$converterbirthDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}birth_date'],
        )!,
      ),
      sex: $ProfilesTable.$convertersexn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sex'],
        ),
      ),
      heightCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height_cm'],
      )!,
      activityLevel: $ProfilesTable.$converteractivityLevel.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}activity_level'],
        )!,
      ),
      dietType: $ProfilesTable.$converterdietTypen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}diet_type'],
        ),
      ),
      trainingPlace: $ProfilesTable.$convertertrainingPlacen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}training_place'],
        ),
      ),
      experience: $ProfilesTable.$converterexperiencen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}experience'],
        ),
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $converterbirthDate =
      const DateConverter();
  static TypeConverter<Sex, String> $convertersex = const OptionConverter<Sex>(
    Sex.values,
  );
  static TypeConverter<Sex?, String?> $convertersexn =
      NullAwareTypeConverter.wrap($convertersex);
  static TypeConverter<ActivityLevel, String> $converteractivityLevel =
      const OptionConverter<ActivityLevel>(ActivityLevel.values);
  static TypeConverter<DietType, String> $converterdietType =
      const OptionConverter<DietType>(DietType.values);
  static TypeConverter<DietType?, String?> $converterdietTypen =
      NullAwareTypeConverter.wrap($converterdietType);
  static TypeConverter<TrainingPlace, String> $convertertrainingPlace =
      const OptionConverter<TrainingPlace>(TrainingPlace.values);
  static TypeConverter<TrainingPlace?, String?> $convertertrainingPlacen =
      NullAwareTypeConverter.wrap($convertertrainingPlace);
  static TypeConverter<Experience, String> $converterexperience =
      const OptionConverter<Experience>(Experience.values);
  static TypeConverter<Experience?, String?> $converterexperiencen =
      NullAwareTypeConverter.wrap($converterexperience);
}

class ProfileRow extends DataClass implements Insertable<ProfileRow> {
  /// Changed on this phone since it was last sent to the account's copy.
  /// New rows are; rows that came from the server aren't. Every save here
  /// sets it.
  final bool dirty;

  /// Always 1. There is one profile on a phone, as there is one per
  /// account, which the server keys it by.
  final int id;
  final DateTime birthDate;

  /// Null when the person would rather not say.
  final Sex? sex;
  final double heightCm;
  final ActivityLevel activityLevel;

  /// The next three can be skipped.
  final DietType? dietType;
  final TrainingPlace? trainingPlace;
  final Experience? experience;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const ProfileRow({
    required this.dirty,
    required this.id,
    required this.birthDate,
    this.sex,
    required this.heightCm,
    required this.activityLevel,
    this.dietType,
    this.trainingPlace,
    this.experience,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['dirty'] = Variable<bool>(dirty);
    map['id'] = Variable<int>(id);
    {
      map['birth_date'] = Variable<String>(
        $ProfilesTable.$converterbirthDate.toSql(birthDate),
      );
    }
    if (!nullToAbsent || sex != null) {
      map['sex'] = Variable<String>($ProfilesTable.$convertersexn.toSql(sex));
    }
    map['height_cm'] = Variable<double>(heightCm);
    {
      map['activity_level'] = Variable<String>(
        $ProfilesTable.$converteractivityLevel.toSql(activityLevel),
      );
    }
    if (!nullToAbsent || dietType != null) {
      map['diet_type'] = Variable<String>(
        $ProfilesTable.$converterdietTypen.toSql(dietType),
      );
    }
    if (!nullToAbsent || trainingPlace != null) {
      map['training_place'] = Variable<String>(
        $ProfilesTable.$convertertrainingPlacen.toSql(trainingPlace),
      );
    }
    if (!nullToAbsent || experience != null) {
      map['experience'] = Variable<String>(
        $ProfilesTable.$converterexperiencen.toSql(experience),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      dirty: Value(dirty),
      id: Value(id),
      birthDate: Value(birthDate),
      sex: sex == null && nullToAbsent ? const Value.absent() : Value(sex),
      heightCm: Value(heightCm),
      activityLevel: Value(activityLevel),
      dietType: dietType == null && nullToAbsent
          ? const Value.absent()
          : Value(dietType),
      trainingPlace: trainingPlace == null && nullToAbsent
          ? const Value.absent()
          : Value(trainingPlace),
      experience: experience == null && nullToAbsent
          ? const Value.absent()
          : Value(experience),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory ProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileRow(
      dirty: serializer.fromJson<bool>(json['dirty']),
      id: serializer.fromJson<int>(json['id']),
      birthDate: serializer.fromJson<DateTime>(json['birthDate']),
      sex: serializer.fromJson<Sex?>(json['sex']),
      heightCm: serializer.fromJson<double>(json['heightCm']),
      activityLevel: serializer.fromJson<ActivityLevel>(json['activityLevel']),
      dietType: serializer.fromJson<DietType?>(json['dietType']),
      trainingPlace: serializer.fromJson<TrainingPlace?>(json['trainingPlace']),
      experience: serializer.fromJson<Experience?>(json['experience']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dirty': serializer.toJson<bool>(dirty),
      'id': serializer.toJson<int>(id),
      'birthDate': serializer.toJson<DateTime>(birthDate),
      'sex': serializer.toJson<Sex?>(sex),
      'heightCm': serializer.toJson<double>(heightCm),
      'activityLevel': serializer.toJson<ActivityLevel>(activityLevel),
      'dietType': serializer.toJson<DietType?>(dietType),
      'trainingPlace': serializer.toJson<TrainingPlace?>(trainingPlace),
      'experience': serializer.toJson<Experience?>(experience),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  ProfileRow copyWith({
    bool? dirty,
    int? id,
    DateTime? birthDate,
    Value<Sex?> sex = const Value.absent(),
    double? heightCm,
    ActivityLevel? activityLevel,
    Value<DietType?> dietType = const Value.absent(),
    Value<TrainingPlace?> trainingPlace = const Value.absent(),
    Value<Experience?> experience = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => ProfileRow(
    dirty: dirty ?? this.dirty,
    id: id ?? this.id,
    birthDate: birthDate ?? this.birthDate,
    sex: sex.present ? sex.value : this.sex,
    heightCm: heightCm ?? this.heightCm,
    activityLevel: activityLevel ?? this.activityLevel,
    dietType: dietType.present ? dietType.value : this.dietType,
    trainingPlace: trainingPlace.present
        ? trainingPlace.value
        : this.trainingPlace,
    experience: experience.present ? experience.value : this.experience,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  ProfileRow copyWithCompanion(ProfilesCompanion data) {
    return ProfileRow(
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
      id: data.id.present ? data.id.value : this.id,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      sex: data.sex.present ? data.sex.value : this.sex,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      activityLevel: data.activityLevel.present
          ? data.activityLevel.value
          : this.activityLevel,
      dietType: data.dietType.present ? data.dietType.value : this.dietType,
      trainingPlace: data.trainingPlace.present
          ? data.trainingPlace.value
          : this.trainingPlace,
      experience: data.experience.present
          ? data.experience.value
          : this.experience,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileRow(')
          ..write('dirty: $dirty, ')
          ..write('id: $id, ')
          ..write('birthDate: $birthDate, ')
          ..write('sex: $sex, ')
          ..write('heightCm: $heightCm, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('dietType: $dietType, ')
          ..write('trainingPlace: $trainingPlace, ')
          ..write('experience: $experience, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    dirty,
    id,
    birthDate,
    sex,
    heightCm,
    activityLevel,
    dietType,
    trainingPlace,
    experience,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileRow &&
          other.dirty == this.dirty &&
          other.id == this.id &&
          other.birthDate == this.birthDate &&
          other.sex == this.sex &&
          other.heightCm == this.heightCm &&
          other.activityLevel == this.activityLevel &&
          other.dietType == this.dietType &&
          other.trainingPlace == this.trainingPlace &&
          other.experience == this.experience &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ProfilesCompanion extends UpdateCompanion<ProfileRow> {
  final Value<bool> dirty;
  final Value<int> id;
  final Value<DateTime> birthDate;
  final Value<Sex?> sex;
  final Value<double> heightCm;
  final Value<ActivityLevel> activityLevel;
  final Value<DietType?> dietType;
  final Value<TrainingPlace?> trainingPlace;
  final Value<Experience?> experience;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  const ProfilesCompanion({
    this.dirty = const Value.absent(),
    this.id = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.sex = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.activityLevel = const Value.absent(),
    this.dietType = const Value.absent(),
    this.trainingPlace = const Value.absent(),
    this.experience = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.dirty = const Value.absent(),
    this.id = const Value.absent(),
    required DateTime birthDate,
    this.sex = const Value.absent(),
    required double heightCm,
    required ActivityLevel activityLevel,
    this.dietType = const Value.absent(),
    this.trainingPlace = const Value.absent(),
    this.experience = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
  }) : birthDate = Value(birthDate),
       heightCm = Value(heightCm),
       activityLevel = Value(activityLevel),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ProfileRow> custom({
    Expression<bool>? dirty,
    Expression<int>? id,
    Expression<String>? birthDate,
    Expression<String>? sex,
    Expression<double>? heightCm,
    Expression<String>? activityLevel,
    Expression<String>? dietType,
    Expression<String>? trainingPlace,
    Expression<String>? experience,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (dirty != null) 'dirty': dirty,
      if (id != null) 'id': id,
      if (birthDate != null) 'birth_date': birthDate,
      if (sex != null) 'sex': sex,
      if (heightCm != null) 'height_cm': heightCm,
      if (activityLevel != null) 'activity_level': activityLevel,
      if (dietType != null) 'diet_type': dietType,
      if (trainingPlace != null) 'training_place': trainingPlace,
      if (experience != null) 'experience': experience,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  ProfilesCompanion copyWith({
    Value<bool>? dirty,
    Value<int>? id,
    Value<DateTime>? birthDate,
    Value<Sex?>? sex,
    Value<double>? heightCm,
    Value<ActivityLevel>? activityLevel,
    Value<DietType?>? dietType,
    Value<TrainingPlace?>? trainingPlace,
    Value<Experience?>? experience,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
  }) {
    return ProfilesCompanion(
      dirty: dirty ?? this.dirty,
      id: id ?? this.id,
      birthDate: birthDate ?? this.birthDate,
      sex: sex ?? this.sex,
      heightCm: heightCm ?? this.heightCm,
      activityLevel: activityLevel ?? this.activityLevel,
      dietType: dietType ?? this.dietType,
      trainingPlace: trainingPlace ?? this.trainingPlace,
      experience: experience ?? this.experience,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<String>(
        $ProfilesTable.$converterbirthDate.toSql(birthDate.value),
      );
    }
    if (sex.present) {
      map['sex'] = Variable<String>(
        $ProfilesTable.$convertersexn.toSql(sex.value),
      );
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (activityLevel.present) {
      map['activity_level'] = Variable<String>(
        $ProfilesTable.$converteractivityLevel.toSql(activityLevel.value),
      );
    }
    if (dietType.present) {
      map['diet_type'] = Variable<String>(
        $ProfilesTable.$converterdietTypen.toSql(dietType.value),
      );
    }
    if (trainingPlace.present) {
      map['training_place'] = Variable<String>(
        $ProfilesTable.$convertertrainingPlacen.toSql(trainingPlace.value),
      );
    }
    if (experience.present) {
      map['experience'] = Variable<String>(
        $ProfilesTable.$converterexperiencen.toSql(experience.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('dirty: $dirty, ')
          ..write('id: $id, ')
          ..write('birthDate: $birthDate, ')
          ..write('sex: $sex, ')
          ..write('heightCm: $heightCm, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('dietType: $dietType, ')
          ..write('trainingPlace: $trainingPlace, ')
          ..write('experience: $experience, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, GoalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<GoalType, String> goalType =
      GeneratedColumn<String>(
        'goal_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<GoalType>($GoalsTable.$convertergoalType);
  static const VerificationMeta _targetWeightKgMeta = const VerificationMeta(
    'targetWeightKg',
  );
  @override
  late final GeneratedColumn<double> targetWeightKg = GeneratedColumn<double>(
    'target_weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _basisWeightKgMeta = const VerificationMeta(
    'basisWeightKg',
  );
  @override
  late final GeneratedColumn<double> basisWeightKg = GeneratedColumn<double>(
    'basis_weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caloriesKcalMeta = const VerificationMeta(
    'caloriesKcal',
  );
  @override
  late final GeneratedColumn<int> caloriesKcal = GeneratedColumn<int>(
    'calories_kcal',
    aliasedName,
    false,
    check: () => ComparableExpr(caloriesKcal).isBiggerOrEqualValue(1200),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<int> proteinG = GeneratedColumn<int>(
    'protein_g',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<int> carbsG = GeneratedColumn<int>(
    'carbs_g',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<int> fatG = GeneratedColumn<int>(
    'fat_g',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _waterMlMeta = const VerificationMeta(
    'waterMl',
  );
  @override
  late final GeneratedColumn<int> waterMl = GeneratedColumn<int>(
    'water_ml',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stepsMeta = const VerificationMeta('steps');
  @override
  late final GeneratedColumn<int> steps = GeneratedColumn<int>(
    'steps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formulaVersionMeta = const VerificationMeta(
    'formulaVersion',
  );
  @override
  late final GeneratedColumn<String> formulaVersion = GeneratedColumn<String>(
    'formula_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    dirty,
    id,
    goalType,
    targetWeightKg,
    basisWeightKg,
    caloriesKcal,
    proteinG,
    carbsG,
    fatG,
    waterMl,
    steps,
    formulaVersion,
    startedAt,
    endedAt,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<GoalRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('target_weight_kg')) {
      context.handle(
        _targetWeightKgMeta,
        targetWeightKg.isAcceptableOrUnknown(
          data['target_weight_kg']!,
          _targetWeightKgMeta,
        ),
      );
    }
    if (data.containsKey('basis_weight_kg')) {
      context.handle(
        _basisWeightKgMeta,
        basisWeightKg.isAcceptableOrUnknown(
          data['basis_weight_kg']!,
          _basisWeightKgMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_basisWeightKgMeta);
    }
    if (data.containsKey('calories_kcal')) {
      context.handle(
        _caloriesKcalMeta,
        caloriesKcal.isAcceptableOrUnknown(
          data['calories_kcal']!,
          _caloriesKcalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caloriesKcalMeta);
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinGMeta);
    }
    if (data.containsKey('carbs_g')) {
      context.handle(
        _carbsGMeta,
        carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta),
      );
    } else if (isInserting) {
      context.missing(_carbsGMeta);
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    } else if (isInserting) {
      context.missing(_fatGMeta);
    }
    if (data.containsKey('water_ml')) {
      context.handle(
        _waterMlMeta,
        waterMl.isAcceptableOrUnknown(data['water_ml']!, _waterMlMeta),
      );
    } else if (isInserting) {
      context.missing(_waterMlMeta);
    }
    if (data.containsKey('steps')) {
      context.handle(
        _stepsMeta,
        steps.isAcceptableOrUnknown(data['steps']!, _stepsMeta),
      );
    } else if (isInserting) {
      context.missing(_stepsMeta);
    }
    if (data.containsKey('formula_version')) {
      context.handle(
        _formulaVersionMeta,
        formulaVersion.isAcceptableOrUnknown(
          data['formula_version']!,
          _formulaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_formulaVersionMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalRow(
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      goalType: $GoalsTable.$convertergoalType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}goal_type'],
        )!,
      ),
      targetWeightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_weight_kg'],
      ),
      basisWeightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}basis_weight_kg'],
      )!,
      caloriesKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calories_kcal'],
      )!,
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}protein_g'],
      )!,
      carbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}carbs_g'],
      )!,
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fat_g'],
      )!,
      waterMl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}water_ml'],
      )!,
      steps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}steps'],
      )!,
      formulaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}formula_version'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }

  static TypeConverter<GoalType, String> $convertergoalType =
      const OptionConverter<GoalType>(GoalType.values);
}

class GoalRow extends DataClass implements Insertable<GoalRow> {
  /// Changed on this phone since it was last sent to the account's copy.
  /// New rows are; rows that came from the server aren't. Every save here
  /// sets it.
  final bool dirty;
  final String id;
  final GoalType goalType;
  final double? targetWeightKg;

  /// The weight the targets were worked out from, so they can be
  /// explained later.
  final double basisWeightKg;

  /// Never below the lowest floor, as on the server.
  final int caloriesKcal;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final int waterMl;
  final int steps;
  final String formulaVersion;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const GoalRow({
    required this.dirty,
    required this.id,
    required this.goalType,
    this.targetWeightKg,
    required this.basisWeightKg,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.waterMl,
    required this.steps,
    required this.formulaVersion,
    required this.startedAt,
    this.endedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['dirty'] = Variable<bool>(dirty);
    map['id'] = Variable<String>(id);
    {
      map['goal_type'] = Variable<String>(
        $GoalsTable.$convertergoalType.toSql(goalType),
      );
    }
    if (!nullToAbsent || targetWeightKg != null) {
      map['target_weight_kg'] = Variable<double>(targetWeightKg);
    }
    map['basis_weight_kg'] = Variable<double>(basisWeightKg);
    map['calories_kcal'] = Variable<int>(caloriesKcal);
    map['protein_g'] = Variable<int>(proteinG);
    map['carbs_g'] = Variable<int>(carbsG);
    map['fat_g'] = Variable<int>(fatG);
    map['water_ml'] = Variable<int>(waterMl);
    map['steps'] = Variable<int>(steps);
    map['formula_version'] = Variable<String>(formulaVersion);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      dirty: Value(dirty),
      id: Value(id),
      goalType: Value(goalType),
      targetWeightKg: targetWeightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(targetWeightKg),
      basisWeightKg: Value(basisWeightKg),
      caloriesKcal: Value(caloriesKcal),
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      fatG: Value(fatG),
      waterMl: Value(waterMl),
      steps: Value(steps),
      formulaVersion: Value(formulaVersion),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory GoalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalRow(
      dirty: serializer.fromJson<bool>(json['dirty']),
      id: serializer.fromJson<String>(json['id']),
      goalType: serializer.fromJson<GoalType>(json['goalType']),
      targetWeightKg: serializer.fromJson<double?>(json['targetWeightKg']),
      basisWeightKg: serializer.fromJson<double>(json['basisWeightKg']),
      caloriesKcal: serializer.fromJson<int>(json['caloriesKcal']),
      proteinG: serializer.fromJson<int>(json['proteinG']),
      carbsG: serializer.fromJson<int>(json['carbsG']),
      fatG: serializer.fromJson<int>(json['fatG']),
      waterMl: serializer.fromJson<int>(json['waterMl']),
      steps: serializer.fromJson<int>(json['steps']),
      formulaVersion: serializer.fromJson<String>(json['formulaVersion']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dirty': serializer.toJson<bool>(dirty),
      'id': serializer.toJson<String>(id),
      'goalType': serializer.toJson<GoalType>(goalType),
      'targetWeightKg': serializer.toJson<double?>(targetWeightKg),
      'basisWeightKg': serializer.toJson<double>(basisWeightKg),
      'caloriesKcal': serializer.toJson<int>(caloriesKcal),
      'proteinG': serializer.toJson<int>(proteinG),
      'carbsG': serializer.toJson<int>(carbsG),
      'fatG': serializer.toJson<int>(fatG),
      'waterMl': serializer.toJson<int>(waterMl),
      'steps': serializer.toJson<int>(steps),
      'formulaVersion': serializer.toJson<String>(formulaVersion),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  GoalRow copyWith({
    bool? dirty,
    String? id,
    GoalType? goalType,
    Value<double?> targetWeightKg = const Value.absent(),
    double? basisWeightKg,
    int? caloriesKcal,
    int? proteinG,
    int? carbsG,
    int? fatG,
    int? waterMl,
    int? steps,
    String? formulaVersion,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => GoalRow(
    dirty: dirty ?? this.dirty,
    id: id ?? this.id,
    goalType: goalType ?? this.goalType,
    targetWeightKg: targetWeightKg.present
        ? targetWeightKg.value
        : this.targetWeightKg,
    basisWeightKg: basisWeightKg ?? this.basisWeightKg,
    caloriesKcal: caloriesKcal ?? this.caloriesKcal,
    proteinG: proteinG ?? this.proteinG,
    carbsG: carbsG ?? this.carbsG,
    fatG: fatG ?? this.fatG,
    waterMl: waterMl ?? this.waterMl,
    steps: steps ?? this.steps,
    formulaVersion: formulaVersion ?? this.formulaVersion,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  GoalRow copyWithCompanion(GoalsCompanion data) {
    return GoalRow(
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
      id: data.id.present ? data.id.value : this.id,
      goalType: data.goalType.present ? data.goalType.value : this.goalType,
      targetWeightKg: data.targetWeightKg.present
          ? data.targetWeightKg.value
          : this.targetWeightKg,
      basisWeightKg: data.basisWeightKg.present
          ? data.basisWeightKg.value
          : this.basisWeightKg,
      caloriesKcal: data.caloriesKcal.present
          ? data.caloriesKcal.value
          : this.caloriesKcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      waterMl: data.waterMl.present ? data.waterMl.value : this.waterMl,
      steps: data.steps.present ? data.steps.value : this.steps,
      formulaVersion: data.formulaVersion.present
          ? data.formulaVersion.value
          : this.formulaVersion,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalRow(')
          ..write('dirty: $dirty, ')
          ..write('id: $id, ')
          ..write('goalType: $goalType, ')
          ..write('targetWeightKg: $targetWeightKg, ')
          ..write('basisWeightKg: $basisWeightKg, ')
          ..write('caloriesKcal: $caloriesKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('waterMl: $waterMl, ')
          ..write('steps: $steps, ')
          ..write('formulaVersion: $formulaVersion, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    dirty,
    id,
    goalType,
    targetWeightKg,
    basisWeightKg,
    caloriesKcal,
    proteinG,
    carbsG,
    fatG,
    waterMl,
    steps,
    formulaVersion,
    startedAt,
    endedAt,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalRow &&
          other.dirty == this.dirty &&
          other.id == this.id &&
          other.goalType == this.goalType &&
          other.targetWeightKg == this.targetWeightKg &&
          other.basisWeightKg == this.basisWeightKg &&
          other.caloriesKcal == this.caloriesKcal &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.fatG == this.fatG &&
          other.waterMl == this.waterMl &&
          other.steps == this.steps &&
          other.formulaVersion == this.formulaVersion &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class GoalsCompanion extends UpdateCompanion<GoalRow> {
  final Value<bool> dirty;
  final Value<String> id;
  final Value<GoalType> goalType;
  final Value<double?> targetWeightKg;
  final Value<double> basisWeightKg;
  final Value<int> caloriesKcal;
  final Value<int> proteinG;
  final Value<int> carbsG;
  final Value<int> fatG;
  final Value<int> waterMl;
  final Value<int> steps;
  final Value<String> formulaVersion;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const GoalsCompanion({
    this.dirty = const Value.absent(),
    this.id = const Value.absent(),
    this.goalType = const Value.absent(),
    this.targetWeightKg = const Value.absent(),
    this.basisWeightKg = const Value.absent(),
    this.caloriesKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.waterMl = const Value.absent(),
    this.steps = const Value.absent(),
    this.formulaVersion = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalsCompanion.insert({
    this.dirty = const Value.absent(),
    required String id,
    required GoalType goalType,
    this.targetWeightKg = const Value.absent(),
    required double basisWeightKg,
    required int caloriesKcal,
    required int proteinG,
    required int carbsG,
    required int fatG,
    required int waterMl,
    required int steps,
    required String formulaVersion,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       goalType = Value(goalType),
       basisWeightKg = Value(basisWeightKg),
       caloriesKcal = Value(caloriesKcal),
       proteinG = Value(proteinG),
       carbsG = Value(carbsG),
       fatG = Value(fatG),
       waterMl = Value(waterMl),
       steps = Value(steps),
       formulaVersion = Value(formulaVersion),
       startedAt = Value(startedAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<GoalRow> custom({
    Expression<bool>? dirty,
    Expression<String>? id,
    Expression<String>? goalType,
    Expression<double>? targetWeightKg,
    Expression<double>? basisWeightKg,
    Expression<int>? caloriesKcal,
    Expression<int>? proteinG,
    Expression<int>? carbsG,
    Expression<int>? fatG,
    Expression<int>? waterMl,
    Expression<int>? steps,
    Expression<String>? formulaVersion,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dirty != null) 'dirty': dirty,
      if (id != null) 'id': id,
      if (goalType != null) 'goal_type': goalType,
      if (targetWeightKg != null) 'target_weight_kg': targetWeightKg,
      if (basisWeightKg != null) 'basis_weight_kg': basisWeightKg,
      if (caloriesKcal != null) 'calories_kcal': caloriesKcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (waterMl != null) 'water_ml': waterMl,
      if (steps != null) 'steps': steps,
      if (formulaVersion != null) 'formula_version': formulaVersion,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalsCompanion copyWith({
    Value<bool>? dirty,
    Value<String>? id,
    Value<GoalType>? goalType,
    Value<double?>? targetWeightKg,
    Value<double>? basisWeightKg,
    Value<int>? caloriesKcal,
    Value<int>? proteinG,
    Value<int>? carbsG,
    Value<int>? fatG,
    Value<int>? waterMl,
    Value<int>? steps,
    Value<String>? formulaVersion,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return GoalsCompanion(
      dirty: dirty ?? this.dirty,
      id: id ?? this.id,
      goalType: goalType ?? this.goalType,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      basisWeightKg: basisWeightKg ?? this.basisWeightKg,
      caloriesKcal: caloriesKcal ?? this.caloriesKcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      waterMl: waterMl ?? this.waterMl,
      steps: steps ?? this.steps,
      formulaVersion: formulaVersion ?? this.formulaVersion,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (goalType.present) {
      map['goal_type'] = Variable<String>(
        $GoalsTable.$convertergoalType.toSql(goalType.value),
      );
    }
    if (targetWeightKg.present) {
      map['target_weight_kg'] = Variable<double>(targetWeightKg.value);
    }
    if (basisWeightKg.present) {
      map['basis_weight_kg'] = Variable<double>(basisWeightKg.value);
    }
    if (caloriesKcal.present) {
      map['calories_kcal'] = Variable<int>(caloriesKcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<int>(proteinG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<int>(carbsG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<int>(fatG.value);
    }
    if (waterMl.present) {
      map['water_ml'] = Variable<int>(waterMl.value);
    }
    if (steps.present) {
      map['steps'] = Variable<int>(steps.value);
    }
    if (formulaVersion.present) {
      map['formula_version'] = Variable<String>(formulaVersion.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('dirty: $dirty, ')
          ..write('id: $id, ')
          ..write('goalType: $goalType, ')
          ..write('targetWeightKg: $targetWeightKg, ')
          ..write('basisWeightKg: $basisWeightKg, ')
          ..write('caloriesKcal: $caloriesKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('waterMl: $waterMl, ')
          ..write('steps: $steps, ')
          ..write('formulaVersion: $formulaVersion, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeightLogsTable extends WeightLogs
    with TableInfo<$WeightLogsTable, WeightLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeightLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> day =
      GeneratedColumn<String>(
        'day',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($WeightLogsTable.$converterday);
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    dirty,
    id,
    day,
    weightKg,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weight_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeightLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeightLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeightLogRow(
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      day: $WeightLogsTable.$converterday.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}day'],
        )!,
      ),
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $WeightLogsTable createAlias(String alias) {
    return $WeightLogsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $converterday = const DateConverter();
}

class WeightLogRow extends DataClass implements Insertable<WeightLogRow> {
  /// Changed on this phone since it was last sent to the account's copy.
  /// New rows are; rows that came from the server aren't. Every save here
  /// sets it.
  final bool dirty;
  final String id;
  final DateTime day;
  final double weightKg;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const WeightLogRow({
    required this.dirty,
    required this.id,
    required this.day,
    required this.weightKg,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['dirty'] = Variable<bool>(dirty);
    map['id'] = Variable<String>(id);
    {
      map['day'] = Variable<String>($WeightLogsTable.$converterday.toSql(day));
    }
    map['weight_kg'] = Variable<double>(weightKg);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  WeightLogsCompanion toCompanion(bool nullToAbsent) {
    return WeightLogsCompanion(
      dirty: Value(dirty),
      id: Value(id),
      day: Value(day),
      weightKg: Value(weightKg),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory WeightLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeightLogRow(
      dirty: serializer.fromJson<bool>(json['dirty']),
      id: serializer.fromJson<String>(json['id']),
      day: serializer.fromJson<DateTime>(json['day']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dirty': serializer.toJson<bool>(dirty),
      'id': serializer.toJson<String>(id),
      'day': serializer.toJson<DateTime>(day),
      'weightKg': serializer.toJson<double>(weightKg),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  WeightLogRow copyWith({
    bool? dirty,
    String? id,
    DateTime? day,
    double? weightKg,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => WeightLogRow(
    dirty: dirty ?? this.dirty,
    id: id ?? this.id,
    day: day ?? this.day,
    weightKg: weightKg ?? this.weightKg,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  WeightLogRow copyWithCompanion(WeightLogsCompanion data) {
    return WeightLogRow(
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
      id: data.id.present ? data.id.value : this.id,
      day: data.day.present ? data.day.value : this.day,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeightLogRow(')
          ..write('dirty: $dirty, ')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('weightKg: $weightKg, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(dirty, id, day, weightKg, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeightLogRow &&
          other.dirty == this.dirty &&
          other.id == this.id &&
          other.day == this.day &&
          other.weightKg == this.weightKg &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class WeightLogsCompanion extends UpdateCompanion<WeightLogRow> {
  final Value<bool> dirty;
  final Value<String> id;
  final Value<DateTime> day;
  final Value<double> weightKg;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const WeightLogsCompanion({
    this.dirty = const Value.absent(),
    this.id = const Value.absent(),
    this.day = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeightLogsCompanion.insert({
    this.dirty = const Value.absent(),
    required String id,
    required DateTime day,
    required double weightKg,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       day = Value(day),
       weightKg = Value(weightKg),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<WeightLogRow> custom({
    Expression<bool>? dirty,
    Expression<String>? id,
    Expression<String>? day,
    Expression<double>? weightKg,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dirty != null) 'dirty': dirty,
      if (id != null) 'id': id,
      if (day != null) 'day': day,
      if (weightKg != null) 'weight_kg': weightKg,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeightLogsCompanion copyWith({
    Value<bool>? dirty,
    Value<String>? id,
    Value<DateTime>? day,
    Value<double>? weightKg,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return WeightLogsCompanion(
      dirty: dirty ?? this.dirty,
      id: id ?? this.id,
      day: day ?? this.day,
      weightKg: weightKg ?? this.weightKg,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(
        $WeightLogsTable.$converterday.toSql(day.value),
      );
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeightLogsCompanion(')
          ..write('dirty: $dirty, ')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('weightKg: $weightKg, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealEntriesTable extends MealEntries
    with TableInfo<$MealEntriesTable, MealEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<String> foodId = GeneratedColumn<String>(
    'food_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Meal, String> meal =
      GeneratedColumn<String>(
        'meal',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Meal>($MealEntriesTable.$convertermeal);
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  @override
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
    'grams',
    aliasedName,
    false,
    check: () => ComparableExpr(grams).isBiggerThanValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<double> kcal = GeneratedColumn<double>(
    'kcal',
    aliasedName,
    false,
    check: () => ComparableExpr(kcal).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    false,
    check: () => ComparableExpr(proteinG).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
    'carbs_g',
    aliasedName,
    false,
    check: () => ComparableExpr(carbsG).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
    'fat_g',
    aliasedName,
    false,
    check: () => ComparableExpr(fatG).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eatenAtMeta = const VerificationMeta(
    'eatenAt',
  );
  @override
  late final GeneratedColumn<DateTime> eatenAt = GeneratedColumn<DateTime>(
    'eaten_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<EntrySource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<EntrySource>($MealEntriesTable.$convertersource);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    dirty,
    id,
    foodId,
    name,
    meal,
    grams,
    kcal,
    proteinG,
    carbsG,
    fatG,
    eatenAt,
    source,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    } else if (isInserting) {
      context.missing(_gramsMeta);
    }
    if (data.containsKey('kcal')) {
      context.handle(
        _kcalMeta,
        kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta),
      );
    } else if (isInserting) {
      context.missing(_kcalMeta);
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinGMeta);
    }
    if (data.containsKey('carbs_g')) {
      context.handle(
        _carbsGMeta,
        carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta),
      );
    } else if (isInserting) {
      context.missing(_carbsGMeta);
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    } else if (isInserting) {
      context.missing(_fatGMeta);
    }
    if (data.containsKey('eaten_at')) {
      context.handle(
        _eatenAtMeta,
        eatenAt.isAcceptableOrUnknown(data['eaten_at']!, _eatenAtMeta),
      );
    } else if (isInserting) {
      context.missing(_eatenAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealEntryRow(
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      meal: $MealEntriesTable.$convertermeal.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}meal'],
        )!,
      ),
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
      )!,
      kcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal'],
      )!,
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      )!,
      carbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_g'],
      )!,
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g'],
      )!,
      eatenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}eaten_at'],
      )!,
      source: $MealEntriesTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $MealEntriesTable createAlias(String alias) {
    return $MealEntriesTable(attachedDatabase, alias);
  }

  static TypeConverter<Meal, String> $convertermeal =
      const OptionConverter<Meal>(Meal.values);
  static TypeConverter<EntrySource, String> $convertersource =
      const OptionConverter<EntrySource>(EntrySource.values);
}

class MealEntryRow extends DataClass implements Insertable<MealEntryRow> {
  /// Changed on this phone since it was last sent to the account's copy.
  /// New rows are; rows that came from the server aren't. Every save here
  /// sets it.
  final bool dirty;
  final String id;

  /// The catalogue food, if it came from one.
  final String? foodId;
  final String name;
  final Meal meal;
  final double grams;
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final DateTime eatenAt;
  final EntrySource source;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const MealEntryRow({
    required this.dirty,
    required this.id,
    this.foodId,
    required this.name,
    required this.meal,
    required this.grams,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.eatenAt,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['dirty'] = Variable<bool>(dirty);
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || foodId != null) {
      map['food_id'] = Variable<String>(foodId);
    }
    map['name'] = Variable<String>(name);
    {
      map['meal'] = Variable<String>(
        $MealEntriesTable.$convertermeal.toSql(meal),
      );
    }
    map['grams'] = Variable<double>(grams);
    map['kcal'] = Variable<double>(kcal);
    map['protein_g'] = Variable<double>(proteinG);
    map['carbs_g'] = Variable<double>(carbsG);
    map['fat_g'] = Variable<double>(fatG);
    map['eaten_at'] = Variable<DateTime>(eatenAt);
    {
      map['source'] = Variable<String>(
        $MealEntriesTable.$convertersource.toSql(source),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  MealEntriesCompanion toCompanion(bool nullToAbsent) {
    return MealEntriesCompanion(
      dirty: Value(dirty),
      id: Value(id),
      foodId: foodId == null && nullToAbsent
          ? const Value.absent()
          : Value(foodId),
      name: Value(name),
      meal: Value(meal),
      grams: Value(grams),
      kcal: Value(kcal),
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      fatG: Value(fatG),
      eatenAt: Value(eatenAt),
      source: Value(source),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory MealEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealEntryRow(
      dirty: serializer.fromJson<bool>(json['dirty']),
      id: serializer.fromJson<String>(json['id']),
      foodId: serializer.fromJson<String?>(json['foodId']),
      name: serializer.fromJson<String>(json['name']),
      meal: serializer.fromJson<Meal>(json['meal']),
      grams: serializer.fromJson<double>(json['grams']),
      kcal: serializer.fromJson<double>(json['kcal']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      carbsG: serializer.fromJson<double>(json['carbsG']),
      fatG: serializer.fromJson<double>(json['fatG']),
      eatenAt: serializer.fromJson<DateTime>(json['eatenAt']),
      source: serializer.fromJson<EntrySource>(json['source']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dirty': serializer.toJson<bool>(dirty),
      'id': serializer.toJson<String>(id),
      'foodId': serializer.toJson<String?>(foodId),
      'name': serializer.toJson<String>(name),
      'meal': serializer.toJson<Meal>(meal),
      'grams': serializer.toJson<double>(grams),
      'kcal': serializer.toJson<double>(kcal),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbsG': serializer.toJson<double>(carbsG),
      'fatG': serializer.toJson<double>(fatG),
      'eatenAt': serializer.toJson<DateTime>(eatenAt),
      'source': serializer.toJson<EntrySource>(source),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  MealEntryRow copyWith({
    bool? dirty,
    String? id,
    Value<String?> foodId = const Value.absent(),
    String? name,
    Meal? meal,
    double? grams,
    double? kcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
    DateTime? eatenAt,
    EntrySource? source,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => MealEntryRow(
    dirty: dirty ?? this.dirty,
    id: id ?? this.id,
    foodId: foodId.present ? foodId.value : this.foodId,
    name: name ?? this.name,
    meal: meal ?? this.meal,
    grams: grams ?? this.grams,
    kcal: kcal ?? this.kcal,
    proteinG: proteinG ?? this.proteinG,
    carbsG: carbsG ?? this.carbsG,
    fatG: fatG ?? this.fatG,
    eatenAt: eatenAt ?? this.eatenAt,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  MealEntryRow copyWithCompanion(MealEntriesCompanion data) {
    return MealEntryRow(
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
      id: data.id.present ? data.id.value : this.id,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      name: data.name.present ? data.name.value : this.name,
      meal: data.meal.present ? data.meal.value : this.meal,
      grams: data.grams.present ? data.grams.value : this.grams,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      eatenAt: data.eatenAt.present ? data.eatenAt.value : this.eatenAt,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealEntryRow(')
          ..write('dirty: $dirty, ')
          ..write('id: $id, ')
          ..write('foodId: $foodId, ')
          ..write('name: $name, ')
          ..write('meal: $meal, ')
          ..write('grams: $grams, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('eatenAt: $eatenAt, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    dirty,
    id,
    foodId,
    name,
    meal,
    grams,
    kcal,
    proteinG,
    carbsG,
    fatG,
    eatenAt,
    source,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealEntryRow &&
          other.dirty == this.dirty &&
          other.id == this.id &&
          other.foodId == this.foodId &&
          other.name == this.name &&
          other.meal == this.meal &&
          other.grams == this.grams &&
          other.kcal == this.kcal &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.fatG == this.fatG &&
          other.eatenAt == this.eatenAt &&
          other.source == this.source &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class MealEntriesCompanion extends UpdateCompanion<MealEntryRow> {
  final Value<bool> dirty;
  final Value<String> id;
  final Value<String?> foodId;
  final Value<String> name;
  final Value<Meal> meal;
  final Value<double> grams;
  final Value<double> kcal;
  final Value<double> proteinG;
  final Value<double> carbsG;
  final Value<double> fatG;
  final Value<DateTime> eatenAt;
  final Value<EntrySource> source;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const MealEntriesCompanion({
    this.dirty = const Value.absent(),
    this.id = const Value.absent(),
    this.foodId = const Value.absent(),
    this.name = const Value.absent(),
    this.meal = const Value.absent(),
    this.grams = const Value.absent(),
    this.kcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.eatenAt = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealEntriesCompanion.insert({
    this.dirty = const Value.absent(),
    required String id,
    this.foodId = const Value.absent(),
    required String name,
    required Meal meal,
    required double grams,
    required double kcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
    required DateTime eatenAt,
    required EntrySource source,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       meal = Value(meal),
       grams = Value(grams),
       kcal = Value(kcal),
       proteinG = Value(proteinG),
       carbsG = Value(carbsG),
       fatG = Value(fatG),
       eatenAt = Value(eatenAt),
       source = Value(source),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<MealEntryRow> custom({
    Expression<bool>? dirty,
    Expression<String>? id,
    Expression<String>? foodId,
    Expression<String>? name,
    Expression<String>? meal,
    Expression<double>? grams,
    Expression<double>? kcal,
    Expression<double>? proteinG,
    Expression<double>? carbsG,
    Expression<double>? fatG,
    Expression<DateTime>? eatenAt,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dirty != null) 'dirty': dirty,
      if (id != null) 'id': id,
      if (foodId != null) 'food_id': foodId,
      if (name != null) 'name': name,
      if (meal != null) 'meal': meal,
      if (grams != null) 'grams': grams,
      if (kcal != null) 'kcal': kcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (eatenAt != null) 'eaten_at': eatenAt,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealEntriesCompanion copyWith({
    Value<bool>? dirty,
    Value<String>? id,
    Value<String?>? foodId,
    Value<String>? name,
    Value<Meal>? meal,
    Value<double>? grams,
    Value<double>? kcal,
    Value<double>? proteinG,
    Value<double>? carbsG,
    Value<double>? fatG,
    Value<DateTime>? eatenAt,
    Value<EntrySource>? source,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return MealEntriesCompanion(
      dirty: dirty ?? this.dirty,
      id: id ?? this.id,
      foodId: foodId ?? this.foodId,
      name: name ?? this.name,
      meal: meal ?? this.meal,
      grams: grams ?? this.grams,
      kcal: kcal ?? this.kcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      eatenAt: eatenAt ?? this.eatenAt,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (foodId.present) {
      map['food_id'] = Variable<String>(foodId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (meal.present) {
      map['meal'] = Variable<String>(
        $MealEntriesTable.$convertermeal.toSql(meal.value),
      );
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<double>(kcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (eatenAt.present) {
      map['eaten_at'] = Variable<DateTime>(eatenAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $MealEntriesTable.$convertersource.toSql(source.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealEntriesCompanion(')
          ..write('dirty: $dirty, ')
          ..write('id: $id, ')
          ..write('foodId: $foodId, ')
          ..write('name: $name, ')
          ..write('meal: $meal, ')
          ..write('grams: $grams, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('eatenAt: $eatenAt, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HealthSamplesTable extends HealthSamples
    with TableInfo<$HealthSamplesTable, HealthSampleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HealthSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<HealthMetric, String> metric =
      GeneratedColumn<String>(
        'metric',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<HealthMetric>($HealthSamplesTable.$convertermetric);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    check: () => ComparableExpr(value).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _measuredAtMeta = const VerificationMeta(
    'measuredAt',
  );
  @override
  late final GeneratedColumn<DateTime> measuredAt = GeneratedColumn<DateTime>(
    'measured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SampleSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SampleSource>($HealthSamplesTable.$convertersource);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    dirty,
    id,
    metric,
    value,
    measuredAt,
    source,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'health_samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<HealthSampleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('measured_at')) {
      context.handle(
        _measuredAtMeta,
        measuredAt.isAcceptableOrUnknown(data['measured_at']!, _measuredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_measuredAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HealthSampleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HealthSampleRow(
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      metric: $HealthSamplesTable.$convertermetric.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}metric'],
        )!,
      ),
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      measuredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}measured_at'],
      )!,
      source: $HealthSamplesTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $HealthSamplesTable createAlias(String alias) {
    return $HealthSamplesTable(attachedDatabase, alias);
  }

  static TypeConverter<HealthMetric, String> $convertermetric =
      const OptionConverter<HealthMetric>(HealthMetric.values);
  static TypeConverter<SampleSource, String> $convertersource =
      const OptionConverter<SampleSource>(SampleSource.values);
}

class HealthSampleRow extends DataClass implements Insertable<HealthSampleRow> {
  /// Changed on this phone since it was last sent to the account's copy.
  /// New rows are; rows that came from the server aren't. Every save here
  /// sets it.
  final bool dirty;
  final String id;
  final HealthMetric metric;
  final double value;
  final DateTime measuredAt;
  final SampleSource source;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const HealthSampleRow({
    required this.dirty,
    required this.id,
    required this.metric,
    required this.value,
    required this.measuredAt,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['dirty'] = Variable<bool>(dirty);
    map['id'] = Variable<String>(id);
    {
      map['metric'] = Variable<String>(
        $HealthSamplesTable.$convertermetric.toSql(metric),
      );
    }
    map['value'] = Variable<double>(value);
    map['measured_at'] = Variable<DateTime>(measuredAt);
    {
      map['source'] = Variable<String>(
        $HealthSamplesTable.$convertersource.toSql(source),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  HealthSamplesCompanion toCompanion(bool nullToAbsent) {
    return HealthSamplesCompanion(
      dirty: Value(dirty),
      id: Value(id),
      metric: Value(metric),
      value: Value(value),
      measuredAt: Value(measuredAt),
      source: Value(source),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory HealthSampleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HealthSampleRow(
      dirty: serializer.fromJson<bool>(json['dirty']),
      id: serializer.fromJson<String>(json['id']),
      metric: serializer.fromJson<HealthMetric>(json['metric']),
      value: serializer.fromJson<double>(json['value']),
      measuredAt: serializer.fromJson<DateTime>(json['measuredAt']),
      source: serializer.fromJson<SampleSource>(json['source']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dirty': serializer.toJson<bool>(dirty),
      'id': serializer.toJson<String>(id),
      'metric': serializer.toJson<HealthMetric>(metric),
      'value': serializer.toJson<double>(value),
      'measuredAt': serializer.toJson<DateTime>(measuredAt),
      'source': serializer.toJson<SampleSource>(source),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  HealthSampleRow copyWith({
    bool? dirty,
    String? id,
    HealthMetric? metric,
    double? value,
    DateTime? measuredAt,
    SampleSource? source,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => HealthSampleRow(
    dirty: dirty ?? this.dirty,
    id: id ?? this.id,
    metric: metric ?? this.metric,
    value: value ?? this.value,
    measuredAt: measuredAt ?? this.measuredAt,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  HealthSampleRow copyWithCompanion(HealthSamplesCompanion data) {
    return HealthSampleRow(
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
      id: data.id.present ? data.id.value : this.id,
      metric: data.metric.present ? data.metric.value : this.metric,
      value: data.value.present ? data.value.value : this.value,
      measuredAt: data.measuredAt.present
          ? data.measuredAt.value
          : this.measuredAt,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HealthSampleRow(')
          ..write('dirty: $dirty, ')
          ..write('id: $id, ')
          ..write('metric: $metric, ')
          ..write('value: $value, ')
          ..write('measuredAt: $measuredAt, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    dirty,
    id,
    metric,
    value,
    measuredAt,
    source,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HealthSampleRow &&
          other.dirty == this.dirty &&
          other.id == this.id &&
          other.metric == this.metric &&
          other.value == this.value &&
          other.measuredAt == this.measuredAt &&
          other.source == this.source &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class HealthSamplesCompanion extends UpdateCompanion<HealthSampleRow> {
  final Value<bool> dirty;
  final Value<String> id;
  final Value<HealthMetric> metric;
  final Value<double> value;
  final Value<DateTime> measuredAt;
  final Value<SampleSource> source;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const HealthSamplesCompanion({
    this.dirty = const Value.absent(),
    this.id = const Value.absent(),
    this.metric = const Value.absent(),
    this.value = const Value.absent(),
    this.measuredAt = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HealthSamplesCompanion.insert({
    this.dirty = const Value.absent(),
    required String id,
    required HealthMetric metric,
    required double value,
    required DateTime measuredAt,
    required SampleSource source,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       metric = Value(metric),
       value = Value(value),
       measuredAt = Value(measuredAt),
       source = Value(source),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<HealthSampleRow> custom({
    Expression<bool>? dirty,
    Expression<String>? id,
    Expression<String>? metric,
    Expression<double>? value,
    Expression<DateTime>? measuredAt,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dirty != null) 'dirty': dirty,
      if (id != null) 'id': id,
      if (metric != null) 'metric': metric,
      if (value != null) 'value': value,
      if (measuredAt != null) 'measured_at': measuredAt,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HealthSamplesCompanion copyWith({
    Value<bool>? dirty,
    Value<String>? id,
    Value<HealthMetric>? metric,
    Value<double>? value,
    Value<DateTime>? measuredAt,
    Value<SampleSource>? source,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return HealthSamplesCompanion(
      dirty: dirty ?? this.dirty,
      id: id ?? this.id,
      metric: metric ?? this.metric,
      value: value ?? this.value,
      measuredAt: measuredAt ?? this.measuredAt,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (metric.present) {
      map['metric'] = Variable<String>(
        $HealthSamplesTable.$convertermetric.toSql(metric.value),
      );
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (measuredAt.present) {
      map['measured_at'] = Variable<DateTime>(measuredAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $HealthSamplesTable.$convertersource.toSql(source.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HealthSamplesCompanion(')
          ..write('dirty: $dirty, ')
          ..write('id: $id, ')
          ..write('metric: $metric, ')
          ..write('value: $value, ')
          ..write('measuredAt: $measuredAt, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncCursorsTable extends SyncCursors
    with TableInfo<$SyncCursorsTable, SyncCursorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCursorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [kind, seq];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_cursors';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncCursorRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kind};
  @override
  SyncCursorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCursorRow(
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
    );
  }

  @override
  $SyncCursorsTable createAlias(String alias) {
    return $SyncCursorsTable(attachedDatabase, alias);
  }
}

class SyncCursorRow extends DataClass implements Insertable<SyncCursorRow> {
  /// The table, by its name on both sides.
  final String kind;
  final int seq;
  const SyncCursorRow({required this.kind, required this.seq});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind'] = Variable<String>(kind);
    map['seq'] = Variable<int>(seq);
    return map;
  }

  SyncCursorsCompanion toCompanion(bool nullToAbsent) {
    return SyncCursorsCompanion(kind: Value(kind), seq: Value(seq));
  }

  factory SyncCursorRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCursorRow(
      kind: serializer.fromJson<String>(json['kind']),
      seq: serializer.fromJson<int>(json['seq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(kind),
      'seq': serializer.toJson<int>(seq),
    };
  }

  SyncCursorRow copyWith({String? kind, int? seq}) =>
      SyncCursorRow(kind: kind ?? this.kind, seq: seq ?? this.seq);
  SyncCursorRow copyWithCompanion(SyncCursorsCompanion data) {
    return SyncCursorRow(
      kind: data.kind.present ? data.kind.value : this.kind,
      seq: data.seq.present ? data.seq.value : this.seq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorRow(')
          ..write('kind: $kind, ')
          ..write('seq: $seq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kind, seq);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCursorRow &&
          other.kind == this.kind &&
          other.seq == this.seq);
}

class SyncCursorsCompanion extends UpdateCompanion<SyncCursorRow> {
  final Value<String> kind;
  final Value<int> seq;
  final Value<int> rowid;
  const SyncCursorsCompanion({
    this.kind = const Value.absent(),
    this.seq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCursorsCompanion.insert({
    required String kind,
    required int seq,
    this.rowid = const Value.absent(),
  }) : kind = Value(kind),
       seq = Value(seq);
  static Insertable<SyncCursorRow> custom({
    Expression<String>? kind,
    Expression<int>? seq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (seq != null) 'seq': seq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCursorsCompanion copyWith({
    Value<String>? kind,
    Value<int>? seq,
    Value<int>? rowid,
  }) {
    return SyncCursorsCompanion(
      kind: kind ?? this.kind,
      seq: seq ?? this.seq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorsCompanion(')
          ..write('kind: $kind, ')
          ..write('seq: $seq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncAccountTable extends SyncAccount
    with TableInfo<$SyncAccountTable, SyncAccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncAccountTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    check: () => id.equals(1),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _boundAtMeta = const VerificationMeta(
    'boundAt',
  );
  @override
  late final GeneratedColumn<DateTime> boundAt = GeneratedColumn<DateTime>(
    'bound_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, accountId, email, boundAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_account';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncAccountRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('bound_at')) {
      context.handle(
        _boundAtMeta,
        boundAt.isAcceptableOrUnknown(data['bound_at']!, _boundAtMeta),
      );
    } else if (isInserting) {
      context.missing(_boundAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncAccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncAccountRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      boundAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}bound_at'],
      )!,
    );
  }

  @override
  $SyncAccountTable createAlias(String alias) {
    return $SyncAccountTable(attachedDatabase, alias);
  }
}

class SyncAccountRow extends DataClass implements Insertable<SyncAccountRow> {
  /// Always 1: a phone's data belongs to one account at a time.
  final int id;
  final String accountId;
  final String? email;
  final DateTime boundAt;
  const SyncAccountRow({
    required this.id,
    required this.accountId,
    this.email,
    required this.boundAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['account_id'] = Variable<String>(accountId);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['bound_at'] = Variable<DateTime>(boundAt);
    return map;
  }

  SyncAccountCompanion toCompanion(bool nullToAbsent) {
    return SyncAccountCompanion(
      id: Value(id),
      accountId: Value(accountId),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      boundAt: Value(boundAt),
    );
  }

  factory SyncAccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncAccountRow(
      id: serializer.fromJson<int>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      email: serializer.fromJson<String?>(json['email']),
      boundAt: serializer.fromJson<DateTime>(json['boundAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'accountId': serializer.toJson<String>(accountId),
      'email': serializer.toJson<String?>(email),
      'boundAt': serializer.toJson<DateTime>(boundAt),
    };
  }

  SyncAccountRow copyWith({
    int? id,
    String? accountId,
    Value<String?> email = const Value.absent(),
    DateTime? boundAt,
  }) => SyncAccountRow(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    email: email.present ? email.value : this.email,
    boundAt: boundAt ?? this.boundAt,
  );
  SyncAccountRow copyWithCompanion(SyncAccountCompanion data) {
    return SyncAccountRow(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      email: data.email.present ? data.email.value : this.email,
      boundAt: data.boundAt.present ? data.boundAt.value : this.boundAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncAccountRow(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('email: $email, ')
          ..write('boundAt: $boundAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, accountId, email, boundAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncAccountRow &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.email == this.email &&
          other.boundAt == this.boundAt);
}

class SyncAccountCompanion extends UpdateCompanion<SyncAccountRow> {
  final Value<int> id;
  final Value<String> accountId;
  final Value<String?> email;
  final Value<DateTime> boundAt;
  const SyncAccountCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.email = const Value.absent(),
    this.boundAt = const Value.absent(),
  });
  SyncAccountCompanion.insert({
    this.id = const Value.absent(),
    required String accountId,
    this.email = const Value.absent(),
    required DateTime boundAt,
  }) : accountId = Value(accountId),
       boundAt = Value(boundAt);
  static Insertable<SyncAccountRow> custom({
    Expression<int>? id,
    Expression<String>? accountId,
    Expression<String>? email,
    Expression<DateTime>? boundAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (email != null) 'email': email,
      if (boundAt != null) 'bound_at': boundAt,
    });
  }

  SyncAccountCompanion copyWith({
    Value<int>? id,
    Value<String>? accountId,
    Value<String?>? email,
    Value<DateTime>? boundAt,
  }) {
    return SyncAccountCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      email: email ?? this.email,
      boundAt: boundAt ?? this.boundAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (boundAt.present) {
      map['bound_at'] = Variable<DateTime>(boundAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncAccountCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('email: $email, ')
          ..write('boundAt: $boundAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final Trigger profilesStampForward = Trigger(
    'CREATE TRIGGER profiles_stamp_forward AFTER UPDATE OF updated_at ON profiles WHEN NEW.dirty = 1 AND NEW.updated_at <= OLD.updated_at BEGIN UPDATE profiles SET updated_at = OLD.updated_at + 1 WHERE id = NEW.id;END',
    'profiles_stamp_forward',
  );
  late final $GoalsTable goals = $GoalsTable(this);
  late final Trigger goalsStampForward = Trigger(
    'CREATE TRIGGER goals_stamp_forward AFTER UPDATE OF updated_at ON goals WHEN NEW.dirty = 1 AND NEW.updated_at <= OLD.updated_at BEGIN UPDATE goals SET updated_at = OLD.updated_at + 1 WHERE id = NEW.id;END',
    'goals_stamp_forward',
  );
  late final $WeightLogsTable weightLogs = $WeightLogsTable(this);
  late final Trigger weightLogsStampForward = Trigger(
    'CREATE TRIGGER weight_logs_stamp_forward AFTER UPDATE OF updated_at ON weight_logs WHEN NEW.dirty = 1 AND NEW.updated_at <= OLD.updated_at BEGIN UPDATE weight_logs SET updated_at = OLD.updated_at + 1 WHERE id = NEW.id;END',
    'weight_logs_stamp_forward',
  );
  late final $MealEntriesTable mealEntries = $MealEntriesTable(this);
  late final Trigger mealEntriesStampForward = Trigger(
    'CREATE TRIGGER meal_entries_stamp_forward AFTER UPDATE OF updated_at ON meal_entries WHEN NEW.dirty = 1 AND NEW.updated_at <= OLD.updated_at BEGIN UPDATE meal_entries SET updated_at = OLD.updated_at + 1 WHERE id = NEW.id;END',
    'meal_entries_stamp_forward',
  );
  late final $HealthSamplesTable healthSamples = $HealthSamplesTable(this);
  late final Trigger healthSamplesStampForward = Trigger(
    'CREATE TRIGGER health_samples_stamp_forward AFTER UPDATE OF updated_at ON health_samples WHEN NEW.dirty = 1 AND NEW.updated_at <= OLD.updated_at BEGIN UPDATE health_samples SET updated_at = OLD.updated_at + 1 WHERE id = NEW.id;END',
    'health_samples_stamp_forward',
  );
  late final $SyncCursorsTable syncCursors = $SyncCursorsTable(this);
  late final $SyncAccountTable syncAccount = $SyncAccountTable(this);
  late final Index goalsOneActive = Index(
    'goals_one_active',
    'CREATE UNIQUE INDEX goals_one_active ON goals ((ended_at IS NULL)) WHERE ended_at IS NULL AND deleted_at IS NULL',
  );
  late final Index weightLogsOneADay = Index(
    'weight_logs_one_a_day',
    'CREATE UNIQUE INDEX weight_logs_one_a_day ON weight_logs (day) WHERE deleted_at IS NULL',
  );
  late final Index mealEntriesEatenAt = Index(
    'meal_entries_eaten_at',
    'CREATE INDEX meal_entries_eaten_at ON meal_entries (eaten_at)',
  );
  late final Index healthSamplesMetricTime = Index(
    'health_samples_metric_time',
    'CREATE INDEX health_samples_metric_time ON health_samples (metric, measured_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profiles,
    profilesStampForward,
    goals,
    goalsStampForward,
    weightLogs,
    weightLogsStampForward,
    mealEntries,
    mealEntriesStampForward,
    healthSamples,
    healthSamplesStampForward,
    syncCursors,
    syncAccount,
    goalsOneActive,
    weightLogsOneADay,
    mealEntriesEatenAt,
    healthSamplesMetricTime,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'profiles',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('profiles', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'goals',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('goals', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'weight_logs',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('weight_logs', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'meal_entries',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('meal_entries', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'health_samples',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('health_samples', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  Value<bool> dirty,
  Value<int> id,
  required DateTime birthDate,
  Value<Sex?> sex,
  required double heightCm,
  required ActivityLevel activityLevel,
  Value<DietType?> dietType,
  Value<TrainingPlace?> trainingPlace,
  Value<Experience?> experience,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<bool> dirty,
  Value<int> id,
  Value<DateTime> birthDate,
  Value<Sex?> sex,
  Value<double> heightCm,
  Value<ActivityLevel> activityLevel,
  Value<DietType?> dietType,
  Value<TrainingPlace?> trainingPlace,
  Value<Experience?> experience,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
});

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get birthDate =>
      $composableBuilder(
        column: $table.birthDate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Sex?, Sex, String> get sex =>
      $composableBuilder(
        column: $table.sex,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ActivityLevel, ActivityLevel, String>
  get activityLevel => $composableBuilder(
    column: $table.activityLevel,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DietType?, DietType, String> get dietType =>
      $composableBuilder(
        column: $table.dietType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<TrainingPlace?, TrainingPlace, String>
  get trainingPlace => $composableBuilder(
    column: $table.trainingPlace,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Experience?, Experience, String>
  get experience => $composableBuilder(
    column: $table.experience,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityLevel => $composableBuilder(
    column: $table.activityLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dietType => $composableBuilder(
    column: $table.dietType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trainingPlace => $composableBuilder(
    column: $table.trainingPlace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get experience => $composableBuilder(
    column: $table.experience,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get birthDate =>
      $composableBuilder(column: $table.birthDate, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Sex?, String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ActivityLevel, String> get activityLevel =>
      $composableBuilder(
        column: $table.activityLevel,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DietType?, String> get dietType =>
      $composableBuilder(column: $table.dietType, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TrainingPlace?, String> get trainingPlace =>
      $composableBuilder(
        column: $table.trainingPlace,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Experience?, String> get experience =>
      $composableBuilder(
        column: $table.experience,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          ProfileRow,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (
            ProfileRow,
            BaseReferences<_$AppDatabase, $ProfilesTable, ProfileRow>,
          ),
          ProfileRow,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<bool> dirty = const Value.absent(),
                Value<int> id = const Value.absent(),
                Value<DateTime> birthDate = const Value.absent(),
                Value<Sex?> sex = const Value.absent(),
                Value<double> heightCm = const Value.absent(),
                Value<ActivityLevel> activityLevel = const Value.absent(),
                Value<DietType?> dietType = const Value.absent(),
                Value<TrainingPlace?> trainingPlace = const Value.absent(),
                Value<Experience?> experience = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => ProfilesCompanion(
                dirty: dirty,
                id: id,
                birthDate: birthDate,
                sex: sex,
                heightCm: heightCm,
                activityLevel: activityLevel,
                dietType: dietType,
                trainingPlace: trainingPlace,
                experience: experience,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<bool> dirty = const Value.absent(),
                Value<int> id = const Value.absent(),
                required DateTime birthDate,
                Value<Sex?> sex = const Value.absent(),
                required double heightCm,
                required ActivityLevel activityLevel,
                Value<DietType?> dietType = const Value.absent(),
                Value<TrainingPlace?> trainingPlace = const Value.absent(),
                Value<Experience?> experience = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => ProfilesCompanion.insert(
                dirty: dirty,
                id: id,
                birthDate: birthDate,
                sex: sex,
                heightCm: heightCm,
                activityLevel: activityLevel,
                dietType: dietType,
                trainingPlace: trainingPlace,
                experience: experience,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfilesTable, ProfileRow>(table),
                  BaseReferences<_$AppDatabase, $ProfilesTable, ProfileRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      ProfileRow,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (ProfileRow, BaseReferences<_$AppDatabase, $ProfilesTable, ProfileRow>),
      ProfileRow,
      PrefetchHooks Function()
    >;
typedef $$GoalsTableCreateCompanionBuilder = GoalsCompanion Function({
  Value<bool> dirty,
  required String id,
  required GoalType goalType,
  Value<double?> targetWeightKg,
  required double basisWeightKg,
  required int caloriesKcal,
  required int proteinG,
  required int carbsG,
  required int fatG,
  required int waterMl,
  required int steps,
  required String formulaVersion,
  required DateTime startedAt,
  Value<DateTime?> endedAt,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$GoalsTableUpdateCompanionBuilder = GoalsCompanion Function({
  Value<bool> dirty,
  Value<String> id,
  Value<GoalType> goalType,
  Value<double?> targetWeightKg,
  Value<double> basisWeightKg,
  Value<int> caloriesKcal,
  Value<int> proteinG,
  Value<int> carbsG,
  Value<int> fatG,
  Value<int> waterMl,
  Value<int> steps,
  Value<String> formulaVersion,
  Value<DateTime> startedAt,
  Value<DateTime?> endedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<GoalType, GoalType, String> get goalType =>
      $composableBuilder(
        column: $table.goalType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get targetWeightKg => $composableBuilder(
    column: $table.targetWeightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get basisWeightKg => $composableBuilder(
    column: $table.basisWeightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get caloriesKcal => $composableBuilder(
    column: $table.caloriesKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get waterMl => $composableBuilder(
    column: $table.waterMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get formulaVersion => $composableBuilder(
    column: $table.formulaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goalType => $composableBuilder(
    column: $table.goalType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetWeightKg => $composableBuilder(
    column: $table.targetWeightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get basisWeightKg => $composableBuilder(
    column: $table.basisWeightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get caloriesKcal => $composableBuilder(
    column: $table.caloriesKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get waterMl => $composableBuilder(
    column: $table.waterMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get formulaVersion => $composableBuilder(
    column: $table.formulaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<GoalType, String> get goalType =>
      $composableBuilder(column: $table.goalType, builder: (column) => column);

  GeneratedColumn<double> get targetWeightKg => $composableBuilder(
    column: $table.targetWeightKg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get basisWeightKg => $composableBuilder(
    column: $table.basisWeightKg,
    builder: (column) => column,
  );

  GeneratedColumn<int> get caloriesKcal => $composableBuilder(
    column: $table.caloriesKcal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<int> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumn<int> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<int> get waterMl =>
      $composableBuilder(column: $table.waterMl, builder: (column) => column);

  GeneratedColumn<int> get steps =>
      $composableBuilder(column: $table.steps, builder: (column) => column);

  GeneratedColumn<String> get formulaVersion => $composableBuilder(
    column: $table.formulaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$GoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalsTable,
          GoalRow,
          $$GoalsTableFilterComposer,
          $$GoalsTableOrderingComposer,
          $$GoalsTableAnnotationComposer,
          $$GoalsTableCreateCompanionBuilder,
          $$GoalsTableUpdateCompanionBuilder,
          (GoalRow, BaseReferences<_$AppDatabase, $GoalsTable, GoalRow>),
          GoalRow,
          PrefetchHooks Function()
        > {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<bool> dirty = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<GoalType> goalType = const Value.absent(),
                Value<double?> targetWeightKg = const Value.absent(),
                Value<double> basisWeightKg = const Value.absent(),
                Value<int> caloriesKcal = const Value.absent(),
                Value<int> proteinG = const Value.absent(),
                Value<int> carbsG = const Value.absent(),
                Value<int> fatG = const Value.absent(),
                Value<int> waterMl = const Value.absent(),
                Value<int> steps = const Value.absent(),
                Value<String> formulaVersion = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion(
                dirty: dirty,
                id: id,
                goalType: goalType,
                targetWeightKg: targetWeightKg,
                basisWeightKg: basisWeightKg,
                caloriesKcal: caloriesKcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                waterMl: waterMl,
                steps: steps,
                formulaVersion: formulaVersion,
                startedAt: startedAt,
                endedAt: endedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<bool> dirty = const Value.absent(),
                required String id,
                required GoalType goalType,
                Value<double?> targetWeightKg = const Value.absent(),
                required double basisWeightKg,
                required int caloriesKcal,
                required int proteinG,
                required int carbsG,
                required int fatG,
                required int waterMl,
                required int steps,
                required String formulaVersion,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion.insert(
                dirty: dirty,
                id: id,
                goalType: goalType,
                targetWeightKg: targetWeightKg,
                basisWeightKg: basisWeightKg,
                caloriesKcal: caloriesKcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                waterMl: waterMl,
                steps: steps,
                formulaVersion: formulaVersion,
                startedAt: startedAt,
                endedAt: endedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GoalsTable, GoalRow>(table),
                  BaseReferences<_$AppDatabase, $GoalsTable, GoalRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalsTable,
      GoalRow,
      $$GoalsTableFilterComposer,
      $$GoalsTableOrderingComposer,
      $$GoalsTableAnnotationComposer,
      $$GoalsTableCreateCompanionBuilder,
      $$GoalsTableUpdateCompanionBuilder,
      (GoalRow, BaseReferences<_$AppDatabase, $GoalsTable, GoalRow>),
      GoalRow,
      PrefetchHooks Function()
    >;
typedef $$WeightLogsTableCreateCompanionBuilder = WeightLogsCompanion Function({
  Value<bool> dirty,
  required String id,
  required DateTime day,
  required double weightKg,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$WeightLogsTableUpdateCompanionBuilder = WeightLogsCompanion Function({
  Value<bool> dirty,
  Value<String> id,
  Value<DateTime> day,
  Value<double> weightKg,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

class $$WeightLogsTableFilterComposer
    extends Composer<_$AppDatabase, $WeightLogsTable> {
  $$WeightLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get day =>
      $composableBuilder(
        column: $table.day,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeightLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $WeightLogsTable> {
  $$WeightLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeightLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeightLogsTable> {
  $$WeightLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$WeightLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeightLogsTable,
          WeightLogRow,
          $$WeightLogsTableFilterComposer,
          $$WeightLogsTableOrderingComposer,
          $$WeightLogsTableAnnotationComposer,
          $$WeightLogsTableCreateCompanionBuilder,
          $$WeightLogsTableUpdateCompanionBuilder,
          (
            WeightLogRow,
            BaseReferences<_$AppDatabase, $WeightLogsTable, WeightLogRow>,
          ),
          WeightLogRow,
          PrefetchHooks Function()
        > {
  $$WeightLogsTableTableManager(_$AppDatabase db, $WeightLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeightLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeightLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeightLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<bool> dirty = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<DateTime> day = const Value.absent(),
                Value<double> weightKg = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeightLogsCompanion(
                dirty: dirty,
                id: id,
                day: day,
                weightKg: weightKg,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<bool> dirty = const Value.absent(),
                required String id,
                required DateTime day,
                required double weightKg,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeightLogsCompanion.insert(
                dirty: dirty,
                id: id,
                day: day,
                weightKg: weightKg,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WeightLogsTable, WeightLogRow>(table),
                  BaseReferences<_$AppDatabase, $WeightLogsTable, WeightLogRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeightLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeightLogsTable,
      WeightLogRow,
      $$WeightLogsTableFilterComposer,
      $$WeightLogsTableOrderingComposer,
      $$WeightLogsTableAnnotationComposer,
      $$WeightLogsTableCreateCompanionBuilder,
      $$WeightLogsTableUpdateCompanionBuilder,
      (
        WeightLogRow,
        BaseReferences<_$AppDatabase, $WeightLogsTable, WeightLogRow>,
      ),
      WeightLogRow,
      PrefetchHooks Function()
    >;
typedef $$MealEntriesTableCreateCompanionBuilder =
    MealEntriesCompanion Function({
      Value<bool> dirty,
      required String id,
      Value<String?> foodId,
      required String name,
      required Meal meal,
      required double grams,
      required double kcal,
      required double proteinG,
      required double carbsG,
      required double fatG,
      required DateTime eatenAt,
      required EntrySource source,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$MealEntriesTableUpdateCompanionBuilder =
    MealEntriesCompanion Function({
      Value<bool> dirty,
      Value<String> id,
      Value<String?> foodId,
      Value<String> name,
      Value<Meal> meal,
      Value<double> grams,
      Value<double> kcal,
      Value<double> proteinG,
      Value<double> carbsG,
      Value<double> fatG,
      Value<DateTime> eatenAt,
      Value<EntrySource> source,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$MealEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $MealEntriesTable> {
  $$MealEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Meal, Meal, String> get meal =>
      $composableBuilder(
        column: $table.meal,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get eatenAt => $composableBuilder(
    column: $table.eatenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EntrySource, EntrySource, String> get source =>
      $composableBuilder(
        column: $table.source,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MealEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MealEntriesTable> {
  $$MealEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meal => $composableBuilder(
    column: $table.meal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get eatenAt => $composableBuilder(
    column: $table.eatenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealEntriesTable> {
  $$MealEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get foodId =>
      $composableBuilder(column: $table.foodId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Meal, String> get meal =>
      $composableBuilder(column: $table.meal, builder: (column) => column);

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  GeneratedColumn<double> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<DateTime> get eatenAt =>
      $composableBuilder(column: $table.eatenAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EntrySource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$MealEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealEntriesTable,
          MealEntryRow,
          $$MealEntriesTableFilterComposer,
          $$MealEntriesTableOrderingComposer,
          $$MealEntriesTableAnnotationComposer,
          $$MealEntriesTableCreateCompanionBuilder,
          $$MealEntriesTableUpdateCompanionBuilder,
          (
            MealEntryRow,
            BaseReferences<_$AppDatabase, $MealEntriesTable, MealEntryRow>,
          ),
          MealEntryRow,
          PrefetchHooks Function()
        > {
  $$MealEntriesTableTableManager(_$AppDatabase db, $MealEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<bool> dirty = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String?> foodId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<Meal> meal = const Value.absent(),
                Value<double> grams = const Value.absent(),
                Value<double> kcal = const Value.absent(),
                Value<double> proteinG = const Value.absent(),
                Value<double> carbsG = const Value.absent(),
                Value<double> fatG = const Value.absent(),
                Value<DateTime> eatenAt = const Value.absent(),
                Value<EntrySource> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealEntriesCompanion(
                dirty: dirty,
                id: id,
                foodId: foodId,
                name: name,
                meal: meal,
                grams: grams,
                kcal: kcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                eatenAt: eatenAt,
                source: source,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<bool> dirty = const Value.absent(),
                required String id,
                Value<String?> foodId = const Value.absent(),
                required String name,
                required Meal meal,
                required double grams,
                required double kcal,
                required double proteinG,
                required double carbsG,
                required double fatG,
                required DateTime eatenAt,
                required EntrySource source,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealEntriesCompanion.insert(
                dirty: dirty,
                id: id,
                foodId: foodId,
                name: name,
                meal: meal,
                grams: grams,
                kcal: kcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                eatenAt: eatenAt,
                source: source,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MealEntriesTable, MealEntryRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MealEntriesTable,
                    MealEntryRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MealEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealEntriesTable,
      MealEntryRow,
      $$MealEntriesTableFilterComposer,
      $$MealEntriesTableOrderingComposer,
      $$MealEntriesTableAnnotationComposer,
      $$MealEntriesTableCreateCompanionBuilder,
      $$MealEntriesTableUpdateCompanionBuilder,
      (
        MealEntryRow,
        BaseReferences<_$AppDatabase, $MealEntriesTable, MealEntryRow>,
      ),
      MealEntryRow,
      PrefetchHooks Function()
    >;
typedef $$HealthSamplesTableCreateCompanionBuilder =
    HealthSamplesCompanion Function({
      Value<bool> dirty,
      required String id,
      required HealthMetric metric,
      required double value,
      required DateTime measuredAt,
      required SampleSource source,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$HealthSamplesTableUpdateCompanionBuilder =
    HealthSamplesCompanion Function({
      Value<bool> dirty,
      Value<String> id,
      Value<HealthMetric> metric,
      Value<double> value,
      Value<DateTime> measuredAt,
      Value<SampleSource> source,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$HealthSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $HealthSamplesTable> {
  $$HealthSamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<HealthMetric, HealthMetric, String>
  get metric => $composableBuilder(
    column: $table.metric,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SampleSource, SampleSource, String>
  get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HealthSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $HealthSamplesTable> {
  $$HealthSamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metric => $composableBuilder(
    column: $table.metric,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HealthSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HealthSamplesTable> {
  $$HealthSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<HealthMetric, String> get metric =>
      $composableBuilder(column: $table.metric, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SampleSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$HealthSamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HealthSamplesTable,
          HealthSampleRow,
          $$HealthSamplesTableFilterComposer,
          $$HealthSamplesTableOrderingComposer,
          $$HealthSamplesTableAnnotationComposer,
          $$HealthSamplesTableCreateCompanionBuilder,
          $$HealthSamplesTableUpdateCompanionBuilder,
          (
            HealthSampleRow,
            BaseReferences<_$AppDatabase, $HealthSamplesTable, HealthSampleRow>,
          ),
          HealthSampleRow,
          PrefetchHooks Function()
        > {
  $$HealthSamplesTableTableManager(_$AppDatabase db, $HealthSamplesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HealthSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HealthSamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HealthSamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<bool> dirty = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<HealthMetric> metric = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<DateTime> measuredAt = const Value.absent(),
                Value<SampleSource> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HealthSamplesCompanion(
                dirty: dirty,
                id: id,
                metric: metric,
                value: value,
                measuredAt: measuredAt,
                source: source,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<bool> dirty = const Value.absent(),
                required String id,
                required HealthMetric metric,
                required double value,
                required DateTime measuredAt,
                required SampleSource source,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HealthSamplesCompanion.insert(
                dirty: dirty,
                id: id,
                metric: metric,
                value: value,
                measuredAt: measuredAt,
                source: source,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HealthSamplesTable, HealthSampleRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $HealthSamplesTable,
                    HealthSampleRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HealthSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HealthSamplesTable,
      HealthSampleRow,
      $$HealthSamplesTableFilterComposer,
      $$HealthSamplesTableOrderingComposer,
      $$HealthSamplesTableAnnotationComposer,
      $$HealthSamplesTableCreateCompanionBuilder,
      $$HealthSamplesTableUpdateCompanionBuilder,
      (
        HealthSampleRow,
        BaseReferences<_$AppDatabase, $HealthSamplesTable, HealthSampleRow>,
      ),
      HealthSampleRow,
      PrefetchHooks Function()
    >;
typedef $$SyncCursorsTableCreateCompanionBuilder =
    SyncCursorsCompanion Function({
      required String kind,
      required int seq,
      Value<int> rowid,
    });
typedef $$SyncCursorsTableUpdateCompanionBuilder =
    SyncCursorsCompanion Function({
      Value<String> kind,
      Value<int> seq,
      Value<int> rowid,
    });

class $$SyncCursorsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncCursorsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncCursorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);
}

class $$SyncCursorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncCursorsTable,
          SyncCursorRow,
          $$SyncCursorsTableFilterComposer,
          $$SyncCursorsTableOrderingComposer,
          $$SyncCursorsTableAnnotationComposer,
          $$SyncCursorsTableCreateCompanionBuilder,
          $$SyncCursorsTableUpdateCompanionBuilder,
          (
            SyncCursorRow,
            BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursorRow>,
          ),
          SyncCursorRow,
          PrefetchHooks Function()
        > {
  $$SyncCursorsTableTableManager(_$AppDatabase db, $SyncCursorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncCursorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncCursorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncCursorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> kind = const Value.absent(),
            Value<int> seq = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SyncCursorsCompanion(kind: kind, seq: seq, rowid: rowid),
          createCompanionCallback: ({
            required String kind,
            required int seq,
            Value<int> rowid = const Value.absent(),
          }) => SyncCursorsCompanion.insert(kind: kind, seq: seq, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncCursorsTable, SyncCursorRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncCursorsTable,
                    SyncCursorRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncCursorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncCursorsTable,
      SyncCursorRow,
      $$SyncCursorsTableFilterComposer,
      $$SyncCursorsTableOrderingComposer,
      $$SyncCursorsTableAnnotationComposer,
      $$SyncCursorsTableCreateCompanionBuilder,
      $$SyncCursorsTableUpdateCompanionBuilder,
      (
        SyncCursorRow,
        BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursorRow>,
      ),
      SyncCursorRow,
      PrefetchHooks Function()
    >;
typedef $$SyncAccountTableCreateCompanionBuilder =
    SyncAccountCompanion Function({
      Value<int> id,
      required String accountId,
      Value<String?> email,
      required DateTime boundAt,
    });
typedef $$SyncAccountTableUpdateCompanionBuilder =
    SyncAccountCompanion Function({
      Value<int> id,
      Value<String> accountId,
      Value<String?> email,
      Value<DateTime> boundAt,
    });

class $$SyncAccountTableFilterComposer
    extends Composer<_$AppDatabase, $SyncAccountTable> {
  $$SyncAccountTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get boundAt => $composableBuilder(
    column: $table.boundAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncAccountTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncAccountTable> {
  $$SyncAccountTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get boundAt => $composableBuilder(
    column: $table.boundAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncAccountTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncAccountTable> {
  $$SyncAccountTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<DateTime> get boundAt =>
      $composableBuilder(column: $table.boundAt, builder: (column) => column);
}

class $$SyncAccountTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncAccountTable,
          SyncAccountRow,
          $$SyncAccountTableFilterComposer,
          $$SyncAccountTableOrderingComposer,
          $$SyncAccountTableAnnotationComposer,
          $$SyncAccountTableCreateCompanionBuilder,
          $$SyncAccountTableUpdateCompanionBuilder,
          (
            SyncAccountRow,
            BaseReferences<_$AppDatabase, $SyncAccountTable, SyncAccountRow>,
          ),
          SyncAccountRow,
          PrefetchHooks Function()
        > {
  $$SyncAccountTableTableManager(_$AppDatabase db, $SyncAccountTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncAccountTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncAccountTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncAccountTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<DateTime> boundAt = const Value.absent(),
              }) => SyncAccountCompanion(
                id: id,
                accountId: accountId,
                email: email,
                boundAt: boundAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String accountId,
                Value<String?> email = const Value.absent(),
                required DateTime boundAt,
              }) => SyncAccountCompanion.insert(
                id: id,
                accountId: accountId,
                email: email,
                boundAt: boundAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncAccountTable, SyncAccountRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncAccountTable,
                    SyncAccountRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncAccountTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncAccountTable,
      SyncAccountRow,
      $$SyncAccountTableFilterComposer,
      $$SyncAccountTableOrderingComposer,
      $$SyncAccountTableAnnotationComposer,
      $$SyncAccountTableCreateCompanionBuilder,
      $$SyncAccountTableUpdateCompanionBuilder,
      (
        SyncAccountRow,
        BaseReferences<_$AppDatabase, $SyncAccountTable, SyncAccountRow>,
      ),
      SyncAccountRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$WeightLogsTableTableManager get weightLogs =>
      $$WeightLogsTableTableManager(_db, _db.weightLogs);
  $$MealEntriesTableTableManager get mealEntries =>
      $$MealEntriesTableTableManager(_db, _db.mealEntries);
  $$HealthSamplesTableTableManager get healthSamples =>
      $$HealthSamplesTableTableManager(_db, _db.healthSamples);
  $$SyncCursorsTableTableManager get syncCursors =>
      $$SyncCursorsTableTableManager(_db, _db.syncCursors);
  $$SyncAccountTableTableManager get syncAccount =>
      $$SyncAccountTableTableManager(_db, _db.syncAccount);
}
