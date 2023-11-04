# KẾ HOẠCH KIỂM THỬ — SECUREDB

## Tầng API/logic (kiểm thử tự động bằng Node test — xem TEST_REPORT)
1. Đăng nhập đúng/sai; response không lộ hash. 2. Thiếu token → 401.
3. SV xem hồ sơ/điểm người khác → 403; xem của mình → 200 (CCCD full của mình).
4. Đào tạo xem hồ sơ → không mask. 5. GV xem SV lớp mình → mask; SV ngoài lớp → 403.
6. Admin xem điểm → 403. 7. GV sửa điểm lớp phân công → 200, tổng đúng công thức, có audit.
8. GV sửa điểm lớp người khác → 403. 9. Đào tạo sửa điểm → 403.
10. /admin/users chỉ Admin, không lộ hash. 11. SQLi: vulnerable lộ dữ liệu, safe vô hiệu.
12. Báo cáo bất thường sau nhiều lần DENIED; SV không xem được báo cáo.

## Tầng DB (database/08_security_tests.sql — chạy trên SQL Server)
- TEST 1: SV qua `v_my_grades` chỉ thấy điểm của mình.
- TEST 2: SV đọc thẳng bảng grades → lỗi 229 (DENIED).
- TEST 3: GV sửa điểm lớp không phân công → THROW 51003.
- TEST 4: Đào tạo sửa điểm → THROW 51002.
- TEST 5: GV sửa điểm đúng lớp → thành công + có dòng audit.
- TEST 6: `sp_anomaly_report` liệt kê username vượt ngưỡng.
