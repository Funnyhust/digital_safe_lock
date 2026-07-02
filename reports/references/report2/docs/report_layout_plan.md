# KẾ HOẠCH BỐ TRÍ LAYOUT BÁO CÁO ĐỒ ÁN TỐT NGHIỆP (DỰ KIẾN 80 TRANG)

Tài liệu này phác thảo kế hoạch phân bổ trang, hình ảnh và bảng biểu dự kiến cho từng chương và tiểu mục của đồ án tốt nghiệp: **"Thiết kế và chế tạo Drone hỗ trợ giám sát an ninh và cứu hộ tích hợp AI"**. Việc phân phối này giúp kiểm soát dung lượng và cấu trúc báo cáo đạt chuẩn quy định (khoảng 80 trang).

---

## 1. TỔNG QUAN PHÂN BỔ DUNG LƯỢNG BÁO CÁO

| Phần / Chương | Nội dung chính | Số trang dự kiến | Số hình ảnh dự kiến | Số bảng biểu dự kiến |
| :--- | :--- | :---: | :---: | :---: |
| **Phần mở đầu** | Bìa, Nhận xét, Lời cảm ơn, Mục lục, Danh mục từ viết tắt | **12** | 2 | 0 |
| **Chương 1** | Giới thiệu tổng quan về đề tài | **6** | 3 | 1 |
| **Chương 2** | Cơ sở lý thuyết hệ thống bay và điều khiển nhúng | **14** | 8 | 1 |
| **Chương 3** | Nghiên cứu thuật toán học sâu YOLO và dung hợp quyết định | **16** | 10 | 2 |
| **Chương 4** | Thiết kế và chế tạo phần cứng Drone và Trạm mặt đất | **18** | 12 | 2 |
| **Chương 5** | Kết quả thực nghiệm và đánh giá | **10** | 8 | 2 |
| **Phần kết thúc**| Kết luận, Tài liệu tham khảo, Phụ lục | **8** | 4 | 0 |
| **TỔNG CỘNG** | | **84 trang** | **47 hình** | **8 bảng** |

---

## 2. CHI TIẾT BỐ TRÍ LAYOUT TỪNG PHẦN

### PHẦN MỞ ĐẦU VÀ HÀNH CHÍNH (Dự kiến: 12 trang)
| Đề mục | Nội dung chi tiết | Số trang | Số hình / bảng |
| :--- | :--- | :---: | :---: |
| Trang bìa | Bìa chính (ngoài) & Bìa phụ (trong) theo chuẩn BKHN | 2 | 2 hình (Logo Trường) |
| Đánh giá | Bản nhận xét của GVHD và Cán bộ phản biện | 2 | 0 |
| Lời mở đầu | Lời nói đầu, Lời cảm ơn, Lời cam đoan | 3 | 0 |
| Mục lục | Mục lục tự động, Danh mục hình vẽ, Danh mục bảng biểu | 4 | 0 |
| Danh mục phụ | Danh mục từ viết tắt & Tóm tắt đồ án (Abstract) | 1 | 0 |

---

### CHƯƠNG 1: GIỚI THIỆU TỔNG QUAN VỀ ĐỀ TÀI (Dự kiến: 6 trang)
*Mục tiêu chương: Giúp người đọc hiểu bối cảnh, lý do chọn đề tài, mục tiêu và phạm vi thực hiện.*

| Đề mục | Nội dung chi tiết | Số trang | Số hình / bảng |
| :--- | :--- | :---: | :---: |
| **1.1** | **Đặt vấn đề**: Bối cảnh UAV/Drone và nhu cầu cứu hộ cứu nạn (SAR). Phân tích hạn chế của các phương pháp SAR truyền thống. | 2 | 1 hình (Thực trạng cứu hộ) |
| **1.2** | **Mục tiêu đề tài**: Mục tiêu phần cứng (Drone bay vững), phần mềm (Nhận diện nạn nhân bằng AI), và trạm mặt đất. | 2 | 1 hình (Mô hình tổng quan đề tài) |
| **1.3** | **Những công việc chính**: Sơ đồ phân chia công việc thực hiện từ lý thuyết đến thực nghiệm. | 2 | 1 hình (Sơ đồ Gantt thực hiện) |

---

### CHƯƠNG 2: CƠ SỞ LÝ THUYẾT VỀ HỆ THỐNG BAY VÀ ĐIỀU KHIỂN NHÚNG (Dự kiến: 14 trang)
*Mục tiêu chương: Trình bày cơ sở toán học về động lực học bay và các giao thức phần cứng cơ bản.*

| Đề mục | Nội dung chi tiết | Số trang | Số hình / bảng |
| :--- | :--- | :---: | :---: |
| **2.1** | **Động lực học Quadcopter**: Hệ tọa độ vật thể (Body frame) và tọa độ Trái Đất (Earth frame). Phương trình lực nâng, lực cản và momen. | 4 | 2 hình (Hệ tọa độ & Chiều quay motor) |
| **2.2** | **Bộ điều khiển PID rời rạc**: Công thức PID rời rạc, thiết kế khâu vi phân có bộ lọc thông thấp số IIR, giải thuật chống bão hòa tích phân (Anti-windup). | 3 | 2 hình (Sơ đồ khối PID & Đáp ứng bộ lọc) |
| **2.3** | **Cảm biến và bộ lọc tư thế**: Nguyên lý cảm biến IMU MPU6050, bộ lọc bù rời rạc (Complementary Filter) để ước lượng góc Roll, Pitch. | 4 | 2 hình (Trục cảm biến MPU6050 & Sơ đồ bộ lọc bù) |
| **2.4** | **Giao thức điều khiển & Chip nhớ**: Giải thích giao thức CRSF (ExpressLRS) truyền sóng tốc độ cao, nguyên lý giao tiếp I2C với chip nhớ EEPROM 24LC256. | 3 | 2 hình (Khung dữ liệu CRSF & Sơ đồ timing I2C) |

---

### CHƯƠNG 3: NGHIÊN CỨU THUẬT TOÁN HỌC SÂU YOLO VÀ DUNG HỢP QUYẾT ĐỊNH TRONG CỨU HỘ (Dự kiến: 16 trang)
*Chương trọng tâm AI: Nghiên cứu sâu về các mô hình học sâu và thuật toán phân tích hành vi nạn nhân cứu hộ.*

| Đề mục | Nội dung chi tiết | Số trang | Số hình / bảng |
| :--- | :--- | :---: | :---: |
| **3.1** | **Kiến trúc YOLO**: Tổng quan mạng nơ-ron phát hiện đối tượng thời gian thực YOLOv8. Giới thiệu mô hình YOLOv8-Rescue và YOLOv8-Posture. | 3 | 2 hình (Mạng YOLO & Dataset huấn luyện) |
| **3.2** | **Ước lượng tư thế YOLO-Pose**: Phân tích cấu trúc 17 điểm khung xương (keypoints). Phương pháp xác định tư thế nằm/ngã, nghiêng, sụp đổ. | 4 | 2 hình (Sơ đồ 17 keypoints & Ví dụ phát hiện nằm) |
| **3.3** | **Thuật toán phân tích cử chỉ cứu hộ**: Thuật toán nhận diện vẫy hai tay cầu cứu (phân tích biến động cổ tay) và phát hiện trạng thái bất động (immobility). | 4 | 2 hình (Biểu đồ quỹ đạo vẫy tay & Thuật toán tính độ lệch tâm) |
| **3.4** | **Dung hợp quyết định (Decision Fusion)**: Công thức toán dung hợp xác suất độc lập đa luồng (Pose + Posture + Rescue). Giải thuật tính điểm nguy cấp (Danger Score). | 5 | 2 hình (Sơ đồ luồng dung hợp) <br> 1 bảng (Bảng quy tắc Danger Score) |

---

### CHƯƠNG 4: THIẾT KẾ VÀ CHẾ TẠO HỆ THỐNG PHẦN CỨNG DRONE VÀ TRẠM MẶT ĐẤT (Dự kiến: 18 trang)
*Mục tiêu chương: Trình bày chi tiết bản thiết kế mạch, lập trình firmware và phần mềm trạm mặt đất.*

| Đề mục | Nội dung chi tiết | Số trang | Số hình / bảng |
| :--- | :--- | :---: | :---: |
| **4.1** | **Thiết kế phần cứng và cơ khí**: Sơ đồ nguyên lý và layout PCB Flight Controller STM32. Thiết kế mạch nguồn LDO, Buck, mạch lọc nhiễu. Lựa chọn hệ thống động lực. | 6 | 4 hình (Mạch nguyên lý, Layout PCB, sơ đồ nguồn) <br> 1 bảng (Bảng thông số linh kiện thực tế) |
| **4.2** | **Lập trình Firmware Flight Controller**: Cấu hình clock, kiến trúc vòng lặp điều khiển 250Hz. Lập trình driver Soft I2C (MPU6050, 24LC256), giải mã CRSF và fail-safe. | 5 | 2 hình (Lưu đồ thuật toán FSM Boot & Chu kỳ loop) |
| **4.3** | **Thiết kế phần mềm trạm mặt đất**: Kiến trúc đa luồng nhận video và chạy xử lý AI. Thiết kế Target Manager (bám và khóa mục tiêu) và tự động ghi log/xuất báo cáo HTML. | 7 | 4 hình (Sơ đồ luồng trạm mặt đất, Giao diện GUI, cấu trúc báo cáo) <br> 1 bảng (Quy ước lệnh phím tắt vận hành) |

---

### CHƯƠNG 5: KẾT QUẢ THỰC NGHIỆM VÀ ĐÁNH GIÁ (Dự kiến: 10 trang)
*Mục tiêu chương: Trưng bày sản phẩm thực tế, đồ thị đo đạc và đánh giá sai số/độ chính xác.*

| Đề mục | Nội dung chi tiết | Số trang | Số hình / bảng |
| :--- | :--- | :---: | :---: |
| **5.1** | **Mô hình thực tế**: Ảnh chụp mạch in PCB sau khi gia công và Drone Quadcopter lắp ráp hoàn chỉnh. | 2 | 2 hình (Ảnh PCB thực tế & Ảnh Drone hoàn chỉnh) |
| **5.2** | **Thực nghiệm bay và điều khiển**: Biểu đồ đáp ứng góc nghiêng Roll/Pitch sau khi cân chỉnh PID, thực nghiệm tầm xa tay phát/thu. | 3 | 2 hình (Biểu đồ góc nghiêng PID & Đồ thị RSSI/LQ sóng ELRS) |
| **5.3** | **Thực nghiệm nhận diện AI**: Ma trận nhầm lẫn (Confusion Matrix) của thuật toán AI. Ảnh chụp giao diện phát hiện nạn nhân thực tế (vẫy tay, nằm). File báo cáo HTML kết quả. | 3 | 2 hình (Confusion matrix & Ảnh chụp màn hình GUI phát hiện nạn nhân) <br> 1 bảng (Bảng so sánh Precision/Recall các mô hình) |
| **5.4** | **Đánh giá ưu nhược điểm & chi phí**: Đánh giá ưu nhược điểm thực tế hệ thống. Bảng giá thành linh kiện. | 2 | 1 bảng (Bảng dự toán chi phí chế tạo thực tế) |

---

### PHẦN KẾT THÚC VÀ PHỤ LỤC (Dự kiến: 8 trang)
| Đề mục | Nội dung chi tiết | Số trang | Số hình / bảng |
| :--- | :--- | :---: | :---: |
| Kết luận | Đánh giá mức độ hoàn thành so với mục tiêu và hướng phát triển (Camera nhiệt, Jetson Nano). | 2 | 2 hình (Mô hình gợi ý nâng cấp) |
| Tài liệu tham khảo | Trích dẫn IEEE cho sách, bài báo khoa học và các datasheets linh kiện. | 2 | 0 |
| Phụ lục | Mã nguồn Python cốt lõi của Detector AI, bản vẽ Layout PCB kích thước lớn. | 4 | 2 hình (Bản vẽ schematic/layout toàn trang) |
