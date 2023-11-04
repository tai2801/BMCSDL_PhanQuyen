/* =====================================================================
   BMCSDL - SECUREDB | 02_seed.sql - du lieu mau
   Mat khau demo cho MOI tai khoan mau: Demo@123
   password_hash duoi day la BCrypt hash cua "Demo@123" (cost 10) - chi dung
   cho moi truong hoc tap/demo; khi trien khai that phai doi mat khau.
   ===================================================================== */
USE SecureDB;
GO
SET NOCOUNT ON;
DELETE FROM dbo.grades; DELETE FROM dbo.enrollments; DELETE FROM dbo.classes;
DELETE FROM dbo.app_users; DELETE FROM dbo.courses; DELETE FROM dbo.lecturers;
DELETE FROM dbo.students; DELETE FROM dbo.roles;
DBCC CHECKIDENT (N'dbo.roles', RESEED, 0); DBCC CHECKIDENT (N'dbo.students', RESEED, 0);
DBCC CHECKIDENT (N'dbo.lecturers', RESEED, 0); DBCC CHECKIDENT (N'dbo.app_users', RESEED, 0);
DBCC CHECKIDENT (N'dbo.courses', RESEED, 0); DBCC CHECKIDENT (N'dbo.classes', RESEED, 0);
DBCC CHECKIDENT (N'dbo.enrollments', RESEED, 0); DBCC CHECKIDENT (N'dbo.grades', RESEED, 0);
GO
INSERT INTO dbo.roles (role_code, role_name) VALUES
 (N'ADMIN',    N'Quản trị hệ thống'),
 (N'DAO_TAO',  N'Phòng đào tạo'),
 (N'GIANG_VIEN', N'Giảng viên'),
 (N'SINH_VIEN',  N'Sinh viên'),
 (N'KIEM_TRA', N'Nhân viên kiểm tra dữ liệu');
GO
INSERT INTO dbo.students (student_code, full_name, date_of_birth, gender, email, home_class) VALUES
 (N'2001210001', N'Nguyễn Văn An',   '2002-03-14', N'Nam', N'an.nv@sv.huit.edu.vn',   N'K13-CNTT'),
 (N'2001210002', N'Trần Thị Bình',   '2002-07-02', N'Nữ',  N'binh.tt@sv.huit.edu.vn',  N'K13-CNTT'),
 (N'2001210003', N'Lê Hoàng Cường',  '2001-11-25', N'Nam', N'cuong.lh@sv.huit.edu.vn', N'K13-CNTT'),
 (N'2001210004', N'Phạm Thu Dung',   '2002-01-19', N'Nữ',  N'dung.pt@sv.huit.edu.vn',  N'K13-KTPM'),
 (N'2001210005', N'Võ Minh Đức',     '2002-09-08', N'Nam', N'duc.vm@sv.huit.edu.vn',   N'K13-KTPM'),
 (N'2001210006', N'Đỗ Ngọc Hà',      '2002-05-30', N'Nữ',  N'ha.dn@sv.huit.edu.vn',    N'K13-KTPM');
GO
INSERT INTO dbo.lecturers (lecturer_code, full_name, email, department) VALUES
 (N'GV01', N'TS. Hoàng Văn Khoa', N'khoa.hv@huit.edu.vn', N'Khoa CNTT'),
 (N'GV02', N'ThS. Vũ Thị Lan',    N'lan.vt@huit.edu.vn',  N'Khoa CNTT'),
 (N'GV03', N'ThS. Bùi Quốc Nam',  N'nam.bq@huit.edu.vn',  N'Khoa CNTT');
GO
DECLARE @hash NVARCHAR(255) = N'$2a$10$YsidLEwgFWIQgEiCoCp8Pessc4RChxyG6rdBd4lx1QD2Bpuvjaic6'; -- BCrypt("Demo@123") - MAT KHAU DEMO
INSERT INTO dbo.app_users (username, password_hash, role_id, student_id, lecturer_id) VALUES
 (N'admin',    @hash, 1, NULL, NULL),
 (N'daotao01', @hash, 2, NULL, NULL),
 (N'gv.khoa',  @hash, 3, NULL, 1),
 (N'gv.lan',   @hash, 3, NULL, 2),
 (N'2001210001', @hash, 4, 1, NULL),
 (N'2001210002', @hash, 4, 2, NULL),
 (N'2001210003', @hash, 4, 3, NULL),
 (N'kiemtra01',  @hash, 5, NULL, NULL);
GO
INSERT INTO dbo.courses (course_code, course_name, credits) VALUES
 (N'INT2213', N'Cơ sở dữ liệu', 3),
 (N'INT2214', N'Bảo mật cơ sở dữ liệu', 3),
 (N'INT3301', N'Phát triển hệ thống thông tin', 3);
GO
INSERT INTO dbo.classes (class_code, course_id, lecturer_id, semester, academic_year) VALUES
 (N'CSDL-N01', 1, 1, N'HK1', N'2023-2024'),   -- GV Khoa
 (N'BMCSDL-N01', 2, 2, N'HK1', N'2023-2024'), -- GV Lan
 (N'PTHT-N01', 3, 1, N'HK1', N'2023-2024');   -- GV Khoa
GO
INSERT INTO dbo.enrollments (class_id, student_id) VALUES
 (1,1),(1,2),(1,3),(1,4),
 (2,1),(2,2),(2,5),
 (3,3),(3,6);
GO
INSERT INTO dbo.grades (enrollment_id, process_score, final_score, updated_by) VALUES
 (1, 8.0, 7.5, N'gv.khoa'), (2, 6.5, 8.0, N'gv.khoa'), (3, 9.0, 8.5, N'gv.khoa'),
 (5, 7.0, 6.0, N'gv.lan'),  (6, 8.5, 9.0, N'gv.lan'),
 (8, 5.5, 6.5, N'gv.khoa');
GO
PRINT N'02_seed.sql: OK - 6 SV, 3 GV, 8 tai khoan, 3 lop hoc phan, 9 dang ky, 6 diem';
GO
