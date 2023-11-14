'use strict';
/* Ban DEMO cua API chay tren SQLite (node:sqlite) de kiem thu nhanh
   cac quy tac phan quyen trong moi truong hoc tap. Cac script T-SQL
   cho SQL Server nam trong thu muc ../../database. */
const { DatabaseSync } = require('node:sqlite');
const bcrypt = require('bcryptjs');

const DEMO_PASSWORD = 'Demo@123'; // mat khau demo cong khai cho bai hoc - phai doi khi dung that

function createDb() {
  const db = new DatabaseSync(':memory:');
  db.exec(`
    CREATE TABLE roles (role_code TEXT PRIMARY KEY, role_name TEXT);
    CREATE TABLE students (student_id INTEGER PRIMARY KEY, student_code TEXT UNIQUE, full_name TEXT,
      date_of_birth TEXT, gender TEXT, email TEXT, phone TEXT, national_id TEXT, home_class TEXT);
    CREATE TABLE lecturers (lecturer_id INTEGER PRIMARY KEY, lecturer_code TEXT UNIQUE, full_name TEXT, email TEXT, department TEXT);
    CREATE TABLE users (user_id INTEGER PRIMARY KEY, username TEXT UNIQUE, password_hash TEXT, role_code TEXT,
      student_id INTEGER, lecturer_id INTEGER, is_active INTEGER DEFAULT 1,
      failed_login_count INTEGER DEFAULT 0, locked_until TEXT);
    CREATE TABLE courses (course_id INTEGER PRIMARY KEY, course_code TEXT UNIQUE, course_name TEXT, credits INTEGER);
    CREATE TABLE classes (class_id INTEGER PRIMARY KEY, class_code TEXT UNIQUE, course_id INTEGER, lecturer_id INTEGER, semester TEXT, academic_year TEXT);
    CREATE TABLE enrollments (enrollment_id INTEGER PRIMARY KEY, class_id INTEGER, student_id INTEGER, UNIQUE(class_id, student_id));
    CREATE TABLE grades (grade_id INTEGER PRIMARY KEY, enrollment_id INTEGER UNIQUE, process_score REAL, final_score REAL,
      total_score REAL, updated_by TEXT, updated_at TEXT);
    CREATE TABLE grade_audit_log (audit_id INTEGER PRIMARY KEY AUTOINCREMENT, grade_id INTEGER, enrollment_id INTEGER,
      old_process REAL, new_process REAL, old_final REAL, new_final REAL, changed_by TEXT, change_reason TEXT, changed_at TEXT);
    CREATE TABLE access_log (log_id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT, action TEXT, target TEXT,
      result TEXT, ip_address TEXT, created_at TEXT);
  `);
  const hash = bcrypt.hashSync(DEMO_PASSWORD, 10);
  const role = db.prepare('INSERT INTO roles VALUES (?,?)');
  [['ADMIN','Quản trị hệ thống'],['DAO_TAO','Phòng đào tạo'],['GIANG_VIEN','Giảng viên'],
   ['SINH_VIEN','Sinh viên'],['KIEM_TRA','Nhân viên kiểm tra dữ liệu']].forEach(r => role.run(...r));
  const st = db.prepare('INSERT INTO students VALUES (?,?,?,?,?,?,?,?,?)');
  st.run(1,'2001210001','Nguyễn Văn An','2002-03-14','Nam','an.nv@sv.huit.edu.vn','0903123456','079202001234','K13-CNTT');
  st.run(2,'2001210002','Trần Thị Bình','2002-07-02','Nữ','binh.tt@sv.huit.edu.vn','0912345678','079202002345','K13-CNTT');
  st.run(3,'2001210003','Lê Hoàng Cường','2001-11-25','Nam','cuong.lh@sv.huit.edu.vn','0987654321','079201003456','K13-CNTT');
  const lc = db.prepare('INSERT INTO lecturers VALUES (?,?,?,?,?)');
  lc.run(1,'GV01','TS. Hoàng Văn Khoa','khoa.hv@huit.edu.vn','Khoa CNTT');
  lc.run(2,'GV02','ThS. Vũ Thị Lan','lan.vt@huit.edu.vn','Khoa CNTT');
  const us = db.prepare('INSERT INTO users (user_id,username,password_hash,role_code,student_id,lecturer_id) VALUES (?,?,?,?,?,?)');
  us.run(1,'admin',hash,'ADMIN',null,null);
  us.run(2,'daotao01',hash,'DAO_TAO',null,null);
  us.run(3,'gv.khoa',hash,'GIANG_VIEN',null,1);
  us.run(4,'gv.lan',hash,'GIANG_VIEN',null,2);
  us.run(5,'2001210001',hash,'SINH_VIEN',1,null);
  us.run(6,'2001210002',hash,'SINH_VIEN',2,null);
  us.run(7,'2001210003',hash,'SINH_VIEN',3,null);
  const co = db.prepare('INSERT INTO courses VALUES (?,?,?,?)');
  co.run(1,'INT2213','Cơ sở dữ liệu',3); co.run(2,'INT2214','Bảo mật cơ sở dữ liệu',3);
  const cl = db.prepare('INSERT INTO classes VALUES (?,?,?,?,?,?)');
  cl.run(1,'CSDL-N01',1,1,'HK1','2023-2024'); cl.run(2,'BMCSDL-N01',2,2,'HK1','2023-2024');
  const en = db.prepare('INSERT INTO enrollments VALUES (?,?,?)');
  en.run(1,1,1); en.run(2,1,2); en.run(3,1,3); en.run(4,2,1); en.run(5,2,2);
  const gr = db.prepare('INSERT INTO grades VALUES (?,?,?,?,?,?,?)');
  const total = (p,f) => Math.round((p*0.4 + f*0.6)*100)/100;
  gr.run(1,1,8.0,7.5,total(8.0,7.5),'gv.khoa','2023-11-01T08:00:00Z');
  gr.run(2,2,6.5,8.0,total(6.5,8.0),'gv.khoa','2023-11-01T08:00:00Z');
  gr.run(3,4,7.0,6.0,total(7.0,6.0),'gv.lan','2023-11-01T08:00:00Z');
  return { db, DEMO_PASSWORD };
}

function logAccess(db, username, action, target, result, ip) {
  db.prepare('INSERT INTO access_log (username,action,target,result,ip_address,created_at) VALUES (?,?,?,?,?,?)')
    .run(username || null, action, target || null, result, ip || null, new Date().toISOString());
}
module.exports = { createDb, logAccess };
