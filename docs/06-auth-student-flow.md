# 6. Flowchart สมัคร/ล็อกอิน + หน้าแรกนิสิต

ไฟล์หลัก: `lib/screens/auth_screens.dart`, `lib/data/registration_rules.dart`, `lib/providers/auth_provider.dart`,
`lib/screens/student_screens.dart`, `lib/screens/profile_screen.dart`

## สมัครสมาชิก

```mermaid
flowchart TD
  A([หน้า Login]) -- "สมัครสมาชิก (sign in)" --> B[หน้าสมัคร: กรอกฟอร์ม]
  B --> P{"กดย้อนกลับ?"}
  P -- "กรอกแล้ว" --> P1["PopScope ถาม “ทิ้งข้อมูลที่กรอกไว้ไหม?”<br/>(UnsavedChangesGuard)"]
  B -- "กด sign in" --> V{"validator ทุกช่อง (บทที่ 8)"}
  V -- ผิด --> V1["แสดงข้อความใต้ช่องทีละจุด"]
  V1 --> B
  V -- ผ่าน --> T["หน้าขอความยินยอม<br/>(LicenseAgreementDialog)"]
  T -- ปฏิเสธ --> B
  T -- ยอมรับและดำเนินการต่อ --> R["AuthProvider.register()<br/>ตรวจกฎซ้ำ + อีเมล/รหัสนิสิตซ้ำ"]
  R -- error --> B
  R -- สำเร็จ --> H["hash รหัสผ่าน (sha256) → บันทึก users<br/>ล็อกอินให้ทันที"]
  H --> SH([StudentShell หน้าแรกนิสิต])
```

### ลำดับการตรวจอีเมล (`RegistrationRules.emailError`) — บอกจุดผิดทีละจุด

```mermaid
flowchart LR
  E1{"ลงท้าย @nu.ac.th?"} -- ไม่ --> X1["โปรดใช้อีเมลของมหาลัยฯ"]
  E1 -- ใช่ --> E2{"รูปแบบ ชื่อ+นามสกุล+เลข 2 หลัก?"}
  E2 -- ไม่ --> X2["รูปแบบอีเมลไม่ถูกต้อง"]
  E2 -- ใช่ --> E3{"เลขปี 66–69?"}
  E3 -- ไม่ --> X3["เลขปีในอีเมลไม่ถูกต้อง"]
  E3 -- ใช่ --> E4{"ขึ้นต้นด้วยชื่ออังกฤษ +<br/>ตัวต้นของนามสกุล (≥1 ตัว)?"}
  E4 -- ไม่ --> X4["อีเมลไม่ตรงกับชื่อภาษาอังกฤษ"]
  E4 -- ใช่ --> E5{"เลขปี = 2 ตัวแรกของรหัสนิสิต?"}
  E5 -- ไม่ --> X5["เลขปีในอีเมลไม่ตรงกับรหัสนิสิต"]
  E5 -- ใช่ --> OK([ผ่าน])
```

รหัสนิสิต (`studentIdError`): 8 หลัก · 2 ตัวแรก 66–69 · ตัวที่ 3–4 = `31` (คณะวิทยาศาสตร์)

## ล็อกอิน และหน้าแรกนิสิต

```mermaid
flowchart TD
  L([Login: Email + password]) --> L1["AuthProvider.login()<br/>เทียบ hash"]
  L1 -- ไม่พบ/รหัสผิด --> L2[แสดงข้อความ error]
  L1 -- สำเร็จ --> G{"_RoleGate<br/>context.watch(AuthProvider)"}
  G -- เจ้าหน้าที่ --> ST([StaffShell: ข้อความ / นัดหมาย / ภาพรวม / โปรไฟล์])
  G -- นิสิต --> SH([StudentShell: หน้าแรก / แชทของฉัน / นัดหมาย / โปรไฟล์])
  SH --> HM["หน้าแรก: เลือกหัวข้อ"]
  HM -- เร่งด่วน --> CH[[เข้าแชททันที → 04-chat-flow.md]]
  HM -- ทั่วไป --> CC["เลือกช่องทาง"] --> CM["เลือกคนไหนก็ได้ / เลือกพี่เอง"]
  CM --> CH
  CM --> AP[[จองนัด → 05-appointment-state.md]]
  SH --> PF["โปรไฟล์: แก้เบอร์ / ภาควิชา-สาขา<br/>updateMyProfile()"]
  HM -. "ปุ่มบ้าน 🏠 ทุกหน้า: goHome()" .-> HM
```
