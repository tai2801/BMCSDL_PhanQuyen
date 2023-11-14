'use strict';
const { test, before, after } = require('node:test');
const assert = require('node:assert');
const { createApp } = require('../src/app');

let server, base, appInstance;
const tokens = {};
async function login(u) {
  const r = await fetch(`${base}/auth/login`, { method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: u, password: 'Demo@123' }) });
  return r.json().then(b => b.token);
}
const H = t => ({ Authorization: `Bearer ${t}`, 'Content-Type': 'application/json' });

before(async () => {
  appInstance = createApp();
  server = appInstance.listen(0);
  base = `http://127.0.0.1:${server.address().port}`;
  for (const u of ['admin', 'daotao01', 'gv.khoa', 'gv.lan', '2001210001', '2001210002']) tokens[u] = await login(u);
});
after(() => server.close());

test('đăng nhập đúng trả JWT, response không chứa password_hash', async () => {
  const r = await fetch(`${base}/auth/login`, { method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'admin', password: 'Demo@123' }) });
  const b = await r.json();
  assert.strictEqual(r.status, 200); assert.ok(b.token);
  assert.ok(!JSON.stringify(b).includes('password_hash') && !JSON.stringify(b).includes('$2b$'));
});
test('đăng nhập sai mật khẩu bị 401', async () => {
  const r = await fetch(`${base}/auth/login`, { method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'admin', password: 'sai' }) });
  assert.strictEqual(r.status, 401);
});
test('không có token bị 401', async () => {
  const r = await fetch(`${base}/students/1/profile`);
  assert.strictEqual(r.status, 401);
});
test('SV xem hồ sơ của mình: thấy CCCD đầy đủ của chính mình', async () => {
  const b = await (await fetch(`${base}/students/1/profile`, { headers: H(tokens['2001210001']) })).json();
  assert.strictEqual(b.national_id, '079202001234');
});
test('SV xem hồ sơ SV khác bị 403', async () => {
  const r = await fetch(`${base}/students/2/profile`, { headers: H(tokens['2001210001']) });
  assert.strictEqual(r.status, 403);
});
test('SV xem điểm SV khác bị 403', async () => {
  const r = await fetch(`${base}/students/2/grades`, { headers: H(tokens['2001210001']) });
  assert.strictEqual(r.status, 403);
});
test('SV xem điểm của mình được', async () => {
  const b = await (await fetch(`${base}/students/1/grades`, { headers: H(tokens['2001210001']) })).json();
  assert.strictEqual(b.length, 2);
});
test('Đào tạo xem hồ sơ: CCCD/SĐT không bị mask', async () => {
  const b = await (await fetch(`${base}/students/1/profile`, { headers: H(tokens.daotao01) })).json();
  assert.strictEqual(b.phone, '0903123456');
});
test('GV xem hồ sơ SV lớp mình: CCCD bị mask', async () => {
  const b = await (await fetch(`${base}/students/1/profile`, { headers: H(tokens['gv.khoa']) })).json();
  assert.ok(b.national_id.startsWith('*') && b.national_id.endsWith('234'));
});
test('GV xem SV không thuộc lớp mình bị 403', async () => {
  const r = await fetch(`${base}/students/3/profile`, { headers: H(tokens['gv.lan']) });
  assert.strictEqual(r.status, 403);
});
test('Admin xem điểm chi tiết bị 403 (đúng ma trận quyền)', async () => {
  const r = await fetch(`${base}/students/1/grades`, { headers: H(tokens.admin) });
  assert.strictEqual(r.status, 403);
});
test('GV sửa điểm lớp được phân công: thành công + tổng điểm đúng công thức', async () => {
  const r = await fetch(`${base}/grades`, { method: 'PUT', headers: H(tokens['gv.khoa']),
    body: JSON.stringify({ class_code: 'CSDL-N01', student_code: '2001210002', process_score: 7, final_score: 9, reason: 'chấm lại' }) });
  const b = await r.json();
  assert.strictEqual(r.status, 200); assert.strictEqual(b.total_score, 8.2);
});
test('GV sửa điểm lớp của GV khác bị 403', async () => {
  const r = await fetch(`${base}/grades`, { method: 'PUT', headers: H(tokens['gv.khoa']),
    body: JSON.stringify({ class_code: 'BMCSDL-N01', student_code: '2001210002', process_score: 5, final_score: 5 }) });
  assert.strictEqual(r.status, 403);
});
test('Phòng đào tạo sửa điểm bị 403 (không sửa điểm trực tiếp)', async () => {
  const r = await fetch(`${base}/grades`, { method: 'PUT', headers: H(tokens.daotao01),
    body: JSON.stringify({ class_code: 'CSDL-N01', student_code: '2001210001', process_score: 5, final_score: 5 }) });
  assert.strictEqual(r.status, 403);
});
test('Sửa điểm ghi audit log thay đổi điểm (kiểm tra trực tiếp trong DB)', async () => {
  const db = appInstance.locals.db;
  const before = db.prepare('SELECT COUNT(*) AS c FROM grade_audit_log').get().c;
  const r = await fetch(`${base}/grades`, { method: 'PUT', headers: H(tokens['gv.lan']),
    body: JSON.stringify({ class_code: 'BMCSDL-N01', student_code: '2001210001', process_score: 9, final_score: 9, reason: 'phúc khảo' }) });
  assert.strictEqual(r.status, 200);
  const rows = db.prepare('SELECT * FROM grade_audit_log ORDER BY audit_id DESC').all();
  assert.strictEqual(rows.length, before + 1);
  assert.strictEqual(rows[0].changed_by, 'gv.lan');
  assert.strictEqual(rows[0].new_process, 9);
  assert.strictEqual(rows[0].change_reason, 'phúc khảo');
});
test('/admin/users chỉ Admin vào được và không lộ hash', async () => {
  const ok = await fetch(`${base}/admin/users`, { headers: H(tokens.admin) });
  const b = await ok.json();
  assert.strictEqual(ok.status, 200); assert.ok(!JSON.stringify(b).includes('$2b$'));
  const no = await fetch(`${base}/admin/users`, { headers: H(tokens.daotao01) });
  assert.strictEqual(no.status, 403);
});
test('SQL Injection: bản vulnerable bị khai thác trả về nhiều dòng', async () => {
  const q = encodeURIComponent(`' OR '1'='1`);
  const b = await (await fetch(`${base}/demo/vulnerable/search?q=${q}`, { headers: H(tokens.admin) })).json();
  assert.ok(b.rows.length > 1, 'vulnerable phải lộ dữ liệu khi bị injection');
});
test('SQL Injection: bản safe (parameterized) vô hiệu hóa chuỗi tấn công', async () => {
  const q = encodeURIComponent(`' OR '1'='1`);
  const b = await (await fetch(`${base}/demo/safe/search?q=${q}`, { headers: H(tokens.admin) })).json();
  assert.strictEqual(b.rows.length, 0);
  const ok = await (await fetch(`${base}/demo/safe/search?q=2001210001`, { headers: H(tokens.admin) })).json();
  assert.strictEqual(ok.rows.length, 1);
});
test('Báo cáo bất thường: sau nhiều lần bị từ chối, username xuất hiện khi hạ ngưỡng', async () => {
  for (let i = 0; i < 5; i++) await fetch(`${base}/students/2/profile`, { headers: H(tokens['2001210001']) });
  const b = await (await fetch(`${base}/reports/anomalies?minutes=60&threshold=3`, { headers: H(tokens.admin) })).json();
  assert.ok(b.some(r => r.username === '2001210001' && r.bad_count >= 3));
});
test('Báo cáo bất thường: SV không có quyền xem', async () => {
  const r = await fetch(`${base}/reports/anomalies`, { headers: H(tokens['2001210001']) });
  assert.strictEqual(r.status, 403);
});
