/* =====================================================================
   BMCSDL - SECUREDB | 06_encryption.sql - ma hoa cot nhay cam (CCCD, SDT)
   Cach 1 (chay duoc trong file nay): ma hoa doi xung EncryptByKey (AES_256)
   Cach 2 (khuyen nghi production, chi mo ta): Always Encrypted - ma hoa
     phia client driver, DB server khong bao gio thay plaintext/key; can
     tao Column Master Key + Column Encryption Key bang SSMS Wizard,
     cot khai bao: national_id_enc VARBINARY(256) ENCRYPTED WITH
     (COLUMN_ENCRYPTION_KEY = CEK_Auto1, ENCRYPTION_TYPE = Deterministic,
      ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256'). Xem SECURITY_MODEL.md.
   ===================================================================== */
USE SecureDB;
GO
IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = N'SecureDB_DataKey')
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = N'SecureDB_Cert')
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name LIKE N'##MS_DatabaseMasterKey##')
            CREATE MASTER KEY ENCRYPTION BY PASSWORD = N'<DAT-MAT-KHAU-THAT-VAO-BIEN-MOI-TRUONG>';
        CREATE CERTIFICATE SecureDB_Cert WITH SUBJECT = N'SecureDB data protection';
    END
    CREATE SYMMETRIC KEY SecureDB_DataKey
        WITH ALGORITHM = AES_256 ENCRYPTION BY CERTIFICATE SecureDB_Cert;
END
GO
/* --- DEMO: ma hoa CCCD/SDT cua 1 sinh vien mau --- */
OPEN SYMMETRIC KEY SecureDB_DataKey DECRYPTION BY CERTIFICATE SecureDB_Cert;
UPDATE dbo.students
SET national_id_enc = EncryptByKey(Key_GUID(N'SecureDB_DataKey'), N'079202001234'),
    phone_enc       = EncryptByKey(Key_GUID(N'SecureDB_DataKey'), N'0903123456')
WHERE student_code = N'2001210001';
-- Doc giai ma (chi role duoc cap quyen VIEW DEFINITION + quyen tren certificate moi mo duoc key):
SELECT student_code,
       CONVERT(NVARCHAR(32), DecryptByKey(national_id_enc)) AS national_id_plain_demo,
       CONVERT(NVARCHAR(32), DecryptByKey(phone_enc))       AS phone_plain_demo
FROM dbo.students WHERE student_code = N'2001210001';
CLOSE SYMMETRIC KEY SecureDB_DataKey;
GO
PRINT N'06_encryption.sql: OK (demo EncryptByKey xong, key da dong)';
GO
