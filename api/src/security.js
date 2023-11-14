'use strict';
/* Che du lieu nhay cam theo vai tro.
   - DAO_TAO: thay full (nghiep vu hoc vu can doi chieu giay to)
   - Chu so huu (sinh vien xem cua minh): thay full cua chinh minh
   - Con lai (GV, ADMIN, KIEM_TRA): bi mask */
function maskNationalId(v) { return v ? '*'.repeat(Math.max(0, v.length - 3)) + v.slice(-3) : v; }
function maskPhone(v) { return v ? '*'.repeat(Math.max(0, v.length - 3)) + v.slice(-3) : v; }
function presentStudent(row, viewer) {
  const isOwner = viewer.role_code === 'SINH_VIEN' && viewer.student_id === row.student_id;
  const full = viewer.role_code === 'DAO_TAO' || isOwner;
  return {
    student_id: row.student_id, student_code: row.student_code, full_name: row.full_name,
    date_of_birth: row.date_of_birth, gender: row.gender, email: row.email, home_class: row.home_class,
    phone: full ? row.phone : maskPhone(row.phone),
    national_id: full ? row.national_id : maskNationalId(row.national_id),
  };
}
module.exports = { maskNationalId, maskPhone, presentStudent };
