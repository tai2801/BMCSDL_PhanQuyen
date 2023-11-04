# MÔ HÌNH BẢO MẬT — SECUREDB ACCESS CONTROL

## 1. Vai trò
| Mã | Vai trò | Mô tả |
|---|---|---|
| ADMIN | Quản trị hệ thống | Quản lý tài khoản, vai trò; **không** xem/sửa điểm chi tiết |
| DAO_TAO | Phòng đào tạo | Quản lý học vụ (SV, lớp, đăng ký), xem điểm toàn trường, **không** sửa điểm |
| GIANG_VIEN | Giảng viên | Xem + sửa điểm **chỉ lớp được phân công** |
| SINH_VIEN | Sinh viên | Chỉ xem hồ sơ + điểm **của chính mình** |
| KIEM_TRA | Nhân viên kiểm tra dữ liệu | Xem dữ liệu đã mask để đối soát, không sửa điểm |

## 2. Ma trận quyền (đối tượng × vai trò)
| Đối tượng / thao tác | ADMIN | DAO_TAO | GIANG_VIEN | SINH_VIEN | KIEM_TRA |
|---|---|---|---|---|---|
| Tài khoản & vai trò (CRUD) | ✅ | ❌ | ❌ | ❌ | ❌ |
| Hồ sơ SV — xem | Mask | Full | Mask, chỉ SV lớp mình | Của mình (full) | Mask |
| CCCD/SĐT plaintext | ❌ | ✅ (nghiệp vụ) | ❌ (mask) | Của mình | ❌ (mask) |
| Điểm — xem | ❌ | ✅ toàn trường | Lớp phân công | Của mình | Mask/tổng hợp |
| Điểm — sửa | ❌ | ❌ | ✅ lớp phân công | ❌ | ❌ |
| Lớp học phần / đăng ký | Xem | ✅ CRUD | Xem lớp mình | Xem của mình | Xem |
| Audit log / báo cáo bất thường | ✅ | ✅ | ❌ | ❌ | ❌ |
| Backup/Restore (DB) | ✅ (DBA) | ❌ | ❌ | ❌ | ❌ |

Ma trận này được thực thi ở **cả 2 tầng**: DB (database roles + DENY + view lọc `SUSER_SNAME()` + SP kiểm tra phân công bên trong) và API (JWT + middleware theo vai trò + kiểm tra chủ sở hữu/phân công trong từng handler).

## 3. Mô hình đe dọa cơ bản (STRIDE rút gọn)
| Mối đe dọa | Ví dụ trong hệ thống | Biện pháp |
|---|---|---|
| Spoofing | Giả mạo người dùng khác | JWT ký bí mật, BCrypt hash, khóa tài khoản sau 5 lần sai |
| Tampering | GV sửa điểm lớp người khác; sửa điểm không để lại dấu | Kiểm tra phân công trong SP/handler; trigger audit ghi old/new |
| Repudiation | Phủ nhận đã sửa điểm | grade_audit_log + access_log bất biến theo thiết kế (chỉ INSERT) |
| Information disclosure | SV xem điểm bạn; lộ CCCD/SĐT; admin xem điểm | Row-level theo chủ sở hữu, mask theo vai trò, DENY ở tầng DB, response không chứa password_hash |
| DoS | Dò mật khẩu hàng loạt | failed_login_count + locked_until 15 phút; báo cáo bất thường |
| Elevation of privilege | DAO_TAO tự sửa điểm; leo thang qua SQL Injection | Ma trận quyền + SP kiểm tra role bên trong; parameterized query |

## 4. Phòng chống SQL Injection
- Mọi truy vấn nghiệp vụ: **parameterized** (API: prepared statement `?`; DB: tham số SP).
- Endpoint `/demo/vulnerable` cố ý nối chuỗi để minh họa lỗ hổng — **chỉ tồn tại trên DB demo**, có cảnh báo trong code/README, tuyệt đối không đưa vào production. Test tự động chứng minh: chuỗi `' OR '1'='1` lấy được nhiều dòng ở bản vulnerable nhưng trả 0 dòng ở bản safe.

## 5. XSS & API
- API chỉ trả JSON (`Content-Type: application/json`), không render HTML từ dữ liệu người dùng; frontend phải escape khi hiển thị (ghi chú cho tầng UI).
- Không trả về `password_hash`, CCCD/SĐT plaintext cho vai trò không được phép.
- JWT hết hạn 1 giờ; secret lấy từ biến môi trường.

## 6. Mã hóa dữ liệu nhạy cảm
- Tại DB: `EncryptByKey` (AES_256, symmetric key bảo vệ bằng certificate + master key) cho CCCD/SĐT — script demo ở `database/06_encryption.sql`.
- Production khuyến nghị **Always Encrypted**: driver phía client mã hóa, server không thấy plaintext lẫn key (mô tả chi tiết trong 06_encryption.sql).
- Mật khẩu: BCrypt (cost 10) — không mã hóa đối xứng, không plaintext.
