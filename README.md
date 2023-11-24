# SecureDB Access Control — Phân quyền & Bảo mật Cơ sở dữ liệu

Hệ thống quản lý hồ sơ sinh viên minh họa **bảo mật cơ sở dữ liệu theo vai trò** (môn Bảo mật CSDL — Nhóm 2, HUIT).

## Hai tầng kiểm soát
1. **Tầng database (SQL Server / T-SQL)** — `database/`: database roles + GRANT/DENY, view lọc theo `SUSER_SNAME()`, stored procedure kiểm tra phân công bên trong, trigger audit thay đổi điểm, mã hóa cột CCCD/SĐT bằng `EncryptByKey`, script backup/restore, bộ test quyền `EXECUTE AS USER`.
2. **Tầng ứng dụng (API demo)** — `api/`: Node + Express, đăng nhập **JWT + BCrypt**, kiểm tra quyền theo vai trò ở middleware + từng handler, **mask CCCD/SĐT theo vai trò**, parameterized query, demo SQL Injection (bản lỗi vs bản an toàn) trên DB demo.

## Ma trận quyền (tóm tắt)
| | Admin | Phòng đào tạo | Giảng viên | Sinh viên |
|---|---|---|---|---|
| Quản lý tài khoản | ✅ | ❌ | ❌ | ❌ |
| Xem hồ sơ SV | Mask | Full | Mask (lớp mình) | Của mình |
| Xem điểm | ❌ | ✅ | Lớp phân công | Của mình |
| Sửa điểm | ❌ | ❌ | ✅ lớp phân công | ❌ |

Chi tiết: `docs/SECURITY_MODEL.md`.

## Chạy API demo
```bash
cd api
npm install
npm start        # http://localhost:3013
npm test         # 20 test phan quyen/SQLi/audit
```
Tài khoản demo (mật khẩu chung `Demo@123` — chỉ cho bài học): `admin`, `daotao01`, `gv.khoa`, `gv.lan`, `2001210001`, `2001210002`, `2001210003`.

Ví dụ:
```bash
TOKEN=$(curl -s -X POST localhost:3013/auth/login -H 'Content-Type: application/json' -d '{"username":"2001210001","password":"Demo@123"}' | node -pe 'JSON.parse(require("fs").readFileSync(0)).token')
curl localhost:3013/students/1/grades -H "Authorization: Bearer $TOKEN"   # 200 - diem cua minh
curl localhost:3013/students/2/grades -H "Authorization: Bearer $TOKEN"   # 403
```

## Chạy phần SQL Server
```bash
docker compose up -d   # SQL Server 2022, cong 14331
# Dung SSMS/sqlcmd chay lan luot database/01 -> 08
```

## Cấu trúc
- `database/` 01 schema · 02 seed · 03 roles & permissions + views bảo vệ · 04 SP an toàn · 05 audit trigger · 06 encryption · 07 backup/restore · 08 security tests
- `api/` Express demo (src: app/db/security/server; tests: 20 test)
- `docs/` SECURITY_MODEL (ma trận quyền + STRIDE) · BUSINESS_ANALYSIS · ERD · TEST_PLAN
- `TEST_REPORT.md` — tổng hợp kết quả kiểm thử phân quyền, audit và bảo mật
