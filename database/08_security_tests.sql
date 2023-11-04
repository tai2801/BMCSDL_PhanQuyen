/* =====================================================================
   BMCSDL - SECUREDB | 08_security_tests.sql
   Kich ban kiem thu quyen o TANG DB. Moi test in KET QUA MONG DOI va
   ket qua thuc te (PASS/FAIL) de doi chieu khi chay tren SQL Server.
   ===================================================================== */
USE SecureDB;
GO
PRINT N'TEST 1 - SV xem diem qua v_my_grades: MONG DOI chi thay diem cua chinh minh (MSSV 2001210001)';
EXECUTE AS USER = N'2001210001';
SELECT * FROM dbo.v_my_grades;
REVERT;
GO
PRINT N'TEST 2 - SV doc thang bang grades: MONG DOI LOI 229 (permission denied)';
BEGIN TRY
    EXECUTE AS USER = N'2001210001';
    SELECT TOP 1 * FROM dbo.grades;
    REVERT;
    PRINT N'TEST 2: FAIL - SV doc duoc bang goc!';
END TRY
BEGIN CATCH
    REVERT;
    PRINT N'TEST 2: PASS - bi tu choi nhu mong doi (' + ERROR_MESSAGE() + N')';
END CATCH
GO
PRINT N'TEST 3 - GV sua diem lop KHONG duoc phan cong (BMCSDL-N01 la cua GV Lan, actor gv.khoa): MONG DOI THROW 51003';
BEGIN TRY
    EXEC dbo.sp_update_grade N'BMCSDL-N01', N'2001210002', 5.0, 5.0, N'gv.khoa', N'test quyen';
    PRINT N'TEST 3: FAIL - sua duoc diem lop nguoi khac!';
END TRY
BEGIN CATCH PRINT N'TEST 3: PASS - ' + ERROR_MESSAGE(); END CATCH
GO
PRINT N'TEST 4 - Phong dao tao sua diem: MONG DOI THROW 51002 (dao tao khong sua diem truc tiep)';
BEGIN TRY
    EXEC dbo.sp_update_grade N'CSDL-N01', N'2001210001', 5.0, 5.0, N'daotao01', N'test quyen';
    PRINT N'TEST 4: FAIL - dao tao sua duoc diem!';
END TRY
BEGIN CATCH PRINT N'TEST 4: PASS - ' + ERROR_MESSAGE(); END CATCH
GO
PRINT N'TEST 5 - GV sua diem lop duoc phan cong (CSDL-N01 / 2001210001): MONG DOI thanh cong + co audit log';
EXEC dbo.sp_update_grade N'CSDL-N01', N'2001210001', 8.0, 7.5, N'gv.khoa', N'kiem thu 08';
SELECT TOP 3 * FROM dbo.v_grade_change_history ORDER BY changed_at DESC;
PRINT N'TEST 5: PASS neu dong audit o tren la cua gv.khoa';
GO
PRINT N'TEST 6 - Bao cao bat thuong: MONG DOI liet ke username co >=5 lan DENIED/FAILED trong 60 phut (co the rong neu chua du du lieu)';
EXEC dbo.sp_anomaly_report 60, 5;
GO
PRINT N'08_security_tests.sql: het kich ban';
GO
