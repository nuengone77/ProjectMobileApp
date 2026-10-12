// ฐานข้อมูล SQLite ในเครื่อง (เก็บข้อมูลไม่ให้หายตอนปิดแอป)
//
// ตาราง:
//   users          ผู้ใช้ (นักศึกษา + เจ้าหน้าที่) เก็บรหัสผ่านเป็น hash
//   conversations  ห้องแชท + สรุปการปรึกษา/ระดับเคส
//   messages       ข้อความในแชท (เรียงตาม seq)
//   appointments   นัดหมายที่ห้องกิจการนิสิต
//   settings       ค่าตั้งค่า เช่น ผู้ที่ล็อกอินค้างไว้
//   case_reports   ตารางสรุปเคสของเจ้าหน้าที่ (สำเนาแยกจากแชท แก้แล้วไม่กระทบแชท) [เวอร์ชัน 2]
//   (เวอร์ชัน 3: messages เพิ่มคอลัมน์ไฟล์แนบ attachment / attachment_name / is_image)
//
// วิธีใช้ร่วมกับ AppData: ตอนเปิดแอปโหลดทั้งหมดขึ้นหน่วยความจำ ([loadAll])
// แล้วทุกครั้งที่ข้อมูลเปลี่ยน Provider จะเรียก save... ให้เขียนลงฐานข้อมูลทันที
// การเขียนทำเรียงคิว (ทีละคำสั่ง ตามลำดับ) จึงไม่ต้องรอใน UI
//
// หมายเหตุ: SQLite เก็บเฉพาะในเครื่องนี้ แชทข้ามเครื่องต้องมี server ภายหลัง
import 'package:flutter/material.dart' show Color;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models.dart';

class AppDatabase {
  AppDatabase._(this._db);

  final Database _db;

  /// คิวการเขียน: ทุกคำสั่งต่อท้ายคิว ทำทีละคำสั่งตามลำดับที่เรียก
  Future<void> _queue = Future.value();

  /// จำนวนข้อความของแต่ละห้องที่บันทึกลงฐานข้อมูลแล้ว (ใช้เพิ่มเฉพาะข้อความใหม่)
  final Map<String, int> _savedMessages = {};

  static const _fileName = 'kaiwan.db';

  /// เปิดฐานข้อมูล
  /// [factory]/[path] ใช้ตอนทดสอบ (เช่น ฐานข้อมูลในหน่วยความจำ) ปกติไม่ต้องส่ง
  static Future<AppDatabase> open({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final f = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await f.getDatabasesPath(), _fileName);
    final db = await f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 3,
        singleInstance: false,
        onCreate: (db, version) async {
          await _createTables(db);
          await _createReportTable(db);
          await _addAttachmentColumns(db);
        },
        // เครื่องที่มีฐานข้อมูลเวอร์ชันเก่า: เพิ่มตารางใหม่โดยไม่ลบข้อมูลเดิม
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) await _createReportTable(db);
          if (oldVersion < 3) await _addAttachmentColumns(db);
        },
      ),
    );
    return AppDatabase._(db);
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        major TEXT NOT NULL DEFAULT '',
        student_id TEXT NOT NULL DEFAULT '',
        name_en TEXT NOT NULL DEFAULT '',
        phone TEXT NOT NULL DEFAULT '',
        nickname TEXT NOT NULL DEFAULT '',
        specialty TEXT NOT NULL DEFAULT '', -- เลิกใช้แล้ว (เคยเก็บความเชี่ยวชาญ) คงคอลัมน์ไว้ให้เข้ากับฐานข้อมูลเดิม
        avatar_color INTEGER NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        is_specific INTEGER NOT NULL,
        staff_id TEXT,
        student_read INTEGER NOT NULL DEFAULT 0,
        staff_read INTEGER NOT NULL DEFAULT 0,
        closed INTEGER NOT NULL DEFAULT 0,
        closed_at INTEGER,
        closed_by TEXT,
        summary_topic TEXT NOT NULL DEFAULT '',
        summary_help TEXT NOT NULL DEFAULT '',
        case_level TEXT
      )''');
    await db.execute('''
      CREATE TABLE messages (
        conversation_id TEXT NOT NULL,
        seq INTEGER NOT NULL,
        sender_id TEXT NOT NULL,
        text TEXT NOT NULL,
        time INTEGER NOT NULL,
        is_system INTEGER NOT NULL DEFAULT 0,
        is_alert INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (conversation_id, seq)
      )''');
    await db.execute('''
      CREATE TABLE appointments (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        start INTEGER NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL,
        staff_id TEXT,
        requested_staff_id TEXT,
        proposed_start INTEGER,
        staff_message TEXT NOT NULL DEFAULT '',
        seen_by_student INTEGER NOT NULL DEFAULT 1
      )''');
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )''');
  }

  static Future<void> _createReportTable(Database db) => db.execute('''
      CREATE TABLE case_reports (
        id TEXT PRIMARY KEY,
        staff_id TEXT NOT NULL,
        conversation_id TEXT UNIQUE,
        date INTEGER NOT NULL,
        student_id_no TEXT NOT NULL,
        student_name TEXT NOT NULL,
        category_id TEXT NOT NULL,
        channel TEXT NOT NULL,
        topic TEXT NOT NULL DEFAULT '',
        advice TEXT NOT NULL DEFAULT '',
        level TEXT,
        edited INTEGER NOT NULL DEFAULT 0
      )''');

  /// คอลัมน์ไฟล์แนบของข้อความ [เวอร์ชัน 3]
  static Future<void> _addAttachmentColumns(Database db) async {
    await db.execute('ALTER TABLE messages ADD COLUMN attachment TEXT');
    await db.execute('ALTER TABLE messages ADD COLUMN attachment_name TEXT');
    await db.execute(
      'ALTER TABLE messages ADD COLUMN is_image INTEGER NOT NULL DEFAULT 0',
    );
  }

  /// ถูกเรียกเมื่อเขียนลงฐานข้อมูลไม่สำเร็จ (AppData ส่งต่อให้หน้าจอแจ้งผู้ใช้)
  void Function(Object error)? onWriteError;

  /// เพิ่มคำสั่งเขียนต่อท้ายคิว
  /// ถ้าเขียนไม่สำเร็จ: พิมพ์ลง log + แจ้ง [onWriteError] และคิวยังทำงานต่อได้ (แอปไม่ค้าง)
  void _enqueue(Future<void> Function() op) {
    _queue = _queue.then((_) => op()).catchError((Object e) {
      // ignore: avoid_print
      print('AppDatabase write failed: $e');
      onWriteError?.call(e);
    });
  }

  /// รอให้คำสั่งเขียนที่ค้างในคิวเสร็จทั้งหมด (ใช้ตอนทดสอบ/ก่อนปิดแอป)
  Future<void> flush() => _queue;

  Future<void> close() async {
    await flush();
    await _db.close();
  }

  // ---------------------------------------------------------------- read

  /// ฐานข้อมูลยังว่างอยู่ไหม (เปิดแอปครั้งแรก -> ต้องใส่ข้อมูลตั้งต้น)
  Future<bool> isEmpty() async =>
      Sqflite.firstIntValue(await _db.rawQuery('SELECT COUNT(*) FROM users')) ==
      0;

  /// โหลดข้อมูลทั้งหมดขึ้นหน่วยความจำ
  Future<
    ({
      List<AppUser> users,
      List<Conversation> conversations,
      List<Appointment> appointments,
      Map<String, String?> settings,
      List<CaseReport> reports,
    })
  >
  loadAll() async {
    final users = [
      for (final r in await _db.query('users', orderBy: 'rowid')) _userFrom(r),
    ];

    final convs = <Conversation>[];
    for (final r in await _db.query('conversations', orderBy: 'rowid')) {
      final id = r['id'] as String;
      final msgs = await _db.query(
        'messages',
        where: 'conversation_id = ?',
        whereArgs: [id],
        orderBy: 'seq',
      );
      final c =
          Conversation(
              id: id,
              studentId: r['student_id'] as String,
              categoryId: r['category_id'] as String,
              isSpecific: r['is_specific'] == 1,
              staffId: r['staff_id'] as String?,
              messages: [for (final m in msgs) _messageFrom(m)],
            )
            ..studentReadCount = r['student_read'] as int
            ..staffReadCount = r['staff_read'] as int
            ..closed = r['closed'] == 1
            ..closedAt = _dateOrNull(r['closed_at'])
            ..closedById = r['closed_by'] as String?
            ..summaryTopic = r['summary_topic'] as String
            ..summaryHelp = r['summary_help'] as String
            ..caseLevel = _enumOrNull(CaseLevel.values, r['case_level']);
      _savedMessages[id] = c.messages.length;
      convs.add(c);
    }

    final appts = [
      for (final r in await _db.query('appointments', orderBy: 'rowid'))
        Appointment(
            id: r['id'] as String,
            studentId: r['student_id'] as String,
            start: _date(r['start']),
            note: r['note'] as String,
            status: AppointmentStatus.values.byName(r['status'] as String),
            staffId: r['staff_id'] as String?,
            requestedStaffId: r['requested_staff_id'] as String?,
          )
          ..proposedStart = _dateOrNull(r['proposed_start'])
          ..staffMessage = r['staff_message'] as String
          ..seenByStudent = r['seen_by_student'] == 1,
    ];

    final settings = {
      for (final r in await _db.query('settings'))
        r['key'] as String: r['value'] as String?,
    };

    final reports = [
      for (final r in await _db.query('case_reports', orderBy: 'date'))
        CaseReport(
          id: r['id'] as String,
          staffId: r['staff_id'] as String,
          conversationId: r['conversation_id'] as String?,
          date: _date(r['date']),
          studentIdNo: r['student_id_no'] as String,
          studentName: r['student_name'] as String,
          categoryId: r['category_id'] as String,
          channel: ConsultChannel.values.byName(r['channel'] as String),
          topic: r['topic'] as String,
          advice: r['advice'] as String,
          level: _enumOrNull(CaseLevel.values, r['level']),
          edited: r['edited'] == 1,
        ),
    ];

    return (
      users: users,
      conversations: convs,
      appointments: appts,
      settings: settings,
      reports: reports,
    );
  }

  // ---------------------------------------------------------------- write

  void saveUser(AppUser u) => _enqueue(
    () => _db.insert('users', {
      'id': u.id,
      'email': u.email,
      'password_hash': u.passwordHash,
      'name': u.name,
      'role': u.role.name,
      'major': u.major,
      'student_id': u.studentId,
      'name_en': u.nameEn,
      'phone': u.phone,
      'nickname': u.nickname,
      'avatar_color': u.avatarColor.toARGB32(),
    }, conflictAlgorithm: ConflictAlgorithm.replace),
  );

  /// บันทึกห้องแชท (ข้อมูลห้อง + ข้อความใหม่ที่ยังไม่เคยบันทึก)
  void saveConversation(Conversation c) {
    final row = {
      'id': c.id,
      'student_id': c.studentId,
      'category_id': c.categoryId,
      'is_specific': c.isSpecific ? 1 : 0,
      'staff_id': c.staffId,
      'student_read': c.studentReadCount,
      'staff_read': c.staffReadCount,
      'closed': c.closed ? 1 : 0,
      'closed_at': c.closedAt?.millisecondsSinceEpoch,
      'closed_by': c.closedById,
      'summary_topic': c.summaryTopic,
      'summary_help': c.summaryHelp,
      'case_level': c.caseLevel?.name,
    };
    // คัดเฉพาะข้อความที่เพิ่มมาใหม่ตั้งแต่บันทึกครั้งก่อน
    final from = _savedMessages[c.id] ?? 0;
    final newMessages = [
      for (var i = from; i < c.messages.length; i++) (i, c.messages[i]),
    ];
    _savedMessages[c.id] = c.messages.length;
    _enqueue(
      () => _db.transaction((txn) async {
        await txn.insert(
          'conversations',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        for (final (seq, m) in newMessages) {
          await txn.insert('messages', {
            'conversation_id': c.id,
            'seq': seq,
            'sender_id': m.senderId,
            'text': m.text,
            'time': m.time.millisecondsSinceEpoch,
            'is_system': m.isSystem ? 1 : 0,
            'is_alert': m.isAlert ? 1 : 0,
            'attachment': m.attachment,
            'attachment_name': m.attachmentName,
            'is_image': m.isImage ? 1 : 0,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }),
    );
  }

  void saveAppointment(Appointment a) => _enqueue(
    () => _db.insert('appointments', {
      'id': a.id,
      'student_id': a.studentId,
      'start': a.start.millisecondsSinceEpoch,
      'note': a.note,
      'status': a.status.name,
      'staff_id': a.staffId,
      'requested_staff_id': a.requestedStaffId,
      'proposed_start': a.proposedStart?.millisecondsSinceEpoch,
      'staff_message': a.staffMessage,
      'seen_by_student': a.seenByStudent ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace),
  );

  void saveReport(CaseReport r) => _enqueue(
    () => _db.insert('case_reports', {
      'id': r.id,
      'staff_id': r.staffId,
      'conversation_id': r.conversationId,
      'date': r.date.millisecondsSinceEpoch,
      'student_id_no': r.studentIdNo,
      'student_name': r.studentName,
      'category_id': r.categoryId,
      'channel': r.channel.name,
      'topic': r.topic,
      'advice': r.advice,
      'level': r.level?.name,
      'edited': r.edited ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace),
  );

  void deleteReport(String id) => _enqueue(
    () => _db.delete('case_reports', where: 'id = ?', whereArgs: [id]),
  );

  /// เก็บค่าตั้งค่า (value = null คือลบ)
  void setSetting(String key, String? value) => _enqueue(
    () => value == null
        ? _db.delete('settings', where: 'key = ?', whereArgs: [key])
        : _db.insert('settings', {
            'key': key,
            'value': value,
          }, conflictAlgorithm: ConflictAlgorithm.replace),
  );

  /// ลบข้อมูลทั้งหมด (ใช้ตอนรีเซ็ตข้อมูล)
  void clearAll() {
    _savedMessages.clear();
    _enqueue(
      () => _db.transaction((txn) async {
        for (final t in [
          'case_reports',
          'messages',
          'conversations',
          'appointments',
          'users',
          'settings',
        ]) {
          await txn.delete(t);
        }
      }),
    );
  }

  // ---------------------------------------------------------------- mapping

  static AppUser _userFrom(Map<String, Object?> r) => AppUser(
    id: r['id'] as String,
    email: r['email'] as String,
    passwordHash: r['password_hash'] as String,
    name: r['name'] as String,
    role: Role.values.byName(r['role'] as String),
    major: r['major'] as String,
    studentId: r['student_id'] as String,
    nameEn: r['name_en'] as String,
    phone: r['phone'] as String,
    nickname: r['nickname'] as String,
    avatarColor: Color(r['avatar_color'] as int),
  );

  static Message _messageFrom(Map<String, Object?> r) => Message(
    senderId: r['sender_id'] as String,
    text: r['text'] as String,
    time: _date(r['time']),
    isSystem: r['is_system'] == 1,
    isAlert: r['is_alert'] == 1,
    attachment: r['attachment'] as String?,
    attachmentName: r['attachment_name'] as String?,
    isImage: r['is_image'] == 1,
  );

  static DateTime _date(Object? v) =>
      DateTime.fromMillisecondsSinceEpoch(v as int);
  static DateTime? _dateOrNull(Object? v) => v == null ? null : _date(v);
  static T? _enumOrNull<T extends Enum>(List<T> values, Object? name) =>
      name == null ? null : values.byName(name as String);
}
