/* =====================================================================
   BMCSDL - SECUREDB ACCESS CONTROL | 01_schema.sql (SQL Server, T-SQL)
   He thong ho so sinh vien minh hoa bao mat CSDL theo vai tro.
   Nhom 2 - HUIT. Chay lai duoc: moi CREATE deu co kiem tra.
   ===================================================================== */
IF DB_ID(N'SecureDB') IS NULL CREATE DATABASE SecureDB;
GO
USE SecureDB;
GO

IF OBJECT_ID(N'dbo.grade_audit_log', N'U') IS NULL
CREATE TABLE dbo.grade_audit_log (
    audit_id      BIGINT IDENTITY(1,1) PRIMARY KEY,
    grade_id      INT NOT NULL,
    enrollment_id INT NOT NULL,
    old_process   DECIMAL(4,2) NULL,
    new_process   DECIMAL(4,2) NULL,
    old_final     DECIMAL(4,2) NULL,
    new_final     DECIMAL(4,2) NULL,
    changed_by    NVARCHAR(64) NOT NULL,
    change_reason NVARCHAR(255) NULL,
    changed_at    DATETIME2 NOT NULL CONSTRAINT DF_gal_at DEFAULT SYSDATETIME()
);
GO
IF OBJECT_ID(N'dbo.access_log', N'U') IS NULL
CREATE TABLE dbo.access_log (
    log_id     BIGINT IDENTITY(1,1) PRIMARY KEY,
    username   NVARCHAR(64) NULL,
    action     NVARCHAR(64) NOT NULL,          -- LOGIN, VIEW_PROFILE, VIEW_GRADES, UPDATE_GRADE...
    target     NVARCHAR(128) NULL,
    result     NVARCHAR(16) NOT NULL           -- SUCCESS | DENIED | FAILED
               CONSTRAINT CK_al_result CHECK (result IN (N'SUCCESS', N'DENIED', N'FAILED')),
    ip_address NVARCHAR(45) NULL,
    created_at DATETIME2 NOT NULL CONSTRAINT DF_al_at DEFAULT SYSDATETIME()
);
GO
IF OBJECT_ID(N'dbo.roles', N'U') IS NULL
CREATE TABLE dbo.roles (
    role_id   INT IDENTITY(1,1) PRIMARY KEY,
    role_code NVARCHAR(32) NOT NULL CONSTRAINT UQ_roles_code UNIQUE,
    role_name NVARCHAR(64) NOT NULL
);
GO
IF OBJECT_ID(N'dbo.students', N'U') IS NULL
CREATE TABLE dbo.students (
    student_id    INT IDENTITY(1,1) PRIMARY KEY,
    student_code  NVARCHAR(16) NOT NULL CONSTRAINT UQ_st_code UNIQUE,  -- MSSV
    full_name     NVARCHAR(80) NOT NULL,
    date_of_birth DATE NULL,
    gender        NVARCHAR(8) NULL CONSTRAINT CK_st_gender CHECK (gender IN (N'Nam', N'Nữ')),
    email         NVARCHAR(120) NULL,
    phone_enc     VARBINARY(256) NULL,   -- SDT ma hoa doi xung (06_encryption.sql)
    national_id_enc VARBINARY(256) NULL, -- CCCD ma hoa doi xung
    home_class    NVARCHAR(16) NULL      -- lop sinh hoat, vd K13-CNTT
);
GO
IF OBJECT_ID(N'dbo.lecturers', N'U') IS NULL
CREATE TABLE dbo.lecturers (
    lecturer_id   INT IDENTITY(1,1) PRIMARY KEY,
    lecturer_code NVARCHAR(16) NOT NULL CONSTRAINT UQ_lc_code UNIQUE,
    full_name     NVARCHAR(80) NOT NULL,
    email         NVARCHAR(120) NULL,
    department    NVARCHAR(80) NULL
);
GO
IF OBJECT_ID(N'dbo.app_users', N'U') IS NULL
CREATE TABLE dbo.app_users (
    user_id           INT IDENTITY(1,1) PRIMARY KEY,
    username          NVARCHAR(64) NOT NULL CONSTRAINT UQ_au_user UNIQUE,
    password_hash     NVARCHAR(255) NOT NULL,  -- BCrypt; KHONG bao gio luu plaintext
    role_id           INT NOT NULL CONSTRAINT FK_au_role REFERENCES dbo.roles(role_id),
    student_id        INT NULL CONSTRAINT FK_au_student REFERENCES dbo.students(student_id),
    lecturer_id       INT NULL CONSTRAINT FK_au_lect REFERENCES dbo.lecturers(lecturer_id),
    is_active         BIT NOT NULL CONSTRAINT DF_au_active DEFAULT 1,
    failed_login_count INT NOT NULL CONSTRAINT DF_au_fail DEFAULT 0,
    locked_until      DATETIME2 NULL,
    created_at        DATETIME2 NOT NULL CONSTRAINT DF_au_at DEFAULT SYSDATETIME()
);
GO
IF OBJECT_ID(N'dbo.courses', N'U') IS NULL
CREATE TABLE dbo.courses (
    course_id   INT IDENTITY(1,1) PRIMARY KEY,
    course_code NVARCHAR(16) NOT NULL CONSTRAINT UQ_co_code UNIQUE,
    course_name NVARCHAR(120) NOT NULL,
    credits     INT NOT NULL CONSTRAINT CK_co_credits CHECK (credits BETWEEN 1 AND 10)
);
GO
IF OBJECT_ID(N'dbo.classes', N'U') IS NULL
CREATE TABLE dbo.classes (
    class_id      INT IDENTITY(1,1) PRIMARY KEY,
    class_code    NVARCHAR(20) NOT NULL CONSTRAINT UQ_cl_code UNIQUE, -- vd CSDL-N02
    course_id     INT NOT NULL CONSTRAINT FK_cl_course REFERENCES dbo.courses(course_id),
    lecturer_id   INT NOT NULL CONSTRAINT FK_cl_lect REFERENCES dbo.lecturers(lecturer_id), -- GV duoc phan cong
    semester      NVARCHAR(16) NOT NULL,
    academic_year NVARCHAR(16) NOT NULL
);
GO
IF OBJECT_ID(N'dbo.enrollments', N'U') IS NULL
CREATE TABLE dbo.enrollments (
    enrollment_id INT IDENTITY(1,1) PRIMARY KEY,
    class_id      INT NOT NULL CONSTRAINT FK_en_class REFERENCES dbo.classes(class_id),
    student_id    INT NOT NULL CONSTRAINT FK_en_student REFERENCES dbo.students(student_id),
    CONSTRAINT UQ_en_class_student UNIQUE (class_id, student_id)
);
GO
IF OBJECT_ID(N'dbo.grades', N'U') IS NULL
CREATE TABLE dbo.grades (
    grade_id      INT IDENTITY(1,1) PRIMARY KEY,
    enrollment_id INT NOT NULL CONSTRAINT FK_gr_en REFERENCES dbo.enrollments(enrollment_id)
                  CONSTRAINT UQ_gr_en UNIQUE,
    process_score DECIMAL(4,2) NULL CONSTRAINT CK_gr_proc CHECK (process_score BETWEEN 0 AND 10),
    final_score   DECIMAL(4,2) NULL CONSTRAINT CK_gr_fin CHECK (final_score BETWEEN 0 AND 10),
    total_score AS (CASE WHEN process_score IS NULL OR final_score IS NULL THEN NULL
                         ELSE CAST(ROUND(process_score * 0.4 + final_score * 0.6, 2) AS DECIMAL(4,2)) END) PERSISTED,
    updated_by    NVARCHAR(64) NULL,
    updated_at    DATETIME2 NULL
);
GO
PRINT N'01_schema.sql: OK';
GO
