# 7. Class Diagram (UML)

แสดงว่า class ไหนใช้ / ถือ / สืบทอด class ไหน (คล้าย ER Diagram แต่เป็นของโค้ด ไม่ใช่ตาราง)

วิธีอ่านลูกศร

| เส้น | ความหมาย | ตัวอย่าง |
|---|---|---|
| หัวสามเหลี่ยมโปร่ง | ฝั่งไม่มีหัว **สืบทอด** จากฝั่งที่มีหัว (`extends`) | `AuthProvider` → `ChangeNotifier` |
| ข้าวหลามตัดทึบ | ฝั่งข้าวหลามตัด **ถือ** อีกฝั่งไว้ข้างใน เป็นส่วนหนึ่งของมัน | `Conversation` ◆ `Message` |
| ข้าวหลามตัดโปร่ง | ฝั่งข้าวหลามตัด **เก็บรายการ** อีกฝั่งไว้ แต่อีกฝั่งอยู่แยกได้ | `AppData` ◇ `AppUser` |
| ลูกศรเส้นทึบ | ฝั่งต้นเส้น **มีตัวแปร** ชี้ไปฝั่งหัวลูกศร | `ChatProvider` มี `_auth` ชี้ไป `AuthProvider` |
| ลูกศรเส้นประ | ฝั่งต้นเส้น **เรียกใช้** ฝั่งหัวลูกศรชั่วคราว | หน้าจอเรียก `context.read<ChatProvider>()` |

ป้าย `<<Provider>>` `<<Model>>` `<<Screen>>` `<<enum>>` บอกชนิดของ class
`+` = public, `-` = private (ชื่อขึ้นต้นด้วย `_`), `$` = static

## ภาพรวมทั้งแอป

```mermaid
classDiagram
  direction TB
  class AppStartup {
    <<Screen · FutureBuilder>>
  }
  class AppProviders {
    <<MultiProvider>>
  }
  class RoleGate {
    <<Widget>>
  }
  class LoginScreen {
    <<Screen>>
  }
  class StudentShell {
    <<Screen · นิสิต>>
  }
  class StaffShell {
    <<Screen · เจ้าหน้าที่>>
  }
  class AuthProvider {
    <<ChangeNotifier · คนที่ 4>>
  }
  class ChatProvider {
    <<ChangeNotifier · คนที่ 2>>
  }
  class AppointmentProvider {
    <<ChangeNotifier · คนที่ 3>>
  }
  class ReportProvider {
    <<ChangeNotifier · คนที่ 1>>
  }
  class AppData {
    <<ข้อมูลกลาง · คนที่ 1>>
  }
  class AppDatabase {
    <<SQLite · คนที่ 1>>
  }
  class StaffAccount {
    <<JSON>>
  }
  class AppUser {
    <<Model>>
  }
  class Conversation {
    <<Model>>
  }
  class Message {
    <<Model>>
  }
  class Appointment {
    <<Model>>
  }
  class CaseReport {
    <<Model>>
  }

  AppStartup --> AppProviders : โหลดเสร็จแล้วสร้าง
  AppProviders *-- AuthProvider
  AppProviders *-- ReportProvider
  AppProviders *-- ChatProvider
  AppProviders *-- AppointmentProvider
  AppProviders --> RoleGate : child
  RoleGate ..> LoginScreen : ยังไม่ล็อกอิน
  RoleGate ..> StudentShell : นิสิต
  RoleGate ..> StaffShell : เจ้าหน้าที่

  ChatProvider --> AuthProvider : ใครล็อกอิน
  ChatProvider --> ReportProvider : จบแชท → สรุปเคส
  AppointmentProvider --> AuthProvider
  ReportProvider --> AuthProvider

  AuthProvider --> AppData
  ChatProvider --> AppData
  AppointmentProvider --> AppData
  ReportProvider --> AppData
  AppData *-- AppDatabase : บันทึกลง SQLite
  AppData o-- StaffAccount
  AppData o-- AppUser
  AppData o-- Conversation
  AppData o-- Appointment
  AppData o-- CaseReport
  Conversation *-- Message
```

สรุปเป็นชั้น ๆ: **หน้าจอ** → อ่าน/สั่ง **Provider** → Provider แก้ **AppData** (ข้อมูลใน memory) → AppData สั่ง **AppDatabase** บันทึกลง SQLite
Provider ทั้ง 4 ตัว `extends ChangeNotifier` (ป้ายบนกล่อง) เมื่อข้อมูลเปลี่ยนจะเรียก `notifyListeners()` หน้าจอที่ `context.watch` อยู่จึงวาดใหม่
หน้าจอทุกหน้าใต้ `StudentShell` / `StaffShell` เรียก Provider ด้วย `context.watch` / `context.read` (ไม่ได้วาดเส้นไว้ในภาพนี้ เพื่อไม่ให้ภาพรก ดูได้ในภาพแยกของแต่ละคน)

---

## คนที่ 1 · โครงสร้าง + ฐานข้อมูล + ตารางสรุปเคส

```mermaid
classDiagram
  direction LR
  class AppStartup {
    <<Screen>>
    +load() Future~AppData~
    -_retry() void
  }
  class AppProviders {
    <<Widget>>
    +AppData data
    +build() MultiProvider
  }
  class StaffAccount {
    <<JSON>>
    +String email
    +String password
    +String name
    +String nickname
    +fromJson(json)$ StaffAccount
    +load(bundle)$ Future~List~
    +samples$
  }
  class AppData {
    <<ข้อมูลกลาง>>
    +AppDatabase db
    +List~AppUser~ users
    +List~Conversation~ conversations
    +List~Appointment~ appointments
    +List~CaseReport~ reports
    +String savedUserId
    +open(staffAccounts)$ Future~AppData~
    +saveAll() void
    +resetData() void
    +newId(prefix) String
    +syncChatReport(conv) void
    +categories$
    +emergencyPhone$
  }
  class AppDatabase {
    <<SQLite v3>>
    -Database _db
    -Future _queue
    +onWriteError
    +open()$ Future~AppDatabase~
    +loadAll() Future
    +saveUser(u) void
    +saveConversation(c) void
    +saveAppointment(a) void
    +saveReport(r) void
    +deleteReport(id) void
    +setSetting(key, value) void
    +clearAll() void
    -_enqueue(op) void
  }
  class ReportProvider {
    <<Provider>>
    -AuthProvider _auth
    +update(auth) void
    +syncChatReport(conv) void
    +myReports(...) List~CaseReport~
    +studentByIdNo(idNo) AppUser
    +addOnsiteReport(...) CaseReport
    +updateReport(...) void
    +deleteReport(r) void
  }
  class CaseReport {
    <<Model>>
    +String id
    +String staffId
    +String conversationId
    +DateTime date
    +String studentIdNo
    +String studentName
    +ConsultChannel channel
    +String categoryId
    +String topic
    +String advice
    +CaseLevel level
    +bool edited
    +bool isManual
  }
  class ConsultChannel {
    <<enum>>
    online
    onsite
  }
  class StaffReportScreen {
    <<Screen>>
  }
  class ReportExport {
    <<Helper>>
    +buildCsv(rows)$ String
    +buildPdf(...)$ Future
  }
  class AuthProvider {
    <<Provider · คนที่ 4>>
  }

  AppStartup ..> StaffAccount : อ่านไฟล์ JSON
  AppStartup ..> AppData : open()
  AppStartup --> AppProviders
  AppData o-- StaffAccount : สร้างบัญชีเจ้าหน้าที่
  AppData *-- AppDatabase
  AppData o-- CaseReport
  AppProviders *-- ReportProvider
  ReportProvider --> AppData
  ReportProvider --> AuthProvider : ใครล็อกอิน
  CaseReport --> ConsultChannel
  StaffReportScreen ..> ReportProvider : context.watch / read
  StaffReportScreen ..> ReportExport : ส่งออก CSV / PDF
```

## คนที่ 2 · แชท (เร่งด่วน + ทั่วไป)

```mermaid
classDiagram
  direction LR
  class ChatProvider {
    <<Provider>>
    -AuthProvider _auth
    +ReportProvider reports
    +update(auth, reports) void
    +myConversations() List~Conversation~
    +openConversation(categoryId, staffId) Conversation
    +send(conv, text) void
    +sendAttachment(...) void
    -_post(conv, msg) void
    +markRead(conv) void
    +closeConversation(...) void
    +saveSummary(...) void
    +staffConversations(...) List~Conversation~
    +hasStudentMessage(conv) bool
    +unreadForStudent(conv) int
    +unreadForStaff(conv) int
  }
  class Conversation {
    <<Model>>
    +String id
    +String studentId
    +String categoryId
    +bool isSpecific
    +String staffId
    +List~Message~ messages
    +int studentReadCount
    +int staffReadCount
    +bool closed
    +String summaryTopic
    +String summaryHelp
    +CaseLevel caseLevel
    +hasSummary bool
  }
  class Message {
    <<Model>>
    +String senderId
    +String text
    +DateTime time
    +bool isSystem
    +bool isAlert
    +String attachment
    +bool isImage
    +preview String
  }
  class ConsultCategory {
    <<Model>>
    +String id
    +String title
    +bool urgent
  }
  class CaseLevel {
    <<enum>>
    small
    medium
    large
  }
  class Attachments {
    <<Helper>>
    +init(path)$ Future
    +import(sourcePath)$ Future~String~
    +pathOf(fileName)$ String
  }
  class ChatScreen {
    <<Screen>>
  }
  class MessageBubble {
    <<Widget>>
  }
  class MessageComposer {
    <<Widget>>
  }
  class EmergencyCard {
    <<Widget>>
  }
  class SummarySheet {
    <<Screen>>
  }
  class ImageAttachment {
    <<Widget>>
  }
  class FileAttachment {
    <<Widget>>
  }
  class MyChatsScreen {
    <<Screen · นิสิต>>
  }
  class StaffConversationsScreen {
    <<Screen · เจ้าหน้าที่>>
  }
  class ConversationTile {
    <<Widget>>
  }
  class AuthProvider {
    <<Provider · คนที่ 4>>
  }
  class ReportProvider {
    <<Provider · คนที่ 1>>
  }
  class AppData {
    <<ข้อมูลกลาง · คนที่ 1>>
  }

  ChatProvider --> AuthProvider : ใครล็อกอิน
  ChatProvider --> ReportProvider : จบแชท → syncChatReport()
  ChatProvider --> AppData
  AppData o-- Conversation
  Conversation *-- Message
  Conversation --> CaseLevel
  Conversation ..> ConsultCategory : categoryId
  Message ..> Attachments : ไฟล์แนบ

  ChatScreen ..> ChatProvider : context.watch / read
  ChatScreen *-- MessageBubble
  ChatScreen *-- MessageComposer
  ChatScreen *-- EmergencyCard : แชทเร่งด่วน
  ChatScreen ..> SummarySheet : เจ้าหน้าที่กดจบ
  ChatScreen ..> Attachments : เลือกรูป/ไฟล์
  MessageBubble *-- ImageAttachment
  MessageBubble *-- FileAttachment
  MyChatsScreen *-- ConversationTile
  StaffConversationsScreen *-- ConversationTile
  MyChatsScreen ..> ChatProvider
  StaffConversationsScreen ..> ChatProvider
  ConversationTile ..> ChatScreen : กดเปิดห้อง
```

## คนที่ 3 · นัดหมาย + หน้าหลักเจ้าหน้าที่

```mermaid
classDiagram
  direction LR
  class AppointmentProvider {
    <<Provider>>
    -AuthProvider _auth
    +update(auth) void
    +requestAppointment(...) Appointment
    +myAppointments() List~Appointment~
    +cancelAppointment(a) void
    +markAppointmentsSeen() void
    +staffAppointments(status) List~Appointment~
    +confirmAppointment(a) void
    +proposeAppointmentTime(...) void
    +acceptProposedTime(a) void
    +conflictsOf(a) List~Appointment~
    -_visibleToStaff(a, me) bool
    +pendingAppointmentCount int
    +studentAppointmentUpdates int
  }
  class Appointment {
    <<Model>>
    +String id
    +String studentId
    +DateTime start
    +String note
    +AppointmentStatus status
    +String staffId
    +String requestedStaffId
    +DateTime proposedStart
    +String staffMessage
    +bool seenByStudent
    +duration$ 30 นาที
    +end DateTime
  }
  class AppointmentStatus {
    <<enum>>
    pending
    confirmed
    proposed
    cancelled
  }
  class AppData {
    <<ข้อมูลกลาง · คนที่ 1>>
    +List~Appointment~ appointments
    +isOfficeDay(d)$ bool
    +slotsOf(day)$ List~DateTime~
    +isBookable(start)$ bool
  }
  class AuthProvider {
    <<Provider · คนที่ 4>>
  }
  class AppointmentBookingScreen {
    <<Screen · นิสิต>>
  }
  class SlotDropdown {
    <<Widget>>
  }
  class OfficeInfoCard {
    <<Widget>>
  }
  class MyAppointmentsScreen {
    <<Screen · นิสิต>>
  }
  class StaffAppointmentsScreen {
    <<Screen · เจ้าหน้าที่>>
  }
  class ProposeTimeSheet {
    <<Screen>>
  }
  class AppointmentCard {
    <<Widget>>
  }
  class StatusChip {
    <<Widget>>
  }
  class StaffShell {
    <<Screen>>
  }
  class StaffHome {
    <<Screen>>
  }

  AppointmentProvider --> AuthProvider : ใครล็อกอิน
  AppointmentProvider --> AppData
  AppData o-- Appointment
  Appointment --> AppointmentStatus

  AppointmentBookingScreen ..> AppointmentProvider : requestAppointment()
  AppointmentBookingScreen *-- SlotDropdown
  AppointmentBookingScreen *-- OfficeInfoCard
  SlotDropdown ..> AppData : slotsOf()
  AppointmentBookingScreen ..> MyAppointmentsScreen : จองเสร็จ
  MyAppointmentsScreen ..> AppointmentProvider
  MyAppointmentsScreen *-- AppointmentCard
  StaffAppointmentsScreen ..> AppointmentProvider
  StaffAppointmentsScreen *-- AppointmentCard
  StaffAppointmentsScreen ..> ProposeTimeSheet : เสนอเวลาอื่น
  AppointmentCard *-- StatusChip
  StaffShell *-- StaffAppointmentsScreen : แท็บนัดหมาย
  StaffShell *-- StaffHome : แท็บภาพรวม
```

## คนที่ 4 · สมัคร · ล็อกอิน · โปรไฟล์ · หน้าแรกนิสิต

```mermaid
classDiagram
  direction LR
  class AuthProvider {
    <<Provider>>
    +AppData data
    +AppUser currentUser
    +login(email, password) String
    +register(...) String
    +logout() void
    +updateMyProfile(phone, major) String
    +staff List~AppUser~
    +user(id) AppUser
  }
  class AppUser {
    <<Model>>
    +String id
    +String email
    +String passwordHash
    +String name
    +Role role
    +String studentId
    +String nameEn
    +String major
    +String phone
    +String nickname
    +isStaff bool
    +displayName String
  }
  class Role {
    <<enum>>
    student
    staff
  }
  class RegistrationRules {
    <<Helper>>
    +emailDomain$
    +studentIdError(input)$ String
    +nameEnError(input)$ String
    +emailError(...)$ String
    +parseNameEn(input)$
  }
  class passwords {
    <<function>>
    +hashPassword(email, password) String
  }
  class AppData {
    <<ข้อมูลกลาง · คนที่ 1>>
  }
  class RoleGate {
    <<Widget · main.dart>>
  }
  class LoginScreen {
    <<Screen>>
  }
  class SignUpScreen {
    <<Screen>>
  }
  class LicenseAgreementDialog {
    <<Screen>>
  }
  class UnsavedChangesGuard {
    <<Widget · PopScope>>
  }
  class ProfileScreen {
    <<Screen>>
  }
  class StudentShell {
    <<Screen>>
  }
  class StudentHome {
    <<Screen>>
  }
  class ConsultChannelScreen {
    <<Screen>>
  }
  class ConsultModeScreen {
    <<Screen>>
  }
  class StaffPickerScreen {
    <<Screen>>
  }

  AuthProvider --> AppData
  AuthProvider --> AppUser : currentUser
  AppData o-- AppUser
  AppUser --> Role
  AuthProvider ..> RegistrationRules : ตรวจซ้ำตอน register
  AuthProvider ..> passwords : hash รหัสผ่าน

  RoleGate ..> AuthProvider : context.watch
  RoleGate ..> LoginScreen
  RoleGate ..> StudentShell
  LoginScreen ..> AuthProvider : login()
  LoginScreen ..> SignUpScreen : สมัครสมาชิก
  SignUpScreen ..> RegistrationRules : validator
  SignUpScreen *-- UnsavedChangesGuard
  SignUpScreen ..> LicenseAgreementDialog : ก่อนสมัคร
  SignUpScreen ..> AuthProvider : register()
  ProfileScreen ..> AuthProvider : updateMyProfile() / logout()

  StudentShell *-- StudentHome : แท็บหน้าแรก
  StudentShell *-- ProfileScreen : แท็บโปรไฟล์
  StudentHome ..> ConsultChannelScreen : ทั่วไป
  ConsultChannelScreen ..> ConsultModeScreen
  ConsultModeScreen ..> StaffPickerScreen : เลือกพี่เอง
```

หมายเหตุ: `RoleGate` ในโค้ดชื่อ `_RoleGate` (private ใน `main.dart`) และ `passwords` เป็นไฟล์ `passwords.dart` ที่มีฟังก์ชัน `hashPassword()` ไม่ใช่ class
แต่ละภาพแสดง class ของคนอื่นแค่ชื่อพร้อมป้าย “คนที่ x” เพื่อให้เห็นว่าส่วนของตัวเองต่อกับส่วนไหน
