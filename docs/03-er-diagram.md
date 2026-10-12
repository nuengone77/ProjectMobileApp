# 3. ER Diagram (ฐานข้อมูล SQLite)

ไฟล์: `lib/data/app_database.dart` · ฐานข้อมูลเวอร์ชัน 3
(v2 เพิ่มตาราง `case_reports`, v3 เพิ่มคอลัมน์ไฟล์แนบใน `messages` — อัปเกรดใน `onUpgrade` โดยข้อมูลเดิมไม่หาย)

```mermaid
erDiagram
  users ||--o{ conversations : "นิสิตเปิดห้อง (student_id)"
  users |o--o{ conversations : "เจ้าหน้าที่ดูแล (staff_id)"
  conversations ||--|{ messages : "มีข้อความ (conversation_id)"
  users ||--o{ messages : "ผู้ส่ง (sender_id)"
  users ||--o{ appointments : "นิสิตขอนัด (student_id)"
  users |o--o{ appointments : "เจ้าหน้าที่รับนัด / ถูกขอโดยตรง"
  users ||--o{ case_reports : "ตารางของเจ้าหน้าที่ (staff_id)"
  conversations |o--o| case_reports : "แถว online จากแชทที่จบ (conversation_id)"

  users {
    TEXT id PK
    TEXT email UK "อีเมล @nu.ac.th"
    TEXT password_hash "sha256 ไม่เก็บรหัสจริง"
    TEXT name
    TEXT role "student / staff"
    TEXT major "สาขา (นิสิต)"
    TEXT student_id "รหัสนิสิต 8 หลัก"
    TEXT name_en
    TEXT phone
    TEXT nickname "ชื่อเล่น (เจ้าหน้าที่)"
    INTEGER avatar_color
  }
  conversations {
    TEXT id PK
    TEXT student_id FK
    TEXT category_id "general / urgent"
    INTEGER is_specific "1 = ส่วนตัว (เลือกพี่เอง)"
    TEXT staff_id FK "ผู้ดูแล"
    INTEGER student_read "จำนวนข้อความที่นิสิตอ่านแล้ว"
    INTEGER staff_read "จำนวนข้อความที่เจ้าหน้าที่อ่านแล้ว"
    INTEGER closed
    INTEGER closed_at
    TEXT closed_by
    TEXT summary_topic "เรื่องที่ถาม/ตอบ"
    TEXT summary_help "คำตอบที่เจ้าหน้าที่ให้"
    TEXT case_level "small / medium / large"
  }
  messages {
    TEXT conversation_id PK,FK
    INTEGER seq PK "ลำดับข้อความในห้อง"
    TEXT sender_id FK "id ผู้ส่ง หรือ system"
    TEXT text
    INTEGER time
    INTEGER is_system "ข้อความระบบ"
    INTEGER is_alert "การ์ดเบอร์ฉุกเฉิน"
    TEXT attachment "ชื่อไฟล์แนบ (v3)"
    TEXT attachment_name "ชื่อไฟล์เดิม (v3)"
    INTEGER is_image "(v3)"
  }
  appointments {
    TEXT id PK
    TEXT student_id FK
    INTEGER start "เวลานัด"
    TEXT note
    TEXT status "pending / confirmed / proposed / cancelled"
    TEXT staff_id FK "ผู้ยืนยัน/เสนอเวลา"
    TEXT requested_staff_id FK "null = คนไหนก็ได้"
    INTEGER proposed_start "เวลาที่พี่เสนอ"
    TEXT staff_message
    INTEGER seen_by_student
  }
  case_reports {
    TEXT id PK
    TEXT staff_id FK
    TEXT conversation_id FK,UK "null = แถว onsite"
    INTEGER date
    TEXT student_id_no
    TEXT student_name
    TEXT category_id
    TEXT channel "online / onsite"
    TEXT topic
    TEXT advice
    TEXT level
    INTEGER edited "แก้ในตารางแล้ว แชทจะไม่ทับ"
  }
  settings {
    TEXT key PK "เช่น current_user_id (ล็อกอินค้าง)"
    TEXT value
  }
```

หมายเหตุ
- ความสัมพันธ์ (FK) เป็นความสัมพันธ์เชิงข้อมูลที่แอปใช้ ไม่ได้บังคับด้วย FOREIGN KEY ใน SQLite
- `case_reports` เป็นสำเนาแยกจากแชท: แก้ในตารางแล้วไม่กระทบแชท (คอลัมน์ `edited`)
- ตาราง `users` ยังมีคอลัมน์ `specialty` ที่เลิกใช้แล้ว (คงไว้ให้เข้ากับฐานข้อมูลเดิม) จึงไม่แสดงในแผนภาพ
- ภาควิชาไม่ได้เก็บแยก หาจากสาขาด้วย `AppData.departmentOf(major)`
