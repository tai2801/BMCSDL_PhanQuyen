/* =====================================================================
   BMCSDL - SECUREDB | 03_roles_permissions.sql
   Phan quyen TANG DATABASE: tao login/user mau + database role rieng,
   chi GRANT qua VIEW va STORED PROCEDURE, DENY truy cap thang bang diem.
   Nguyen tac: least privilege - moi vai tro chi co dung quyen can thiet.
   ===================================================================== */
USE SecureDB;
GO
/* --- Database roles rieng cua ung dung (khac roles nghiep vu trong bang dbo.roles) --- */
IF DATABASE_PRINCIPAL_ID(N'rl_admin')     IS NULL CREATE ROLE rl_admin;
IF DATABASE_PRINCIPAL_ID(N'rl_dao_tao')   IS NULL CREATE ROLE rl_dao_tao;
IF DATABASE_PRINCIPAL_ID(N'rl_giang_vien') IS NULL CREATE ROLE rl_giang_vien;
IF DATABASE_PRINCIPAL_ID(N'rl_sinh_vien') IS NULL CREATE ROLE rl_sinh_vien;
GO
/* --- User mau (trong thuc te moi nguoi 1 login rieng; day la vi du) --- */
IF DATABASE_PRINCIPAL_ID(N'daotao01')   IS NULL CREATE USER daotao01   WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID(N'gv.khoa')    IS NULL CREATE USER [gv.khoa]  WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID(N'2001210001') IS NULL CREATE USER [2001210001] WITHOUT LOGIN;
ALTER ROLE rl_dao_tao    ADD MEMBER daotao01;
ALTER ROLE rl_giang_vien ADD MEMBER [gv.khoa];
ALTER ROLE rl_sinh_vien  ADD MEMBER [2001210001];
GO
/* --- VIEW bao ve du lieu --- */
CREATE OR ALTER VIEW dbo.v_my_grades AS
SELECT g.grade_id, c.class_code, co.course_name, g.process_score, g.final_score, g.total_score
FROM dbo.grades g
JOIN dbo.enrollments e ON e.enrollment_id = g.enrollment_id
JOIN dbo.classes c     ON c.class_id = e.class_id
JOIN dbo.courses co    ON co.course_id = c.course_id
JOIN dbo.app_users au  ON au.student_id = e.student_id
WHERE au.username = SUSER_SNAME();   -- loc theo tai khoan dang dang nhap o tang DB
GO
CREATE OR ALTER VIEW dbo.v_all_grades AS
SELECT s.student_code, s.full_name, c.class_code, co.course_name,
       g.process_score, g.final_score, g.total_score, g.updated_by, g.updated_at
FROM dbo.grades g
JOIN dbo.enrollments e ON e.enrollment_id = g.enrollment_id
JOIN dbo.students s ON s.student_id = e.student_id
JOIN dbo.classes c  ON c.class_id = e.class_id
JOIN dbo.courses co ON co.course_id = c.course_id;
GO
CREATE OR ALTER VIEW dbo.v_lecturer_class_grades AS
SELECT c.class_code, co.course_name, s.student_code, s.full_name,
       g.process_score, g.final_score, g.total_score
FROM dbo.grades g
JOIN dbo.enrollments e ON e.enrollment_id = g.enrollment_id
JOIN dbo.classes c  ON c.class_id = e.class_id
JOIN dbo.courses co ON co.course_id = c.course_id
JOIN dbo.students s ON s.student_id = e.student_id
JOIN dbo.app_users au ON au.lecturer_id = c.lecturer_id
WHERE au.username = SUSER_SNAME();
GO
CREATE OR ALTER VIEW dbo.v_student_directory_masked AS
-- Che du lieu nhay cam o tang DB: email chi hien phan truoc @ bi rut gon, khong co CCCD/SDT
SELECT student_code, full_name, home_class,
       LEFT(email, 3) + N'***' + SUBSTRING(email, CHARINDEX(N'@', email), 60) AS email_masked
FROM dbo.students;
GO
/* --- ADMIN: quan ly tai khoan/vai tro, KHONG co quyen SELECT bang diem --- */
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.app_users TO rl_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.roles     TO rl_admin;
GRANT SELECT ON dbo.access_log TO rl_admin;
GRANT SELECT ON dbo.grade_audit_log TO rl_admin;
DENY  SELECT, UPDATE ON dbo.grades TO rl_admin;   -- admin he thong khong xem/sua diem chi tiet
GO
/* --- PHONG DAO TAO: quan ly hoc vu (SV, lop, dang ky), xem diem qua view, KHONG sua diem --- */
GRANT SELECT, INSERT, UPDATE ON dbo.students    TO rl_dao_tao;
GRANT SELECT, INSERT, UPDATE ON dbo.classes     TO rl_dao_tao;
GRANT SELECT, INSERT, UPDATE ON dbo.enrollments TO rl_dao_tao;
GRANT SELECT ON dbo.v_all_grades TO rl_dao_tao;
GRANT SELECT ON dbo.grade_audit_log TO rl_dao_tao;
DENY  UPDATE ON dbo.grades TO rl_dao_tao;          -- dao tao khong sua diem truc tiep
-- Luu y: cot phone_enc/national_id_enc trong students chi la ciphertext (EncryptByKey);
-- doc duoc plaintext phai co quyen mo symmetric key - dao tao KHONG duoc cap quyen do,
-- plaintext CCCD/SDT chi giai ma qua quy trinh nghiep vu rieng (xem SECURITY_MODEL.md).
GO
/* --- GIANG VIEN: chi qua view/SP theo lop duoc phan cong, khong dung bang goc --- */
GRANT SELECT ON dbo.v_lecturer_class_grades TO rl_giang_vien;
DENY  SELECT, UPDATE ON dbo.grades      TO rl_giang_vien;
DENY  SELECT ON dbo.students            TO rl_giang_vien;  -- thong tin SV chi qua view da loc
GRANT SELECT ON dbo.v_student_directory_masked TO rl_giang_vien;
GO
/* --- SINH VIEN: chi xem diem cua chinh minh qua view loc theo SUSER_SNAME --- */
GRANT SELECT ON dbo.v_my_grades TO rl_sinh_vien;
DENY  SELECT ON dbo.grades TO rl_sinh_vien;
DENY  SELECT ON dbo.students TO rl_sinh_vien;
GO
PRINT N'03_roles_permissions.sql: OK';
GO
