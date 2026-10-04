// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ChildrenTable extends Children with TableInfo<$ChildrenTable, ChildRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChildrenTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _legacyIdMeta = const VerificationMeta(
    'legacyId',
  );
  @override
  late final GeneratedColumn<String> legacyId = GeneratedColumn<String>(
    'legacy_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasProfileMeta = const VerificationMeta(
    'hasProfile',
  );
  @override
  late final GeneratedColumn<bool> hasProfile = GeneratedColumn<bool>(
    'has_profile',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_profile" IN (0, 1))',
    ),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('boy'),
  );
  static const VerificationMeta _avatarMeta = const VerificationMeta('avatar');
  @override
  late final GeneratedColumn<int> avatar = GeneratedColumn<int>(
    'avatar',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _paletteMeta = const VerificationMeta(
    'palette',
  );
  @override
  late final GeneratedColumn<String> palette = GeneratedColumn<String>(
    'palette',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('automatic'),
  );
  static const VerificationMeta _pendingPhotoMeta = const VerificationMeta(
    'pendingPhoto',
  );
  @override
  late final GeneratedColumn<bool> pendingPhoto = GeneratedColumn<bool>(
    'pending_photo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_photo" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    legacyId,
    hasProfile,
    displayName,
    gender,
    avatar,
    palette,
    pendingPhoto,
    sortOrder,
    version,
    syncStatus,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'children';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChildRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('legacy_id')) {
      context.handle(
        _legacyIdMeta,
        legacyId.isAcceptableOrUnknown(data['legacy_id']!, _legacyIdMeta),
      );
    }
    if (data.containsKey('has_profile')) {
      context.handle(
        _hasProfileMeta,
        hasProfile.isAcceptableOrUnknown(data['has_profile']!, _hasProfileMeta),
      );
    } else if (isInserting) {
      context.missing(_hasProfileMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    }
    if (data.containsKey('avatar')) {
      context.handle(
        _avatarMeta,
        avatar.isAcceptableOrUnknown(data['avatar']!, _avatarMeta),
      );
    }
    if (data.containsKey('palette')) {
      context.handle(
        _paletteMeta,
        palette.isAcceptableOrUnknown(data['palette']!, _paletteMeta),
      );
    }
    if (data.containsKey('pending_photo')) {
      context.handle(
        _pendingPhotoMeta,
        pendingPhoto.isAcceptableOrUnknown(
          data['pending_photo']!,
          _pendingPhotoMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChildRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChildRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      legacyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legacy_id'],
      ),
      hasProfile: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_profile'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      )!,
      avatar: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}avatar'],
      )!,
      palette: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}palette'],
      )!,
      pendingPhoto: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_photo'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ChildrenTable createAlias(String alias) {
    return $ChildrenTable(attachedDatabase, alias);
  }
}

class ChildRow extends DataClass implements Insertable<ChildRow> {
  /// UUIDv7.
  final String id;

  /// The ID the child had in the Hive save (`local-child`, 32 hex, ...).
  final String? legacyId;

  /// False for the empty profile shown before onboarding finishes.
  final bool hasProfile;
  final String displayName;
  final String gender;
  final int avatar;
  final String palette;
  final bool pendingPhoto;
  final int sortOrder;
  final int version;
  final String syncStatus;
  final DateTime updatedAt;
  const ChildRow({
    required this.id,
    this.legacyId,
    required this.hasProfile,
    required this.displayName,
    required this.gender,
    required this.avatar,
    required this.palette,
    required this.pendingPhoto,
    required this.sortOrder,
    required this.version,
    required this.syncStatus,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || legacyId != null) {
      map['legacy_id'] = Variable<String>(legacyId);
    }
    map['has_profile'] = Variable<bool>(hasProfile);
    map['display_name'] = Variable<String>(displayName);
    map['gender'] = Variable<String>(gender);
    map['avatar'] = Variable<int>(avatar);
    map['palette'] = Variable<String>(palette);
    map['pending_photo'] = Variable<bool>(pendingPhoto);
    map['sort_order'] = Variable<int>(sortOrder);
    map['version'] = Variable<int>(version);
    map['sync_status'] = Variable<String>(syncStatus);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ChildrenCompanion toCompanion(bool nullToAbsent) {
    return ChildrenCompanion(
      id: Value(id),
      legacyId: legacyId == null && nullToAbsent
          ? const Value.absent()
          : Value(legacyId),
      hasProfile: Value(hasProfile),
      displayName: Value(displayName),
      gender: Value(gender),
      avatar: Value(avatar),
      palette: Value(palette),
      pendingPhoto: Value(pendingPhoto),
      sortOrder: Value(sortOrder),
      version: Value(version),
      syncStatus: Value(syncStatus),
      updatedAt: Value(updatedAt),
    );
  }

  factory ChildRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChildRow(
      id: serializer.fromJson<String>(json['id']),
      legacyId: serializer.fromJson<String?>(json['legacyId']),
      hasProfile: serializer.fromJson<bool>(json['hasProfile']),
      displayName: serializer.fromJson<String>(json['displayName']),
      gender: serializer.fromJson<String>(json['gender']),
      avatar: serializer.fromJson<int>(json['avatar']),
      palette: serializer.fromJson<String>(json['palette']),
      pendingPhoto: serializer.fromJson<bool>(json['pendingPhoto']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      version: serializer.fromJson<int>(json['version']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'legacyId': serializer.toJson<String?>(legacyId),
      'hasProfile': serializer.toJson<bool>(hasProfile),
      'displayName': serializer.toJson<String>(displayName),
      'gender': serializer.toJson<String>(gender),
      'avatar': serializer.toJson<int>(avatar),
      'palette': serializer.toJson<String>(palette),
      'pendingPhoto': serializer.toJson<bool>(pendingPhoto),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'version': serializer.toJson<int>(version),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ChildRow copyWith({
    String? id,
    Value<String?> legacyId = const Value.absent(),
    bool? hasProfile,
    String? displayName,
    String? gender,
    int? avatar,
    String? palette,
    bool? pendingPhoto,
    int? sortOrder,
    int? version,
    String? syncStatus,
    DateTime? updatedAt,
  }) => ChildRow(
    id: id ?? this.id,
    legacyId: legacyId.present ? legacyId.value : this.legacyId,
    hasProfile: hasProfile ?? this.hasProfile,
    displayName: displayName ?? this.displayName,
    gender: gender ?? this.gender,
    avatar: avatar ?? this.avatar,
    palette: palette ?? this.palette,
    pendingPhoto: pendingPhoto ?? this.pendingPhoto,
    sortOrder: sortOrder ?? this.sortOrder,
    version: version ?? this.version,
    syncStatus: syncStatus ?? this.syncStatus,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ChildRow copyWithCompanion(ChildrenCompanion data) {
    return ChildRow(
      id: data.id.present ? data.id.value : this.id,
      legacyId: data.legacyId.present ? data.legacyId.value : this.legacyId,
      hasProfile: data.hasProfile.present
          ? data.hasProfile.value
          : this.hasProfile,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      gender: data.gender.present ? data.gender.value : this.gender,
      avatar: data.avatar.present ? data.avatar.value : this.avatar,
      palette: data.palette.present ? data.palette.value : this.palette,
      pendingPhoto: data.pendingPhoto.present
          ? data.pendingPhoto.value
          : this.pendingPhoto,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      version: data.version.present ? data.version.value : this.version,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChildRow(')
          ..write('id: $id, ')
          ..write('legacyId: $legacyId, ')
          ..write('hasProfile: $hasProfile, ')
          ..write('displayName: $displayName, ')
          ..write('gender: $gender, ')
          ..write('avatar: $avatar, ')
          ..write('palette: $palette, ')
          ..write('pendingPhoto: $pendingPhoto, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    legacyId,
    hasProfile,
    displayName,
    gender,
    avatar,
    palette,
    pendingPhoto,
    sortOrder,
    version,
    syncStatus,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChildRow &&
          other.id == this.id &&
          other.legacyId == this.legacyId &&
          other.hasProfile == this.hasProfile &&
          other.displayName == this.displayName &&
          other.gender == this.gender &&
          other.avatar == this.avatar &&
          other.palette == this.palette &&
          other.pendingPhoto == this.pendingPhoto &&
          other.sortOrder == this.sortOrder &&
          other.version == this.version &&
          other.syncStatus == this.syncStatus &&
          other.updatedAt == this.updatedAt);
}

class ChildrenCompanion extends UpdateCompanion<ChildRow> {
  final Value<String> id;
  final Value<String?> legacyId;
  final Value<bool> hasProfile;
  final Value<String> displayName;
  final Value<String> gender;
  final Value<int> avatar;
  final Value<String> palette;
  final Value<bool> pendingPhoto;
  final Value<int> sortOrder;
  final Value<int> version;
  final Value<String> syncStatus;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ChildrenCompanion({
    this.id = const Value.absent(),
    this.legacyId = const Value.absent(),
    this.hasProfile = const Value.absent(),
    this.displayName = const Value.absent(),
    this.gender = const Value.absent(),
    this.avatar = const Value.absent(),
    this.palette = const Value.absent(),
    this.pendingPhoto = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChildrenCompanion.insert({
    required String id,
    this.legacyId = const Value.absent(),
    required bool hasProfile,
    this.displayName = const Value.absent(),
    this.gender = const Value.absent(),
    this.avatar = const Value.absent(),
    this.palette = const Value.absent(),
    this.pendingPhoto = const Value.absent(),
    required int sortOrder,
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       hasProfile = Value(hasProfile),
       sortOrder = Value(sortOrder),
       updatedAt = Value(updatedAt);
  static Insertable<ChildRow> custom({
    Expression<String>? id,
    Expression<String>? legacyId,
    Expression<bool>? hasProfile,
    Expression<String>? displayName,
    Expression<String>? gender,
    Expression<int>? avatar,
    Expression<String>? palette,
    Expression<bool>? pendingPhoto,
    Expression<int>? sortOrder,
    Expression<int>? version,
    Expression<String>? syncStatus,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (legacyId != null) 'legacy_id': legacyId,
      if (hasProfile != null) 'has_profile': hasProfile,
      if (displayName != null) 'display_name': displayName,
      if (gender != null) 'gender': gender,
      if (avatar != null) 'avatar': avatar,
      if (palette != null) 'palette': palette,
      if (pendingPhoto != null) 'pending_photo': pendingPhoto,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (version != null) 'version': version,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChildrenCompanion copyWith({
    Value<String>? id,
    Value<String?>? legacyId,
    Value<bool>? hasProfile,
    Value<String>? displayName,
    Value<String>? gender,
    Value<int>? avatar,
    Value<String>? palette,
    Value<bool>? pendingPhoto,
    Value<int>? sortOrder,
    Value<int>? version,
    Value<String>? syncStatus,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ChildrenCompanion(
      id: id ?? this.id,
      legacyId: legacyId ?? this.legacyId,
      hasProfile: hasProfile ?? this.hasProfile,
      displayName: displayName ?? this.displayName,
      gender: gender ?? this.gender,
      avatar: avatar ?? this.avatar,
      palette: palette ?? this.palette,
      pendingPhoto: pendingPhoto ?? this.pendingPhoto,
      sortOrder: sortOrder ?? this.sortOrder,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (legacyId.present) {
      map['legacy_id'] = Variable<String>(legacyId.value);
    }
    if (hasProfile.present) {
      map['has_profile'] = Variable<bool>(hasProfile.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (avatar.present) {
      map['avatar'] = Variable<int>(avatar.value);
    }
    if (palette.present) {
      map['palette'] = Variable<String>(palette.value);
    }
    if (pendingPhoto.present) {
      map['pending_photo'] = Variable<bool>(pendingPhoto.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChildrenCompanion(')
          ..write('id: $id, ')
          ..write('legacyId: $legacyId, ')
          ..write('hasProfile: $hasProfile, ')
          ..write('displayName: $displayName, ')
          ..write('gender: $gender, ')
          ..write('avatar: $avatar, ')
          ..write('palette: $palette, ')
          ..write('pendingPhoto: $pendingPhoto, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChildPhotosTable extends ChildPhotos
    with TableInfo<$ChildPhotosTable, ChildPhotoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChildPhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _childIdMeta = const VerificationMeta(
    'childId',
  );
  @override
  late final GeneratedColumn<String> childId = GeneratedColumn<String>(
    'child_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES children (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<Uint8List> bytes = GeneratedColumn<Uint8List>(
    'bytes',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [childId, bytes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'child_photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChildPhotoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('child_id')) {
      context.handle(
        _childIdMeta,
        childId.isAcceptableOrUnknown(data['child_id']!, _childIdMeta),
      );
    } else if (isInserting) {
      context.missing(_childIdMeta);
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    } else if (isInserting) {
      context.missing(_bytesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {childId};
  @override
  ChildPhotoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChildPhotoRow(
      childId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_id'],
      )!,
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}bytes'],
      )!,
    );
  }

  @override
  $ChildPhotosTable createAlias(String alias) {
    return $ChildPhotosTable(attachedDatabase, alias);
  }
}

class ChildPhotoRow extends DataClass implements Insertable<ChildPhotoRow> {
  final String childId;
  final Uint8List bytes;
  const ChildPhotoRow({required this.childId, required this.bytes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['child_id'] = Variable<String>(childId);
    map['bytes'] = Variable<Uint8List>(bytes);
    return map;
  }

  ChildPhotosCompanion toCompanion(bool nullToAbsent) {
    return ChildPhotosCompanion(childId: Value(childId), bytes: Value(bytes));
  }

  factory ChildPhotoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChildPhotoRow(
      childId: serializer.fromJson<String>(json['childId']),
      bytes: serializer.fromJson<Uint8List>(json['bytes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'childId': serializer.toJson<String>(childId),
      'bytes': serializer.toJson<Uint8List>(bytes),
    };
  }

  ChildPhotoRow copyWith({String? childId, Uint8List? bytes}) => ChildPhotoRow(
    childId: childId ?? this.childId,
    bytes: bytes ?? this.bytes,
  );
  ChildPhotoRow copyWithCompanion(ChildPhotosCompanion data) {
    return ChildPhotoRow(
      childId: data.childId.present ? data.childId.value : this.childId,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChildPhotoRow(')
          ..write('childId: $childId, ')
          ..write('bytes: $bytes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(childId, $driftBlobEquality.hash(bytes));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChildPhotoRow &&
          other.childId == this.childId &&
          $driftBlobEquality.equals(other.bytes, this.bytes));
}

class ChildPhotosCompanion extends UpdateCompanion<ChildPhotoRow> {
  final Value<String> childId;
  final Value<Uint8List> bytes;
  final Value<int> rowid;
  const ChildPhotosCompanion({
    this.childId = const Value.absent(),
    this.bytes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChildPhotosCompanion.insert({
    required String childId,
    required Uint8List bytes,
    this.rowid = const Value.absent(),
  }) : childId = Value(childId),
       bytes = Value(bytes);
  static Insertable<ChildPhotoRow> custom({
    Expression<String>? childId,
    Expression<Uint8List>? bytes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (childId != null) 'child_id': childId,
      if (bytes != null) 'bytes': bytes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChildPhotosCompanion copyWith({
    Value<String>? childId,
    Value<Uint8List>? bytes,
    Value<int>? rowid,
  }) {
    return ChildPhotosCompanion(
      childId: childId ?? this.childId,
      bytes: bytes ?? this.bytes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (childId.present) {
      map['child_id'] = Variable<String>(childId.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<Uint8List>(bytes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChildPhotosCompanion(')
          ..write('childId: $childId, ')
          ..write('bytes: $bytes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChildSettingsTable extends ChildSettings
    with TableInfo<$ChildSettingsTable, ChildSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChildSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _childIdMeta = const VerificationMeta(
    'childId',
  );
  @override
  late final GeneratedColumn<String> childId = GeneratedColumn<String>(
    'child_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES children (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [childId, json, version];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'child_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChildSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('child_id')) {
      context.handle(
        _childIdMeta,
        childId.isAcceptableOrUnknown(data['child_id']!, _childIdMeta),
      );
    } else if (isInserting) {
      context.missing(_childIdMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {childId};
  @override
  ChildSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChildSettingsRow(
      childId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $ChildSettingsTable createAlias(String alias) {
    return $ChildSettingsTable(attachedDatabase, alias);
  }
}

class ChildSettingsRow extends DataClass
    implements Insertable<ChildSettingsRow> {
  final String childId;

  /// The settings object exactly as saved (values are validated by
  /// AppSettings when read).
  final String json;
  final int version;
  const ChildSettingsRow({
    required this.childId,
    required this.json,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['child_id'] = Variable<String>(childId);
    map['json'] = Variable<String>(json);
    map['version'] = Variable<int>(version);
    return map;
  }

  ChildSettingsCompanion toCompanion(bool nullToAbsent) {
    return ChildSettingsCompanion(
      childId: Value(childId),
      json: Value(json),
      version: Value(version),
    );
  }

  factory ChildSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChildSettingsRow(
      childId: serializer.fromJson<String>(json['childId']),
      json: serializer.fromJson<String>(json['json']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'childId': serializer.toJson<String>(childId),
      'json': serializer.toJson<String>(json),
      'version': serializer.toJson<int>(version),
    };
  }

  ChildSettingsRow copyWith({String? childId, String? json, int? version}) =>
      ChildSettingsRow(
        childId: childId ?? this.childId,
        json: json ?? this.json,
        version: version ?? this.version,
      );
  ChildSettingsRow copyWithCompanion(ChildSettingsCompanion data) {
    return ChildSettingsRow(
      childId: data.childId.present ? data.childId.value : this.childId,
      json: data.json.present ? data.json.value : this.json,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChildSettingsRow(')
          ..write('childId: $childId, ')
          ..write('json: $json, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(childId, json, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChildSettingsRow &&
          other.childId == this.childId &&
          other.json == this.json &&
          other.version == this.version);
}

class ChildSettingsCompanion extends UpdateCompanion<ChildSettingsRow> {
  final Value<String> childId;
  final Value<String> json;
  final Value<int> version;
  final Value<int> rowid;
  const ChildSettingsCompanion({
    this.childId = const Value.absent(),
    this.json = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChildSettingsCompanion.insert({
    required String childId,
    required String json,
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : childId = Value(childId),
       json = Value(json);
  static Insertable<ChildSettingsRow> custom({
    Expression<String>? childId,
    Expression<String>? json,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (childId != null) 'child_id': childId,
      if (json != null) 'json': json,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChildSettingsCompanion copyWith({
    Value<String>? childId,
    Value<String>? json,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return ChildSettingsCompanion(
      childId: childId ?? this.childId,
      json: json ?? this.json,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (childId.present) {
      map['child_id'] = Variable<String>(childId.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChildSettingsCompanion(')
          ..write('childId: $childId, ')
          ..write('json: $json, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UnitAttemptsTable extends UnitAttempts
    with TableInfo<$UnitAttemptsTable, AttemptRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnitAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _childIdMeta = const VerificationMeta(
    'childId',
  );
  @override
  late final GeneratedColumn<String> childId = GeneratedColumn<String>(
    'child_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES children (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _curriculumMeta = const VerificationMeta(
    'curriculum',
  );
  @override
  late final GeneratedColumn<String> curriculum = GeneratedColumn<String>(
    'curriculum',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientAttemptIdMeta = const VerificationMeta(
    'clientAttemptId',
  );
  @override
  late final GeneratedColumn<String> clientAttemptId = GeneratedColumn<String>(
    'client_attempt_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitIdMeta = const VerificationMeta('unitId');
  @override
  late final GeneratedColumn<String> unitId = GeneratedColumn<String>(
    'unit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentVersionMeta = const VerificationMeta(
    'contentVersion',
  );
  @override
  late final GeneratedColumn<int> contentVersion = GeneratedColumn<int>(
    'content_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _effortStarsMeta = const VerificationMeta(
    'effortStars',
  );
  @override
  late final GeneratedColumn<int> effortStars = GeneratedColumn<int>(
    'effort_stars',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<String> completedAt = GeneratedColumn<String>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    childId,
    curriculum,
    clientAttemptId,
    unitId,
    contentVersion,
    completed,
    effortStars,
    completedAt,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'unit_attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttemptRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('child_id')) {
      context.handle(
        _childIdMeta,
        childId.isAcceptableOrUnknown(data['child_id']!, _childIdMeta),
      );
    } else if (isInserting) {
      context.missing(_childIdMeta);
    }
    if (data.containsKey('curriculum')) {
      context.handle(
        _curriculumMeta,
        curriculum.isAcceptableOrUnknown(data['curriculum']!, _curriculumMeta),
      );
    } else if (isInserting) {
      context.missing(_curriculumMeta);
    }
    if (data.containsKey('client_attempt_id')) {
      context.handle(
        _clientAttemptIdMeta,
        clientAttemptId.isAcceptableOrUnknown(
          data['client_attempt_id']!,
          _clientAttemptIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientAttemptIdMeta);
    }
    if (data.containsKey('unit_id')) {
      context.handle(
        _unitIdMeta,
        unitId.isAcceptableOrUnknown(data['unit_id']!, _unitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_unitIdMeta);
    }
    if (data.containsKey('content_version')) {
      context.handle(
        _contentVersionMeta,
        contentVersion.isAcceptableOrUnknown(
          data['content_version']!,
          _contentVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentVersionMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    } else if (isInserting) {
      context.missing(_completedMeta);
    }
    if (data.containsKey('effort_stars')) {
      context.handle(
        _effortStarsMeta,
        effortStars.isAcceptableOrUnknown(
          data['effort_stars']!,
          _effortStarsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_effortStarsMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttemptRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttemptRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      childId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_id'],
      )!,
      curriculum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}curriculum'],
      )!,
      clientAttemptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_attempt_id'],
      )!,
      unitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_id'],
      )!,
      contentVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}content_version'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      effortStars: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}effort_stars'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completed_at'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $UnitAttemptsTable createAlias(String alias) {
    return $UnitAttemptsTable(attachedDatabase, alias);
  }
}

class AttemptRow extends DataClass implements Insertable<AttemptRow> {
  /// UUIDv7.
  final String id;
  final String childId;

  /// Year and subject the unit belongs to, e.g. `y1.science` (AUD-023):
  /// unit IDs like `unit_01` only need to be unique inside a curriculum.
  final String curriculum;

  /// The attempt ID the app uses for de-duplication (`{lesson}-{micros}`),
  /// kept exactly as saved; empty for very old attempts.
  final String clientAttemptId;
  final String unitId;
  final int contentVersion;
  final bool completed;
  final int effortStars;

  /// ISO-8601 text exactly as saved (local time without offset).
  final String completedAt;
  final int sortOrder;
  const AttemptRow({
    required this.id,
    required this.childId,
    required this.curriculum,
    required this.clientAttemptId,
    required this.unitId,
    required this.contentVersion,
    required this.completed,
    required this.effortStars,
    required this.completedAt,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['child_id'] = Variable<String>(childId);
    map['curriculum'] = Variable<String>(curriculum);
    map['client_attempt_id'] = Variable<String>(clientAttemptId);
    map['unit_id'] = Variable<String>(unitId);
    map['content_version'] = Variable<int>(contentVersion);
    map['completed'] = Variable<bool>(completed);
    map['effort_stars'] = Variable<int>(effortStars);
    map['completed_at'] = Variable<String>(completedAt);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  UnitAttemptsCompanion toCompanion(bool nullToAbsent) {
    return UnitAttemptsCompanion(
      id: Value(id),
      childId: Value(childId),
      curriculum: Value(curriculum),
      clientAttemptId: Value(clientAttemptId),
      unitId: Value(unitId),
      contentVersion: Value(contentVersion),
      completed: Value(completed),
      effortStars: Value(effortStars),
      completedAt: Value(completedAt),
      sortOrder: Value(sortOrder),
    );
  }

  factory AttemptRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttemptRow(
      id: serializer.fromJson<String>(json['id']),
      childId: serializer.fromJson<String>(json['childId']),
      curriculum: serializer.fromJson<String>(json['curriculum']),
      clientAttemptId: serializer.fromJson<String>(json['clientAttemptId']),
      unitId: serializer.fromJson<String>(json['unitId']),
      contentVersion: serializer.fromJson<int>(json['contentVersion']),
      completed: serializer.fromJson<bool>(json['completed']),
      effortStars: serializer.fromJson<int>(json['effortStars']),
      completedAt: serializer.fromJson<String>(json['completedAt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'childId': serializer.toJson<String>(childId),
      'curriculum': serializer.toJson<String>(curriculum),
      'clientAttemptId': serializer.toJson<String>(clientAttemptId),
      'unitId': serializer.toJson<String>(unitId),
      'contentVersion': serializer.toJson<int>(contentVersion),
      'completed': serializer.toJson<bool>(completed),
      'effortStars': serializer.toJson<int>(effortStars),
      'completedAt': serializer.toJson<String>(completedAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  AttemptRow copyWith({
    String? id,
    String? childId,
    String? curriculum,
    String? clientAttemptId,
    String? unitId,
    int? contentVersion,
    bool? completed,
    int? effortStars,
    String? completedAt,
    int? sortOrder,
  }) => AttemptRow(
    id: id ?? this.id,
    childId: childId ?? this.childId,
    curriculum: curriculum ?? this.curriculum,
    clientAttemptId: clientAttemptId ?? this.clientAttemptId,
    unitId: unitId ?? this.unitId,
    contentVersion: contentVersion ?? this.contentVersion,
    completed: completed ?? this.completed,
    effortStars: effortStars ?? this.effortStars,
    completedAt: completedAt ?? this.completedAt,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  AttemptRow copyWithCompanion(UnitAttemptsCompanion data) {
    return AttemptRow(
      id: data.id.present ? data.id.value : this.id,
      childId: data.childId.present ? data.childId.value : this.childId,
      curriculum: data.curriculum.present
          ? data.curriculum.value
          : this.curriculum,
      clientAttemptId: data.clientAttemptId.present
          ? data.clientAttemptId.value
          : this.clientAttemptId,
      unitId: data.unitId.present ? data.unitId.value : this.unitId,
      contentVersion: data.contentVersion.present
          ? data.contentVersion.value
          : this.contentVersion,
      completed: data.completed.present ? data.completed.value : this.completed,
      effortStars: data.effortStars.present
          ? data.effortStars.value
          : this.effortStars,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttemptRow(')
          ..write('id: $id, ')
          ..write('childId: $childId, ')
          ..write('curriculum: $curriculum, ')
          ..write('clientAttemptId: $clientAttemptId, ')
          ..write('unitId: $unitId, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('completed: $completed, ')
          ..write('effortStars: $effortStars, ')
          ..write('completedAt: $completedAt, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    childId,
    curriculum,
    clientAttemptId,
    unitId,
    contentVersion,
    completed,
    effortStars,
    completedAt,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttemptRow &&
          other.id == this.id &&
          other.childId == this.childId &&
          other.curriculum == this.curriculum &&
          other.clientAttemptId == this.clientAttemptId &&
          other.unitId == this.unitId &&
          other.contentVersion == this.contentVersion &&
          other.completed == this.completed &&
          other.effortStars == this.effortStars &&
          other.completedAt == this.completedAt &&
          other.sortOrder == this.sortOrder);
}

class UnitAttemptsCompanion extends UpdateCompanion<AttemptRow> {
  final Value<String> id;
  final Value<String> childId;
  final Value<String> curriculum;
  final Value<String> clientAttemptId;
  final Value<String> unitId;
  final Value<int> contentVersion;
  final Value<bool> completed;
  final Value<int> effortStars;
  final Value<String> completedAt;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const UnitAttemptsCompanion({
    this.id = const Value.absent(),
    this.childId = const Value.absent(),
    this.curriculum = const Value.absent(),
    this.clientAttemptId = const Value.absent(),
    this.unitId = const Value.absent(),
    this.contentVersion = const Value.absent(),
    this.completed = const Value.absent(),
    this.effortStars = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UnitAttemptsCompanion.insert({
    required String id,
    required String childId,
    required String curriculum,
    required String clientAttemptId,
    required String unitId,
    required int contentVersion,
    required bool completed,
    required int effortStars,
    required String completedAt,
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       childId = Value(childId),
       curriculum = Value(curriculum),
       clientAttemptId = Value(clientAttemptId),
       unitId = Value(unitId),
       contentVersion = Value(contentVersion),
       completed = Value(completed),
       effortStars = Value(effortStars),
       completedAt = Value(completedAt),
       sortOrder = Value(sortOrder);
  static Insertable<AttemptRow> custom({
    Expression<String>? id,
    Expression<String>? childId,
    Expression<String>? curriculum,
    Expression<String>? clientAttemptId,
    Expression<String>? unitId,
    Expression<int>? contentVersion,
    Expression<bool>? completed,
    Expression<int>? effortStars,
    Expression<String>? completedAt,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (childId != null) 'child_id': childId,
      if (curriculum != null) 'curriculum': curriculum,
      if (clientAttemptId != null) 'client_attempt_id': clientAttemptId,
      if (unitId != null) 'unit_id': unitId,
      if (contentVersion != null) 'content_version': contentVersion,
      if (completed != null) 'completed': completed,
      if (effortStars != null) 'effort_stars': effortStars,
      if (completedAt != null) 'completed_at': completedAt,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UnitAttemptsCompanion copyWith({
    Value<String>? id,
    Value<String>? childId,
    Value<String>? curriculum,
    Value<String>? clientAttemptId,
    Value<String>? unitId,
    Value<int>? contentVersion,
    Value<bool>? completed,
    Value<int>? effortStars,
    Value<String>? completedAt,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return UnitAttemptsCompanion(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      curriculum: curriculum ?? this.curriculum,
      clientAttemptId: clientAttemptId ?? this.clientAttemptId,
      unitId: unitId ?? this.unitId,
      contentVersion: contentVersion ?? this.contentVersion,
      completed: completed ?? this.completed,
      effortStars: effortStars ?? this.effortStars,
      completedAt: completedAt ?? this.completedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (childId.present) {
      map['child_id'] = Variable<String>(childId.value);
    }
    if (curriculum.present) {
      map['curriculum'] = Variable<String>(curriculum.value);
    }
    if (clientAttemptId.present) {
      map['client_attempt_id'] = Variable<String>(clientAttemptId.value);
    }
    if (unitId.present) {
      map['unit_id'] = Variable<String>(unitId.value);
    }
    if (contentVersion.present) {
      map['content_version'] = Variable<int>(contentVersion.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (effortStars.present) {
      map['effort_stars'] = Variable<int>(effortStars.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<String>(completedAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnitAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('childId: $childId, ')
          ..write('curriculum: $curriculum, ')
          ..write('clientAttemptId: $clientAttemptId, ')
          ..write('unitId: $unitId, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('completed: $completed, ')
          ..write('effortStars: $effortStars, ')
          ..write('completedAt: $completedAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttemptObjectivesTable extends AttemptObjectives
    with TableInfo<$AttemptObjectivesTable, ObjectiveRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttemptObjectivesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _attemptIdMeta = const VerificationMeta(
    'attemptId',
  );
  @override
  late final GeneratedColumn<String> attemptId = GeneratedColumn<String>(
    'attempt_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES unit_attempts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _objectiveIdMeta = const VerificationMeta(
    'objectiveId',
  );
  @override
  late final GeneratedColumn<String> objectiveId = GeneratedColumn<String>(
    'objective_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [attemptId, objectiveId, outcome];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attempt_objectives';
  @override
  VerificationContext validateIntegrity(
    Insertable<ObjectiveRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('attempt_id')) {
      context.handle(
        _attemptIdMeta,
        attemptId.isAcceptableOrUnknown(data['attempt_id']!, _attemptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_attemptIdMeta);
    }
    if (data.containsKey('objective_id')) {
      context.handle(
        _objectiveIdMeta,
        objectiveId.isAcceptableOrUnknown(
          data['objective_id']!,
          _objectiveIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_objectiveIdMeta);
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {attemptId, objectiveId};
  @override
  ObjectiveRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ObjectiveRow(
      attemptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attempt_id'],
      )!,
      objectiveId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}objective_id'],
      )!,
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      )!,
    );
  }

  @override
  $AttemptObjectivesTable createAlias(String alias) {
    return $AttemptObjectivesTable(attachedDatabase, alias);
  }
}

class ObjectiveRow extends DataClass implements Insertable<ObjectiveRow> {
  final String attemptId;
  final String objectiveId;
  final String outcome;
  const ObjectiveRow({
    required this.attemptId,
    required this.objectiveId,
    required this.outcome,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['attempt_id'] = Variable<String>(attemptId);
    map['objective_id'] = Variable<String>(objectiveId);
    map['outcome'] = Variable<String>(outcome);
    return map;
  }

  AttemptObjectivesCompanion toCompanion(bool nullToAbsent) {
    return AttemptObjectivesCompanion(
      attemptId: Value(attemptId),
      objectiveId: Value(objectiveId),
      outcome: Value(outcome),
    );
  }

  factory ObjectiveRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ObjectiveRow(
      attemptId: serializer.fromJson<String>(json['attemptId']),
      objectiveId: serializer.fromJson<String>(json['objectiveId']),
      outcome: serializer.fromJson<String>(json['outcome']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'attemptId': serializer.toJson<String>(attemptId),
      'objectiveId': serializer.toJson<String>(objectiveId),
      'outcome': serializer.toJson<String>(outcome),
    };
  }

  ObjectiveRow copyWith({
    String? attemptId,
    String? objectiveId,
    String? outcome,
  }) => ObjectiveRow(
    attemptId: attemptId ?? this.attemptId,
    objectiveId: objectiveId ?? this.objectiveId,
    outcome: outcome ?? this.outcome,
  );
  ObjectiveRow copyWithCompanion(AttemptObjectivesCompanion data) {
    return ObjectiveRow(
      attemptId: data.attemptId.present ? data.attemptId.value : this.attemptId,
      objectiveId: data.objectiveId.present
          ? data.objectiveId.value
          : this.objectiveId,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ObjectiveRow(')
          ..write('attemptId: $attemptId, ')
          ..write('objectiveId: $objectiveId, ')
          ..write('outcome: $outcome')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(attemptId, objectiveId, outcome);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ObjectiveRow &&
          other.attemptId == this.attemptId &&
          other.objectiveId == this.objectiveId &&
          other.outcome == this.outcome);
}

class AttemptObjectivesCompanion extends UpdateCompanion<ObjectiveRow> {
  final Value<String> attemptId;
  final Value<String> objectiveId;
  final Value<String> outcome;
  final Value<int> rowid;
  const AttemptObjectivesCompanion({
    this.attemptId = const Value.absent(),
    this.objectiveId = const Value.absent(),
    this.outcome = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttemptObjectivesCompanion.insert({
    required String attemptId,
    required String objectiveId,
    required String outcome,
    this.rowid = const Value.absent(),
  }) : attemptId = Value(attemptId),
       objectiveId = Value(objectiveId),
       outcome = Value(outcome);
  static Insertable<ObjectiveRow> custom({
    Expression<String>? attemptId,
    Expression<String>? objectiveId,
    Expression<String>? outcome,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (attemptId != null) 'attempt_id': attemptId,
      if (objectiveId != null) 'objective_id': objectiveId,
      if (outcome != null) 'outcome': outcome,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttemptObjectivesCompanion copyWith({
    Value<String>? attemptId,
    Value<String>? objectiveId,
    Value<String>? outcome,
    Value<int>? rowid,
  }) {
    return AttemptObjectivesCompanion(
      attemptId: attemptId ?? this.attemptId,
      objectiveId: objectiveId ?? this.objectiveId,
      outcome: outcome ?? this.outcome,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (attemptId.present) {
      map['attempt_id'] = Variable<String>(attemptId.value);
    }
    if (objectiveId.present) {
      map['objective_id'] = Variable<String>(objectiveId.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttemptObjectivesCompanion(')
          ..write('attemptId: $attemptId, ')
          ..write('objectiveId: $objectiveId, ')
          ..write('outcome: $outcome, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JourneysTable extends Journeys
    with TableInfo<$JourneysTable, JourneyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JourneysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _childIdMeta = const VerificationMeta(
    'childId',
  );
  @override
  late final GeneratedColumn<String> childId = GeneratedColumn<String>(
    'child_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES children (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _curriculumMeta = const VerificationMeta(
    'curriculum',
  );
  @override
  late final GeneratedColumn<String> curriculum = GeneratedColumn<String>(
    'curriculum',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _journeyKeyMeta = const VerificationMeta(
    'journeyKey',
  );
  @override
  late final GeneratedColumn<String> journeyKey = GeneratedColumn<String>(
    'journey_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  @override
  List<GeneratedColumn> get $columns => [
    childId,
    curriculum,
    journeyKey,
    json,
    version,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journeys';
  @override
  VerificationContext validateIntegrity(
    Insertable<JourneyRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('child_id')) {
      context.handle(
        _childIdMeta,
        childId.isAcceptableOrUnknown(data['child_id']!, _childIdMeta),
      );
    } else if (isInserting) {
      context.missing(_childIdMeta);
    }
    if (data.containsKey('curriculum')) {
      context.handle(
        _curriculumMeta,
        curriculum.isAcceptableOrUnknown(data['curriculum']!, _curriculumMeta),
      );
    } else if (isInserting) {
      context.missing(_curriculumMeta);
    }
    if (data.containsKey('journey_key')) {
      context.handle(
        _journeyKeyMeta,
        journeyKey.isAcceptableOrUnknown(data['journey_key']!, _journeyKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_journeyKeyMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {childId, curriculum, journeyKey};
  @override
  JourneyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JourneyRow(
      childId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_id'],
      )!,
      curriculum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}curriculum'],
      )!,
      journeyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}journey_key'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $JourneysTable createAlias(String alias) {
    return $JourneysTable(attachedDatabase, alias);
  }
}

class JourneyRow extends DataClass implements Insertable<JourneyRow> {
  final String childId;
  final String curriculum;
  final String journeyKey;
  final String json;
  final int version;
  final DateTime updatedAt;
  const JourneyRow({
    required this.childId,
    required this.curriculum,
    required this.journeyKey,
    required this.json,
    required this.version,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['child_id'] = Variable<String>(childId);
    map['curriculum'] = Variable<String>(curriculum);
    map['journey_key'] = Variable<String>(journeyKey);
    map['json'] = Variable<String>(json);
    map['version'] = Variable<int>(version);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  JourneysCompanion toCompanion(bool nullToAbsent) {
    return JourneysCompanion(
      childId: Value(childId),
      curriculum: Value(curriculum),
      journeyKey: Value(journeyKey),
      json: Value(json),
      version: Value(version),
      updatedAt: Value(updatedAt),
    );
  }

  factory JourneyRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JourneyRow(
      childId: serializer.fromJson<String>(json['childId']),
      curriculum: serializer.fromJson<String>(json['curriculum']),
      journeyKey: serializer.fromJson<String>(json['journeyKey']),
      json: serializer.fromJson<String>(json['json']),
      version: serializer.fromJson<int>(json['version']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'childId': serializer.toJson<String>(childId),
      'curriculum': serializer.toJson<String>(curriculum),
      'journeyKey': serializer.toJson<String>(journeyKey),
      'json': serializer.toJson<String>(json),
      'version': serializer.toJson<int>(version),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  JourneyRow copyWith({
    String? childId,
    String? curriculum,
    String? journeyKey,
    String? json,
    int? version,
    DateTime? updatedAt,
  }) => JourneyRow(
    childId: childId ?? this.childId,
    curriculum: curriculum ?? this.curriculum,
    journeyKey: journeyKey ?? this.journeyKey,
    json: json ?? this.json,
    version: version ?? this.version,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  JourneyRow copyWithCompanion(JourneysCompanion data) {
    return JourneyRow(
      childId: data.childId.present ? data.childId.value : this.childId,
      curriculum: data.curriculum.present
          ? data.curriculum.value
          : this.curriculum,
      journeyKey: data.journeyKey.present
          ? data.journeyKey.value
          : this.journeyKey,
      json: data.json.present ? data.json.value : this.json,
      version: data.version.present ? data.version.value : this.version,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JourneyRow(')
          ..write('childId: $childId, ')
          ..write('curriculum: $curriculum, ')
          ..write('journeyKey: $journeyKey, ')
          ..write('json: $json, ')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(childId, curriculum, journeyKey, json, version, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JourneyRow &&
          other.childId == this.childId &&
          other.curriculum == this.curriculum &&
          other.journeyKey == this.journeyKey &&
          other.json == this.json &&
          other.version == this.version &&
          other.updatedAt == this.updatedAt);
}

class JourneysCompanion extends UpdateCompanion<JourneyRow> {
  final Value<String> childId;
  final Value<String> curriculum;
  final Value<String> journeyKey;
  final Value<String> json;
  final Value<int> version;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const JourneysCompanion({
    this.childId = const Value.absent(),
    this.curriculum = const Value.absent(),
    this.journeyKey = const Value.absent(),
    this.json = const Value.absent(),
    this.version = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JourneysCompanion.insert({
    required String childId,
    required String curriculum,
    required String journeyKey,
    required String json,
    this.version = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : childId = Value(childId),
       curriculum = Value(curriculum),
       journeyKey = Value(journeyKey),
       json = Value(json),
       updatedAt = Value(updatedAt);
  static Insertable<JourneyRow> custom({
    Expression<String>? childId,
    Expression<String>? curriculum,
    Expression<String>? journeyKey,
    Expression<String>? json,
    Expression<int>? version,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (childId != null) 'child_id': childId,
      if (curriculum != null) 'curriculum': curriculum,
      if (journeyKey != null) 'journey_key': journeyKey,
      if (json != null) 'json': json,
      if (version != null) 'version': version,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JourneysCompanion copyWith({
    Value<String>? childId,
    Value<String>? curriculum,
    Value<String>? journeyKey,
    Value<String>? json,
    Value<int>? version,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return JourneysCompanion(
      childId: childId ?? this.childId,
      curriculum: curriculum ?? this.curriculum,
      journeyKey: journeyKey ?? this.journeyKey,
      json: json ?? this.json,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (childId.present) {
      map['child_id'] = Variable<String>(childId.value);
    }
    if (curriculum.present) {
      map['curriculum'] = Variable<String>(curriculum.value);
    }
    if (journeyKey.present) {
      map['journey_key'] = Variable<String>(journeyKey.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JourneysCompanion(')
          ..write('childId: $childId, ')
          ..write('curriculum: $curriculum, ')
          ..write('journeyKey: $journeyKey, ')
          ..write('json: $json, ')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsageDailyTable extends UsageDaily
    with TableInfo<$UsageDailyTable, UsageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsageDailyTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _childIdMeta = const VerificationMeta(
    'childId',
  );
  @override
  late final GeneratedColumn<String> childId = GeneratedColumn<String>(
    'child_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES children (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _secondsMeta = const VerificationMeta(
    'seconds',
  );
  @override
  late final GeneratedColumn<int> seconds = GeneratedColumn<int>(
    'seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [childId, deviceId, day, seconds];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'usage_daily';
  @override
  VerificationContext validateIntegrity(
    Insertable<UsageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('child_id')) {
      context.handle(
        _childIdMeta,
        childId.isAcceptableOrUnknown(data['child_id']!, _childIdMeta),
      );
    } else if (isInserting) {
      context.missing(_childIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('seconds')) {
      context.handle(
        _secondsMeta,
        seconds.isAcceptableOrUnknown(data['seconds']!, _secondsMeta),
      );
    } else if (isInserting) {
      context.missing(_secondsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {childId, deviceId, day};
  @override
  UsageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UsageRow(
      childId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      seconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seconds'],
      )!,
    );
  }

  @override
  $UsageDailyTable createAlias(String alias) {
    return $UsageDailyTable(attachedDatabase, alias);
  }
}

class UsageRow extends DataClass implements Insertable<UsageRow> {
  final String childId;
  final String deviceId;

  /// `YYYY-MM-DD` in the device's local calendar.
  final String day;
  final int seconds;
  const UsageRow({
    required this.childId,
    required this.deviceId,
    required this.day,
    required this.seconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['child_id'] = Variable<String>(childId);
    map['device_id'] = Variable<String>(deviceId);
    map['day'] = Variable<String>(day);
    map['seconds'] = Variable<int>(seconds);
    return map;
  }

  UsageDailyCompanion toCompanion(bool nullToAbsent) {
    return UsageDailyCompanion(
      childId: Value(childId),
      deviceId: Value(deviceId),
      day: Value(day),
      seconds: Value(seconds),
    );
  }

  factory UsageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UsageRow(
      childId: serializer.fromJson<String>(json['childId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      day: serializer.fromJson<String>(json['day']),
      seconds: serializer.fromJson<int>(json['seconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'childId': serializer.toJson<String>(childId),
      'deviceId': serializer.toJson<String>(deviceId),
      'day': serializer.toJson<String>(day),
      'seconds': serializer.toJson<int>(seconds),
    };
  }

  UsageRow copyWith({
    String? childId,
    String? deviceId,
    String? day,
    int? seconds,
  }) => UsageRow(
    childId: childId ?? this.childId,
    deviceId: deviceId ?? this.deviceId,
    day: day ?? this.day,
    seconds: seconds ?? this.seconds,
  );
  UsageRow copyWithCompanion(UsageDailyCompanion data) {
    return UsageRow(
      childId: data.childId.present ? data.childId.value : this.childId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      day: data.day.present ? data.day.value : this.day,
      seconds: data.seconds.present ? data.seconds.value : this.seconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UsageRow(')
          ..write('childId: $childId, ')
          ..write('deviceId: $deviceId, ')
          ..write('day: $day, ')
          ..write('seconds: $seconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(childId, deviceId, day, seconds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UsageRow &&
          other.childId == this.childId &&
          other.deviceId == this.deviceId &&
          other.day == this.day &&
          other.seconds == this.seconds);
}

class UsageDailyCompanion extends UpdateCompanion<UsageRow> {
  final Value<String> childId;
  final Value<String> deviceId;
  final Value<String> day;
  final Value<int> seconds;
  final Value<int> rowid;
  const UsageDailyCompanion({
    this.childId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.day = const Value.absent(),
    this.seconds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsageDailyCompanion.insert({
    required String childId,
    required String deviceId,
    required String day,
    required int seconds,
    this.rowid = const Value.absent(),
  }) : childId = Value(childId),
       deviceId = Value(deviceId),
       day = Value(day),
       seconds = Value(seconds);
  static Insertable<UsageRow> custom({
    Expression<String>? childId,
    Expression<String>? deviceId,
    Expression<String>? day,
    Expression<int>? seconds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (childId != null) 'child_id': childId,
      if (deviceId != null) 'device_id': deviceId,
      if (day != null) 'day': day,
      if (seconds != null) 'seconds': seconds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsageDailyCompanion copyWith({
    Value<String>? childId,
    Value<String>? deviceId,
    Value<String>? day,
    Value<int>? seconds,
    Value<int>? rowid,
  }) {
    return UsageDailyCompanion(
      childId: childId ?? this.childId,
      deviceId: deviceId ?? this.deviceId,
      day: day ?? this.day,
      seconds: seconds ?? this.seconds,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (childId.present) {
      map['child_id'] = Variable<String>(childId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (seconds.present) {
      map['seconds'] = Variable<int>(seconds.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsageDailyCompanion(')
          ..write('childId: $childId, ')
          ..write('deviceId: $deviceId, ')
          ..write('day: $day, ')
          ..write('seconds: $seconds, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OtherSubjectsTable extends OtherSubjects
    with TableInfo<$OtherSubjectsTable, SubjectRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OtherSubjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _childIdMeta = const VerificationMeta(
    'childId',
  );
  @override
  late final GeneratedColumn<String> childId = GeneratedColumn<String>(
    'child_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES children (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [childId, subject, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'other_subjects';
  @override
  VerificationContext validateIntegrity(
    Insertable<SubjectRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('child_id')) {
      context.handle(
        _childIdMeta,
        childId.isAcceptableOrUnknown(data['child_id']!, _childIdMeta),
      );
    } else if (isInserting) {
      context.missing(_childIdMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {childId, subject};
  @override
  SubjectRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubjectRow(
      childId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_id'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
    );
  }

  @override
  $OtherSubjectsTable createAlias(String alias) {
    return $OtherSubjectsTable(attachedDatabase, alias);
  }
}

class SubjectRow extends DataClass implements Insertable<SubjectRow> {
  final String childId;
  final String subject;
  final String json;
  const SubjectRow({
    required this.childId,
    required this.subject,
    required this.json,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['child_id'] = Variable<String>(childId);
    map['subject'] = Variable<String>(subject);
    map['json'] = Variable<String>(json);
    return map;
  }

  OtherSubjectsCompanion toCompanion(bool nullToAbsent) {
    return OtherSubjectsCompanion(
      childId: Value(childId),
      subject: Value(subject),
      json: Value(json),
    );
  }

  factory SubjectRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubjectRow(
      childId: serializer.fromJson<String>(json['childId']),
      subject: serializer.fromJson<String>(json['subject']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'childId': serializer.toJson<String>(childId),
      'subject': serializer.toJson<String>(subject),
      'json': serializer.toJson<String>(json),
    };
  }

  SubjectRow copyWith({String? childId, String? subject, String? json}) =>
      SubjectRow(
        childId: childId ?? this.childId,
        subject: subject ?? this.subject,
        json: json ?? this.json,
      );
  SubjectRow copyWithCompanion(OtherSubjectsCompanion data) {
    return SubjectRow(
      childId: data.childId.present ? data.childId.value : this.childId,
      subject: data.subject.present ? data.subject.value : this.subject,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubjectRow(')
          ..write('childId: $childId, ')
          ..write('subject: $subject, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(childId, subject, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubjectRow &&
          other.childId == this.childId &&
          other.subject == this.subject &&
          other.json == this.json);
}

class OtherSubjectsCompanion extends UpdateCompanion<SubjectRow> {
  final Value<String> childId;
  final Value<String> subject;
  final Value<String> json;
  final Value<int> rowid;
  const OtherSubjectsCompanion({
    this.childId = const Value.absent(),
    this.subject = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OtherSubjectsCompanion.insert({
    required String childId,
    required String subject,
    required String json,
    this.rowid = const Value.absent(),
  }) : childId = Value(childId),
       subject = Value(subject),
       json = Value(json);
  static Insertable<SubjectRow> custom({
    Expression<String>? childId,
    Expression<String>? subject,
    Expression<String>? json,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (childId != null) 'child_id': childId,
      if (subject != null) 'subject': subject,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OtherSubjectsCompanion copyWith({
    Value<String>? childId,
    Value<String>? subject,
    Value<String>? json,
    Value<int>? rowid,
  }) {
    return OtherSubjectsCompanion(
      childId: childId ?? this.childId,
      subject: subject ?? this.subject,
      json: json ?? this.json,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (childId.present) {
      map['child_id'] = Variable<String>(childId.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OtherSubjectsCompanion(')
          ..write('childId: $childId, ')
          ..write('subject: $subject, ')
          ..write('json: $json, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuarantinedRecordsTable extends QuarantinedRecords
    with TableInfo<$QuarantinedRecordsTable, QuarantineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuarantinedRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _legacyIdMeta = const VerificationMeta(
    'legacyId',
  );
  @override
  late final GeneratedColumn<String> legacyId = GeneratedColumn<String>(
    'legacy_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawJsonMeta = const VerificationMeta(
    'rawJson',
  );
  @override
  late final GeneratedColumn<String> rawJson = GeneratedColumn<String>(
    'raw_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foundAtMeta = const VerificationMeta(
    'foundAt',
  );
  @override
  late final GeneratedColumn<DateTime> foundAt = GeneratedColumn<DateTime>(
    'found_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    source,
    legacyId,
    rawJson,
    foundAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quarantined_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuarantineRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('legacy_id')) {
      context.handle(
        _legacyIdMeta,
        legacyId.isAcceptableOrUnknown(data['legacy_id']!, _legacyIdMeta),
      );
    }
    if (data.containsKey('raw_json')) {
      context.handle(
        _rawJsonMeta,
        rawJson.isAcceptableOrUnknown(data['raw_json']!, _rawJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_rawJsonMeta);
    }
    if (data.containsKey('found_at')) {
      context.handle(
        _foundAtMeta,
        foundAt.isAcceptableOrUnknown(data['found_at']!, _foundAtMeta),
      );
    } else if (isInserting) {
      context.missing(_foundAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuarantineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuarantineRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      legacyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legacy_id'],
      ),
      rawJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_json'],
      )!,
      foundAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}found_at'],
      )!,
    );
  }

  @override
  $QuarantinedRecordsTable createAlias(String alias) {
    return $QuarantinedRecordsTable(attachedDatabase, alias);
  }
}

class QuarantineRow extends DataClass implements Insertable<QuarantineRow> {
  final int id;

  /// `child` for a damaged child record; `hive:<key>` for raw Hive copies.
  final String source;
  final String? legacyId;
  final String rawJson;
  final DateTime foundAt;
  const QuarantineRow({
    required this.id,
    required this.source,
    this.legacyId,
    required this.rawJson,
    required this.foundAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || legacyId != null) {
      map['legacy_id'] = Variable<String>(legacyId);
    }
    map['raw_json'] = Variable<String>(rawJson);
    map['found_at'] = Variable<DateTime>(foundAt);
    return map;
  }

  QuarantinedRecordsCompanion toCompanion(bool nullToAbsent) {
    return QuarantinedRecordsCompanion(
      id: Value(id),
      source: Value(source),
      legacyId: legacyId == null && nullToAbsent
          ? const Value.absent()
          : Value(legacyId),
      rawJson: Value(rawJson),
      foundAt: Value(foundAt),
    );
  }

  factory QuarantineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuarantineRow(
      id: serializer.fromJson<int>(json['id']),
      source: serializer.fromJson<String>(json['source']),
      legacyId: serializer.fromJson<String?>(json['legacyId']),
      rawJson: serializer.fromJson<String>(json['rawJson']),
      foundAt: serializer.fromJson<DateTime>(json['foundAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'source': serializer.toJson<String>(source),
      'legacyId': serializer.toJson<String?>(legacyId),
      'rawJson': serializer.toJson<String>(rawJson),
      'foundAt': serializer.toJson<DateTime>(foundAt),
    };
  }

  QuarantineRow copyWith({
    int? id,
    String? source,
    Value<String?> legacyId = const Value.absent(),
    String? rawJson,
    DateTime? foundAt,
  }) => QuarantineRow(
    id: id ?? this.id,
    source: source ?? this.source,
    legacyId: legacyId.present ? legacyId.value : this.legacyId,
    rawJson: rawJson ?? this.rawJson,
    foundAt: foundAt ?? this.foundAt,
  );
  QuarantineRow copyWithCompanion(QuarantinedRecordsCompanion data) {
    return QuarantineRow(
      id: data.id.present ? data.id.value : this.id,
      source: data.source.present ? data.source.value : this.source,
      legacyId: data.legacyId.present ? data.legacyId.value : this.legacyId,
      rawJson: data.rawJson.present ? data.rawJson.value : this.rawJson,
      foundAt: data.foundAt.present ? data.foundAt.value : this.foundAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuarantineRow(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('legacyId: $legacyId, ')
          ..write('rawJson: $rawJson, ')
          ..write('foundAt: $foundAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, source, legacyId, rawJson, foundAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuarantineRow &&
          other.id == this.id &&
          other.source == this.source &&
          other.legacyId == this.legacyId &&
          other.rawJson == this.rawJson &&
          other.foundAt == this.foundAt);
}

class QuarantinedRecordsCompanion extends UpdateCompanion<QuarantineRow> {
  final Value<int> id;
  final Value<String> source;
  final Value<String?> legacyId;
  final Value<String> rawJson;
  final Value<DateTime> foundAt;
  const QuarantinedRecordsCompanion({
    this.id = const Value.absent(),
    this.source = const Value.absent(),
    this.legacyId = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.foundAt = const Value.absent(),
  });
  QuarantinedRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String source,
    this.legacyId = const Value.absent(),
    required String rawJson,
    required DateTime foundAt,
  }) : source = Value(source),
       rawJson = Value(rawJson),
       foundAt = Value(foundAt);
  static Insertable<QuarantineRow> custom({
    Expression<int>? id,
    Expression<String>? source,
    Expression<String>? legacyId,
    Expression<String>? rawJson,
    Expression<DateTime>? foundAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (source != null) 'source': source,
      if (legacyId != null) 'legacy_id': legacyId,
      if (rawJson != null) 'raw_json': rawJson,
      if (foundAt != null) 'found_at': foundAt,
    });
  }

  QuarantinedRecordsCompanion copyWith({
    Value<int>? id,
    Value<String>? source,
    Value<String?>? legacyId,
    Value<String>? rawJson,
    Value<DateTime>? foundAt,
  }) {
    return QuarantinedRecordsCompanion(
      id: id ?? this.id,
      source: source ?? this.source,
      legacyId: legacyId ?? this.legacyId,
      rawJson: rawJson ?? this.rawJson,
      foundAt: foundAt ?? this.foundAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (legacyId.present) {
      map['legacy_id'] = Variable<String>(legacyId.value);
    }
    if (rawJson.present) {
      map['raw_json'] = Variable<String>(rawJson.value);
    }
    if (foundAt.present) {
      map['found_at'] = Variable<DateTime>(foundAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuarantinedRecordsCompanion(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('legacyId: $legacyId, ')
          ..write('rawJson: $rawJson, ')
          ..write('foundAt: $foundAt')
          ..write(')'))
        .toString();
  }
}

class $AppMetaTable extends AppMeta with TableInfo<$AppMetaTable, MetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  MetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetaRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppMetaTable createAlias(String alias) {
    return $AppMetaTable(attachedDatabase, alias);
  }
}

class MetaRow extends DataClass implements Insertable<MetaRow> {
  final String key;
  final String value;
  const MetaRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppMetaCompanion toCompanion(bool nullToAbsent) {
    return AppMetaCompanion(key: Value(key), value: Value(value));
  }

  factory MetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetaRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  MetaRow copyWith({String? key, String? value}) =>
      MetaRow(key: key ?? this.key, value: value ?? this.value);
  MetaRow copyWithCompanion(AppMetaCompanion data) {
    return MetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetaRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetaRow && other.key == this.key && other.value == this.value);
}

class AppMetaCompanion extends UpdateCompanion<MetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<MetaRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _mutationIdMeta = const VerificationMeta(
    'mutationId',
  );
  @override
  late final GeneratedColumn<String> mutationId = GeneratedColumn<String>(
    'mutation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opMeta = const VerificationMeta('op');
  @override
  late final GeneratedColumn<String> op = GeneratedColumn<String>(
    'op',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseVersionMeta = const VerificationMeta(
    'baseVersion',
  );
  @override
  late final GeneratedColumn<int> baseVersion = GeneratedColumn<int>(
    'base_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _triesMeta = const VerificationMeta('tries');
  @override
  late final GeneratedColumn<int> tries = GeneratedColumn<int>(
    'tries',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
  @override
  List<GeneratedColumn> get $columns => [
    seq,
    mutationId,
    entity,
    op,
    entityId,
    baseVersion,
    payloadJson,
    status,
    tries,
    lastError,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('mutation_id')) {
      context.handle(
        _mutationIdMeta,
        mutationId.isAcceptableOrUnknown(data['mutation_id']!, _mutationIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mutationIdMeta);
    }
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('op')) {
      context.handle(_opMeta, op.isAcceptableOrUnknown(data['op']!, _opMeta));
    } else if (isInserting) {
      context.missing(_opMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('base_version')) {
      context.handle(
        _baseVersionMeta,
        baseVersion.isAcceptableOrUnknown(
          data['base_version']!,
          _baseVersionMeta,
        ),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('tries')) {
      context.handle(
        _triesMeta,
        tries.isAcceptableOrUnknown(data['tries']!, _triesMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  OutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRow(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      mutationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mutation_id'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      op: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      baseVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_version'],
      ),
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      tries: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tries'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class OutboxRow extends DataClass implements Insertable<OutboxRow> {
  final int seq;
  final String mutationId;
  final String entity;
  final String op;
  final String entityId;
  final int? baseVersion;
  final String payloadJson;
  final String status;
  final int tries;
  final String? lastError;
  final DateTime createdAt;
  const OutboxRow({
    required this.seq,
    required this.mutationId,
    required this.entity,
    required this.op,
    required this.entityId,
    this.baseVersion,
    required this.payloadJson,
    required this.status,
    required this.tries,
    this.lastError,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['mutation_id'] = Variable<String>(mutationId);
    map['entity'] = Variable<String>(entity);
    map['op'] = Variable<String>(op);
    map['entity_id'] = Variable<String>(entityId);
    if (!nullToAbsent || baseVersion != null) {
      map['base_version'] = Variable<int>(baseVersion);
    }
    map['payload_json'] = Variable<String>(payloadJson);
    map['status'] = Variable<String>(status);
    map['tries'] = Variable<int>(tries);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      seq: Value(seq),
      mutationId: Value(mutationId),
      entity: Value(entity),
      op: Value(op),
      entityId: Value(entityId),
      baseVersion: baseVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(baseVersion),
      payloadJson: Value(payloadJson),
      status: Value(status),
      tries: Value(tries),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
    );
  }

  factory OutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRow(
      seq: serializer.fromJson<int>(json['seq']),
      mutationId: serializer.fromJson<String>(json['mutationId']),
      entity: serializer.fromJson<String>(json['entity']),
      op: serializer.fromJson<String>(json['op']),
      entityId: serializer.fromJson<String>(json['entityId']),
      baseVersion: serializer.fromJson<int?>(json['baseVersion']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      status: serializer.fromJson<String>(json['status']),
      tries: serializer.fromJson<int>(json['tries']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'mutationId': serializer.toJson<String>(mutationId),
      'entity': serializer.toJson<String>(entity),
      'op': serializer.toJson<String>(op),
      'entityId': serializer.toJson<String>(entityId),
      'baseVersion': serializer.toJson<int?>(baseVersion),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'status': serializer.toJson<String>(status),
      'tries': serializer.toJson<int>(tries),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OutboxRow copyWith({
    int? seq,
    String? mutationId,
    String? entity,
    String? op,
    String? entityId,
    Value<int?> baseVersion = const Value.absent(),
    String? payloadJson,
    String? status,
    int? tries,
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
  }) => OutboxRow(
    seq: seq ?? this.seq,
    mutationId: mutationId ?? this.mutationId,
    entity: entity ?? this.entity,
    op: op ?? this.op,
    entityId: entityId ?? this.entityId,
    baseVersion: baseVersion.present ? baseVersion.value : this.baseVersion,
    payloadJson: payloadJson ?? this.payloadJson,
    status: status ?? this.status,
    tries: tries ?? this.tries,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
  );
  OutboxRow copyWithCompanion(OutboxCompanion data) {
    return OutboxRow(
      seq: data.seq.present ? data.seq.value : this.seq,
      mutationId: data.mutationId.present
          ? data.mutationId.value
          : this.mutationId,
      entity: data.entity.present ? data.entity.value : this.entity,
      op: data.op.present ? data.op.value : this.op,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      baseVersion: data.baseVersion.present
          ? data.baseVersion.value
          : this.baseVersion,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      status: data.status.present ? data.status.value : this.status,
      tries: data.tries.present ? data.tries.value : this.tries,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRow(')
          ..write('seq: $seq, ')
          ..write('mutationId: $mutationId, ')
          ..write('entity: $entity, ')
          ..write('op: $op, ')
          ..write('entityId: $entityId, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('tries: $tries, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    seq,
    mutationId,
    entity,
    op,
    entityId,
    baseVersion,
    payloadJson,
    status,
    tries,
    lastError,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRow &&
          other.seq == this.seq &&
          other.mutationId == this.mutationId &&
          other.entity == this.entity &&
          other.op == this.op &&
          other.entityId == this.entityId &&
          other.baseVersion == this.baseVersion &&
          other.payloadJson == this.payloadJson &&
          other.status == this.status &&
          other.tries == this.tries &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt);
}

class OutboxCompanion extends UpdateCompanion<OutboxRow> {
  final Value<int> seq;
  final Value<String> mutationId;
  final Value<String> entity;
  final Value<String> op;
  final Value<String> entityId;
  final Value<int?> baseVersion;
  final Value<String> payloadJson;
  final Value<String> status;
  final Value<int> tries;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  const OutboxCompanion({
    this.seq = const Value.absent(),
    this.mutationId = const Value.absent(),
    this.entity = const Value.absent(),
    this.op = const Value.absent(),
    this.entityId = const Value.absent(),
    this.baseVersion = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.status = const Value.absent(),
    this.tries = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  OutboxCompanion.insert({
    this.seq = const Value.absent(),
    required String mutationId,
    required String entity,
    required String op,
    required String entityId,
    this.baseVersion = const Value.absent(),
    required String payloadJson,
    this.status = const Value.absent(),
    this.tries = const Value.absent(),
    this.lastError = const Value.absent(),
    required DateTime createdAt,
  }) : mutationId = Value(mutationId),
       entity = Value(entity),
       op = Value(op),
       entityId = Value(entityId),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt);
  static Insertable<OutboxRow> custom({
    Expression<int>? seq,
    Expression<String>? mutationId,
    Expression<String>? entity,
    Expression<String>? op,
    Expression<String>? entityId,
    Expression<int>? baseVersion,
    Expression<String>? payloadJson,
    Expression<String>? status,
    Expression<int>? tries,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (mutationId != null) 'mutation_id': mutationId,
      if (entity != null) 'entity': entity,
      if (op != null) 'op': op,
      if (entityId != null) 'entity_id': entityId,
      if (baseVersion != null) 'base_version': baseVersion,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (status != null) 'status': status,
      if (tries != null) 'tries': tries,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  OutboxCompanion copyWith({
    Value<int>? seq,
    Value<String>? mutationId,
    Value<String>? entity,
    Value<String>? op,
    Value<String>? entityId,
    Value<int?>? baseVersion,
    Value<String>? payloadJson,
    Value<String>? status,
    Value<int>? tries,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
  }) {
    return OutboxCompanion(
      seq: seq ?? this.seq,
      mutationId: mutationId ?? this.mutationId,
      entity: entity ?? this.entity,
      op: op ?? this.op,
      entityId: entityId ?? this.entityId,
      baseVersion: baseVersion ?? this.baseVersion,
      payloadJson: payloadJson ?? this.payloadJson,
      status: status ?? this.status,
      tries: tries ?? this.tries,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (mutationId.present) {
      map['mutation_id'] = Variable<String>(mutationId.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (op.present) {
      map['op'] = Variable<String>(op.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (baseVersion.present) {
      map['base_version'] = Variable<int>(baseVersion.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (tries.present) {
      map['tries'] = Variable<int>(tries.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('seq: $seq, ')
          ..write('mutationId: $mutationId, ')
          ..write('entity: $entity, ')
          ..write('op: $op, ')
          ..write('entityId: $entityId, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('tries: $tries, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ChildrenTable children = $ChildrenTable(this);
  late final $ChildPhotosTable childPhotos = $ChildPhotosTable(this);
  late final $ChildSettingsTable childSettings = $ChildSettingsTable(this);
  late final $UnitAttemptsTable unitAttempts = $UnitAttemptsTable(this);
  late final $AttemptObjectivesTable attemptObjectives =
      $AttemptObjectivesTable(this);
  late final $JourneysTable journeys = $JourneysTable(this);
  late final $UsageDailyTable usageDaily = $UsageDailyTable(this);
  late final $OtherSubjectsTable otherSubjects = $OtherSubjectsTable(this);
  late final $QuarantinedRecordsTable quarantinedRecords =
      $QuarantinedRecordsTable(this);
  late final $AppMetaTable appMeta = $AppMetaTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    children,
    childPhotos,
    childSettings,
    unitAttempts,
    attemptObjectives,
    journeys,
    usageDaily,
    otherSubjects,
    quarantinedRecords,
    appMeta,
    outbox,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'children',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('child_photos', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'children',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('child_settings', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'children',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('unit_attempts', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'unit_attempts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('attempt_objectives', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'children',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('journeys', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'children',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('usage_daily', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'children',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('other_subjects', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ChildrenTableCreateCompanionBuilder = ChildrenCompanion Function({
  required String id,
  Value<String?> legacyId,
  required bool hasProfile,
  Value<String> displayName,
  Value<String> gender,
  Value<int> avatar,
  Value<String> palette,
  Value<bool> pendingPhoto,
  required int sortOrder,
  Value<int> version,
  Value<String> syncStatus,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ChildrenTableUpdateCompanionBuilder = ChildrenCompanion Function({
  Value<String> id,
  Value<String?> legacyId,
  Value<bool> hasProfile,
  Value<String> displayName,
  Value<String> gender,
  Value<int> avatar,
  Value<String> palette,
  Value<bool> pendingPhoto,
  Value<int> sortOrder,
  Value<int> version,
  Value<String> syncStatus,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$ChildrenTableReferences
    extends BaseReferences<_$AppDatabase, $ChildrenTable, ChildRow> {
  $$ChildrenTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ChildPhotosTable, List<ChildPhotoRow>>
  _childPhotosRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.childPhotos,
    aliasName: 'children__id__child_photos__child_id',
  );

  $$ChildPhotosTableProcessedTableManager get childPhotosRefs {
    final manager = $$ChildPhotosTableTableManager(
      $_db,
      $_db.childPhotos,
    ).filter((f) => f.childId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_childPhotosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ChildSettingsTable, List<ChildSettingsRow>>
  _childSettingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.childSettings,
    aliasName: 'children__id__child_settings__child_id',
  );

  $$ChildSettingsTableProcessedTableManager get childSettingsRefs {
    final manager = $$ChildSettingsTableTableManager(
      $_db,
      $_db.childSettings,
    ).filter((f) => f.childId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_childSettingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$UnitAttemptsTable, List<AttemptRow>>
  _unitAttemptsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.unitAttempts,
    aliasName: 'children__id__unit_attempts__child_id',
  );

  $$UnitAttemptsTableProcessedTableManager get unitAttemptsRefs {
    final manager = $$UnitAttemptsTableTableManager(
      $_db,
      $_db.unitAttempts,
    ).filter((f) => f.childId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_unitAttemptsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$JourneysTable, List<JourneyRow>>
  _journeysRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.journeys,
    aliasName: 'children__id__journeys__child_id',
  );

  $$JourneysTableProcessedTableManager get journeysRefs {
    final manager = $$JourneysTableTableManager(
      $_db,
      $_db.journeys,
    ).filter((f) => f.childId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_journeysRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$UsageDailyTable, List<UsageRow>>
  _usageDailyRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.usageDaily,
    aliasName: 'children__id__usage_daily__child_id',
  );

  $$UsageDailyTableProcessedTableManager get usageDailyRefs {
    final manager = $$UsageDailyTableTableManager(
      $_db,
      $_db.usageDaily,
    ).filter((f) => f.childId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_usageDailyRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$OtherSubjectsTable, List<SubjectRow>>
  _otherSubjectsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.otherSubjects,
    aliasName: 'children__id__other_subjects__child_id',
  );

  $$OtherSubjectsTableProcessedTableManager get otherSubjectsRefs {
    final manager = $$OtherSubjectsTableTableManager(
      $_db,
      $_db.otherSubjects,
    ).filter((f) => f.childId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_otherSubjectsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChildrenTableFilterComposer
    extends Composer<_$AppDatabase, $ChildrenTable> {
  $$ChildrenTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get legacyId => $composableBuilder(
    column: $table.legacyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasProfile => $composableBuilder(
    column: $table.hasProfile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get palette => $composableBuilder(
    column: $table.palette,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingPhoto => $composableBuilder(
    column: $table.pendingPhoto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> childPhotosRefs(
    Expression<bool> Function($$ChildPhotosTableFilterComposer f) f,
  ) {
    final $$ChildPhotosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.childPhotos,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildPhotosTableFilterComposer(
            $db: $db,
            $table: $db.childPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> childSettingsRefs(
    Expression<bool> Function($$ChildSettingsTableFilterComposer f) f,
  ) {
    final $$ChildSettingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.childSettings,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildSettingsTableFilterComposer(
            $db: $db,
            $table: $db.childSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> unitAttemptsRefs(
    Expression<bool> Function($$UnitAttemptsTableFilterComposer f) f,
  ) {
    final $$UnitAttemptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.unitAttempts,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UnitAttemptsTableFilterComposer(
            $db: $db,
            $table: $db.unitAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> journeysRefs(
    Expression<bool> Function($$JourneysTableFilterComposer f) f,
  ) {
    final $$JourneysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.journeys,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JourneysTableFilterComposer(
            $db: $db,
            $table: $db.journeys,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> usageDailyRefs(
    Expression<bool> Function($$UsageDailyTableFilterComposer f) f,
  ) {
    final $$UsageDailyTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.usageDaily,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsageDailyTableFilterComposer(
            $db: $db,
            $table: $db.usageDaily,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> otherSubjectsRefs(
    Expression<bool> Function($$OtherSubjectsTableFilterComposer f) f,
  ) {
    final $$OtherSubjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.otherSubjects,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OtherSubjectsTableFilterComposer(
            $db: $db,
            $table: $db.otherSubjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChildrenTableOrderingComposer
    extends Composer<_$AppDatabase, $ChildrenTable> {
  $$ChildrenTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get legacyId => $composableBuilder(
    column: $table.legacyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasProfile => $composableBuilder(
    column: $table.hasProfile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get palette => $composableBuilder(
    column: $table.palette,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingPhoto => $composableBuilder(
    column: $table.pendingPhoto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChildrenTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChildrenTable> {
  $$ChildrenTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get legacyId =>
      $composableBuilder(column: $table.legacyId, builder: (column) => column);

  GeneratedColumn<bool> get hasProfile => $composableBuilder(
    column: $table.hasProfile,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<int> get avatar =>
      $composableBuilder(column: $table.avatar, builder: (column) => column);

  GeneratedColumn<String> get palette =>
      $composableBuilder(column: $table.palette, builder: (column) => column);

  GeneratedColumn<bool> get pendingPhoto => $composableBuilder(
    column: $table.pendingPhoto,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> childPhotosRefs<T extends Object>(
    Expression<T> Function($$ChildPhotosTableAnnotationComposer a) f,
  ) {
    final $$ChildPhotosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.childPhotos,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildPhotosTableAnnotationComposer(
            $db: $db,
            $table: $db.childPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> childSettingsRefs<T extends Object>(
    Expression<T> Function($$ChildSettingsTableAnnotationComposer a) f,
  ) {
    final $$ChildSettingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.childSettings,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildSettingsTableAnnotationComposer(
            $db: $db,
            $table: $db.childSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> unitAttemptsRefs<T extends Object>(
    Expression<T> Function($$UnitAttemptsTableAnnotationComposer a) f,
  ) {
    final $$UnitAttemptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.unitAttempts,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UnitAttemptsTableAnnotationComposer(
            $db: $db,
            $table: $db.unitAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> journeysRefs<T extends Object>(
    Expression<T> Function($$JourneysTableAnnotationComposer a) f,
  ) {
    final $$JourneysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.journeys,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JourneysTableAnnotationComposer(
            $db: $db,
            $table: $db.journeys,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> usageDailyRefs<T extends Object>(
    Expression<T> Function($$UsageDailyTableAnnotationComposer a) f,
  ) {
    final $$UsageDailyTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.usageDaily,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsageDailyTableAnnotationComposer(
            $db: $db,
            $table: $db.usageDaily,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> otherSubjectsRefs<T extends Object>(
    Expression<T> Function($$OtherSubjectsTableAnnotationComposer a) f,
  ) {
    final $$OtherSubjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.otherSubjects,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OtherSubjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.otherSubjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChildrenTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChildrenTable,
          ChildRow,
          $$ChildrenTableFilterComposer,
          $$ChildrenTableOrderingComposer,
          $$ChildrenTableAnnotationComposer,
          $$ChildrenTableCreateCompanionBuilder,
          $$ChildrenTableUpdateCompanionBuilder,
          (ChildRow, $$ChildrenTableReferences),
          ChildRow,
          PrefetchHooks Function({
            bool childPhotosRefs,
            bool childSettingsRefs,
            bool unitAttemptsRefs,
            bool journeysRefs,
            bool usageDailyRefs,
            bool otherSubjectsRefs,
          })
        > {
  $$ChildrenTableTableManager(_$AppDatabase db, $ChildrenTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChildrenTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChildrenTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChildrenTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> legacyId = const Value.absent(),
                Value<bool> hasProfile = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> gender = const Value.absent(),
                Value<int> avatar = const Value.absent(),
                Value<String> palette = const Value.absent(),
                Value<bool> pendingPhoto = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChildrenCompanion(
                id: id,
                legacyId: legacyId,
                hasProfile: hasProfile,
                displayName: displayName,
                gender: gender,
                avatar: avatar,
                palette: palette,
                pendingPhoto: pendingPhoto,
                sortOrder: sortOrder,
                version: version,
                syncStatus: syncStatus,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> legacyId = const Value.absent(),
                required bool hasProfile,
                Value<String> displayName = const Value.absent(),
                Value<String> gender = const Value.absent(),
                Value<int> avatar = const Value.absent(),
                Value<String> palette = const Value.absent(),
                Value<bool> pendingPhoto = const Value.absent(),
                required int sortOrder,
                Value<int> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ChildrenCompanion.insert(
                id: id,
                legacyId: legacyId,
                hasProfile: hasProfile,
                displayName: displayName,
                gender: gender,
                avatar: avatar,
                palette: palette,
                pendingPhoto: pendingPhoto,
                sortOrder: sortOrder,
                version: version,
                syncStatus: syncStatus,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChildrenTable, ChildRow>(table),
                  $$ChildrenTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                childPhotosRefs = false,
                childSettingsRefs = false,
                unitAttemptsRefs = false,
                journeysRefs = false,
                usageDailyRefs = false,
                otherSubjectsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (childPhotosRefs) db.childPhotos,
                    if (childSettingsRefs) db.childSettings,
                    if (unitAttemptsRefs) db.unitAttempts,
                    if (journeysRefs) db.journeys,
                    if (usageDailyRefs) db.usageDaily,
                    if (otherSubjectsRefs) db.otherSubjects,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (childPhotosRefs)
                        await $_getPrefetchedData<
                          ChildRow,
                          $ChildrenTable,
                          ChildPhotoRow
                        >(
                          currentTable: table,
                          referencedTable: $$ChildrenTableReferences
                              ._childPhotosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChildrenTableReferences(
                                db,
                                table,
                                p0,
                              ).childPhotosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.childId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (childSettingsRefs)
                        await $_getPrefetchedData<
                          ChildRow,
                          $ChildrenTable,
                          ChildSettingsRow
                        >(
                          currentTable: table,
                          referencedTable: $$ChildrenTableReferences
                              ._childSettingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChildrenTableReferences(
                                db,
                                table,
                                p0,
                              ).childSettingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.childId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (unitAttemptsRefs)
                        await $_getPrefetchedData<
                          ChildRow,
                          $ChildrenTable,
                          AttemptRow
                        >(
                          currentTable: table,
                          referencedTable: $$ChildrenTableReferences
                              ._unitAttemptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChildrenTableReferences(
                                db,
                                table,
                                p0,
                              ).unitAttemptsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.childId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (journeysRefs)
                        await $_getPrefetchedData<
                          ChildRow,
                          $ChildrenTable,
                          JourneyRow
                        >(
                          currentTable: table,
                          referencedTable: $$ChildrenTableReferences
                              ._journeysRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChildrenTableReferences(
                                db,
                                table,
                                p0,
                              ).journeysRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.childId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (usageDailyRefs)
                        await $_getPrefetchedData<
                          ChildRow,
                          $ChildrenTable,
                          UsageRow
                        >(
                          currentTable: table,
                          referencedTable: $$ChildrenTableReferences
                              ._usageDailyRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChildrenTableReferences(
                                db,
                                table,
                                p0,
                              ).usageDailyRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.childId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (otherSubjectsRefs)
                        await $_getPrefetchedData<
                          ChildRow,
                          $ChildrenTable,
                          SubjectRow
                        >(
                          currentTable: table,
                          referencedTable: $$ChildrenTableReferences
                              ._otherSubjectsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChildrenTableReferences(
                                db,
                                table,
                                p0,
                              ).otherSubjectsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.childId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ChildrenTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChildrenTable,
      ChildRow,
      $$ChildrenTableFilterComposer,
      $$ChildrenTableOrderingComposer,
      $$ChildrenTableAnnotationComposer,
      $$ChildrenTableCreateCompanionBuilder,
      $$ChildrenTableUpdateCompanionBuilder,
      (ChildRow, $$ChildrenTableReferences),
      ChildRow,
      PrefetchHooks Function({
        bool childPhotosRefs,
        bool childSettingsRefs,
        bool unitAttemptsRefs,
        bool journeysRefs,
        bool usageDailyRefs,
        bool otherSubjectsRefs,
      })
    >;
typedef $$ChildPhotosTableCreateCompanionBuilder =
    ChildPhotosCompanion Function({
      required String childId,
      required Uint8List bytes,
      Value<int> rowid,
    });
typedef $$ChildPhotosTableUpdateCompanionBuilder =
    ChildPhotosCompanion Function({
      Value<String> childId,
      Value<Uint8List> bytes,
      Value<int> rowid,
    });

final class $$ChildPhotosTableReferences
    extends BaseReferences<_$AppDatabase, $ChildPhotosTable, ChildPhotoRow> {
  $$ChildPhotosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChildrenTable _childIdTable(_$AppDatabase db) =>
      db.children.createAlias('child_photos__child_id__children__id');

  $$ChildrenTableProcessedTableManager get childId {
    final $_column = $_itemColumn<String>('child_id')!;

    final manager = $$ChildrenTableTableManager(
      $_db,
      $_db.children,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_childIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ChildPhotosTableFilterComposer
    extends Composer<_$AppDatabase, $ChildPhotosTable> {
  $$ChildPhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );

  $$ChildrenTableFilterComposer get childId {
    final $$ChildrenTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableFilterComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChildPhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $ChildPhotosTable> {
  $$ChildPhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChildrenTableOrderingComposer get childId {
    final $$ChildrenTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableOrderingComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChildPhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChildPhotosTable> {
  $$ChildPhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<Uint8List> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  $$ChildrenTableAnnotationComposer get childId {
    final $$ChildrenTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableAnnotationComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChildPhotosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChildPhotosTable,
          ChildPhotoRow,
          $$ChildPhotosTableFilterComposer,
          $$ChildPhotosTableOrderingComposer,
          $$ChildPhotosTableAnnotationComposer,
          $$ChildPhotosTableCreateCompanionBuilder,
          $$ChildPhotosTableUpdateCompanionBuilder,
          (ChildPhotoRow, $$ChildPhotosTableReferences),
          ChildPhotoRow,
          PrefetchHooks Function({bool childId})
        > {
  $$ChildPhotosTableTableManager(_$AppDatabase db, $ChildPhotosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChildPhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChildPhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChildPhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> childId = const Value.absent(),
                Value<Uint8List> bytes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChildPhotosCompanion(
                childId: childId,
                bytes: bytes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String childId,
                required Uint8List bytes,
                Value<int> rowid = const Value.absent(),
              }) => ChildPhotosCompanion.insert(
                childId: childId,
                bytes: bytes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChildPhotosTable, ChildPhotoRow>(table),
                  $$ChildPhotosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({childId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (childId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.childId,
                        referencedTable: $$ChildPhotosTableReferences
                            ._childIdTable(db),
                        referencedColumn: $$ChildPhotosTableReferences
                            ._childIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ChildPhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChildPhotosTable,
      ChildPhotoRow,
      $$ChildPhotosTableFilterComposer,
      $$ChildPhotosTableOrderingComposer,
      $$ChildPhotosTableAnnotationComposer,
      $$ChildPhotosTableCreateCompanionBuilder,
      $$ChildPhotosTableUpdateCompanionBuilder,
      (ChildPhotoRow, $$ChildPhotosTableReferences),
      ChildPhotoRow,
      PrefetchHooks Function({bool childId})
    >;
typedef $$ChildSettingsTableCreateCompanionBuilder =
    ChildSettingsCompanion Function({
      required String childId,
      required String json,
      Value<int> version,
      Value<int> rowid,
    });
typedef $$ChildSettingsTableUpdateCompanionBuilder =
    ChildSettingsCompanion Function({
      Value<String> childId,
      Value<String> json,
      Value<int> version,
      Value<int> rowid,
    });

final class $$ChildSettingsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ChildSettingsTable, ChildSettingsRow> {
  $$ChildSettingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ChildrenTable _childIdTable(_$AppDatabase db) =>
      db.children.createAlias('child_settings__child_id__children__id');

  $$ChildrenTableProcessedTableManager get childId {
    final $_column = $_itemColumn<String>('child_id')!;

    final manager = $$ChildrenTableTableManager(
      $_db,
      $_db.children,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_childIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ChildSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $ChildSettingsTable> {
  $$ChildSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  $$ChildrenTableFilterComposer get childId {
    final $$ChildrenTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableFilterComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChildSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChildSettingsTable> {
  $$ChildSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChildrenTableOrderingComposer get childId {
    final $$ChildrenTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableOrderingComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChildSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChildSettingsTable> {
  $$ChildSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  $$ChildrenTableAnnotationComposer get childId {
    final $$ChildrenTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableAnnotationComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChildSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChildSettingsTable,
          ChildSettingsRow,
          $$ChildSettingsTableFilterComposer,
          $$ChildSettingsTableOrderingComposer,
          $$ChildSettingsTableAnnotationComposer,
          $$ChildSettingsTableCreateCompanionBuilder,
          $$ChildSettingsTableUpdateCompanionBuilder,
          (ChildSettingsRow, $$ChildSettingsTableReferences),
          ChildSettingsRow,
          PrefetchHooks Function({bool childId})
        > {
  $$ChildSettingsTableTableManager(_$AppDatabase db, $ChildSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChildSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChildSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChildSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> childId = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChildSettingsCompanion(
                childId: childId,
                json: json,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String childId,
                required String json,
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChildSettingsCompanion.insert(
                childId: childId,
                json: json,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChildSettingsTable, ChildSettingsRow>(table),
                  $$ChildSettingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({childId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (childId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.childId,
                        referencedTable: $$ChildSettingsTableReferences
                            ._childIdTable(db),
                        referencedColumn: $$ChildSettingsTableReferences
                            ._childIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ChildSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChildSettingsTable,
      ChildSettingsRow,
      $$ChildSettingsTableFilterComposer,
      $$ChildSettingsTableOrderingComposer,
      $$ChildSettingsTableAnnotationComposer,
      $$ChildSettingsTableCreateCompanionBuilder,
      $$ChildSettingsTableUpdateCompanionBuilder,
      (ChildSettingsRow, $$ChildSettingsTableReferences),
      ChildSettingsRow,
      PrefetchHooks Function({bool childId})
    >;
typedef $$UnitAttemptsTableCreateCompanionBuilder =
    UnitAttemptsCompanion Function({
      required String id,
      required String childId,
      required String curriculum,
      required String clientAttemptId,
      required String unitId,
      required int contentVersion,
      required bool completed,
      required int effortStars,
      required String completedAt,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$UnitAttemptsTableUpdateCompanionBuilder =
    UnitAttemptsCompanion Function({
      Value<String> id,
      Value<String> childId,
      Value<String> curriculum,
      Value<String> clientAttemptId,
      Value<String> unitId,
      Value<int> contentVersion,
      Value<bool> completed,
      Value<int> effortStars,
      Value<String> completedAt,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$UnitAttemptsTableReferences
    extends BaseReferences<_$AppDatabase, $UnitAttemptsTable, AttemptRow> {
  $$UnitAttemptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChildrenTable _childIdTable(_$AppDatabase db) =>
      db.children.createAlias('unit_attempts__child_id__children__id');

  $$ChildrenTableProcessedTableManager get childId {
    final $_column = $_itemColumn<String>('child_id')!;

    final manager = $$ChildrenTableTableManager(
      $_db,
      $_db.children,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_childIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AttemptObjectivesTable, List<ObjectiveRow>>
  _attemptObjectivesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.attemptObjectives,
        aliasName: 'unit_attempts__id__attempt_objectives__attempt_id',
      );

  $$AttemptObjectivesTableProcessedTableManager get attemptObjectivesRefs {
    final manager = $$AttemptObjectivesTableTableManager(
      $_db,
      $_db.attemptObjectives,
    ).filter((f) => f.attemptId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _attemptObjectivesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UnitAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $UnitAttemptsTable> {
  $$UnitAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get curriculum => $composableBuilder(
    column: $table.curriculum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientAttemptId => $composableBuilder(
    column: $table.clientAttemptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitId => $composableBuilder(
    column: $table.unitId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get effortStars => $composableBuilder(
    column: $table.effortStars,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$ChildrenTableFilterComposer get childId {
    final $$ChildrenTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableFilterComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> attemptObjectivesRefs(
    Expression<bool> Function($$AttemptObjectivesTableFilterComposer f) f,
  ) {
    final $$AttemptObjectivesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attemptObjectives,
      getReferencedColumn: (t) => t.attemptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttemptObjectivesTableFilterComposer(
            $db: $db,
            $table: $db.attemptObjectives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UnitAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $UnitAttemptsTable> {
  $$UnitAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get curriculum => $composableBuilder(
    column: $table.curriculum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientAttemptId => $composableBuilder(
    column: $table.clientAttemptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitId => $composableBuilder(
    column: $table.unitId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get effortStars => $composableBuilder(
    column: $table.effortStars,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChildrenTableOrderingComposer get childId {
    final $$ChildrenTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableOrderingComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UnitAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UnitAttemptsTable> {
  $$UnitAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get curriculum => $composableBuilder(
    column: $table.curriculum,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientAttemptId => $composableBuilder(
    column: $table.clientAttemptId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unitId =>
      $composableBuilder(column: $table.unitId, builder: (column) => column);

  GeneratedColumn<int> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<int> get effortStars => $composableBuilder(
    column: $table.effortStars,
    builder: (column) => column,
  );

  GeneratedColumn<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$ChildrenTableAnnotationComposer get childId {
    final $$ChildrenTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableAnnotationComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> attemptObjectivesRefs<T extends Object>(
    Expression<T> Function($$AttemptObjectivesTableAnnotationComposer a) f,
  ) {
    final $$AttemptObjectivesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.attemptObjectives,
          getReferencedColumn: (t) => t.attemptId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AttemptObjectivesTableAnnotationComposer(
                $db: $db,
                $table: $db.attemptObjectives,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$UnitAttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UnitAttemptsTable,
          AttemptRow,
          $$UnitAttemptsTableFilterComposer,
          $$UnitAttemptsTableOrderingComposer,
          $$UnitAttemptsTableAnnotationComposer,
          $$UnitAttemptsTableCreateCompanionBuilder,
          $$UnitAttemptsTableUpdateCompanionBuilder,
          (AttemptRow, $$UnitAttemptsTableReferences),
          AttemptRow,
          PrefetchHooks Function({bool childId, bool attemptObjectivesRefs})
        > {
  $$UnitAttemptsTableTableManager(_$AppDatabase db, $UnitAttemptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnitAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnitAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UnitAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> childId = const Value.absent(),
                Value<String> curriculum = const Value.absent(),
                Value<String> clientAttemptId = const Value.absent(),
                Value<String> unitId = const Value.absent(),
                Value<int> contentVersion = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int> effortStars = const Value.absent(),
                Value<String> completedAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UnitAttemptsCompanion(
                id: id,
                childId: childId,
                curriculum: curriculum,
                clientAttemptId: clientAttemptId,
                unitId: unitId,
                contentVersion: contentVersion,
                completed: completed,
                effortStars: effortStars,
                completedAt: completedAt,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String childId,
                required String curriculum,
                required String clientAttemptId,
                required String unitId,
                required int contentVersion,
                required bool completed,
                required int effortStars,
                required String completedAt,
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => UnitAttemptsCompanion.insert(
                id: id,
                childId: childId,
                curriculum: curriculum,
                clientAttemptId: clientAttemptId,
                unitId: unitId,
                contentVersion: contentVersion,
                completed: completed,
                effortStars: effortStars,
                completedAt: completedAt,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UnitAttemptsTable, AttemptRow>(table),
                  $$UnitAttemptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({childId = false, attemptObjectivesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (attemptObjectivesRefs) db.attemptObjectives,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (childId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.childId,
                            referencedTable: $$UnitAttemptsTableReferences
                                ._childIdTable(db),
                            referencedColumn: $$UnitAttemptsTableReferences
                                ._childIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (attemptObjectivesRefs)
                        await $_getPrefetchedData<
                          AttemptRow,
                          $UnitAttemptsTable,
                          ObjectiveRow
                        >(
                          currentTable: table,
                          referencedTable: $$UnitAttemptsTableReferences
                              ._attemptObjectivesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UnitAttemptsTableReferences(
                                db,
                                table,
                                p0,
                              ).attemptObjectivesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.attemptId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$UnitAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UnitAttemptsTable,
      AttemptRow,
      $$UnitAttemptsTableFilterComposer,
      $$UnitAttemptsTableOrderingComposer,
      $$UnitAttemptsTableAnnotationComposer,
      $$UnitAttemptsTableCreateCompanionBuilder,
      $$UnitAttemptsTableUpdateCompanionBuilder,
      (AttemptRow, $$UnitAttemptsTableReferences),
      AttemptRow,
      PrefetchHooks Function({bool childId, bool attemptObjectivesRefs})
    >;
typedef $$AttemptObjectivesTableCreateCompanionBuilder =
    AttemptObjectivesCompanion Function({
      required String attemptId,
      required String objectiveId,
      required String outcome,
      Value<int> rowid,
    });
typedef $$AttemptObjectivesTableUpdateCompanionBuilder =
    AttemptObjectivesCompanion Function({
      Value<String> attemptId,
      Value<String> objectiveId,
      Value<String> outcome,
      Value<int> rowid,
    });

final class $$AttemptObjectivesTableReferences
    extends
        BaseReferences<_$AppDatabase, $AttemptObjectivesTable, ObjectiveRow> {
  $$AttemptObjectivesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UnitAttemptsTable _attemptIdTable(_$AppDatabase db) => db.unitAttempts
      .createAlias('attempt_objectives__attempt_id__unit_attempts__id');

  $$UnitAttemptsTableProcessedTableManager get attemptId {
    final $_column = $_itemColumn<String>('attempt_id')!;

    final manager = $$UnitAttemptsTableTableManager(
      $_db,
      $_db.unitAttempts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_attemptIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AttemptObjectivesTableFilterComposer
    extends Composer<_$AppDatabase, $AttemptObjectivesTable> {
  $$AttemptObjectivesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get objectiveId => $composableBuilder(
    column: $table.objectiveId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );

  $$UnitAttemptsTableFilterComposer get attemptId {
    final $$UnitAttemptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.attemptId,
      referencedTable: $db.unitAttempts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UnitAttemptsTableFilterComposer(
            $db: $db,
            $table: $db.unitAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttemptObjectivesTableOrderingComposer
    extends Composer<_$AppDatabase, $AttemptObjectivesTable> {
  $$AttemptObjectivesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get objectiveId => $composableBuilder(
    column: $table.objectiveId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  $$UnitAttemptsTableOrderingComposer get attemptId {
    final $$UnitAttemptsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.attemptId,
      referencedTable: $db.unitAttempts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UnitAttemptsTableOrderingComposer(
            $db: $db,
            $table: $db.unitAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttemptObjectivesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttemptObjectivesTable> {
  $$AttemptObjectivesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get objectiveId => $composableBuilder(
    column: $table.objectiveId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  $$UnitAttemptsTableAnnotationComposer get attemptId {
    final $$UnitAttemptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.attemptId,
      referencedTable: $db.unitAttempts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UnitAttemptsTableAnnotationComposer(
            $db: $db,
            $table: $db.unitAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttemptObjectivesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttemptObjectivesTable,
          ObjectiveRow,
          $$AttemptObjectivesTableFilterComposer,
          $$AttemptObjectivesTableOrderingComposer,
          $$AttemptObjectivesTableAnnotationComposer,
          $$AttemptObjectivesTableCreateCompanionBuilder,
          $$AttemptObjectivesTableUpdateCompanionBuilder,
          (ObjectiveRow, $$AttemptObjectivesTableReferences),
          ObjectiveRow,
          PrefetchHooks Function({bool attemptId})
        > {
  $$AttemptObjectivesTableTableManager(
    _$AppDatabase db,
    $AttemptObjectivesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttemptObjectivesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttemptObjectivesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttemptObjectivesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> attemptId = const Value.absent(),
                Value<String> objectiveId = const Value.absent(),
                Value<String> outcome = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttemptObjectivesCompanion(
                attemptId: attemptId,
                objectiveId: objectiveId,
                outcome: outcome,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String attemptId,
                required String objectiveId,
                required String outcome,
                Value<int> rowid = const Value.absent(),
              }) => AttemptObjectivesCompanion.insert(
                attemptId: attemptId,
                objectiveId: objectiveId,
                outcome: outcome,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AttemptObjectivesTable, ObjectiveRow>(table),
                  $$AttemptObjectivesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({attemptId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (attemptId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.attemptId,
                        referencedTable: $$AttemptObjectivesTableReferences
                            ._attemptIdTable(db),
                        referencedColumn: $$AttemptObjectivesTableReferences
                            ._attemptIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AttemptObjectivesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttemptObjectivesTable,
      ObjectiveRow,
      $$AttemptObjectivesTableFilterComposer,
      $$AttemptObjectivesTableOrderingComposer,
      $$AttemptObjectivesTableAnnotationComposer,
      $$AttemptObjectivesTableCreateCompanionBuilder,
      $$AttemptObjectivesTableUpdateCompanionBuilder,
      (ObjectiveRow, $$AttemptObjectivesTableReferences),
      ObjectiveRow,
      PrefetchHooks Function({bool attemptId})
    >;
typedef $$JourneysTableCreateCompanionBuilder = JourneysCompanion Function({
  required String childId,
  required String curriculum,
  required String journeyKey,
  required String json,
  Value<int> version,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$JourneysTableUpdateCompanionBuilder = JourneysCompanion Function({
  Value<String> childId,
  Value<String> curriculum,
  Value<String> journeyKey,
  Value<String> json,
  Value<int> version,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$JourneysTableReferences
    extends BaseReferences<_$AppDatabase, $JourneysTable, JourneyRow> {
  $$JourneysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChildrenTable _childIdTable(_$AppDatabase db) =>
      db.children.createAlias('journeys__child_id__children__id');

  $$ChildrenTableProcessedTableManager get childId {
    final $_column = $_itemColumn<String>('child_id')!;

    final manager = $$ChildrenTableTableManager(
      $_db,
      $_db.children,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_childIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$JourneysTableFilterComposer
    extends Composer<_$AppDatabase, $JourneysTable> {
  $$JourneysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get curriculum => $composableBuilder(
    column: $table.curriculum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get journeyKey => $composableBuilder(
    column: $table.journeyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ChildrenTableFilterComposer get childId {
    final $$ChildrenTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableFilterComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JourneysTableOrderingComposer
    extends Composer<_$AppDatabase, $JourneysTable> {
  $$JourneysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get curriculum => $composableBuilder(
    column: $table.curriculum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get journeyKey => $composableBuilder(
    column: $table.journeyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChildrenTableOrderingComposer get childId {
    final $$ChildrenTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableOrderingComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JourneysTableAnnotationComposer
    extends Composer<_$AppDatabase, $JourneysTable> {
  $$JourneysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get curriculum => $composableBuilder(
    column: $table.curriculum,
    builder: (column) => column,
  );

  GeneratedColumn<String> get journeyKey => $composableBuilder(
    column: $table.journeyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ChildrenTableAnnotationComposer get childId {
    final $$ChildrenTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableAnnotationComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JourneysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JourneysTable,
          JourneyRow,
          $$JourneysTableFilterComposer,
          $$JourneysTableOrderingComposer,
          $$JourneysTableAnnotationComposer,
          $$JourneysTableCreateCompanionBuilder,
          $$JourneysTableUpdateCompanionBuilder,
          (JourneyRow, $$JourneysTableReferences),
          JourneyRow,
          PrefetchHooks Function({bool childId})
        > {
  $$JourneysTableTableManager(_$AppDatabase db, $JourneysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JourneysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JourneysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JourneysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> childId = const Value.absent(),
                Value<String> curriculum = const Value.absent(),
                Value<String> journeyKey = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JourneysCompanion(
                childId: childId,
                curriculum: curriculum,
                journeyKey: journeyKey,
                json: json,
                version: version,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String childId,
                required String curriculum,
                required String journeyKey,
                required String json,
                Value<int> version = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => JourneysCompanion.insert(
                childId: childId,
                curriculum: curriculum,
                journeyKey: journeyKey,
                json: json,
                version: version,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$JourneysTable, JourneyRow>(table),
                  $$JourneysTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({childId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (childId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.childId,
                        referencedTable: $$JourneysTableReferences
                            ._childIdTable(db),
                        referencedColumn: $$JourneysTableReferences
                            ._childIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$JourneysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JourneysTable,
      JourneyRow,
      $$JourneysTableFilterComposer,
      $$JourneysTableOrderingComposer,
      $$JourneysTableAnnotationComposer,
      $$JourneysTableCreateCompanionBuilder,
      $$JourneysTableUpdateCompanionBuilder,
      (JourneyRow, $$JourneysTableReferences),
      JourneyRow,
      PrefetchHooks Function({bool childId})
    >;
typedef $$UsageDailyTableCreateCompanionBuilder = UsageDailyCompanion Function({
  required String childId,
  required String deviceId,
  required String day,
  required int seconds,
  Value<int> rowid,
});
typedef $$UsageDailyTableUpdateCompanionBuilder = UsageDailyCompanion Function({
  Value<String> childId,
  Value<String> deviceId,
  Value<String> day,
  Value<int> seconds,
  Value<int> rowid,
});

final class $$UsageDailyTableReferences
    extends BaseReferences<_$AppDatabase, $UsageDailyTable, UsageRow> {
  $$UsageDailyTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChildrenTable _childIdTable(_$AppDatabase db) =>
      db.children.createAlias('usage_daily__child_id__children__id');

  $$ChildrenTableProcessedTableManager get childId {
    final $_column = $_itemColumn<String>('child_id')!;

    final manager = $$ChildrenTableTableManager(
      $_db,
      $_db.children,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_childIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UsageDailyTableFilterComposer
    extends Composer<_$AppDatabase, $UsageDailyTable> {
  $$UsageDailyTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnFilters(column),
  );

  $$ChildrenTableFilterComposer get childId {
    final $$ChildrenTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableFilterComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UsageDailyTableOrderingComposer
    extends Composer<_$AppDatabase, $UsageDailyTable> {
  $$UsageDailyTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChildrenTableOrderingComposer get childId {
    final $$ChildrenTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableOrderingComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UsageDailyTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsageDailyTable> {
  $$UsageDailyTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get seconds =>
      $composableBuilder(column: $table.seconds, builder: (column) => column);

  $$ChildrenTableAnnotationComposer get childId {
    final $$ChildrenTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableAnnotationComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UsageDailyTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsageDailyTable,
          UsageRow,
          $$UsageDailyTableFilterComposer,
          $$UsageDailyTableOrderingComposer,
          $$UsageDailyTableAnnotationComposer,
          $$UsageDailyTableCreateCompanionBuilder,
          $$UsageDailyTableUpdateCompanionBuilder,
          (UsageRow, $$UsageDailyTableReferences),
          UsageRow,
          PrefetchHooks Function({bool childId})
        > {
  $$UsageDailyTableTableManager(_$AppDatabase db, $UsageDailyTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsageDailyTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsageDailyTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsageDailyTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> childId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<int> seconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsageDailyCompanion(
                childId: childId,
                deviceId: deviceId,
                day: day,
                seconds: seconds,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String childId,
                required String deviceId,
                required String day,
                required int seconds,
                Value<int> rowid = const Value.absent(),
              }) => UsageDailyCompanion.insert(
                childId: childId,
                deviceId: deviceId,
                day: day,
                seconds: seconds,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UsageDailyTable, UsageRow>(table),
                  $$UsageDailyTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({childId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (childId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.childId,
                        referencedTable: $$UsageDailyTableReferences
                            ._childIdTable(db),
                        referencedColumn: $$UsageDailyTableReferences
                            ._childIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$UsageDailyTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsageDailyTable,
      UsageRow,
      $$UsageDailyTableFilterComposer,
      $$UsageDailyTableOrderingComposer,
      $$UsageDailyTableAnnotationComposer,
      $$UsageDailyTableCreateCompanionBuilder,
      $$UsageDailyTableUpdateCompanionBuilder,
      (UsageRow, $$UsageDailyTableReferences),
      UsageRow,
      PrefetchHooks Function({bool childId})
    >;
typedef $$OtherSubjectsTableCreateCompanionBuilder =
    OtherSubjectsCompanion Function({
      required String childId,
      required String subject,
      required String json,
      Value<int> rowid,
    });
typedef $$OtherSubjectsTableUpdateCompanionBuilder =
    OtherSubjectsCompanion Function({
      Value<String> childId,
      Value<String> subject,
      Value<String> json,
      Value<int> rowid,
    });

final class $$OtherSubjectsTableReferences
    extends BaseReferences<_$AppDatabase, $OtherSubjectsTable, SubjectRow> {
  $$OtherSubjectsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ChildrenTable _childIdTable(_$AppDatabase db) =>
      db.children.createAlias('other_subjects__child_id__children__id');

  $$ChildrenTableProcessedTableManager get childId {
    final $_column = $_itemColumn<String>('child_id')!;

    final manager = $$ChildrenTableTableManager(
      $_db,
      $_db.children,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_childIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OtherSubjectsTableFilterComposer
    extends Composer<_$AppDatabase, $OtherSubjectsTable> {
  $$OtherSubjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  $$ChildrenTableFilterComposer get childId {
    final $$ChildrenTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableFilterComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OtherSubjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $OtherSubjectsTable> {
  $$OtherSubjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChildrenTableOrderingComposer get childId {
    final $$ChildrenTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableOrderingComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OtherSubjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OtherSubjectsTable> {
  $$OtherSubjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  $$ChildrenTableAnnotationComposer get childId {
    final $$ChildrenTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.children,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChildrenTableAnnotationComposer(
            $db: $db,
            $table: $db.children,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OtherSubjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OtherSubjectsTable,
          SubjectRow,
          $$OtherSubjectsTableFilterComposer,
          $$OtherSubjectsTableOrderingComposer,
          $$OtherSubjectsTableAnnotationComposer,
          $$OtherSubjectsTableCreateCompanionBuilder,
          $$OtherSubjectsTableUpdateCompanionBuilder,
          (SubjectRow, $$OtherSubjectsTableReferences),
          SubjectRow,
          PrefetchHooks Function({bool childId})
        > {
  $$OtherSubjectsTableTableManager(_$AppDatabase db, $OtherSubjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OtherSubjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OtherSubjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OtherSubjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> childId = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OtherSubjectsCompanion(
                childId: childId,
                subject: subject,
                json: json,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String childId,
                required String subject,
                required String json,
                Value<int> rowid = const Value.absent(),
              }) => OtherSubjectsCompanion.insert(
                childId: childId,
                subject: subject,
                json: json,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OtherSubjectsTable, SubjectRow>(table),
                  $$OtherSubjectsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({childId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (childId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.childId,
                        referencedTable: $$OtherSubjectsTableReferences
                            ._childIdTable(db),
                        referencedColumn: $$OtherSubjectsTableReferences
                            ._childIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$OtherSubjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OtherSubjectsTable,
      SubjectRow,
      $$OtherSubjectsTableFilterComposer,
      $$OtherSubjectsTableOrderingComposer,
      $$OtherSubjectsTableAnnotationComposer,
      $$OtherSubjectsTableCreateCompanionBuilder,
      $$OtherSubjectsTableUpdateCompanionBuilder,
      (SubjectRow, $$OtherSubjectsTableReferences),
      SubjectRow,
      PrefetchHooks Function({bool childId})
    >;
typedef $$QuarantinedRecordsTableCreateCompanionBuilder =
    QuarantinedRecordsCompanion Function({
      Value<int> id,
      required String source,
      Value<String?> legacyId,
      required String rawJson,
      required DateTime foundAt,
    });
typedef $$QuarantinedRecordsTableUpdateCompanionBuilder =
    QuarantinedRecordsCompanion Function({
      Value<int> id,
      Value<String> source,
      Value<String?> legacyId,
      Value<String> rawJson,
      Value<DateTime> foundAt,
    });

class $$QuarantinedRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $QuarantinedRecordsTable> {
  $$QuarantinedRecordsTableFilterComposer({
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

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get legacyId => $composableBuilder(
    column: $table.legacyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get foundAt => $composableBuilder(
    column: $table.foundAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuarantinedRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuarantinedRecordsTable> {
  $$QuarantinedRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get legacyId => $composableBuilder(
    column: $table.legacyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get foundAt => $composableBuilder(
    column: $table.foundAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuarantinedRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuarantinedRecordsTable> {
  $$QuarantinedRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get legacyId =>
      $composableBuilder(column: $table.legacyId, builder: (column) => column);

  GeneratedColumn<String> get rawJson =>
      $composableBuilder(column: $table.rawJson, builder: (column) => column);

  GeneratedColumn<DateTime> get foundAt =>
      $composableBuilder(column: $table.foundAt, builder: (column) => column);
}

class $$QuarantinedRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuarantinedRecordsTable,
          QuarantineRow,
          $$QuarantinedRecordsTableFilterComposer,
          $$QuarantinedRecordsTableOrderingComposer,
          $$QuarantinedRecordsTableAnnotationComposer,
          $$QuarantinedRecordsTableCreateCompanionBuilder,
          $$QuarantinedRecordsTableUpdateCompanionBuilder,
          (
            QuarantineRow,
            BaseReferences<
              _$AppDatabase,
              $QuarantinedRecordsTable,
              QuarantineRow
            >,
          ),
          QuarantineRow,
          PrefetchHooks Function()
        > {
  $$QuarantinedRecordsTableTableManager(
    _$AppDatabase db,
    $QuarantinedRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuarantinedRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuarantinedRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuarantinedRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> legacyId = const Value.absent(),
                Value<String> rawJson = const Value.absent(),
                Value<DateTime> foundAt = const Value.absent(),
              }) => QuarantinedRecordsCompanion(
                id: id,
                source: source,
                legacyId: legacyId,
                rawJson: rawJson,
                foundAt: foundAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String source,
                Value<String?> legacyId = const Value.absent(),
                required String rawJson,
                required DateTime foundAt,
              }) => QuarantinedRecordsCompanion.insert(
                id: id,
                source: source,
                legacyId: legacyId,
                rawJson: rawJson,
                foundAt: foundAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QuarantinedRecordsTable, QuarantineRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $QuarantinedRecordsTable,
                    QuarantineRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuarantinedRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuarantinedRecordsTable,
      QuarantineRow,
      $$QuarantinedRecordsTableFilterComposer,
      $$QuarantinedRecordsTableOrderingComposer,
      $$QuarantinedRecordsTableAnnotationComposer,
      $$QuarantinedRecordsTableCreateCompanionBuilder,
      $$QuarantinedRecordsTableUpdateCompanionBuilder,
      (
        QuarantineRow,
        BaseReferences<_$AppDatabase, $QuarantinedRecordsTable, QuarantineRow>,
      ),
      QuarantineRow,
      PrefetchHooks Function()
    >;
typedef $$AppMetaTableCreateCompanionBuilder = AppMetaCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$AppMetaTableUpdateCompanionBuilder = AppMetaCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$AppMetaTableFilterComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppMetaTable,
          MetaRow,
          $$AppMetaTableFilterComposer,
          $$AppMetaTableOrderingComposer,
          $$AppMetaTableAnnotationComposer,
          $$AppMetaTableCreateCompanionBuilder,
          $$AppMetaTableUpdateCompanionBuilder,
          (MetaRow, BaseReferences<_$AppDatabase, $AppMetaTable, MetaRow>),
          MetaRow,
          PrefetchHooks Function()
        > {
  $$AppMetaTableTableManager(_$AppDatabase db, $AppMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => AppMetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppMetaTable, MetaRow>(table),
                  BaseReferences<_$AppDatabase, $AppMetaTable, MetaRow>(
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

typedef $$AppMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppMetaTable,
      MetaRow,
      $$AppMetaTableFilterComposer,
      $$AppMetaTableOrderingComposer,
      $$AppMetaTableAnnotationComposer,
      $$AppMetaTableCreateCompanionBuilder,
      $$AppMetaTableUpdateCompanionBuilder,
      (MetaRow, BaseReferences<_$AppDatabase, $AppMetaTable, MetaRow>),
      MetaRow,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableCreateCompanionBuilder = OutboxCompanion Function({
  Value<int> seq,
  required String mutationId,
  required String entity,
  required String op,
  required String entityId,
  Value<int?> baseVersion,
  required String payloadJson,
  Value<String> status,
  Value<int> tries,
  Value<String?> lastError,
  required DateTime createdAt,
});
typedef $$OutboxTableUpdateCompanionBuilder = OutboxCompanion Function({
  Value<int> seq,
  Value<String> mutationId,
  Value<String> entity,
  Value<String> op,
  Value<String> entityId,
  Value<int?> baseVersion,
  Value<String> payloadJson,
  Value<String> status,
  Value<int> tries,
  Value<String?> lastError,
  Value<DateTime> createdAt,
});

class $$OutboxTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tries => $composableBuilder(
    column: $table.tries,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tries => $composableBuilder(
    column: $table.tries,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get op =>
      $composableBuilder(column: $table.op, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get tries =>
      $composableBuilder(column: $table.tries, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxTable,
          OutboxRow,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (OutboxRow, BaseReferences<_$AppDatabase, $OutboxTable, OutboxRow>),
          OutboxRow,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$AppDatabase db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                Value<String> mutationId = const Value.absent(),
                Value<String> entity = const Value.absent(),
                Value<String> op = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<int?> baseVersion = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> tries = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OutboxCompanion(
                seq: seq,
                mutationId: mutationId,
                entity: entity,
                op: op,
                entityId: entityId,
                baseVersion: baseVersion,
                payloadJson: payloadJson,
                status: status,
                tries: tries,
                lastError: lastError,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                required String mutationId,
                required String entity,
                required String op,
                required String entityId,
                Value<int?> baseVersion = const Value.absent(),
                required String payloadJson,
                Value<String> status = const Value.absent(),
                Value<int> tries = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required DateTime createdAt,
              }) => OutboxCompanion.insert(
                seq: seq,
                mutationId: mutationId,
                entity: entity,
                op: op,
                entityId: entityId,
                baseVersion: baseVersion,
                payloadJson: payloadJson,
                status: status,
                tries: tries,
                lastError: lastError,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxTable, OutboxRow>(table),
                  BaseReferences<_$AppDatabase, $OutboxTable, OutboxRow>(
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

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxTable,
      OutboxRow,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (OutboxRow, BaseReferences<_$AppDatabase, $OutboxTable, OutboxRow>),
      OutboxRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ChildrenTableTableManager get children =>
      $$ChildrenTableTableManager(_db, _db.children);
  $$ChildPhotosTableTableManager get childPhotos =>
      $$ChildPhotosTableTableManager(_db, _db.childPhotos);
  $$ChildSettingsTableTableManager get childSettings =>
      $$ChildSettingsTableTableManager(_db, _db.childSettings);
  $$UnitAttemptsTableTableManager get unitAttempts =>
      $$UnitAttemptsTableTableManager(_db, _db.unitAttempts);
  $$AttemptObjectivesTableTableManager get attemptObjectives =>
      $$AttemptObjectivesTableTableManager(_db, _db.attemptObjectives);
  $$JourneysTableTableManager get journeys =>
      $$JourneysTableTableManager(_db, _db.journeys);
  $$UsageDailyTableTableManager get usageDaily =>
      $$UsageDailyTableTableManager(_db, _db.usageDaily);
  $$OtherSubjectsTableTableManager get otherSubjects =>
      $$OtherSubjectsTableTableManager(_db, _db.otherSubjects);
  $$QuarantinedRecordsTableTableManager get quarantinedRecords =>
      $$QuarantinedRecordsTableTableManager(_db, _db.quarantinedRecords);
  $$AppMetaTableTableManager get appMeta =>
      $$AppMetaTableTableManager(_db, _db.appMeta);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db, _db.outbox);
}
