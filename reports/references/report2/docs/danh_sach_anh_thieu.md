# DANH SÁCH HÌNH ẢNH CẦN THIẾT CHO BÁO CÁO ĐỒ ÁN TỐT NGHIỆP

Tài liệu này tổng hợp toàn bộ hình ảnh cần thiết cho báo cáo đồ án tốt nghiệp theo kế hoạch [report_layout_plan.md](file:///d:/Duong/Drone/drone_hehe/report/plan/report_layout_plan.md). Danh sách được chia thành hai nhóm: **Nhóm hình ảnh tôi có thể tự động tìm tải trên mạng/tự vẽ giúp bạn** và **Nhóm hình ảnh đặc thù của đồ án cần bạn cung cấp**.

---

## 1. NHÓM 1: HÌNH ẢNH TÔI SẼ TỰ TẢI TRÊN MẠNG HOẶC TỰ VẼ GIÚP BẠN
*Các hình ảnh này mang tính chất lý thuyết chung, sơ đồ khối thuật toán hoặc kiến trúc hệ thống chuẩn.*

| STT | Tên file ảnh dự kiến | Chương | Nội dung mô tả hình ảnh | Nguồn / Cách xử lý |
| :---: | :--- | :---: | :--- | :--- |
| 1 | `cuu_ho_sar.jpg` | Chương 1 | Hình ảnh minh họa hoạt động tìm kiếm cứu nạn (SAR) bằng Drone. | Tải từ nguồn ảnh báo chí cứu hộ. |
| 2 | `he_toa_do_drone.png` | Chương 2 | Sơ đồ hệ tọa độ vật thể (Body frame) của Quadcopter với các trục Roll, Pitch, Yaw. | Tải sơ đồ vector tọa độ chuẩn. |
| 3 | `chieu_quay_motor.png` | Chương 2 | Sơ đồ chiều quay của 4 động cơ cấu hình Quad-X (động cơ thuận CW và nghịch CCW). | Tải sơ đồ chuẩn Quad-X. |
| 4 | `so_do_khoi_pid.png` | Chương 2 | Sơ đồ khối bộ điều khiển phản hồi PID vòng kín cơ bản. | Tải sơ đồ khối toán học PID. |
| 5 | `truc_mpu6050.png` | Chương 2 | Sơ đồ các trục cảm biến gia tốc và vận tốc góc ($X, Y, Z$) trên chip MPU6050. | Tải từ datasheet MPU6050. |
| 6 | `bo_loc_bu.png` | Chương 2 | Sơ đồ thuật toán bộ lọc bù (Complementary Filter) kết hợp Gyro và Accel. | Tải từ sơ đồ khối xử lý tín hiệu. |
| 7 | `crsf_protocol.png` | Chương 2 | Cấu trúc khung truyền dữ liệu của giao thức CRSF (ExpressLRS). | Tải sơ đồ phân tích gói tin CRSF. |
| 8 | `i2c_timing.png` | Chương 2 | Sơ đồ giản đồ xung timing (SCL, SDA, Start, Stop, Ack) giao tiếp I2C. | Tải sơ đồ timing chuẩn. |
| 9 | `yolov8_architecture.png` | Chương 3 | Sơ đồ kiến trúc mạng nơ-ron YOLOv8 (Backbone, Neck, Head). | Tải sơ đồ kiến trúc Ultralytics. |
| 10 | `yolo_pose_17_keypoints.png` | Chương 3 | Sơ đồ phân bổ 17 điểm keypoints trên cơ thể người của mô hình Pose Estimation. | Tải từ tài liệu chuẩn COCO Keypoints. |
| 11 | `mach_nguon_lm2596_ams1117.png` | Chương 4 | Sơ đồ mạch nguồn hạ áp Buck (LM2596) và LDO (AMS1117) tham khảo. | Tải từ schematic tham khảo của NS/TI. |
| 12 | `lưu_đo_fsm_boot.png` | Chương 4 | Lưu đồ thuật toán máy trạng thái khởi động (FSM Boot) của firmware STM32. | Tôi sẽ tự vẽ bằng mã **Mermaid / Python Graph**. |
| 13 | `luong_phan_mem_gui.png` | Chương 4 | Sơ đồ luồng xử lý video đa luồng và luồng nhận diện AI của trạm mặt đất. | Tôi sẽ tự vẽ bằng mã **Mermaid / Python Graph**. |
| 14 | `jetson_nano_thermal.png` | Kết luận | Hình ảnh máy tính nhúng NVIDIA Jetson Nano và camera nhiệt Flir Lepton để nâng cấp. | Tải ảnh sản phẩm chính hãng. |

---

## 2. NHÓM 2: HÌNH ẢNH ĐẶC THÙ ĐỒ ÁN - CẦN BẠN CUNG CẤP (UP LÊN CHAT)
*Các hình ảnh này thể hiện kết quả thiết kế mạch in, mô hình cơ khí và dữ liệu thực nghiệm chạy phần mềm thực tế của bạn.*

| STT | Tên file ảnh đề xuất | Chương | Nội dung mô tả hình ảnh cần bạn chụp / xuất file |
| :---: | :--- | :---: | :--- |
| 1 | `tiến_trình_gantt.png` | Chương 1 | Sơ đồ Gantt tiến độ thực hiện đồ án của bạn (nếu có, hoặc tôi sẽ tự vẽ sơ đồ Gantt tổng quát). |
| 2 | `schematic_fc.png` | Chương 4 | Ảnh chụp sơ đồ nguyên lý (Schematic) mạch Flight Controller thiết kế trên Altium. |
| 3 | `layout_pcb_fc.png` | Chương 4 | Ảnh chụp sơ đồ đi dây Layout 2D hoặc phối cảnh 3D của mạch Flight Controller trên Altium. |
| 4 | `pcb_thuc_te.jpg` | Chương 5 | Ảnh chụp mạch in Flight Controller thực tế sau khi gia công PCB và hàn hoàn thiện linh kiện. |
| 5 | `drone_hoan_chinh.jpg` | Chương 5 | Ảnh chụp mô hình Drone thực tế sau khi lắp ráp hoàn chỉnh khung, cánh, động cơ và cân bằng. |
| 6 | `do_thi_pid.png` | Chương 5 | Biểu đồ đồ thị đáp ứng góc nghiêng Roll/Pitch thực tế thu được từ log bay để chứng minh PID chạy ổn định. |
| 7 | `do_thi_rssi_lq.png` | Chương 5 | Đồ thị hoặc chỉ số chất lượng sóng RSSI/LQ của mạch thu phát ELRS ghi nhận thực tế. |
| 8 | `dataset_samples.jpg` | Chương 5 | Một vài hình ảnh mẫu trong bộ dữ liệu huấn luyện (Dataset) mô hình phát hiện nạn nhân cứu hộ của bạn. |
| 9 | `confusion_matrix.png` | Chương 5 | Ma trận nhầm lẫn (Confusion Matrix) hoặc biểu đồ Loss/Accuracy khi bạn huấn luyện mô hình YOLOv8-Rescue. |
| 10 | `gui_hoat_dong.jpg` | Chương 5 | Ảnh chụp màn hình giao diện GUI phần mềm trạm mặt đất của bạn đang hoạt động bình thường. |
| 11 | `detect_nan_nhan.jpg` | Chương 5 | Ảnh chụp màn hình GUI lúc phát hiện nạn nhân thực tế (vẽ khung xương, khoanh vùng, và hiện cảnh báo đỏ). |
| 12 | `bao_cao_html.png` | Chương 5 | Ảnh chụp màn hình giao diện file báo cáo cứu hộ định dạng HTML được phần mềm tự động sinh ra. |

---

## 3. CÁCH THỨC TẢI LÊN VÀ QUẢN LÝ
1. **Đối với ảnh Nhóm 1**: Tôi sẽ tiến hành tìm kiếm và tự động tải về lưu trực tiếp vào thư mục `report/Images/` trong các lượt tiếp theo.
2. **Đối với ảnh Nhóm 2**: Khi bạn có hình ảnh nào, hãy kéo thả tải lên khung chat này kèm theo lời nhắn (Ví dụ: *"Đây là ảnh pcb_thuc_te.jpg"* hoặc *"đây là ảnh schematic_fc.png"*). Tôi sẽ tự động lưu và cấu trúc chúng vào đúng thư mục [linhkien](file:///d:/Duong/Drone/drone_hehe/report/Images/linhkien) để phục vụ viết báo cáo LaTeX.
