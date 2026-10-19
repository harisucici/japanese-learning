import 'enums.dart';

/// User 模型 - 账号系统
///
/// 字段: id, email, name, currentLevel, targetLevel, createdAt
class User {
  /// 用户唯一 ID (UUID)
  final String id;

  /// 邮箱（登录凭证）
  final String email;

  /// 用户名/昵称
  final String name;

  /// 当前等级
  final JLPTLevel currentLevel;

  /// 目标等级
  final JLPTLevel targetLevel;

  /// 创建时间
  final DateTime createdAt;

  /// 头像 URL（可选）
  final String? avatarUrl;

  /// 连续学习天数
  final int streakDays;

  /// 总刷题数
  final int totalQuestions;

  /// 正确率（0.0 - 1.0）
  final double accuracy;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.currentLevel = JLPTLevel.n5,
    this.targetLevel = JLPTLevel.n5,
    DateTime? createdAt,
    this.avatarUrl,
    this.streakDays = 0,
    this.totalQuestions = 0,
    this.accuracy = 0.0,
  }) : createdAt = createdAt ?? const _EpochDateTime();

  /// 从 JSON 构造
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      currentLevel: JLPTLevel.fromString(json['currentLevel'] as String?),
      targetLevel: JLPTLevel.fromString(json['targetLevel'] as String?),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      avatarUrl: json['avatarUrl'] as String?,
      streakDays: (json['streakDays'] as int?) ?? 0,
      totalQuestions: (json['totalQuestions'] as int?) ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'currentLevel': currentLevel.name,
      'targetLevel': targetLevel.name,
      'createdAt': createdAt.toIso8601String(),
      'avatarUrl': avatarUrl,
      'streakDays': streakDays,
      'totalQuestions': totalQuestions,
      'accuracy': accuracy,
    };
  }

  /// 复制并修改
  User copyWith({
    String? id,
    String? email,
    String? name,
    JLPTLevel? currentLevel,
    JLPTLevel? targetLevel,
    DateTime? createdAt,
    String? avatarUrl,
    int? streakDays,
    int? totalQuestions,
    double? accuracy,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      currentLevel: currentLevel ?? this.currentLevel,
      targetLevel: targetLevel ?? this.targetLevel,
      createdAt: createdAt ?? this.createdAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      streakDays: streakDays ?? this.streakDays,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      accuracy: accuracy ?? this.accuracy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is User && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'User(id: $id, email: $email, name: $name)';
}

/// 一个 trick 类，用于 const 构造中的默认 DateTime.now()
class _EpochDateTime implements DateTime {
  const _EpochDateTime();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
