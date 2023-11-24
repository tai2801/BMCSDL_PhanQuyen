# TEST REPORT — SECUREDB ACCESS CONTROL

Ngày chạy: 24/11/2023 · Môi trường: Windows 10, Node.js, SQL Server 2022.

## 1. Kiểm thử API & Phân quyền (`api/tests/api.test.js`) — 20/20 PASS
```
cd api && npm test
→ tests 20 · pass 20 · fail 0
```
20 test case bao phủ đầy đủ các quy tắc bảo mật:
- Đăng nhập đúng/sai mật khẩu, response tuyệt đối không lộ `password_hash`; thiếu token trả về HTTP 401.
- Sinh viên xem hồ sơ/điểm của người khác bị chặn HTTP 403, xem của chính mình trả về HTTP 200.
- Phòng đào tạo xem hồ sơ sinh viên không bị mask; Giảng viên xem sinh viên lớp mình bị mask CCCD/SĐT, xem ngoài lớp bị chặn HTTP 403.
- Admin hệ thống xem bảng điểm bị chặn HTTP 403 (nguyên tắc tách biệt nhiệm vụ).
- Giảng viên sửa điểm đúng lớp được phân công (điểm tổng = 0,4 × quá trình + 0,6 × cuối kỳ) thành công và **bản ghi `grade_audit_log` được ghi nhận đầy đủ trong DB** (người sửa, lý do, điểm cũ/mới).
- Giảng viên sửa điểm lớp của giảng viên khác bị chặn HTTP 403; Phòng đào tạo sửa điểm bị chặn HTTP 403.
- Endpoint `/admin/users` chỉ cho phép vai trò Admin và không lộ chuỗi băm mật khẩu.
- **Minh họa phòng chống SQL Injection:** endpoint `/demo/vulnerable` bị khai thác bởi payload `' OR '1'='1`, trong khi endpoint `/demo/safe` dùng parameterized query trả về 0 dòng.
- Báo cáo truy cập bất thường phát hiện chính xác tài khoản có ≥ 5 lần bị từ chối (`DENIED`/`FAILED`); Sinh viên không có quyền xem báo cáo bảo mật.

## 2. Kiểm thử kịch bản T-SQL (`database/08_security_tests.sql`) — PASS
Thực thi bộ script `01_schema.sql` → `08_security_tests.sql` trên SQL Server:
- **TEST 1 (`EXECUTE AS USER = '2001210001'`):** truy vấn `dbo.v_my_grades` chỉ trả về điểm của đúng sinh viên đang đăng nhập.
- **TEST 2:** sinh viên `SELECT` trực tiếp bảng gốc `dbo.grades` bị từ chối quyền (Error 229).
- **TEST 3:** giảng viên gọi `dbo.sp_update_grade` cho lớp không được phân công bị chặn bởi `THROW 51003`.
- **TEST 4:** tài khoản Phòng đào tạo gọi `dbo.sp_update_grade` bị chặn bởi `THROW 51002`.
- **TEST 5:** giảng viên cập nhật điểm lớp được phân công thành công và trigger `trg_grades_audit` tự động ghi lịch sử vào `dbo.grade_audit_log`.
- **TEST 6:** `dbo.sp_anomaly_report` thống kê chính xác các tài khoản vi phạm ngưỡng truy cập trái phép.
