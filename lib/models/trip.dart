class Trip {
  final int? id;
  final String? uuid;
  final String? ownerId;
  final String? syncedAt;
  final bool isDirty;
  final String name;
  final double budget;
  final String baseCurrency;
  final String targetCurrency;
  final DateTime startDate;
  final DateTime endDate;
  final String? coverImagePath;
  final String? coverImageUrl;
  final DateTime createdAt;

  // Collaboration: set when loaded from Supabase/sync
  final String? memberRole; // 'owner' | 'editor' | 'viewer' | null (local)
  final int? memberCount;

  Trip({
    this.id,
    this.uuid,
    this.ownerId,
    this.syncedAt,
    this.isDirty = true,
    required this.name,
    required this.budget,
    required this.baseCurrency,
    required this.targetCurrency,
    required this.startDate,
    required this.endDate,
    this.coverImagePath,
    this.coverImageUrl,
    DateTime? createdAt,
    this.memberRole,
    this.memberCount,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isShared => memberRole != null && memberRole != 'owner';
  bool get canEdit =>
      memberRole == null || memberRole == 'owner' || memberRole == 'editor';

  int get totalDays => endDate.difference(startDate).inDays + 1;

  Trip copyWith({
    int? id,
    String? uuid,
    String? ownerId,
    String? syncedAt,
    bool? isDirty,
    String? name,
    double? budget,
    String? baseCurrency,
    String? targetCurrency,
    DateTime? startDate,
    DateTime? endDate,
    String? coverImagePath,
    String? coverImageUrl,
    DateTime? createdAt,
    String? memberRole,
    int? memberCount,
  }) {
    return Trip(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      ownerId: ownerId ?? this.ownerId,
      syncedAt: syncedAt ?? this.syncedAt,
      isDirty: isDirty ?? this.isDirty,
      name: name ?? this.name,
      budget: budget ?? this.budget,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      targetCurrency: targetCurrency ?? this.targetCurrency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdAt: createdAt ?? this.createdAt,
      memberRole: memberRole ?? this.memberRole,
      memberCount: memberCount ?? this.memberCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,
      'owner_id': ownerId,
      'synced_at': syncedAt,
      'is_dirty': isDirty ? 1 : 0,
      'name': name,
      'budget': budget,
      'base_currency': baseCurrency,
      'target_currency': targetCurrency,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'cover_image_path': coverImagePath,
      'cover_image_url': coverImageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] as int?,
      uuid: map['uuid'] as String?,
      ownerId: map['owner_id'] as String?,
      syncedAt: map['synced_at'] as String?,
      isDirty: (map['is_dirty'] as int? ?? 1) == 1,
      name: map['name'] as String,
      budget: (map['budget'] as num).toDouble(),
      baseCurrency: map['base_currency'] as String,
      targetCurrency: map['target_currency'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      coverImagePath: map['cover_image_path'] as String?,
      coverImageUrl: map['cover_image_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Build from Supabase response (with optional member role)
  factory Trip.fromSupabase(Map<String, dynamic> map,
      {String? memberRole, int? memberCount}) {
    return Trip(
      uuid: map['id'] as String,
      ownerId: map['owner_id'] as String?,
      isDirty: false,
      name: map['name'] as String,
      budget: (map['budget'] as num).toDouble(),
      baseCurrency: map['base_currency'] as String,
      targetCurrency: map['target_currency'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      coverImageUrl: map['cover_image_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      memberRole: memberRole,
      memberCount: memberCount,
    );
  }

  Map<String, dynamic> toSupabaseMap(String userId) {
    return {
      if (uuid != null) 'id': uuid,
      'owner_id': userId,
      'name': name,
      'budget': budget,
      'base_currency': baseCurrency,
      'target_currency': targetCurrency,
      'start_date': startDate.toIso8601String().substring(0, 10),
      'end_date': endDate.toIso8601String().substring(0, 10),
      'cover_image_url': coverImageUrl,
    };
  }
}
