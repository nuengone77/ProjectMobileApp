# 5. State Diagram สถานะนัดหมาย

ไฟล์หลัก: `lib/providers/appointment_provider.dart`, `lib/screens/appointment/`
สถานะอยู่ใน `enum AppointmentStatus` (`lib/data/models.dart`)

```mermaid
stateDiagram-v2
  [*] --> pending: นิสิตส่งคำขอ<br/>requestAppointment()

  state "รอยืนยัน (pending)" as pending
  state "ยืนยันแล้ว (confirmed)" as confirmed
  state "พี่เสนอเวลาใหม่ (proposed)" as proposed
  state "ยกเลิกแล้ว (cancelled)" as cancelled

  pending --> confirmed: เจ้าหน้าที่ “ยืนยัน สะดวกเวลานี้”<br/>confirmAppointment()
  pending --> proposed: เจ้าหน้าที่ “เสนอเวลาอื่น” + ข้อความ<br/>proposeAppointmentTime()
  pending --> cancelled: นิสิตกดยกเลิก (ยืนยันก่อน)<br/>cancelAppointment()
  proposed --> confirmed: นิสิต “ตกลงเวลานี้”<br/>acceptProposedTime() → เวลานัด = เวลาที่พี่เสนอ
  proposed --> cancelled: นิสิตยกเลิก หรือ “เลือกเวลาอื่น”<br/>(ยกเลิกแล้วจองใหม่กับพี่คนเดิม)
  confirmed --> [*]
  cancelled --> [*]
```

## ใครเห็นคำขอนัด

```mermaid
flowchart LR
  A[นิสิตจองนัด] --> B{เลือกพี่เองไหม}
  B -- "คนไหนก็ได้<br/>requestedStaffId = null" --> C[เจ้าหน้าที่ทุกคนเห็น + badge]
  B -- "เลือกพี่เอง<br/>requestedStaffId = id" --> D[เห็นเฉพาะพี่คนนั้น]
  C & D --> E[เจ้าหน้าที่คนที่กดยืนยัน/เสนอเวลา = staffId ของนัด]
  E --> F["seenByStudent = false → badge แท็บ “นัดหมาย” ฝั่งนิสิต"]
```

กติกาเวลานัด (`AppData`): จันทร์–ศุกร์ 08:30–16:30 ช่วงละ 30 นาที (`isOfficeDay`, `slotsOf`)
เลือกได้ทุกช่องที่ยังไม่ผ่านไป (`isBookable`) เจ้าหน้าที่ตรวจเวลาว่างเอง
ถ้ามีนัดที่ยืนยันแล้วเวลาเดียวกัน การ์ดฝั่งเจ้าหน้าที่จะเตือน (`conflictsOf`)
