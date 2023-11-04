# PHÂN TÍCH NGHIỆP VỤ — SECUREDB ACCESS CONTROL

## Actors
Quản trị hệ thống, Phòng đào tạo, Giảng viên, Sinh viên, Nhân viên kiểm tra dữ liệu.

## Use cases chính
- UC01 Đăng nhập an toàn (khóa sau 5 lần sai, ghi access_log)
- UC02 Sinh viên xem hồ sơ + điểm của mình
- UC03 Giảng viên xem/sửa điểm lớp được phân công (ghi audit + lý do)
- UC04 Phòng đào tạo quản lý học vụ, xem điểm toàn trường (không sửa điểm)
- UC05 Admin quản lý tài khoản/vai trò (không xem điểm chi tiết)
- UC06 Xem báo cáo truy cập bất thường (nhiều DENIED/FAILED trong cửa sổ thời gian)
- UC07 Sao lưu/khôi phục CSDL theo kịch bản
- UC08 (Minh họa học tập) So sánh SQL Injection: endpoint lỗi vs endpoint an toàn

## Business rules
- BR01 Điểm tổng = 0,4 × quá trình + 0,6 × cuối kỳ; điểm thành phần trong [0,10].
- BR02 Chỉ giảng viên được sửa điểm, và chỉ lớp được phân công.
- BR03 Mọi thay đổi điểm phải có audit (giá trị cũ/mới, người sửa, lý do, thời gian).
- BR04 CCCD/SĐT chỉ hiển thị đầy đủ cho Phòng đào tạo và chính chủ sở hữu; vai trò khác bị mask còn 3 ký tự cuối.
- BR05 Đăng nhập sai 5 lần liên tiếp → khóa 15 phút.
- BR06 ≥5 lần truy cập bị từ chối/thất bại trong 60 phút → xuất hiện trong báo cáo bất thường.
- BR07 Mật khẩu lưu dạng BCrypt hash; API response không bao giờ chứa hash hay mật khẩu.

## Luồng ngoại lệ
- Xem dữ liệu người khác → 403 + ghi access_log DENIED.
- Token hết hạn/không có → 401.
- Tài khoản bị khóa → 423.
