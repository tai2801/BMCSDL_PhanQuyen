/* =====================================================================
   BMCSDL - SECUREDB | 04_procedures_secure.sql
   SP an toan: parameterized 100%, kiem tra phan quyen BEN TRONG SP
   (khong chi dua vao GRANT) - phong thu nhieu lop.
   ===================================================================== */
USE SecureDB;
GO
CREATE OR ALTER PROCEDURE dbo.sp_get_my_grades
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.v_my_grades ORDER BY class_code;
END
GO
CREATE OR ALTER PROCEDURE dbo.sp_get_class_grades
    @class_code NVARCHAR(20),
    @actor      NVARCHAR(64)   -- username cua giang vien (tang ung dung truyen vao / SUSER_SNAME o tang DB)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (
        SELECT 1 FROM dbo.classes c
        JOIN dbo.app_users au ON au.lecturer_id = c.lecturer_id
        WHERE c.class_code = @class_code AND au.username = @actor)
    BEGIN
        INSERT INTO dbo.access_log (username, action, target, result)
        VALUES (@actor, N'VIEW_GRADES', @class_code, N'DENIED');
        THROW 51001, N'Truy cap bi tu choi: giang vien khong duoc phan cong lop nay.', 1;
    END
    SELECT s.student_code, s.full_name, g.process_score, g.final_score, g.total_score
    FROM dbo.grades g
    JOIN dbo.enrollments e ON e.enrollment_id = g.enrollment_id
    JOIN dbo.classes c ON c.class_id = e.class_id
    JOIN dbo.students s ON s.student_id = e.student_id
    WHERE c.class_code = @class_code
    ORDER BY s.student_code;
END
GO
CREATE OR ALTER PROCEDURE dbo.sp_update_grade
    @class_code   NVARCHAR(20),
    @student_code NVARCHAR(16),
    @process      DECIMAL(4,2),
    @final        DECIMAL(4,2),
    @actor        NVARCHAR(64),
    @reason       NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    -- 1) Chi GIANG_VIEN moi duoc sua diem (DAO_TAO va ADMIN bi tu choi ngay trong SP)
    IF NOT EXISTS (SELECT 1 FROM dbo.app_users au JOIN dbo.roles r ON r.role_id = au.role_id
                   WHERE au.username = @actor AND r.role_code = N'GIANG_VIEN')
    BEGIN
        INSERT INTO dbo.access_log (username, action, target, result)
        VALUES (@actor, N'UPDATE_GRADE', @class_code + N'/' + @student_code, N'DENIED');
        COMMIT; THROW 51002, N'Chi giang vien moi duoc sua diem.', 1;
    END
    -- 2) GV chi sua duoc lop duoc phan cong
    DECLARE @enrollment_id INT, @grade_id INT;
    SELECT @enrollment_id = e.enrollment_id, @grade_id = g.grade_id
    FROM dbo.enrollments e
    JOIN dbo.classes c ON c.class_id = e.class_id
    JOIN dbo.students s ON s.student_id = e.student_id
    JOIN dbo.app_users au ON au.lecturer_id = c.lecturer_id
    LEFT JOIN dbo.grades g ON g.enrollment_id = e.enrollment_id
    WHERE c.class_code = @class_code AND s.student_code = @student_code AND au.username = @actor;
    IF @enrollment_id IS NULL
    BEGIN
        INSERT INTO dbo.access_log (username, action, target, result)
        VALUES (@actor, N'UPDATE_GRADE', @class_code + N'/' + @student_code, N'DENIED');
        COMMIT; THROW 51003, N'Truy cap bi tu choi: lop khong thuoc phan cong cua giang vien.', 1;
    END
    -- 3) Cap nhat (audit bang trigger trg_grades_audit)
    IF @grade_id IS NULL
        INSERT INTO dbo.grades (enrollment_id, process_score, final_score, updated_by, updated_at)
        VALUES (@enrollment_id, @process, @final, @actor, SYSDATETIME());
    ELSE
        UPDATE dbo.grades SET process_score = @process, final_score = @final,
               updated_by = @actor, updated_at = SYSDATETIME()
        WHERE grade_id = @grade_id;
    EXEC sp_set_session_context @key = N'grade_reason', @value = @reason;
    INSERT INTO dbo.access_log (username, action, target, result)
    VALUES (@actor, N'UPDATE_GRADE', @class_code + N'/' + @student_code, N'SUCCESS');
    COMMIT;
END
GO
CREATE OR ALTER PROCEDURE dbo.sp_anomaly_report
    @minutes INT = 60, @threshold INT = 5
AS
BEGIN
    SET NOCOUNT ON;
    -- Bao cao truy cap bat thuong: nhieu lan bi tu choi / dang nhap that bai trong cua so thoi gian
    SELECT username, COUNT(*) AS denied_or_failed_count, MIN(created_at) AS first_at, MAX(created_at) AS last_at
    FROM dbo.access_log
    WHERE result IN (N'DENIED', N'FAILED')
      AND created_at >= DATEADD(MINUTE, -@minutes, SYSDATETIME())
    GROUP BY username
    HAVING COUNT(*) >= @threshold
    ORDER BY denied_or_failed_count DESC;
END
GO
/* --- Cap quyen EXECUTE sau khi SP da ton tai (GRANT o file 03 se loi neu SP chua co) --- */
GRANT EXECUTE ON dbo.sp_get_class_grades TO rl_giang_vien;
GRANT EXECUTE ON dbo.sp_update_grade     TO rl_giang_vien;
GRANT EXECUTE ON dbo.sp_get_my_grades    TO rl_sinh_vien;
GO
PRINT N'04_procedures_secure.sql: OK';
GO
