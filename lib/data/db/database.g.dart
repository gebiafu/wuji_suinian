// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _createAtMeta = const VerificationMeta(
    'createAt',
  );
  @override
  late final GeneratedColumn<int> createAt = GeneratedColumn<int>(
    'create_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('create_at')) {
      context.handle(
        _createAtMeta,
        createAt.isAcceptableOrUnknown(data['create_at']!, _createAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}create_at'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final int id;
  final String name;
  final int createAt;
  const Tag({required this.id, required this.name, required this.createAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['create_at'] = Variable<int>(createAt);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      name: Value(name),
      createAt: Value(createAt),
    );
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createAt: serializer.fromJson<int>(json['createAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'createAt': serializer.toJson<int>(createAt),
    };
  }

  Tag copyWith({int? id, String? name, int? createAt}) => Tag(
    id: id ?? this.id,
    name: name ?? this.name,
    createAt: createAt ?? this.createAt,
  );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createAt: data.createAt.present ? data.createAt.value : this.createAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createAt: $createAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.name == this.name &&
          other.createAt == this.createAt);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> createAt;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createAt = const Value.absent(),
  });
  TagsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int createAt,
  }) : name = Value(name),
       createAt = Value(createAt);
  static Insertable<Tag> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? createAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createAt != null) 'create_at': createAt,
    });
  }

  TagsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? createAt,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createAt: createAt ?? this.createAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createAt.present) {
      map['create_at'] = Variable<int>(createAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createAt: $createAt')
          ..write(')'))
        .toString();
  }
}

class $ItemsTable extends Items with TableInfo<$ItemsTable, Item> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('元'),
  );
  static const VerificationMeta _buyChannelMeta = const VerificationMeta(
    'buyChannel',
  );
  @override
  late final GeneratedColumn<String> buyChannel = GeneratedColumn<String>(
    'buy_channel',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _buyDateMeta = const VerificationMeta(
    'buyDate',
  );
  @override
  late final GeneratedColumn<int> buyDate = GeneratedColumn<int>(
    'buy_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _warrantyEndDateMeta = const VerificationMeta(
    'warrantyEndDate',
  );
  @override
  late final GeneratedColumn<int> warrantyEndDate = GeneratedColumn<int>(
    'warranty_end_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('using'),
  );
  static const VerificationMeta _lendTargetMeta = const VerificationMeta(
    'lendTarget',
  );
  @override
  late final GeneratedColumn<String> lendTarget = GeneratedColumn<String>(
    'lend_target',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lendTimeMeta = const VerificationMeta(
    'lendTime',
  );
  @override
  late final GeneratedColumn<int> lendTime = GeneratedColumn<int>(
    'lend_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expectReturnTimeMeta = const VerificationMeta(
    'expectReturnTime',
  );
  @override
  late final GeneratedColumn<int> expectReturnTime = GeneratedColumn<int>(
    'expect_return_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createAtMeta = const VerificationMeta(
    'createAt',
  );
  @override
  late final GeneratedColumn<int> createAt = GeneratedColumn<int>(
    'create_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updateAtMeta = const VerificationMeta(
    'updateAt',
  );
  @override
  late final GeneratedColumn<int> updateAt = GeneratedColumn<int>(
    'update_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    categoryId,
    location,
    price,
    unit,
    buyChannel,
    buyDate,
    warrantyEndDate,
    status,
    lendTarget,
    lendTime,
    expectReturnTime,
    description,
    createAt,
    updateAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(
    Insertable<Item> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('buy_channel')) {
      context.handle(
        _buyChannelMeta,
        buyChannel.isAcceptableOrUnknown(data['buy_channel']!, _buyChannelMeta),
      );
    }
    if (data.containsKey('buy_date')) {
      context.handle(
        _buyDateMeta,
        buyDate.isAcceptableOrUnknown(data['buy_date']!, _buyDateMeta),
      );
    }
    if (data.containsKey('warranty_end_date')) {
      context.handle(
        _warrantyEndDateMeta,
        warrantyEndDate.isAcceptableOrUnknown(
          data['warranty_end_date']!,
          _warrantyEndDateMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('lend_target')) {
      context.handle(
        _lendTargetMeta,
        lendTarget.isAcceptableOrUnknown(data['lend_target']!, _lendTargetMeta),
      );
    }
    if (data.containsKey('lend_time')) {
      context.handle(
        _lendTimeMeta,
        lendTime.isAcceptableOrUnknown(data['lend_time']!, _lendTimeMeta),
      );
    }
    if (data.containsKey('expect_return_time')) {
      context.handle(
        _expectReturnTimeMeta,
        expectReturnTime.isAcceptableOrUnknown(
          data['expect_return_time']!,
          _expectReturnTimeMeta,
        ),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('create_at')) {
      context.handle(
        _createAtMeta,
        createAt.isAcceptableOrUnknown(data['create_at']!, _createAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createAtMeta);
    }
    if (data.containsKey('update_at')) {
      context.handle(
        _updateAtMeta,
        updateAt.isAcceptableOrUnknown(data['update_at']!, _updateAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updateAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Item map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Item(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      buyChannel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}buy_channel'],
      ),
      buyDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}buy_date'],
      ),
      warrantyEndDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}warranty_end_date'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      lendTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lend_target'],
      ),
      lendTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lend_time'],
      ),
      expectReturnTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expect_return_time'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}create_at'],
      )!,
      updateAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}update_at'],
      )!,
    );
  }

  @override
  $ItemsTable createAlias(String alias) {
    return $ItemsTable(attachedDatabase, alias);
  }
}

class Item extends DataClass implements Insertable<Item> {
  final int id;
  final String name;

  /// 分类（标签 id，指向 tags 表）
  final int? categoryId;
  final String? location;
  final double? price;
  final String unit;
  final String? buyChannel;
  final int? buyDate;
  final int? warrantyEndDate;

  /// using / idle / discarded / lend
  final String status;
  final String? lendTarget;
  final int? lendTime;
  final int? expectReturnTime;
  final String? description;
  final int createAt;
  final int updateAt;
  const Item({
    required this.id,
    required this.name,
    this.categoryId,
    this.location,
    this.price,
    required this.unit,
    this.buyChannel,
    this.buyDate,
    this.warrantyEndDate,
    required this.status,
    this.lendTarget,
    this.lendTime,
    this.expectReturnTime,
    this.description,
    required this.createAt,
    required this.updateAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || price != null) {
      map['price'] = Variable<double>(price);
    }
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || buyChannel != null) {
      map['buy_channel'] = Variable<String>(buyChannel);
    }
    if (!nullToAbsent || buyDate != null) {
      map['buy_date'] = Variable<int>(buyDate);
    }
    if (!nullToAbsent || warrantyEndDate != null) {
      map['warranty_end_date'] = Variable<int>(warrantyEndDate);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || lendTarget != null) {
      map['lend_target'] = Variable<String>(lendTarget);
    }
    if (!nullToAbsent || lendTime != null) {
      map['lend_time'] = Variable<int>(lendTime);
    }
    if (!nullToAbsent || expectReturnTime != null) {
      map['expect_return_time'] = Variable<int>(expectReturnTime);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['create_at'] = Variable<int>(createAt);
    map['update_at'] = Variable<int>(updateAt);
    return map;
  }

  ItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemsCompanion(
      id: Value(id),
      name: Value(name),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      price: price == null && nullToAbsent
          ? const Value.absent()
          : Value(price),
      unit: Value(unit),
      buyChannel: buyChannel == null && nullToAbsent
          ? const Value.absent()
          : Value(buyChannel),
      buyDate: buyDate == null && nullToAbsent
          ? const Value.absent()
          : Value(buyDate),
      warrantyEndDate: warrantyEndDate == null && nullToAbsent
          ? const Value.absent()
          : Value(warrantyEndDate),
      status: Value(status),
      lendTarget: lendTarget == null && nullToAbsent
          ? const Value.absent()
          : Value(lendTarget),
      lendTime: lendTime == null && nullToAbsent
          ? const Value.absent()
          : Value(lendTime),
      expectReturnTime: expectReturnTime == null && nullToAbsent
          ? const Value.absent()
          : Value(expectReturnTime),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createAt: Value(createAt),
      updateAt: Value(updateAt),
    );
  }

  factory Item.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Item(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      location: serializer.fromJson<String?>(json['location']),
      price: serializer.fromJson<double?>(json['price']),
      unit: serializer.fromJson<String>(json['unit']),
      buyChannel: serializer.fromJson<String?>(json['buyChannel']),
      buyDate: serializer.fromJson<int?>(json['buyDate']),
      warrantyEndDate: serializer.fromJson<int?>(json['warrantyEndDate']),
      status: serializer.fromJson<String>(json['status']),
      lendTarget: serializer.fromJson<String?>(json['lendTarget']),
      lendTime: serializer.fromJson<int?>(json['lendTime']),
      expectReturnTime: serializer.fromJson<int?>(json['expectReturnTime']),
      description: serializer.fromJson<String?>(json['description']),
      createAt: serializer.fromJson<int>(json['createAt']),
      updateAt: serializer.fromJson<int>(json['updateAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'categoryId': serializer.toJson<int?>(categoryId),
      'location': serializer.toJson<String?>(location),
      'price': serializer.toJson<double?>(price),
      'unit': serializer.toJson<String>(unit),
      'buyChannel': serializer.toJson<String?>(buyChannel),
      'buyDate': serializer.toJson<int?>(buyDate),
      'warrantyEndDate': serializer.toJson<int?>(warrantyEndDate),
      'status': serializer.toJson<String>(status),
      'lendTarget': serializer.toJson<String?>(lendTarget),
      'lendTime': serializer.toJson<int?>(lendTime),
      'expectReturnTime': serializer.toJson<int?>(expectReturnTime),
      'description': serializer.toJson<String?>(description),
      'createAt': serializer.toJson<int>(createAt),
      'updateAt': serializer.toJson<int>(updateAt),
    };
  }

  Item copyWith({
    int? id,
    String? name,
    Value<int?> categoryId = const Value.absent(),
    Value<String?> location = const Value.absent(),
    Value<double?> price = const Value.absent(),
    String? unit,
    Value<String?> buyChannel = const Value.absent(),
    Value<int?> buyDate = const Value.absent(),
    Value<int?> warrantyEndDate = const Value.absent(),
    String? status,
    Value<String?> lendTarget = const Value.absent(),
    Value<int?> lendTime = const Value.absent(),
    Value<int?> expectReturnTime = const Value.absent(),
    Value<String?> description = const Value.absent(),
    int? createAt,
    int? updateAt,
  }) => Item(
    id: id ?? this.id,
    name: name ?? this.name,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    location: location.present ? location.value : this.location,
    price: price.present ? price.value : this.price,
    unit: unit ?? this.unit,
    buyChannel: buyChannel.present ? buyChannel.value : this.buyChannel,
    buyDate: buyDate.present ? buyDate.value : this.buyDate,
    warrantyEndDate: warrantyEndDate.present
        ? warrantyEndDate.value
        : this.warrantyEndDate,
    status: status ?? this.status,
    lendTarget: lendTarget.present ? lendTarget.value : this.lendTarget,
    lendTime: lendTime.present ? lendTime.value : this.lendTime,
    expectReturnTime: expectReturnTime.present
        ? expectReturnTime.value
        : this.expectReturnTime,
    description: description.present ? description.value : this.description,
    createAt: createAt ?? this.createAt,
    updateAt: updateAt ?? this.updateAt,
  );
  Item copyWithCompanion(ItemsCompanion data) {
    return Item(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      location: data.location.present ? data.location.value : this.location,
      price: data.price.present ? data.price.value : this.price,
      unit: data.unit.present ? data.unit.value : this.unit,
      buyChannel: data.buyChannel.present
          ? data.buyChannel.value
          : this.buyChannel,
      buyDate: data.buyDate.present ? data.buyDate.value : this.buyDate,
      warrantyEndDate: data.warrantyEndDate.present
          ? data.warrantyEndDate.value
          : this.warrantyEndDate,
      status: data.status.present ? data.status.value : this.status,
      lendTarget: data.lendTarget.present
          ? data.lendTarget.value
          : this.lendTarget,
      lendTime: data.lendTime.present ? data.lendTime.value : this.lendTime,
      expectReturnTime: data.expectReturnTime.present
          ? data.expectReturnTime.value
          : this.expectReturnTime,
      description: data.description.present
          ? data.description.value
          : this.description,
      createAt: data.createAt.present ? data.createAt.value : this.createAt,
      updateAt: data.updateAt.present ? data.updateAt.value : this.updateAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Item(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('location: $location, ')
          ..write('price: $price, ')
          ..write('unit: $unit, ')
          ..write('buyChannel: $buyChannel, ')
          ..write('buyDate: $buyDate, ')
          ..write('warrantyEndDate: $warrantyEndDate, ')
          ..write('status: $status, ')
          ..write('lendTarget: $lendTarget, ')
          ..write('lendTime: $lendTime, ')
          ..write('expectReturnTime: $expectReturnTime, ')
          ..write('description: $description, ')
          ..write('createAt: $createAt, ')
          ..write('updateAt: $updateAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    categoryId,
    location,
    price,
    unit,
    buyChannel,
    buyDate,
    warrantyEndDate,
    status,
    lendTarget,
    lendTime,
    expectReturnTime,
    description,
    createAt,
    updateAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Item &&
          other.id == this.id &&
          other.name == this.name &&
          other.categoryId == this.categoryId &&
          other.location == this.location &&
          other.price == this.price &&
          other.unit == this.unit &&
          other.buyChannel == this.buyChannel &&
          other.buyDate == this.buyDate &&
          other.warrantyEndDate == this.warrantyEndDate &&
          other.status == this.status &&
          other.lendTarget == this.lendTarget &&
          other.lendTime == this.lendTime &&
          other.expectReturnTime == this.expectReturnTime &&
          other.description == this.description &&
          other.createAt == this.createAt &&
          other.updateAt == this.updateAt);
}

class ItemsCompanion extends UpdateCompanion<Item> {
  final Value<int> id;
  final Value<String> name;
  final Value<int?> categoryId;
  final Value<String?> location;
  final Value<double?> price;
  final Value<String> unit;
  final Value<String?> buyChannel;
  final Value<int?> buyDate;
  final Value<int?> warrantyEndDate;
  final Value<String> status;
  final Value<String?> lendTarget;
  final Value<int?> lendTime;
  final Value<int?> expectReturnTime;
  final Value<String?> description;
  final Value<int> createAt;
  final Value<int> updateAt;
  const ItemsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.location = const Value.absent(),
    this.price = const Value.absent(),
    this.unit = const Value.absent(),
    this.buyChannel = const Value.absent(),
    this.buyDate = const Value.absent(),
    this.warrantyEndDate = const Value.absent(),
    this.status = const Value.absent(),
    this.lendTarget = const Value.absent(),
    this.lendTime = const Value.absent(),
    this.expectReturnTime = const Value.absent(),
    this.description = const Value.absent(),
    this.createAt = const Value.absent(),
    this.updateAt = const Value.absent(),
  });
  ItemsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.categoryId = const Value.absent(),
    this.location = const Value.absent(),
    this.price = const Value.absent(),
    this.unit = const Value.absent(),
    this.buyChannel = const Value.absent(),
    this.buyDate = const Value.absent(),
    this.warrantyEndDate = const Value.absent(),
    this.status = const Value.absent(),
    this.lendTarget = const Value.absent(),
    this.lendTime = const Value.absent(),
    this.expectReturnTime = const Value.absent(),
    this.description = const Value.absent(),
    required int createAt,
    required int updateAt,
  }) : name = Value(name),
       createAt = Value(createAt),
       updateAt = Value(updateAt);
  static Insertable<Item> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? categoryId,
    Expression<String>? location,
    Expression<double>? price,
    Expression<String>? unit,
    Expression<String>? buyChannel,
    Expression<int>? buyDate,
    Expression<int>? warrantyEndDate,
    Expression<String>? status,
    Expression<String>? lendTarget,
    Expression<int>? lendTime,
    Expression<int>? expectReturnTime,
    Expression<String>? description,
    Expression<int>? createAt,
    Expression<int>? updateAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (categoryId != null) 'category_id': categoryId,
      if (location != null) 'location': location,
      if (price != null) 'price': price,
      if (unit != null) 'unit': unit,
      if (buyChannel != null) 'buy_channel': buyChannel,
      if (buyDate != null) 'buy_date': buyDate,
      if (warrantyEndDate != null) 'warranty_end_date': warrantyEndDate,
      if (status != null) 'status': status,
      if (lendTarget != null) 'lend_target': lendTarget,
      if (lendTime != null) 'lend_time': lendTime,
      if (expectReturnTime != null) 'expect_return_time': expectReturnTime,
      if (description != null) 'description': description,
      if (createAt != null) 'create_at': createAt,
      if (updateAt != null) 'update_at': updateAt,
    });
  }

  ItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int?>? categoryId,
    Value<String?>? location,
    Value<double?>? price,
    Value<String>? unit,
    Value<String?>? buyChannel,
    Value<int?>? buyDate,
    Value<int?>? warrantyEndDate,
    Value<String>? status,
    Value<String?>? lendTarget,
    Value<int?>? lendTime,
    Value<int?>? expectReturnTime,
    Value<String?>? description,
    Value<int>? createAt,
    Value<int>? updateAt,
  }) {
    return ItemsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      location: location ?? this.location,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      buyChannel: buyChannel ?? this.buyChannel,
      buyDate: buyDate ?? this.buyDate,
      warrantyEndDate: warrantyEndDate ?? this.warrantyEndDate,
      status: status ?? this.status,
      lendTarget: lendTarget ?? this.lendTarget,
      lendTime: lendTime ?? this.lendTime,
      expectReturnTime: expectReturnTime ?? this.expectReturnTime,
      description: description ?? this.description,
      createAt: createAt ?? this.createAt,
      updateAt: updateAt ?? this.updateAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (buyChannel.present) {
      map['buy_channel'] = Variable<String>(buyChannel.value);
    }
    if (buyDate.present) {
      map['buy_date'] = Variable<int>(buyDate.value);
    }
    if (warrantyEndDate.present) {
      map['warranty_end_date'] = Variable<int>(warrantyEndDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lendTarget.present) {
      map['lend_target'] = Variable<String>(lendTarget.value);
    }
    if (lendTime.present) {
      map['lend_time'] = Variable<int>(lendTime.value);
    }
    if (expectReturnTime.present) {
      map['expect_return_time'] = Variable<int>(expectReturnTime.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createAt.present) {
      map['create_at'] = Variable<int>(createAt.value);
    }
    if (updateAt.present) {
      map['update_at'] = Variable<int>(updateAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('location: $location, ')
          ..write('price: $price, ')
          ..write('unit: $unit, ')
          ..write('buyChannel: $buyChannel, ')
          ..write('buyDate: $buyDate, ')
          ..write('warrantyEndDate: $warrantyEndDate, ')
          ..write('status: $status, ')
          ..write('lendTarget: $lendTarget, ')
          ..write('lendTime: $lendTime, ')
          ..write('expectReturnTime: $expectReturnTime, ')
          ..write('description: $description, ')
          ..write('createAt: $createAt, ')
          ..write('updateAt: $updateAt')
          ..write(')'))
        .toString();
  }
}

class $ItemImagesTable extends ItemImages
    with TableInfo<$ItemImagesTable, ItemImage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemImagesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _relativePathMeta = const VerificationMeta(
    'relativePath',
  );
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortMeta = const VerificationMeta('sort');
  @override
  late final GeneratedColumn<int> sort = GeneratedColumn<int>(
    'sort',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, itemId, relativePath, sort];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_images';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemImage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
        _relativePathMeta,
        relativePath.isAcceptableOrUnknown(
          data['relative_path']!,
          _relativePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('sort')) {
      context.handle(
        _sortMeta,
        sort.isAcceptableOrUnknown(data['sort']!, _sortMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItemImage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemImage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      relativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_path'],
      )!,
      sort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort'],
      ),
    );
  }

  @override
  $ItemImagesTable createAlias(String alias) {
    return $ItemImagesTable(attachedDatabase, alias);
  }
}

class ItemImage extends DataClass implements Insertable<ItemImage> {
  final int id;
  final int itemId;
  final String relativePath;
  final int? sort;
  const ItemImage({
    required this.id,
    required this.itemId,
    required this.relativePath,
    this.sort,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<int>(itemId);
    map['relative_path'] = Variable<String>(relativePath);
    if (!nullToAbsent || sort != null) {
      map['sort'] = Variable<int>(sort);
    }
    return map;
  }

  ItemImagesCompanion toCompanion(bool nullToAbsent) {
    return ItemImagesCompanion(
      id: Value(id),
      itemId: Value(itemId),
      relativePath: Value(relativePath),
      sort: sort == null && nullToAbsent ? const Value.absent() : Value(sort),
    );
  }

  factory ItemImage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemImage(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<int>(json['itemId']),
      relativePath: serializer.fromJson<String>(json['relativePath']),
      sort: serializer.fromJson<int?>(json['sort']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<int>(itemId),
      'relativePath': serializer.toJson<String>(relativePath),
      'sort': serializer.toJson<int?>(sort),
    };
  }

  ItemImage copyWith({
    int? id,
    int? itemId,
    String? relativePath,
    Value<int?> sort = const Value.absent(),
  }) => ItemImage(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    relativePath: relativePath ?? this.relativePath,
    sort: sort.present ? sort.value : this.sort,
  );
  ItemImage copyWithCompanion(ItemImagesCompanion data) {
    return ItemImage(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      sort: data.sort.present ? data.sort.value : this.sort,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemImage(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('relativePath: $relativePath, ')
          ..write('sort: $sort')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, itemId, relativePath, sort);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemImage &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.relativePath == this.relativePath &&
          other.sort == this.sort);
}

class ItemImagesCompanion extends UpdateCompanion<ItemImage> {
  final Value<int> id;
  final Value<int> itemId;
  final Value<String> relativePath;
  final Value<int?> sort;
  const ItemImagesCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.sort = const Value.absent(),
  });
  ItemImagesCompanion.insert({
    this.id = const Value.absent(),
    required int itemId,
    required String relativePath,
    this.sort = const Value.absent(),
  }) : itemId = Value(itemId),
       relativePath = Value(relativePath);
  static Insertable<ItemImage> custom({
    Expression<int>? id,
    Expression<int>? itemId,
    Expression<String>? relativePath,
    Expression<int>? sort,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (relativePath != null) 'relative_path': relativePath,
      if (sort != null) 'sort': sort,
    });
  }

  ItemImagesCompanion copyWith({
    Value<int>? id,
    Value<int>? itemId,
    Value<String>? relativePath,
    Value<int?>? sort,
  }) {
    return ItemImagesCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      relativePath: relativePath ?? this.relativePath,
      sort: sort ?? this.sort,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (sort.present) {
      map['sort'] = Variable<int>(sort.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemImagesCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('relativePath: $relativePath, ')
          ..write('sort: $sort')
          ..write(')'))
        .toString();
  }
}

class $BulletNotesTable extends BulletNotes
    with TableInfo<$BulletNotesTable, BulletNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BulletNotesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isTodoMeta = const VerificationMeta('isTodo');
  @override
  late final GeneratedColumn<bool> isTodo = GeneratedColumn<bool>(
    'is_todo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_todo" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _todoFinishedMeta = const VerificationMeta(
    'todoFinished',
  );
  @override
  late final GeneratedColumn<bool> todoFinished = GeneratedColumn<bool>(
    'todo_finished',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("todo_finished" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isTopMeta = const VerificationMeta('isTop');
  @override
  late final GeneratedColumn<bool> isTop = GeneratedColumn<bool>(
    'is_top',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_top" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createAtMeta = const VerificationMeta(
    'createAt',
  );
  @override
  late final GeneratedColumn<int> createAt = GeneratedColumn<int>(
    'create_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updateAtMeta = const VerificationMeta(
    'updateAt',
  );
  @override
  late final GeneratedColumn<int> updateAt = GeneratedColumn<int>(
    'update_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    content,
    imagePath,
    isTodo,
    todoFinished,
    isTop,
    createAt,
    updateAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bullet_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<BulletNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('is_todo')) {
      context.handle(
        _isTodoMeta,
        isTodo.isAcceptableOrUnknown(data['is_todo']!, _isTodoMeta),
      );
    }
    if (data.containsKey('todo_finished')) {
      context.handle(
        _todoFinishedMeta,
        todoFinished.isAcceptableOrUnknown(
          data['todo_finished']!,
          _todoFinishedMeta,
        ),
      );
    }
    if (data.containsKey('is_top')) {
      context.handle(
        _isTopMeta,
        isTop.isAcceptableOrUnknown(data['is_top']!, _isTopMeta),
      );
    }
    if (data.containsKey('create_at')) {
      context.handle(
        _createAtMeta,
        createAt.isAcceptableOrUnknown(data['create_at']!, _createAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createAtMeta);
    }
    if (data.containsKey('update_at')) {
      context.handle(
        _updateAtMeta,
        updateAt.isAcceptableOrUnknown(data['update_at']!, _updateAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updateAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BulletNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BulletNote(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      isTodo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_todo'],
      )!,
      todoFinished: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}todo_finished'],
      )!,
      isTop: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_top'],
      )!,
      createAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}create_at'],
      )!,
      updateAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}update_at'],
      )!,
    );
  }

  @override
  $BulletNotesTable createAlias(String alias) {
    return $BulletNotesTable(attachedDatabase, alias);
  }
}

class BulletNote extends DataClass implements Insertable<BulletNote> {
  final int id;
  final String content;
  final String? imagePath;
  final bool isTodo;
  final bool todoFinished;
  final bool isTop;
  final int createAt;
  final int updateAt;
  const BulletNote({
    required this.id,
    required this.content,
    this.imagePath,
    required this.isTodo,
    required this.todoFinished,
    required this.isTop,
    required this.createAt,
    required this.updateAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['is_todo'] = Variable<bool>(isTodo);
    map['todo_finished'] = Variable<bool>(todoFinished);
    map['is_top'] = Variable<bool>(isTop);
    map['create_at'] = Variable<int>(createAt);
    map['update_at'] = Variable<int>(updateAt);
    return map;
  }

  BulletNotesCompanion toCompanion(bool nullToAbsent) {
    return BulletNotesCompanion(
      id: Value(id),
      content: Value(content),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      isTodo: Value(isTodo),
      todoFinished: Value(todoFinished),
      isTop: Value(isTop),
      createAt: Value(createAt),
      updateAt: Value(updateAt),
    );
  }

  factory BulletNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BulletNote(
      id: serializer.fromJson<int>(json['id']),
      content: serializer.fromJson<String>(json['content']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      isTodo: serializer.fromJson<bool>(json['isTodo']),
      todoFinished: serializer.fromJson<bool>(json['todoFinished']),
      isTop: serializer.fromJson<bool>(json['isTop']),
      createAt: serializer.fromJson<int>(json['createAt']),
      updateAt: serializer.fromJson<int>(json['updateAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'content': serializer.toJson<String>(content),
      'imagePath': serializer.toJson<String?>(imagePath),
      'isTodo': serializer.toJson<bool>(isTodo),
      'todoFinished': serializer.toJson<bool>(todoFinished),
      'isTop': serializer.toJson<bool>(isTop),
      'createAt': serializer.toJson<int>(createAt),
      'updateAt': serializer.toJson<int>(updateAt),
    };
  }

  BulletNote copyWith({
    int? id,
    String? content,
    Value<String?> imagePath = const Value.absent(),
    bool? isTodo,
    bool? todoFinished,
    bool? isTop,
    int? createAt,
    int? updateAt,
  }) => BulletNote(
    id: id ?? this.id,
    content: content ?? this.content,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    isTodo: isTodo ?? this.isTodo,
    todoFinished: todoFinished ?? this.todoFinished,
    isTop: isTop ?? this.isTop,
    createAt: createAt ?? this.createAt,
    updateAt: updateAt ?? this.updateAt,
  );
  BulletNote copyWithCompanion(BulletNotesCompanion data) {
    return BulletNote(
      id: data.id.present ? data.id.value : this.id,
      content: data.content.present ? data.content.value : this.content,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      isTodo: data.isTodo.present ? data.isTodo.value : this.isTodo,
      todoFinished: data.todoFinished.present
          ? data.todoFinished.value
          : this.todoFinished,
      isTop: data.isTop.present ? data.isTop.value : this.isTop,
      createAt: data.createAt.present ? data.createAt.value : this.createAt,
      updateAt: data.updateAt.present ? data.updateAt.value : this.updateAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BulletNote(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('imagePath: $imagePath, ')
          ..write('isTodo: $isTodo, ')
          ..write('todoFinished: $todoFinished, ')
          ..write('isTop: $isTop, ')
          ..write('createAt: $createAt, ')
          ..write('updateAt: $updateAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    content,
    imagePath,
    isTodo,
    todoFinished,
    isTop,
    createAt,
    updateAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BulletNote &&
          other.id == this.id &&
          other.content == this.content &&
          other.imagePath == this.imagePath &&
          other.isTodo == this.isTodo &&
          other.todoFinished == this.todoFinished &&
          other.isTop == this.isTop &&
          other.createAt == this.createAt &&
          other.updateAt == this.updateAt);
}

class BulletNotesCompanion extends UpdateCompanion<BulletNote> {
  final Value<int> id;
  final Value<String> content;
  final Value<String?> imagePath;
  final Value<bool> isTodo;
  final Value<bool> todoFinished;
  final Value<bool> isTop;
  final Value<int> createAt;
  final Value<int> updateAt;
  const BulletNotesCompanion({
    this.id = const Value.absent(),
    this.content = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.isTodo = const Value.absent(),
    this.todoFinished = const Value.absent(),
    this.isTop = const Value.absent(),
    this.createAt = const Value.absent(),
    this.updateAt = const Value.absent(),
  });
  BulletNotesCompanion.insert({
    this.id = const Value.absent(),
    required String content,
    this.imagePath = const Value.absent(),
    this.isTodo = const Value.absent(),
    this.todoFinished = const Value.absent(),
    this.isTop = const Value.absent(),
    required int createAt,
    required int updateAt,
  }) : content = Value(content),
       createAt = Value(createAt),
       updateAt = Value(updateAt);
  static Insertable<BulletNote> custom({
    Expression<int>? id,
    Expression<String>? content,
    Expression<String>? imagePath,
    Expression<bool>? isTodo,
    Expression<bool>? todoFinished,
    Expression<bool>? isTop,
    Expression<int>? createAt,
    Expression<int>? updateAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (content != null) 'content': content,
      if (imagePath != null) 'image_path': imagePath,
      if (isTodo != null) 'is_todo': isTodo,
      if (todoFinished != null) 'todo_finished': todoFinished,
      if (isTop != null) 'is_top': isTop,
      if (createAt != null) 'create_at': createAt,
      if (updateAt != null) 'update_at': updateAt,
    });
  }

  BulletNotesCompanion copyWith({
    Value<int>? id,
    Value<String>? content,
    Value<String?>? imagePath,
    Value<bool>? isTodo,
    Value<bool>? todoFinished,
    Value<bool>? isTop,
    Value<int>? createAt,
    Value<int>? updateAt,
  }) {
    return BulletNotesCompanion(
      id: id ?? this.id,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,
      isTodo: isTodo ?? this.isTodo,
      todoFinished: todoFinished ?? this.todoFinished,
      isTop: isTop ?? this.isTop,
      createAt: createAt ?? this.createAt,
      updateAt: updateAt ?? this.updateAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (isTodo.present) {
      map['is_todo'] = Variable<bool>(isTodo.value);
    }
    if (todoFinished.present) {
      map['todo_finished'] = Variable<bool>(todoFinished.value);
    }
    if (isTop.present) {
      map['is_top'] = Variable<bool>(isTop.value);
    }
    if (createAt.present) {
      map['create_at'] = Variable<int>(createAt.value);
    }
    if (updateAt.present) {
      map['update_at'] = Variable<int>(updateAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BulletNotesCompanion(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('imagePath: $imagePath, ')
          ..write('isTodo: $isTodo, ')
          ..write('todoFinished: $todoFinished, ')
          ..write('isTop: $isTop, ')
          ..write('createAt: $createAt, ')
          ..write('updateAt: $updateAt')
          ..write(')'))
        .toString();
  }
}

class $BulletNoteTagRelTable extends BulletNoteTagRel
    with TableInfo<$BulletNoteTagRelTable, BulletNoteTagRelData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BulletNoteTagRelTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<int> noteId = GeneratedColumn<int>(
    'note_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int> tagId = GeneratedColumn<int>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [noteId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bullet_note_tag_rel';
  @override
  VerificationContext validateIntegrity(
    Insertable<BulletNoteTagRelData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {noteId, tagId};
  @override
  BulletNoteTagRelData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BulletNoteTagRelData(
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}note_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $BulletNoteTagRelTable createAlias(String alias) {
    return $BulletNoteTagRelTable(attachedDatabase, alias);
  }
}

class BulletNoteTagRelData extends DataClass
    implements Insertable<BulletNoteTagRelData> {
  final int noteId;
  final int tagId;
  const BulletNoteTagRelData({required this.noteId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['note_id'] = Variable<int>(noteId);
    map['tag_id'] = Variable<int>(tagId);
    return map;
  }

  BulletNoteTagRelCompanion toCompanion(bool nullToAbsent) {
    return BulletNoteTagRelCompanion(
      noteId: Value(noteId),
      tagId: Value(tagId),
    );
  }

  factory BulletNoteTagRelData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BulletNoteTagRelData(
      noteId: serializer.fromJson<int>(json['noteId']),
      tagId: serializer.fromJson<int>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'noteId': serializer.toJson<int>(noteId),
      'tagId': serializer.toJson<int>(tagId),
    };
  }

  BulletNoteTagRelData copyWith({int? noteId, int? tagId}) =>
      BulletNoteTagRelData(
        noteId: noteId ?? this.noteId,
        tagId: tagId ?? this.tagId,
      );
  BulletNoteTagRelData copyWithCompanion(BulletNoteTagRelCompanion data) {
    return BulletNoteTagRelData(
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BulletNoteTagRelData(')
          ..write('noteId: $noteId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(noteId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BulletNoteTagRelData &&
          other.noteId == this.noteId &&
          other.tagId == this.tagId);
}

class BulletNoteTagRelCompanion extends UpdateCompanion<BulletNoteTagRelData> {
  final Value<int> noteId;
  final Value<int> tagId;
  final Value<int> rowid;
  const BulletNoteTagRelCompanion({
    this.noteId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BulletNoteTagRelCompanion.insert({
    required int noteId,
    required int tagId,
    this.rowid = const Value.absent(),
  }) : noteId = Value(noteId),
       tagId = Value(tagId);
  static Insertable<BulletNoteTagRelData> custom({
    Expression<int>? noteId,
    Expression<int>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (noteId != null) 'note_id': noteId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BulletNoteTagRelCompanion copyWith({
    Value<int>? noteId,
    Value<int>? tagId,
    Value<int>? rowid,
  }) {
    return BulletNoteTagRelCompanion(
      noteId: noteId ?? this.noteId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (noteId.present) {
      map['note_id'] = Variable<int>(noteId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BulletNoteTagRelCompanion(')
          ..write('noteId: $noteId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemTagRelTable extends ItemTagRel
    with TableInfo<$ItemTagRelTable, ItemTagRelData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemTagRelTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int> tagId = GeneratedColumn<int>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [itemId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_tag_rel';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemTagRelData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId, tagId};
  @override
  ItemTagRelData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemTagRelData(
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $ItemTagRelTable createAlias(String alias) {
    return $ItemTagRelTable(attachedDatabase, alias);
  }
}

class ItemTagRelData extends DataClass implements Insertable<ItemTagRelData> {
  final int itemId;
  final int tagId;
  const ItemTagRelData({required this.itemId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<int>(itemId);
    map['tag_id'] = Variable<int>(tagId);
    return map;
  }

  ItemTagRelCompanion toCompanion(bool nullToAbsent) {
    return ItemTagRelCompanion(itemId: Value(itemId), tagId: Value(tagId));
  }

  factory ItemTagRelData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemTagRelData(
      itemId: serializer.fromJson<int>(json['itemId']),
      tagId: serializer.fromJson<int>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<int>(itemId),
      'tagId': serializer.toJson<int>(tagId),
    };
  }

  ItemTagRelData copyWith({int? itemId, int? tagId}) =>
      ItemTagRelData(itemId: itemId ?? this.itemId, tagId: tagId ?? this.tagId);
  ItemTagRelData copyWithCompanion(ItemTagRelCompanion data) {
    return ItemTagRelData(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemTagRelData(')
          ..write('itemId: $itemId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(itemId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemTagRelData &&
          other.itemId == this.itemId &&
          other.tagId == this.tagId);
}

class ItemTagRelCompanion extends UpdateCompanion<ItemTagRelData> {
  final Value<int> itemId;
  final Value<int> tagId;
  final Value<int> rowid;
  const ItemTagRelCompanion({
    this.itemId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemTagRelCompanion.insert({
    required int itemId,
    required int tagId,
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       tagId = Value(tagId);
  static Insertable<ItemTagRelData> custom({
    Expression<int>? itemId,
    Expression<int>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemTagRelCompanion copyWith({
    Value<int>? itemId,
    Value<int>? tagId,
    Value<int>? rowid,
  }) {
    return ItemTagRelCompanion(
      itemId: itemId ?? this.itemId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemTagRelCompanion(')
          ..write('itemId: $itemId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BackupRecordsTable extends BackupRecords
    with TableInfo<$BackupRecordsTable, BackupRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BackupRecordsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remotePathMeta = const VerificationMeta(
    'remotePath',
  );
  @override
  late final GeneratedColumn<String> remotePath = GeneratedColumn<String>(
    'remote_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createAtMeta = const VerificationMeta(
    'createAt',
  );
  @override
  late final GeneratedColumn<int> createAt = GeneratedColumn<int>(
    'create_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    status,
    message,
    size,
    remotePath,
    createAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'backup_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<BackupRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    }
    if (data.containsKey('remote_path')) {
      context.handle(
        _remotePathMeta,
        remotePath.isAcceptableOrUnknown(data['remote_path']!, _remotePathMeta),
      );
    }
    if (data.containsKey('create_at')) {
      context.handle(
        _createAtMeta,
        createAt.isAcceptableOrUnknown(data['create_at']!, _createAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BackupRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BackupRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      ),
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      ),
      remotePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_path'],
      ),
      createAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}create_at'],
      )!,
    );
  }

  @override
  $BackupRecordsTable createAlias(String alias) {
    return $BackupRecordsTable(attachedDatabase, alias);
  }
}

class BackupRecord extends DataClass implements Insertable<BackupRecord> {
  final int id;

  /// backup / restore / sync / export / import
  final String type;

  /// success / failed / conflict
  final String status;
  final String? message;
  final int? size;
  final String? remotePath;
  final int createAt;
  const BackupRecord({
    required this.id,
    required this.type,
    required this.status,
    this.message,
    this.size,
    this.remotePath,
    required this.createAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || message != null) {
      map['message'] = Variable<String>(message);
    }
    if (!nullToAbsent || size != null) {
      map['size'] = Variable<int>(size);
    }
    if (!nullToAbsent || remotePath != null) {
      map['remote_path'] = Variable<String>(remotePath);
    }
    map['create_at'] = Variable<int>(createAt);
    return map;
  }

  BackupRecordsCompanion toCompanion(bool nullToAbsent) {
    return BackupRecordsCompanion(
      id: Value(id),
      type: Value(type),
      status: Value(status),
      message: message == null && nullToAbsent
          ? const Value.absent()
          : Value(message),
      size: size == null && nullToAbsent ? const Value.absent() : Value(size),
      remotePath: remotePath == null && nullToAbsent
          ? const Value.absent()
          : Value(remotePath),
      createAt: Value(createAt),
    );
  }

  factory BackupRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BackupRecord(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      status: serializer.fromJson<String>(json['status']),
      message: serializer.fromJson<String?>(json['message']),
      size: serializer.fromJson<int?>(json['size']),
      remotePath: serializer.fromJson<String?>(json['remotePath']),
      createAt: serializer.fromJson<int>(json['createAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'status': serializer.toJson<String>(status),
      'message': serializer.toJson<String?>(message),
      'size': serializer.toJson<int?>(size),
      'remotePath': serializer.toJson<String?>(remotePath),
      'createAt': serializer.toJson<int>(createAt),
    };
  }

  BackupRecord copyWith({
    int? id,
    String? type,
    String? status,
    Value<String?> message = const Value.absent(),
    Value<int?> size = const Value.absent(),
    Value<String?> remotePath = const Value.absent(),
    int? createAt,
  }) => BackupRecord(
    id: id ?? this.id,
    type: type ?? this.type,
    status: status ?? this.status,
    message: message.present ? message.value : this.message,
    size: size.present ? size.value : this.size,
    remotePath: remotePath.present ? remotePath.value : this.remotePath,
    createAt: createAt ?? this.createAt,
  );
  BackupRecord copyWithCompanion(BackupRecordsCompanion data) {
    return BackupRecord(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      status: data.status.present ? data.status.value : this.status,
      message: data.message.present ? data.message.value : this.message,
      size: data.size.present ? data.size.value : this.size,
      remotePath: data.remotePath.present
          ? data.remotePath.value
          : this.remotePath,
      createAt: data.createAt.present ? data.createAt.value : this.createAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BackupRecord(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('message: $message, ')
          ..write('size: $size, ')
          ..write('remotePath: $remotePath, ')
          ..write('createAt: $createAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, type, status, message, size, remotePath, createAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BackupRecord &&
          other.id == this.id &&
          other.type == this.type &&
          other.status == this.status &&
          other.message == this.message &&
          other.size == this.size &&
          other.remotePath == this.remotePath &&
          other.createAt == this.createAt);
}

class BackupRecordsCompanion extends UpdateCompanion<BackupRecord> {
  final Value<int> id;
  final Value<String> type;
  final Value<String> status;
  final Value<String?> message;
  final Value<int?> size;
  final Value<String?> remotePath;
  final Value<int> createAt;
  const BackupRecordsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.status = const Value.absent(),
    this.message = const Value.absent(),
    this.size = const Value.absent(),
    this.remotePath = const Value.absent(),
    this.createAt = const Value.absent(),
  });
  BackupRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required String status,
    this.message = const Value.absent(),
    this.size = const Value.absent(),
    this.remotePath = const Value.absent(),
    required int createAt,
  }) : type = Value(type),
       status = Value(status),
       createAt = Value(createAt);
  static Insertable<BackupRecord> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? status,
    Expression<String>? message,
    Expression<int>? size,
    Expression<String>? remotePath,
    Expression<int>? createAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (message != null) 'message': message,
      if (size != null) 'size': size,
      if (remotePath != null) 'remote_path': remotePath,
      if (createAt != null) 'create_at': createAt,
    });
  }

  BackupRecordsCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<String>? status,
    Value<String?>? message,
    Value<int?>? size,
    Value<String?>? remotePath,
    Value<int>? createAt,
  }) {
    return BackupRecordsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      message: message ?? this.message,
      size: size ?? this.size,
      remotePath: remotePath ?? this.remotePath,
      createAt: createAt ?? this.createAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (remotePath.present) {
      map['remote_path'] = Variable<String>(remotePath.value);
    }
    if (createAt.present) {
      map['create_at'] = Variable<int>(createAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BackupRecordsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('message: $message, ')
          ..write('size: $size, ')
          ..write('remotePath: $remotePath, ')
          ..write('createAt: $createAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $ItemImagesTable itemImages = $ItemImagesTable(this);
  late final $BulletNotesTable bulletNotes = $BulletNotesTable(this);
  late final $BulletNoteTagRelTable bulletNoteTagRel = $BulletNoteTagRelTable(
    this,
  );
  late final $ItemTagRelTable itemTagRel = $ItemTagRelTable(this);
  late final $BackupRecordsTable backupRecords = $BackupRecordsTable(this);
  late final ItemsDao itemsDao = ItemsDao(this as AppDatabase);
  late final NotesDao notesDao = NotesDao(this as AppDatabase);
  late final TagsDao tagsDao = TagsDao(this as AppDatabase);
  late final BackupRecordsDao backupRecordsDao = BackupRecordsDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tags,
    items,
    itemImages,
    bulletNotes,
    bulletNoteTagRel,
    itemTagRel,
    backupRecords,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('item_images', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$TagsTableCreateCompanionBuilder = TagsCompanion Function({
  Value<int> id,
  required String name,
  required int createAt,
});
typedef $$TagsTableUpdateCompanionBuilder = TagsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> createAt,
});

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createAt => $composableBuilder(
    column: $table.createAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createAt => $composableBuilder(
    column: $table.createAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get createAt =>
      $composableBuilder(column: $table.createAt, builder: (column) => column);
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, BaseReferences<_$AppDatabase, $TagsTable, Tag>),
          Tag,
          PrefetchHooks Function()
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> createAt = const Value.absent(),
          }) => TagsCompanion(id: id, name: name, createAt: createAt),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required int createAt,
          }) => TagsCompanion.insert(id: id, name: name, createAt: createAt),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TagsTable, Tag>(table),
                  BaseReferences<_$AppDatabase, $TagsTable, Tag>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, BaseReferences<_$AppDatabase, $TagsTable, Tag>),
      Tag,
      PrefetchHooks Function()
    >;
typedef $$ItemsTableCreateCompanionBuilder = ItemsCompanion Function({
  Value<int> id,
  required String name,
  Value<int?> categoryId,
  Value<String?> location,
  Value<double?> price,
  Value<String> unit,
  Value<String?> buyChannel,
  Value<int?> buyDate,
  Value<int?> warrantyEndDate,
  Value<String> status,
  Value<String?> lendTarget,
  Value<int?> lendTime,
  Value<int?> expectReturnTime,
  Value<String?> description,
  required int createAt,
  required int updateAt,
});
typedef $$ItemsTableUpdateCompanionBuilder = ItemsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int?> categoryId,
  Value<String?> location,
  Value<double?> price,
  Value<String> unit,
  Value<String?> buyChannel,
  Value<int?> buyDate,
  Value<int?> warrantyEndDate,
  Value<String> status,
  Value<String?> lendTarget,
  Value<int?> lendTime,
  Value<int?> expectReturnTime,
  Value<String?> description,
  Value<int> createAt,
  Value<int> updateAt,
});

final class $$ItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ItemsTable, Item> {
  $$ItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ItemImagesTable, List<ItemImage>>
  _itemImagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.itemImages,
    aliasName: 'items__id__item_images__item_id',
  );

  $$ItemImagesTableProcessedTableManager get itemImagesRefs {
    final manager = $$ItemImagesTableTableManager(
      $_db,
      $_db.itemImages,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemImagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ItemsTableFilterComposer extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get buyChannel => $composableBuilder(
    column: $table.buyChannel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get buyDate => $composableBuilder(
    column: $table.buyDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get warrantyEndDate => $composableBuilder(
    column: $table.warrantyEndDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lendTarget => $composableBuilder(
    column: $table.lendTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lendTime => $composableBuilder(
    column: $table.lendTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expectReturnTime => $composableBuilder(
    column: $table.expectReturnTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createAt => $composableBuilder(
    column: $table.createAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updateAt => $composableBuilder(
    column: $table.updateAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> itemImagesRefs(
    Expression<bool> Function($$ItemImagesTableFilterComposer f) f,
  ) {
    final $$ItemImagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemImages,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemImagesTableFilterComposer(
            $db: $db,
            $table: $db.itemImages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get buyChannel => $composableBuilder(
    column: $table.buyChannel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get buyDate => $composableBuilder(
    column: $table.buyDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get warrantyEndDate => $composableBuilder(
    column: $table.warrantyEndDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lendTarget => $composableBuilder(
    column: $table.lendTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lendTime => $composableBuilder(
    column: $table.lendTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expectReturnTime => $composableBuilder(
    column: $table.expectReturnTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createAt => $composableBuilder(
    column: $table.createAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updateAt => $composableBuilder(
    column: $table.updateAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get buyChannel => $composableBuilder(
    column: $table.buyChannel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get buyDate =>
      $composableBuilder(column: $table.buyDate, builder: (column) => column);

  GeneratedColumn<int> get warrantyEndDate => $composableBuilder(
    column: $table.warrantyEndDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get lendTarget => $composableBuilder(
    column: $table.lendTarget,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lendTime =>
      $composableBuilder(column: $table.lendTime, builder: (column) => column);

  GeneratedColumn<int> get expectReturnTime => $composableBuilder(
    column: $table.expectReturnTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createAt =>
      $composableBuilder(column: $table.createAt, builder: (column) => column);

  GeneratedColumn<int> get updateAt =>
      $composableBuilder(column: $table.updateAt, builder: (column) => column);

  Expression<T> itemImagesRefs<T extends Object>(
    Expression<T> Function($$ItemImagesTableAnnotationComposer a) f,
  ) {
    final $$ItemImagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemImages,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemImagesTableAnnotationComposer(
            $db: $db,
            $table: $db.itemImages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemsTable,
          Item,
          $$ItemsTableFilterComposer,
          $$ItemsTableOrderingComposer,
          $$ItemsTableAnnotationComposer,
          $$ItemsTableCreateCompanionBuilder,
          $$ItemsTableUpdateCompanionBuilder,
          (Item, $$ItemsTableReferences),
          Item,
          PrefetchHooks Function({bool itemImagesRefs})
        > {
  $$ItemsTableTableManager(_$AppDatabase db, $ItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<double?> price = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String?> buyChannel = const Value.absent(),
                Value<int?> buyDate = const Value.absent(),
                Value<int?> warrantyEndDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> lendTarget = const Value.absent(),
                Value<int?> lendTime = const Value.absent(),
                Value<int?> expectReturnTime = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> createAt = const Value.absent(),
                Value<int> updateAt = const Value.absent(),
              }) => ItemsCompanion(
                id: id,
                name: name,
                categoryId: categoryId,
                location: location,
                price: price,
                unit: unit,
                buyChannel: buyChannel,
                buyDate: buyDate,
                warrantyEndDate: warrantyEndDate,
                status: status,
                lendTarget: lendTarget,
                lendTime: lendTime,
                expectReturnTime: expectReturnTime,
                description: description,
                createAt: createAt,
                updateAt: updateAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int?> categoryId = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<double?> price = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String?> buyChannel = const Value.absent(),
                Value<int?> buyDate = const Value.absent(),
                Value<int?> warrantyEndDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> lendTarget = const Value.absent(),
                Value<int?> lendTime = const Value.absent(),
                Value<int?> expectReturnTime = const Value.absent(),
                Value<String?> description = const Value.absent(),
                required int createAt,
                required int updateAt,
              }) => ItemsCompanion.insert(
                id: id,
                name: name,
                categoryId: categoryId,
                location: location,
                price: price,
                unit: unit,
                buyChannel: buyChannel,
                buyDate: buyDate,
                warrantyEndDate: warrantyEndDate,
                status: status,
                lendTarget: lendTarget,
                lendTime: lendTime,
                expectReturnTime: expectReturnTime,
                description: description,
                createAt: createAt,
                updateAt: updateAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ItemsTable, Item>(table),
                  $$ItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemImagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (itemImagesRefs) db.itemImages],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (itemImagesRefs)
                    await $_getPrefetchedData<Item, $ItemsTable, ItemImage>(
                      currentTable: table,
                      referencedTable: $$ItemsTableReferences
                          ._itemImagesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ItemsTableReferences(db, table, p0).itemImagesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.itemId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemsTable,
      Item,
      $$ItemsTableFilterComposer,
      $$ItemsTableOrderingComposer,
      $$ItemsTableAnnotationComposer,
      $$ItemsTableCreateCompanionBuilder,
      $$ItemsTableUpdateCompanionBuilder,
      (Item, $$ItemsTableReferences),
      Item,
      PrefetchHooks Function({bool itemImagesRefs})
    >;
typedef $$ItemImagesTableCreateCompanionBuilder = ItemImagesCompanion Function({
  Value<int> id,
  required int itemId,
  required String relativePath,
  Value<int?> sort,
});
typedef $$ItemImagesTableUpdateCompanionBuilder = ItemImagesCompanion Function({
  Value<int> id,
  Value<int> itemId,
  Value<String> relativePath,
  Value<int?> sort,
});

final class $$ItemImagesTableReferences
    extends BaseReferences<_$AppDatabase, $ItemImagesTable, ItemImage> {
  $$ItemImagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ItemsTable _itemIdTable(_$AppDatabase db) =>
      db.items.createAlias('item_images__item_id__items__id');

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<int>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ItemImagesTableFilterComposer
    extends Composer<_$AppDatabase, $ItemImagesTable> {
  $$ItemImagesTableFilterComposer({
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

  ColumnFilters<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemImagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemImagesTable> {
  $$ItemImagesTableOrderingComposer({
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

  ColumnOrderings<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemImagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemImagesTable> {
  $$ItemImagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sort =>
      $composableBuilder(column: $table.sort, builder: (column) => column);

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemImagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemImagesTable,
          ItemImage,
          $$ItemImagesTableFilterComposer,
          $$ItemImagesTableOrderingComposer,
          $$ItemImagesTableAnnotationComposer,
          $$ItemImagesTableCreateCompanionBuilder,
          $$ItemImagesTableUpdateCompanionBuilder,
          (ItemImage, $$ItemImagesTableReferences),
          ItemImage,
          PrefetchHooks Function({bool itemId})
        > {
  $$ItemImagesTableTableManager(_$AppDatabase db, $ItemImagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemImagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemImagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemImagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<String> relativePath = const Value.absent(),
                Value<int?> sort = const Value.absent(),
              }) => ItemImagesCompanion(
                id: id,
                itemId: itemId,
                relativePath: relativePath,
                sort: sort,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int itemId,
                required String relativePath,
                Value<int?> sort = const Value.absent(),
              }) => ItemImagesCompanion.insert(
                id: id,
                itemId: itemId,
                relativePath: relativePath,
                sort: sort,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ItemImagesTable, ItemImage>(table),
                  $$ItemImagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
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
                    if (itemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.itemId,
                        referencedTable: $$ItemImagesTableReferences
                            ._itemIdTable(db),
                        referencedColumn: $$ItemImagesTableReferences
                            ._itemIdTable(db)
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

typedef $$ItemImagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemImagesTable,
      ItemImage,
      $$ItemImagesTableFilterComposer,
      $$ItemImagesTableOrderingComposer,
      $$ItemImagesTableAnnotationComposer,
      $$ItemImagesTableCreateCompanionBuilder,
      $$ItemImagesTableUpdateCompanionBuilder,
      (ItemImage, $$ItemImagesTableReferences),
      ItemImage,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$BulletNotesTableCreateCompanionBuilder =
    BulletNotesCompanion Function({
      Value<int> id,
      required String content,
      Value<String?> imagePath,
      Value<bool> isTodo,
      Value<bool> todoFinished,
      Value<bool> isTop,
      required int createAt,
      required int updateAt,
    });
typedef $$BulletNotesTableUpdateCompanionBuilder =
    BulletNotesCompanion Function({
      Value<int> id,
      Value<String> content,
      Value<String?> imagePath,
      Value<bool> isTodo,
      Value<bool> todoFinished,
      Value<bool> isTop,
      Value<int> createAt,
      Value<int> updateAt,
    });

class $$BulletNotesTableFilterComposer
    extends Composer<_$AppDatabase, $BulletNotesTable> {
  $$BulletNotesTableFilterComposer({
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

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTodo => $composableBuilder(
    column: $table.isTodo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get todoFinished => $composableBuilder(
    column: $table.todoFinished,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTop => $composableBuilder(
    column: $table.isTop,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createAt => $composableBuilder(
    column: $table.createAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updateAt => $composableBuilder(
    column: $table.updateAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BulletNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $BulletNotesTable> {
  $$BulletNotesTableOrderingComposer({
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

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTodo => $composableBuilder(
    column: $table.isTodo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get todoFinished => $composableBuilder(
    column: $table.todoFinished,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTop => $composableBuilder(
    column: $table.isTop,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createAt => $composableBuilder(
    column: $table.createAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updateAt => $composableBuilder(
    column: $table.updateAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BulletNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BulletNotesTable> {
  $$BulletNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<bool> get isTodo =>
      $composableBuilder(column: $table.isTodo, builder: (column) => column);

  GeneratedColumn<bool> get todoFinished => $composableBuilder(
    column: $table.todoFinished,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isTop =>
      $composableBuilder(column: $table.isTop, builder: (column) => column);

  GeneratedColumn<int> get createAt =>
      $composableBuilder(column: $table.createAt, builder: (column) => column);

  GeneratedColumn<int> get updateAt =>
      $composableBuilder(column: $table.updateAt, builder: (column) => column);
}

class $$BulletNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BulletNotesTable,
          BulletNote,
          $$BulletNotesTableFilterComposer,
          $$BulletNotesTableOrderingComposer,
          $$BulletNotesTableAnnotationComposer,
          $$BulletNotesTableCreateCompanionBuilder,
          $$BulletNotesTableUpdateCompanionBuilder,
          (
            BulletNote,
            BaseReferences<_$AppDatabase, $BulletNotesTable, BulletNote>,
          ),
          BulletNote,
          PrefetchHooks Function()
        > {
  $$BulletNotesTableTableManager(_$AppDatabase db, $BulletNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BulletNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BulletNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BulletNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<bool> isTodo = const Value.absent(),
                Value<bool> todoFinished = const Value.absent(),
                Value<bool> isTop = const Value.absent(),
                Value<int> createAt = const Value.absent(),
                Value<int> updateAt = const Value.absent(),
              }) => BulletNotesCompanion(
                id: id,
                content: content,
                imagePath: imagePath,
                isTodo: isTodo,
                todoFinished: todoFinished,
                isTop: isTop,
                createAt: createAt,
                updateAt: updateAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String content,
                Value<String?> imagePath = const Value.absent(),
                Value<bool> isTodo = const Value.absent(),
                Value<bool> todoFinished = const Value.absent(),
                Value<bool> isTop = const Value.absent(),
                required int createAt,
                required int updateAt,
              }) => BulletNotesCompanion.insert(
                id: id,
                content: content,
                imagePath: imagePath,
                isTodo: isTodo,
                todoFinished: todoFinished,
                isTop: isTop,
                createAt: createAt,
                updateAt: updateAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BulletNotesTable, BulletNote>(table),
                  BaseReferences<_$AppDatabase, $BulletNotesTable, BulletNote>(
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

typedef $$BulletNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BulletNotesTable,
      BulletNote,
      $$BulletNotesTableFilterComposer,
      $$BulletNotesTableOrderingComposer,
      $$BulletNotesTableAnnotationComposer,
      $$BulletNotesTableCreateCompanionBuilder,
      $$BulletNotesTableUpdateCompanionBuilder,
      (
        BulletNote,
        BaseReferences<_$AppDatabase, $BulletNotesTable, BulletNote>,
      ),
      BulletNote,
      PrefetchHooks Function()
    >;
typedef $$BulletNoteTagRelTableCreateCompanionBuilder =
    BulletNoteTagRelCompanion Function({
      required int noteId,
      required int tagId,
      Value<int> rowid,
    });
typedef $$BulletNoteTagRelTableUpdateCompanionBuilder =
    BulletNoteTagRelCompanion Function({
      Value<int> noteId,
      Value<int> tagId,
      Value<int> rowid,
    });

class $$BulletNoteTagRelTableFilterComposer
    extends Composer<_$AppDatabase, $BulletNoteTagRelTable> {
  $$BulletNoteTagRelTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BulletNoteTagRelTableOrderingComposer
    extends Composer<_$AppDatabase, $BulletNoteTagRelTable> {
  $$BulletNoteTagRelTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BulletNoteTagRelTableAnnotationComposer
    extends Composer<_$AppDatabase, $BulletNoteTagRelTable> {
  $$BulletNoteTagRelTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get noteId =>
      $composableBuilder(column: $table.noteId, builder: (column) => column);

  GeneratedColumn<int> get tagId =>
      $composableBuilder(column: $table.tagId, builder: (column) => column);
}

class $$BulletNoteTagRelTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BulletNoteTagRelTable,
          BulletNoteTagRelData,
          $$BulletNoteTagRelTableFilterComposer,
          $$BulletNoteTagRelTableOrderingComposer,
          $$BulletNoteTagRelTableAnnotationComposer,
          $$BulletNoteTagRelTableCreateCompanionBuilder,
          $$BulletNoteTagRelTableUpdateCompanionBuilder,
          (
            BulletNoteTagRelData,
            BaseReferences<
              _$AppDatabase,
              $BulletNoteTagRelTable,
              BulletNoteTagRelData
            >,
          ),
          BulletNoteTagRelData,
          PrefetchHooks Function()
        > {
  $$BulletNoteTagRelTableTableManager(
    _$AppDatabase db,
    $BulletNoteTagRelTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BulletNoteTagRelTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BulletNoteTagRelTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BulletNoteTagRelTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> noteId = const Value.absent(),
                Value<int> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BulletNoteTagRelCompanion(
                noteId: noteId,
                tagId: tagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int noteId,
                required int tagId,
                Value<int> rowid = const Value.absent(),
              }) => BulletNoteTagRelCompanion.insert(
                noteId: noteId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BulletNoteTagRelTable, BulletNoteTagRelData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $BulletNoteTagRelTable,
                    BulletNoteTagRelData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BulletNoteTagRelTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BulletNoteTagRelTable,
      BulletNoteTagRelData,
      $$BulletNoteTagRelTableFilterComposer,
      $$BulletNoteTagRelTableOrderingComposer,
      $$BulletNoteTagRelTableAnnotationComposer,
      $$BulletNoteTagRelTableCreateCompanionBuilder,
      $$BulletNoteTagRelTableUpdateCompanionBuilder,
      (
        BulletNoteTagRelData,
        BaseReferences<
          _$AppDatabase,
          $BulletNoteTagRelTable,
          BulletNoteTagRelData
        >,
      ),
      BulletNoteTagRelData,
      PrefetchHooks Function()
    >;
typedef $$ItemTagRelTableCreateCompanionBuilder = ItemTagRelCompanion Function({
  required int itemId,
  required int tagId,
  Value<int> rowid,
});
typedef $$ItemTagRelTableUpdateCompanionBuilder = ItemTagRelCompanion Function({
  Value<int> itemId,
  Value<int> tagId,
  Value<int> rowid,
});

class $$ItemTagRelTableFilterComposer
    extends Composer<_$AppDatabase, $ItemTagRelTable> {
  $$ItemTagRelTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ItemTagRelTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemTagRelTable> {
  $$ItemTagRelTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ItemTagRelTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemTagRelTable> {
  $$ItemTagRelTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get tagId =>
      $composableBuilder(column: $table.tagId, builder: (column) => column);
}

class $$ItemTagRelTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemTagRelTable,
          ItemTagRelData,
          $$ItemTagRelTableFilterComposer,
          $$ItemTagRelTableOrderingComposer,
          $$ItemTagRelTableAnnotationComposer,
          $$ItemTagRelTableCreateCompanionBuilder,
          $$ItemTagRelTableUpdateCompanionBuilder,
          (
            ItemTagRelData,
            BaseReferences<_$AppDatabase, $ItemTagRelTable, ItemTagRelData>,
          ),
          ItemTagRelData,
          PrefetchHooks Function()
        > {
  $$ItemTagRelTableTableManager(_$AppDatabase db, $ItemTagRelTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemTagRelTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemTagRelTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemTagRelTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> itemId = const Value.absent(),
            Value<int> tagId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => ItemTagRelCompanion(itemId: itemId, tagId: tagId, rowid: rowid),
          createCompanionCallback:
              ({
                required int itemId,
                required int tagId,
                Value<int> rowid = const Value.absent(),
              }) => ItemTagRelCompanion.insert(
                itemId: itemId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ItemTagRelTable, ItemTagRelData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ItemTagRelTable,
                    ItemTagRelData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ItemTagRelTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemTagRelTable,
      ItemTagRelData,
      $$ItemTagRelTableFilterComposer,
      $$ItemTagRelTableOrderingComposer,
      $$ItemTagRelTableAnnotationComposer,
      $$ItemTagRelTableCreateCompanionBuilder,
      $$ItemTagRelTableUpdateCompanionBuilder,
      (
        ItemTagRelData,
        BaseReferences<_$AppDatabase, $ItemTagRelTable, ItemTagRelData>,
      ),
      ItemTagRelData,
      PrefetchHooks Function()
    >;
typedef $$BackupRecordsTableCreateCompanionBuilder =
    BackupRecordsCompanion Function({
      Value<int> id,
      required String type,
      required String status,
      Value<String?> message,
      Value<int?> size,
      Value<String?> remotePath,
      required int createAt,
    });
typedef $$BackupRecordsTableUpdateCompanionBuilder =
    BackupRecordsCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<String> status,
      Value<String?> message,
      Value<int?> size,
      Value<String?> remotePath,
      Value<int> createAt,
    });

class $$BackupRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $BackupRecordsTable> {
  $$BackupRecordsTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createAt => $composableBuilder(
    column: $table.createAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BackupRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $BackupRecordsTable> {
  $$BackupRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createAt => $composableBuilder(
    column: $table.createAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BackupRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BackupRecordsTable> {
  $$BackupRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createAt =>
      $composableBuilder(column: $table.createAt, builder: (column) => column);
}

class $$BackupRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BackupRecordsTable,
          BackupRecord,
          $$BackupRecordsTableFilterComposer,
          $$BackupRecordsTableOrderingComposer,
          $$BackupRecordsTableAnnotationComposer,
          $$BackupRecordsTableCreateCompanionBuilder,
          $$BackupRecordsTableUpdateCompanionBuilder,
          (
            BackupRecord,
            BaseReferences<_$AppDatabase, $BackupRecordsTable, BackupRecord>,
          ),
          BackupRecord,
          PrefetchHooks Function()
        > {
  $$BackupRecordsTableTableManager(_$AppDatabase db, $BackupRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BackupRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BackupRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BackupRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> message = const Value.absent(),
                Value<int?> size = const Value.absent(),
                Value<String?> remotePath = const Value.absent(),
                Value<int> createAt = const Value.absent(),
              }) => BackupRecordsCompanion(
                id: id,
                type: type,
                status: status,
                message: message,
                size: size,
                remotePath: remotePath,
                createAt: createAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                required String status,
                Value<String?> message = const Value.absent(),
                Value<int?> size = const Value.absent(),
                Value<String?> remotePath = const Value.absent(),
                required int createAt,
              }) => BackupRecordsCompanion.insert(
                id: id,
                type: type,
                status: status,
                message: message,
                size: size,
                remotePath: remotePath,
                createAt: createAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BackupRecordsTable, BackupRecord>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $BackupRecordsTable,
                    BackupRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BackupRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BackupRecordsTable,
      BackupRecord,
      $$BackupRecordsTableFilterComposer,
      $$BackupRecordsTableOrderingComposer,
      $$BackupRecordsTableAnnotationComposer,
      $$BackupRecordsTableCreateCompanionBuilder,
      $$BackupRecordsTableUpdateCompanionBuilder,
      (
        BackupRecord,
        BaseReferences<_$AppDatabase, $BackupRecordsTable, BackupRecord>,
      ),
      BackupRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db, _db.items);
  $$ItemImagesTableTableManager get itemImages =>
      $$ItemImagesTableTableManager(_db, _db.itemImages);
  $$BulletNotesTableTableManager get bulletNotes =>
      $$BulletNotesTableTableManager(_db, _db.bulletNotes);
  $$BulletNoteTagRelTableTableManager get bulletNoteTagRel =>
      $$BulletNoteTagRelTableTableManager(_db, _db.bulletNoteTagRel);
  $$ItemTagRelTableTableManager get itemTagRel =>
      $$ItemTagRelTableTableManager(_db, _db.itemTagRel);
  $$BackupRecordsTableTableManager get backupRecords =>
      $$BackupRecordsTableTableManager(_db, _db.backupRecords);
}

mixin _$ItemsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ItemsTable get items => attachedDatabase.items;
  $ItemImagesTable get itemImages => attachedDatabase.itemImages;
  $ItemTagRelTable get itemTagRel => attachedDatabase.itemTagRel;
  ItemsDaoManager get managers => ItemsDaoManager(this);
}

class ItemsDaoManager {
  final _$ItemsDaoMixin _db;
  ItemsDaoManager(this._db);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db.attachedDatabase, _db.items);
  $$ItemImagesTableTableManager get itemImages =>
      $$ItemImagesTableTableManager(_db.attachedDatabase, _db.itemImages);
  $$ItemTagRelTableTableManager get itemTagRel =>
      $$ItemTagRelTableTableManager(_db.attachedDatabase, _db.itemTagRel);
}

mixin _$NotesDaoMixin on DatabaseAccessor<AppDatabase> {
  $BulletNotesTable get bulletNotes => attachedDatabase.bulletNotes;
  $BulletNoteTagRelTable get bulletNoteTagRel =>
      attachedDatabase.bulletNoteTagRel;
  NotesDaoManager get managers => NotesDaoManager(this);
}

class NotesDaoManager {
  final _$NotesDaoMixin _db;
  NotesDaoManager(this._db);
  $$BulletNotesTableTableManager get bulletNotes =>
      $$BulletNotesTableTableManager(_db.attachedDatabase, _db.bulletNotes);
  $$BulletNoteTagRelTableTableManager get bulletNoteTagRel =>
      $$BulletNoteTagRelTableTableManager(
        _db.attachedDatabase,
        _db.bulletNoteTagRel,
      );
}

mixin _$TagsDaoMixin on DatabaseAccessor<AppDatabase> {
  $TagsTable get tags => attachedDatabase.tags;
  $ItemTagRelTable get itemTagRel => attachedDatabase.itemTagRel;
  $BulletNoteTagRelTable get bulletNoteTagRel =>
      attachedDatabase.bulletNoteTagRel;
  $ItemsTable get items => attachedDatabase.items;
  TagsDaoManager get managers => TagsDaoManager(this);
}

class TagsDaoManager {
  final _$TagsDaoMixin _db;
  TagsDaoManager(this._db);
  $$TagsTableTableManager get tags =>
      $$TagsTableTableManager(_db.attachedDatabase, _db.tags);
  $$ItemTagRelTableTableManager get itemTagRel =>
      $$ItemTagRelTableTableManager(_db.attachedDatabase, _db.itemTagRel);
  $$BulletNoteTagRelTableTableManager get bulletNoteTagRel =>
      $$BulletNoteTagRelTableTableManager(
        _db.attachedDatabase,
        _db.bulletNoteTagRel,
      );
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db.attachedDatabase, _db.items);
}

mixin _$BackupRecordsDaoMixin on DatabaseAccessor<AppDatabase> {
  $BackupRecordsTable get backupRecords => attachedDatabase.backupRecords;
  BackupRecordsDaoManager get managers => BackupRecordsDaoManager(this);
}

class BackupRecordsDaoManager {
  final _$BackupRecordsDaoMixin _db;
  BackupRecordsDaoManager(this._db);
  $$BackupRecordsTableTableManager get backupRecords =>
      $$BackupRecordsTableTableManager(_db.attachedDatabase, _db.backupRecords);
}
