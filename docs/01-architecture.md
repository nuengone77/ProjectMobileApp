# 1. โครงสร้างระบบ (Architecture)

หน้าจอไม่คุยกับฐานข้อมูลโดยตรง แต่ผ่าน **Provider** (บทที่ 10–11) ซึ่งแยกตามฟีเจอร์ 4 ตัว
ทุกตัวใช้ข้อมูลกลาง `AppData` ร่วมกัน และ `AppData` บันทึกลง SQLite ผ่าน `AppDatabase`

```mermaid
flowchart TB
  subgraph screens["หน้าจอ (lib/screens/)"]
    auth["auth_screens.dart<br/>login · สมัคร · ขอความยินยอม"]
    student["student_screens.dart<br/>หน้าแรกนิสิต · เลือกหัวข้อ/ช่องทาง/พี่"]
    profile["profile_screen.dart"]
    chat["chat/<br/>หน้าแชท · บับเบิล · ไฟล์แนบ<br/>การ์ดฉุกเฉิน · สรุปการสนทนา"]
    appt["appointment/<br/>จองนัด · นัดของฉัน · นัดฝั่งเจ้าหน้าที่"]
    staff["staff_screens.dart<br/>แท็บเจ้าหน้าที่ · ภาพรวม"]
    report["report_screen.dart<br/>ตารางสรุปเคส"]
  end

  subgraph providers["Provider (lib/providers/) — รวมด้วย MultiProvider ใน app_providers.dart"]
    AP["AuthProvider<br/>ล็อกอิน · สมัคร · โปรไฟล์"]
    CP["ChatProvider<br/>แชท · ยังไม่อ่าน · จบการสนทนา"]
    APP["AppointmentProvider<br/>ขอนัด · ยืนยัน · เสนอเวลาใหม่"]
    RP["ReportProvider<br/>ตารางสรุปเคส"]
  end

  data["AppData (lib/data/app_data.dart)<br/>ข้อมูลกลางในหน่วยความจำ + ค่าคงที่ + ข้อมูลตั้งต้น"]
  db[("AppDatabase<br/>SQLite: kaiwan.db")]
  files[["assets/config/staff_accounts.json<br/>(บัญชีเจ้าหน้าที่ · ไม่ขึ้น git)"]]

  auth & profile --> AP
  student --> AP & CP & APP
  chat --> CP & AP
  appt --> APP & AP
  staff --> CP & APP & AP
  report --> RP & AP

  CP -. "ProxyProvider: รู้ว่าใครล็อกอิน" .-> AP
  APP -. ProxyProvider .-> AP
  RP -. ProxyProvider .-> AP
  CP -- "จบแชท -> syncChatReport" --> RP

  AP & CP & APP & RP --> data
  data -- "save... (คิวเขียน)" --> db
  files -. "StaffAccount.load()" .-> data
```

## วิธีที่หน้าจอใช้ Provider

| ที่ไหน | ใช้อะไร | ผล |
|---|---|---|
| ใน `build()` | `context.watch<ChatProvider>()` | ข้อมูลเปลี่ยน (`notifyListeners`) → หน้าจอวาดใหม่เอง |
| ในปุ่ม / คำสั่ง | `context.read<ChatProvider>().send(...)` | เรียกใช้อย่างเดียว ไม่ฟังการเปลี่ยนแปลง |
| Provider พึ่ง Provider | `ChangeNotifierProxyProvider` | ล็อกอินคนใหม่ → `update(auth)` → Provider นั้นแจ้งหน้าจอ |

## เส้นทางข้อมูลเมื่อกดปุ่ม (ตัวอย่าง: ส่งข้อความ)

```mermaid
sequenceDiagram
  actor U as ผู้ใช้
  participant S as ChatScreen
  participant C as ChatProvider
  participant D as AppData
  participant DB as AppDatabase (SQLite)
  U->>S: พิมพ์แล้วกดส่ง
  S->>C: context.read(ChatProvider).send(conv, text)
  C->>D: เพิ่ม Message ลงห้อง (conversations)
  C->>DB: data.db.saveConversation(conv) (เข้าคิวเขียน)
  C-->>S: notifyListeners()
  S->>S: context.watch เห็นการเปลี่ยนแปลง → วาดบับเบิลใหม่
```
