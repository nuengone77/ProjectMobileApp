import 'package:flutter/material.dart';

enum Role { student, staff }

class AppUser {
  AppUser({
    required this.id,
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    this.major = '',
    this.nickname = '',
    this.specialty = '',
    this.avatarColor = const Color(0xFFB9D7E8),
    this.online = true,
  });

  final String id;
  final String email;
  final String password;
  final String name;
  final Role role;
  final String major;
  final String nickname;
  final String specialty;
  final Color avatarColor;
  final bool online;

  bool get isStaff => role == Role.staff;
  String get displayName => isStaff ? 'พี่ไข่หวาน $nickname' : name;
}

class ConsultCategory {
  const ConsultCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.subtopics,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> subtopics;
}

class Message {
  Message({
    required this.senderId,
    required this.text,
    DateTime? time,
    this.isSystem = false,
  }) : time = time ?? DateTime.now();

  final String senderId;
  final String text;
  final DateTime time;
  final bool isSystem;
}

class Conversation {
  Conversation({
    required this.id,
    required this.studentId,
    required this.categoryId,
    required this.subtopic,
    required this.isSpecific,
    this.staffId,
    List<Message>? messages,
  }) : messages = messages ?? [];

  final String id;
  final String studentId;
  final String categoryId;
  final String subtopic;

  /// true = ปรึกษาแบบเลือกเจ้าหน้าที่เฉพาะเจาะจง (ส่วนตัว)
  /// false = เจ้าหน้าที่คนไหนก็ได้ (ส่วนรวม)
  final bool isSpecific;

  /// For specific chats this is the chosen staff; for "any" chats it's the
  /// staff who picked it up first (null until someone replies).
  String? staffId;
  final List<Message> messages;

  /// Index of the last message each side has read.
  int studentReadCount = 0;
  int staffReadCount = 0;
  bool closed = false;

  Message? get last => messages.isEmpty ? null : messages.last;
}

class Report {
  Report({
    required this.conversationId,
    required this.reporterId,
    required this.reason,
    this.detail = '',
    DateTime? time,
  }) : time = time ?? DateTime.now();

  final String conversationId;
  final String reporterId;
  final String reason;
  final String detail;
  final DateTime time;
}
