/* =====================================================================
   BMCSDL - SECUREDB | 05_audit.sql - trigger ghi audit thay doi diem
   ===================================================================== */
USE SecureDB;
GO
CREATE OR ALTER TRIGGER dbo.trg_grades_audit ON dbo.grades AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.grade_audit_log
        (grade_id, enrollment_id, old_process, new_process, old_final, new_final, changed_by, change_reason)
    SELECT i.grade_id, i.enrollment_id,
           d.process_score, i.process_score, d.final_score, i.final_score,
           ISNULL(i.updated_by, SUSER_SNAME()),
           CAST(SESSION_CONTEXT(N'grade_reason') AS NVARCHAR(255))
    FROM inserted i JOIN deleted d ON d.grade_id = i.grade_id
    WHERE ISNULL(d.process_score, -1) <> ISNULL(i.process_score, -1)
       OR ISNULL(d.final_score, -1)   <> ISNULL(i.final_score, -1);
END
GO
CREATE OR ALTER VIEW dbo.v_grade_change_history AS
SELECT a.changed_at, a.changed_by, s.student_code, s.full_name,
       a.old_process, a.new_process, a.old_final, a.new_final, a.change_reason
FROM dbo.grade_audit_log a
JOIN dbo.enrollments e ON e.enrollment_id = a.enrollment_id
JOIN dbo.students s ON s.student_id = e.student_id;
GO
PRINT N'05_audit.sql: OK';
GO
