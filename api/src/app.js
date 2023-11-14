'use strict';
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { createDb, logAccess } = require('./db');
const { presentStudent } = require('./security');

const JWT_SECRET = process.env.JWT_SECRET || 'demo-secret-chi-dung-cho-bai-hoc';
const MAX_FAILED = 5;

function createApp() {
  const { db } = createDb();
  const app = express();
  app.use(express.json());

  const auth = (req, res, next) => {
    const h = req.headers.authorization || '';
    if (!h.startsWith('Bearer ')) return res.status(401).json({ error: 'Thiếu token' });
    try { req.user = jwt.verify(h.slice(7), JWT_SECRET); next(); }
    catch { return res.status(401).json({ error: 'Token không hợp lệ/hết hạn' }); }
  };
  const requireRole = (...roles) => (req, res, next) =>
    roles.includes(req.user.role_code) ? next() : res.status(403).json({ error: 'Không có quyền' });

  app.post('/auth/login', (req, res) => {
    const { username, password } = req.body || {};
    const u = db.prepare('SELECT * FROM users WHERE username = ?').get(username || '');
    const fail = (msg, code = 401) => {
      if (u) db.prepare('UPDATE users SET failed_login_count = failed_login_count + 1 WHERE user_id = ?').run(u.user_id);
      logAccess(db, username, 'LOGIN', null, 'FAILED', req.ip);
      return res.status(code).json({ error: msg });
    };
    if (!u || !u.is_active) return fail('Sai tài khoản hoặc mật khẩu');
    if (u.locked_until && new Date(u.locked_until) > new Date()) return fail('Tài khoản đang bị khóa tạm thời', 423);
    if (!bcrypt.compareSync(password || '', u.password_hash)) {
      const after = db.prepare('SELECT failed_login_count FROM users WHERE user_id = ?').get(u.user_id).failed_login_count + 1;
      if (after >= MAX_FAILED) db.prepare("UPDATE users SET locked_until = datetime('now','+15 minutes') WHERE user_id = ?").run(u.user_id);
      return fail('Sai tài khoản hoặc mật khẩu');
    }
    db.prepare('UPDATE users SET failed_login_count = 0, locked_until = NULL WHERE user_id = ?').run(u.user_id);
    logAccess(db, username, 'LOGIN', null, 'SUCCESS', req.ip);
    const token = jwt.sign({ user_id: u.user_id, username: u.username, role_code: u.role_code,
      student_id: u.student_id, lecturer_id: u.lecturer_id }, JWT_SECRET, { expiresIn: '1h' });
    // Response dang nhap KHONG bao gio chua password_hash
    res.json({ token, user: { username: u.username, role_code: u.role_code } });
  });

  app.get('/students/:id/profile', auth, (req, res) => {
    const id = Number(req.params.id);
    const row = db.prepare('SELECT * FROM students WHERE student_id = ?').get(id);
    if (!row) return res.status(404).json({ error: 'Không tìm thấy sinh viên' });
    const v = req.user;
    if (v.role_code === 'SINH_VIEN' && v.student_id !== id) {
      logAccess(db, v.username, 'VIEW_PROFILE', String(id), 'DENIED', req.ip);
      return res.status(403).json({ error: 'Sinh viên chỉ xem được hồ sơ của mình' });
    }
    if (v.role_code === 'GIANG_VIEN') {
      const taught = db.prepare(`SELECT 1 FROM enrollments e JOIN classes c ON c.class_id = e.class_id
        WHERE e.student_id = ? AND c.lecturer_id = ?`).get(id, v.lecturer_id);
      if (!taught) { logAccess(db, v.username, 'VIEW_PROFILE', String(id), 'DENIED', req.ip);
        return res.status(403).json({ error: 'Giảng viên chỉ xem được sinh viên trong lớp mình phụ trách' }); }
    }
    logAccess(db, v.username, 'VIEW_PROFILE', String(id), 'SUCCESS', req.ip);
    res.json(presentStudent(row, v));
  });

  app.get('/students/:id/grades', auth, (req, res) => {
    const id = Number(req.params.id);
    const v = req.user;
    if (v.role_code === 'ADMIN') { // Admin quan ly tai khoan, KHONG xem diem chi tiet
      logAccess(db, v.username, 'VIEW_GRADES', String(id), 'DENIED', req.ip);
      return res.status(403).json({ error: 'Admin không có quyền xem điểm chi tiết' });
    }
    if (v.role_code === 'SINH_VIEN' && v.student_id !== id) {
      logAccess(db, v.username, 'VIEW_GRADES', String(id), 'DENIED', req.ip);
      return res.status(403).json({ error: 'Sinh viên chỉ xem được điểm của mình' });
    }
    if (v.role_code === 'GIANG_VIEN') {
      const taught = db.prepare(`SELECT 1 FROM enrollments e JOIN classes c ON c.class_id = e.class_id
        WHERE e.student_id = ? AND c.lecturer_id = ?`).get(id, v.lecturer_id);
      if (!taught) { logAccess(db, v.username, 'VIEW_GRADES', String(id), 'DENIED', req.ip);
        return res.status(403).json({ error: 'Sinh viên không thuộc lớp giảng viên phụ trách' }); }
    }
    const rows = db.prepare(`SELECT c.class_code, co.course_name, g.process_score, g.final_score, g.total_score
      FROM grades g JOIN enrollments e ON e.enrollment_id = g.enrollment_id
      JOIN classes c ON c.class_id = e.class_id JOIN courses co ON co.course_id = c.course_id
      WHERE e.student_id = ? ORDER BY c.class_code`).all(id);
    logAccess(db, v.username, 'VIEW_GRADES', String(id), 'SUCCESS', req.ip);
    res.json(rows);
  });

  app.put('/grades', auth, (req, res) => {
    const v = req.user;
    const { class_code, student_code, process_score, final_score, reason } = req.body || {};
    const deny = (msg) => { logAccess(db, v.username, 'UPDATE_GRADE', `${class_code}/${student_code}`, 'DENIED', req.ip);
      return res.status(403).json({ error: msg }); };
    if (v.role_code !== 'GIANG_VIEN') return deny('Chỉ giảng viên mới được sửa điểm (Phòng đào tạo/Admin không sửa điểm trực tiếp)');
    const enr = db.prepare(`SELECT e.enrollment_id, g.grade_id, g.process_score AS op, g.final_score AS ofin
      FROM enrollments e JOIN classes c ON c.class_id = e.class_id JOIN students s ON s.student_id = e.student_id
      LEFT JOIN grades g ON g.enrollment_id = e.enrollment_id
      WHERE c.class_code = ? AND s.student_code = ? AND c.lecturer_id = ?`).get(class_code, student_code, v.lecturer_id);
    if (!enr) return deny('Lớp không thuộc phân công của giảng viên');
    if (!(process_score >= 0 && process_score <= 10 && final_score >= 0 && final_score <= 10))
      return res.status(400).json({ error: 'Điểm phải trong khoảng 0-10' });
    const total = Math.round((process_score * 0.4 + final_score * 0.6) * 100) / 100;
    const now = new Date().toISOString();
    if (enr.grade_id == null) {
      const info = db.prepare('INSERT INTO grades (enrollment_id, process_score, final_score, total_score, updated_by, updated_at) VALUES (?,?,?,?,?,?)')
        .run(enr.enrollment_id, process_score, final_score, total, v.username, now);
      db.prepare('INSERT INTO grade_audit_log (grade_id,enrollment_id,old_process,new_process,old_final,new_final,changed_by,change_reason,changed_at) VALUES (?,?,?,?,?,?,?,?,?)')
        .run(Number(info.lastInsertRowid), enr.enrollment_id, null, process_score, null, final_score, v.username, reason || null, now);
    } else {
      db.prepare('UPDATE grades SET process_score=?, final_score=?, total_score=?, updated_by=?, updated_at=? WHERE grade_id=?')
        .run(process_score, final_score, total, v.username, now, enr.grade_id);
      db.prepare('INSERT INTO grade_audit_log (grade_id,enrollment_id,old_process,new_process,old_final,new_final,changed_by,change_reason,changed_at) VALUES (?,?,?,?,?,?,?,?,?)')
        .run(enr.grade_id, enr.enrollment_id, enr.op, process_score, enr.ofin, final_score, v.username, reason || null, now);
    }
    logAccess(db, v.username, 'UPDATE_GRADE', `${class_code}/${student_code}`, 'SUCCESS', req.ip);
    res.json({ ok: true, total_score: total });
  });

  app.get('/admin/users', auth, requireRole('ADMIN'), (req, res) => {
    // Chi tra ve thong tin cong khai - tuyet doi khong co password_hash
    res.json(db.prepare('SELECT user_id, username, role_code, student_id, lecturer_id, is_active FROM users ORDER BY user_id').all());
  });

  app.get('/reports/anomalies', auth, requireRole('ADMIN', 'DAO_TAO'), (req, res) => {
    const minutes = Number(req.query.minutes || 60), threshold = Number(req.query.threshold || 5);
    const rows = db.prepare(`SELECT username, COUNT(*) AS bad_count FROM access_log
      WHERE result IN ('DENIED','FAILED') AND created_at >= datetime('now', ?)
      GROUP BY username HAVING COUNT(*) >= ? ORDER BY bad_count DESC`)
      .all(`-${minutes} minutes`, threshold);
    res.json(rows);
  });

  /* ===== DEMO SQL INJECTION - CHI DUNG TREN DB DEMO, TUYET DOI KHONG DUNG THAT ===== */
  app.get('/demo/vulnerable/search', auth, (req, res) => {
    // LO HONG CO Y: noi chuoi truc tiep vao SQL -> bi SQL Injection
    const q = req.query.q || '';
    const sql = `SELECT student_code, full_name FROM students WHERE student_code = '${q}'`;
    try { res.json({ mode: 'vulnerable', sql, rows: db.prepare(sql).all() }); }
    catch (e) { res.status(400).json({ mode: 'vulnerable', sql, error: e.message }); }
  });
  app.get('/demo/safe/search', auth, (req, res) => {
    // AN TOAN: parameterized query - chuoi injection chi la du lieu thuong
    const q = req.query.q || '';
    res.json({ mode: 'safe', rows: db.prepare('SELECT student_code, full_name FROM students WHERE student_code = ?').all(q) });
  });

  app.locals.db = db;
  return app;
}
module.exports = { createApp };
