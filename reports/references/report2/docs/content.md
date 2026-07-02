# KHUNG BÁO CÁO ĐỒ ÁN TỐT NGHIỆP: THIẾT KẾ VÀ CHẾ TẠO DRONE HỖ TRỢ GIÁM SÁT AN NINH VÀ CỨU HỘ TÍCH HỢP AI

## PHẦN HÀNH CHÍNH VÀ MỞ ĐẦU
* **Trang bìa** (Theo mẫu quy định của Đại học Bách Khoa Hà Nội)
* **Đánh giá quyển đồ án tốt nghiệp** (Dành cho Giảng viên hướng dẫn)
* **Đánh giá quyển đồ án tốt nghiệp** (Dành cho Cán bộ phản biện)
* **Lời nói đầu**
* **Lời cảm ơn**
* **Lời cam đoan**
* **Mục lục**
* **Danh mục hình ảnh**
* **Danh mục bảng biểu**
* **Danh mục từ viết tắt**
* **Tóm tắt đồ án**

---

## CHƯƠNG 1. GIỚI THIỆU TỔNG QUAN VỀ ĐỀ TÀI

**1.1. Đặt vấn đề**
* Bối cảnh công nghệ, tính ứng dụng thực tiễn của UAV/Drone trong giám sát và đặc biệt là công tác tìm kiếm cứu nạn (Search and Rescue - SAR).
* Tầm quan trọng của việc ứng dụng Trí tuệ nhân tạo (AI) trong phân tích tự động dữ liệu hình ảnh cứu hộ từ trên cao.
* Lý do lựa chọn đề tài: Thiết kế và chế tạo Drone Quadcopter kết hợp trạm mặt đất tích hợp mô hình học sâu (YOLO) để phát hiện và định danh nạn nhân khẩn cấp.

**1.2. Mục tiêu và kết quả dự kiến**
* Mục tiêu phần cứng và firmware: Thiết kế bo mạch Flight Controller dựa trên STM32F103C8T6 hoạt động ổn định.
* Mục tiêu phần mềm AI: Tích hợp hệ thống phát hiện cứu hộ thông minh thời gian thực trên máy trạm mặt đất.
* Sản phẩm đầu ra mong muốn.

**1.3. Những công việc chính**
* Nghiên cứu lý thuyết động lực học bay và lập trình firmware nhúng.
* Thiết kế phần cứng PCB Flight Controller và lắp ráp cơ khí Drone.
* Nghiên cứu lý thuyết mạng học sâu YOLO và xây dựng thuật toán phân tích tư thế, cử chỉ cứu hộ.
* Phát triển chương trình điều phối trạm mặt đất và tích hợp mô hình AI nhận diện cứu hộ.
* Thử nghiệm thực tế và đánh giá hiệu năng toàn hệ thống.

---

## CHƯƠNG 2. CƠ SỞ LÝ THUYẾT VỀ HỆ THỐNG BAY VÀ ĐIỀU KHIỂN NHÚNG

**2.1. Động lực học Quadcopter và Bộ điều khiển phản hồi**
* 2.1.1. Các lực tác dụng lên UAV (Lực nâng, lực kéo, mô-men xoắn) và hệ trục tọa độ bay.
* 2.1.2. Nguyên lý di chuyển và cân bằng động học của Quadcopter.
* 2.1.3. Hệ thống điều khiển phản hồi PID trong miền rời rạc cho 3 trục Roll, Pitch, Yaw.
* 2.1.4. Kỹ thuật chống bão hòa tích phân (Anti-windup) và lọc thông thấp số (IIR Filter) cho vi phân trong hệ thống nhúng.

**2.2. Hệ thống cảm biến định vị quán tính**
* 2.2.1. Cấu tạo và nguyên lý hoạt động của Cảm biến đo lường quán tính (IMU) 6 trục MPU6050.
* 2.2.2. Phương pháp ước lượng tư thế bay (Attitude Estimation) bằng bộ lọc bù (Complementary Filter).

**2.3. Chip nhớ và Giao thức truyền thông điều khiển**
* 2.3.1. Chip nhớ EEPROM 24LC256 lưu trữ tham số cấu hình.
* 2.3.2. Giao thức truyền thông điều khiển vô tuyến ExpressLRS (ELRS) và giao thức CRSF tốc độ cao.
* 2.3.3. Tín hiệu điều khiển động cơ qua PWM truyền thống.

---

## CHƯƠNG 3. NGHIÊN CỨU THUẬT TOÁN HỌC SÂU YOLO VÀ DUNG HỢP QUYẾT ĐỊNH TRONG CỨU HỘ

**3.1. Tổng quan về kiến trúc YOLO trong phát hiện đối tượng**
* 3.1.1. Lý thuyết mạng học sâu phát hiện đối tượng thời gian thực YOLO (You Only Look Once).
* 3.1.2. Ứng dụng mô hình YOLO trong phát hiện nạn nhân cứu hộ (YOLOv8-Rescue) và phân loại tư thế người (YOLOv8-Posture).

**3.2. Ước lượng tư thế người (Pose Estimation) dựa trên YOLO-Pose**
* 3.2.1. Nguyên lý ước lượng tư thế người và trích xuất 17 điểm khung xương keypoints.
* 3.2.2. Phân tích hình học tư thế dựa trên keypoints: phát hiện trạng thái nằm/ngã, nghiêng người và gục đầu (collapsed).

**3.3. Thuật toán phân tích cử chỉ động và trạng thái nạn nhân**
* 3.3.1. Phát hiện cử chỉ vẫy hai tay cầu cứu (two_hands_waving) dựa trên phân tích chuyển động tuần hoàn cổ tay so với vai.
* 3.3.2. Thuật toán đánh giá trạng thái bất động tĩnh (immobility) thông qua tích lũy và kiểm tra độ lệch tâm của mục tiêu trong thời gian thực.

**3.4. Cơ chế dung hợp quyết định (Decision Fusion) đa mô hình**
* 3.4.1. Sự cần thiết của việc kết hợp thông tin đa nguồn (Pose + Posture + Rescue Model) để giảm thiểu báo nhầm (false alarm).
* 3.4.2. Thuật toán dung hợp tích lũy bằng chứng độc lập tính xác suất nạn nhân (victim probability).
* 3.4.3. Thiết lập hệ thống tính điểm nguy cấp (Danger Score) để phân loại trạng thái khẩn cấp (Bình thường, Nghi ngờ, Cần cứu giúp).

---

## CHƯƠNG 4. THIẾT KẾ VÀ CHẾ TẠO HỆ THỐNG PHẦN CỨNG DRONE VÀ TRẠM MẶT ĐẤT

**4.1. Thiết kế phần cứng và cơ khí Drone**
* 4.1.1. Thiết kế sơ đồ nguyên lý (Schematic) và Layout PCB cho Flight Controller dựa trên STM32F103C8T6.
* 4.1.2. Thiết kế mạch nguồn logic (3.3V LDO), mạch nguồn phụ (5V Buck) và cầu phân áp ADC đo điện áp pin.
* 4.1.3. Lắp ráp cơ khí, lựa chọn linh kiện động lực (Động cơ A2212 1000KV, ESC 40A, Pin LiPo 3S 2200mAh).

**4.2. Lập trình phần mềm nhúng (Firmware Flight Controller)**
* 4.2.1. Thiết kế vòng lặp điều khiển chính thời gian thực tần số 250Hz.
* 4.2.2. Giao tiếp Software I2C tốc độ cao đọc cảm biến MPU6050 và đọc/ghi EEPROM 24LC256.
* 4.2.3. Giải mã luồng dữ liệu điều khiển từ bộ thu sóng qua giao thức CRSF.
* 4.2.4. Thiết lập hệ thống an toàn (Watchdog timer, trạng thái Arm/Disarm, ngắt động cơ khẩn cấp).

**4.3. Thiết kế phần mềm điều phối trạm mặt đất**
* 4.3.1. Kiến trúc hệ thống điều phối đa luồng (Multi-threading) và xử lý luồng Video qua OpenCV.
* 4.3.2. Nhúng bộ Detector tích hợp 3 mô hình YOLO và module dung hợp quyết định.
* 4.3.3. Thiết kế bộ quản lý mục tiêu (Target Manager) và cơ chế khóa mục tiêu (Focus lock).
* 4.3.4. Thiết kế phân hệ ghi sự kiện cứu hộ (Event Logger) và tự động xuất báo cáo HTML cứu hộ (Report Generator).

---

## CHƯƠNG 5. KẾT QUẢ THỰC NGHIỆM VÀ ĐÁNH GIÁ

**5.1. Kết quả chế tạo mô hình phần cứng thực tế**
* 5.1.1. Sản phẩm mạch in PCB Flight Controller hoàn chỉnh.
* 5.1.2. Mô hình Drone Quadcopter hoàn chỉnh tích hợp camera và pin nguồn.

**5.2. Kết quả thực nghiệm tính ổn định của hệ thống bay**
* 5.2.1. Đồ thị đáp ứng tư thế và kết quả hiệu chỉnh thông số PID.
* 5.2.2. Đánh giá độ nhạy điều khiển và khả năng kết nối không dây của sóng ELRS.

**5.3. Kết quả thực nghiệm hệ thống nhận dạng cứu hộ AI tại trạm mặt đất**
* 5.3.1. Đánh giá độ chính xác (Precision, Recall, F1-score) của thuật toán dung hợp so với các mô hình YOLO đơn lẻ.
* 5.3.2. Kết quả phát hiện nạn nhân trong các tình huống thực tế (Nằm bất động, vẫy hai tay cầu cứu).
* 5.3.3. Đánh giá tốc độ xử lý (FPS) và độ trễ tính toán của hệ thống nhận diện AI.
* 5.3.4. Kết quả ghi nhận dữ liệu cứu hộ (`rescue_events.csv`) và báo cáo HTML cứu hộ tự động.

**5.5. Đánh giá ưu nhược điểm và chi phí chế tạo**
* 5.5.1. Đánh giá ưu, nhược điểm của hệ thống (Độ trôi cảm biến, tính kháng gió, và độ nhạy của mô hình AI).
* 5.5.2. Bảng tổng hợp chi phí linh kiện và chế tạo hệ thống.

---

## KẾT LUẬN VÀ HƯỚNG PHÁT TRIỂN

* **Kết luận:** Tổng kết các kết quả đạt được về chế tạo Drone, lập trình firmware điều khiển và phát triển hệ thống nhận diện cứu hộ AI.
* **Hướng phát triển:** 
  * Tích hợp camera cảm biến nhiệt (Thermal camera) để nâng cao khả năng cứu hộ ban đêm.
  * Tích hợp máy tính nhúng (như NVIDIA Jetson) trực tiếp trên Drone để xử lý AI Edge.
  * Nghiên cứu thuật toán bay tự hành và lập bản đồ 3D.

---

## TÀI LIỆU THAM KHẢO

---

## PHỤ LỤC
* Phụ lục A: Mã nguồn C++ phần firmware Flight Controller (STM32).
* Phụ lục B: Mã nguồn Python phần trạm mặt đất xử lý luồng Video và thuật toán AI.
* Phụ lục C: Bản vẽ sơ đồ mạch nguyên lý Flight Controller và Layout PCB.