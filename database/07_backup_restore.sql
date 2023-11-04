/* =====================================================================
   BMCSDL - SECUREDB | 07_backup_restore.sql - sao luu / khoi phuc (mau)
   Thay <BACKUP_DIR> bang thu muc that tren may SQL Server truoc khi chay.
   ===================================================================== */
DECLARE @backup_file NVARCHAR(400) =
    N'<BACKUP_DIR>\SecureDB_' + FORMAT(SYSDATETIME(), 'yyyyMMdd_HHmmss') + N'.bak';
BACKUP DATABASE SecureDB TO DISK = @backup_file WITH INIT, COMPRESSION, CHECKSUM;
RESTORE VERIFYONLY FROM DISK = @backup_file WITH CHECKSUM;
PRINT N'Backup xong: ' + @backup_file;
GO
/* --- Khoi phuc (CHI chay khi can, se ghi de du lieu hien tai) ---
USE master;
ALTER DATABASE SecureDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE DATABASE SecureDB FROM DISK = N'<BACKUP_DIR>\SecureDB_YYYYMMDD_HHMMSS.bak' WITH REPLACE;
ALTER DATABASE SecureDB SET MULTI_USER;
-------------------------------------------------------------------- */
