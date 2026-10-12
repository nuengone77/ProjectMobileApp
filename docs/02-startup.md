# 2. ลำดับการทำงานตอนเปิดแอป (Startup)

`main()` ไม่รอโหลดข้อมูลก่อน แต่ให้ `AppStartup` รอด้วย **FutureBuilder** (บทที่ 12)
ระหว่างรอแสดง "กำลังโหลด..." ถ้าผิดพลาดแสดงข้อความ + ปุ่มลองใหม่

```mermaid
sequenceDiagram
  participant M as main()
  participant S as AppStartup (FutureBuilder)
  participant L as loadAppData()
  participant SA as StaffAccount.load()
  participant D as AppData.open()
  participant DB as SQLite
  participant P as AppProviders (MultiProvider)
  participant G as _RoleGate

  M->>S: runApp(AppStartup)
  S->>L: เริ่ม Future (ครั้งเดียวตอนสร้าง State)
  S-->>S: snapshot ยังไม่มีข้อมูล → แสดง "กำลังโหลด..."
  L->>L: Attachments.init() เตรียมโฟลเดอร์ไฟล์แนบ
  L->>SA: อ่าน assets/config/staff_accounts.json
  alt มีไฟล์และอ่านได้
    SA-->>L: บัญชีเจ้าหน้าที่จริง
  else ไม่มีไฟล์ / รูปแบบผิด
    SA-->>L: บัญชีตัวอย่าง (StaffAccount.samples)
  end
  L->>D: AppData.open(staffAccounts)
  D->>DB: เปิด kaiwan.db (อัปเกรดเวอร์ชันถ้าเป็นไฟล์เก่า)
  alt ฐานข้อมูลว่าง (เปิดครั้งแรก)
    D->>DB: ใส่ข้อมูลตั้งต้น: เจ้าหน้าที่ + นักศึกษาทดสอบ testerk67
  else มีข้อมูลแล้ว
    DB-->>D: loadAll() โหลดทั้งหมดขึ้นหน่วยความจำ + ผู้ที่ล็อกอินค้างไว้
  end
  opt --dart-define=RESET_DB=true
    L->>D: resetData() ล้างแล้วใส่ข้อมูลตั้งต้นใหม่
  end
  L-->>S: AppData พร้อม
  alt สำเร็จ
    S->>P: KaiwanApp(data) สร้าง Provider ทั้ง 4 ตัว
    P->>G: context.watch(AuthProvider).currentUser
    G-->>G: ยังไม่ล็อกอิน → Login / นักศึกษา → StudentShell / เจ้าหน้าที่ → StaffShell
  else เกิด error
    S-->>S: แสดง "เปิดข้อมูลไม่สำเร็จ" + ปุ่มลองใหม่ (_retry สร้าง Future ใหม่)
  end
```

ไฟล์ที่เกี่ยวข้อง: `lib/main.dart`, `lib/data/staff_account.dart`, `lib/data/app_data.dart`,
`lib/data/app_database.dart`, `lib/providers/app_providers.dart`
