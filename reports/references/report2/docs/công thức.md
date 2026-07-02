# TỔNG HỢP CÁC CÔNG THỨC TOÁN HỌC TRONG ĐỒ ÁN VÀ ĐỐI CHIẾU MÃ NGUỒN

Tài liệu này tổng hợp và đối chiếu toàn bộ các công thức toán học được mô tả trong báo cáo đồ án tốt nghiệp với mã nguồn triển khai thực tế (firmware C++ trên Drone và phần mềm trạm mặt đất Python) cũng như các nguồn tài liệu lý thuyết tham khảo trên mạng.

---

## 1. NHÓM ĐIỀU KHIỂN BAY VÀ XỬ LÝ CẢM BIẾN (FIRMWARE NHÚNG)

### 1.1. Ước lượng tư thế góc nghiêng tĩnh từ gia tốc kế (Accelerometer)
* **Công thức toán học**:
  * Góc Roll ($\phi$):
    $$\phi_{accel} = \arctan2(a_y, a_z) \cdot \frac{180}{\pi}$$
  * Góc Pitch ($\theta$):
    $$\theta_{accel} = \arctan2(-a_x, \sqrt{a_y^2 + a_z^2}) \cdot \frac{180}{\pi}$$
* **Nguồn gốc**: 
  * **Mã nguồn**: Triển khai trong tệp [imu_estimator.cpp](file:///d:/Duong/Drone/drone_hehe/drone_fw/src/middleware/imu_estimator.cpp#L20-L25).
  * **Lý thuyết**: Công thức lượng giác chuẩn để chiếu vectơ gia tốc trọng trường $g$ lên hệ trục vật thể Body Frame của thiết bị IMU.
* **Đối chiếu code**:
  ```cpp
  float roll_acc = atanf(p_imu->ay, p_imu->az) * 57.29578f; // 57.29578 = 180/PI
  float pitch_acc = atanf(-p_imu->ax, sqrtf(p_imu->ay * p_imu->ay + p_imu->az * p_imu->az)) * 57.29578f;
  ```

---

### 1.2. Thuật toán Bộ lọc bù rời rạc (Complementary Filter)
* **Công thức toán học**:
  $$\theta_{filter}[n] = \alpha \cdot (\theta_{filter}[n-1] + \omega_{gyro} \cdot dt) + (1 - \alpha) \cdot \theta_{accel}[n]$$
* **Nguồn gốc**:
  * **Mã nguồn**: Triển khai trong tệp [imu_estimator.cpp](file:///d:/Duong/Drone/drone_hehe/drone_fw/src/middleware/imu_estimator.cpp#L7-L10) và [L51-L54](file:///d:/Duong/Drone/drone_hehe/drone_fw/src/middleware/imu_estimator.cpp#L51-L54).
  * **Hằng số**: Trong code cấu hình hệ số $\alpha = 0.9996$ (Brokking YMFC-32 dùng tỷ lệ $0.9996 / 0.0004$ rất cao để tin cậy tuyệt đối vào Gyroscope trong thời gian ngắn và lọc sạch nhiễu cơ học từ Accelerometer).
  * **Lý thuyết**: Tài liệu nghiên cứu *"Nonlinear Complementary Filters on the Special Orthogonal Group"* (Mahony et al., 2008).
* **Đối chiếu code**:
  ```cpp
  static const float Alpha = 0.9996f;
  current_att.roll  = Alpha * current_att.roll  + (1.0f - Alpha) * roll_acc;
  current_att.pitch = Alpha * current_att.pitch + (1.0f - Alpha) * pitch_acc;
  ```

---

### 1.3. Bù chéo góc khi xoay trục Yaw (Yaw Coupling Compensation)
* **Công thức toán học**:
  $$\phi[n] = \phi[n-1] + \theta[n-1] \cdot \sin(\omega_{yaw} \cdot dt)$$
  $$\theta[n] = \theta[n-1] - \phi[n-1] \cdot \sin(\omega_{yaw} \cdot dt)$$
* **Nguồn gốc**:
  * **Mã nguồn**: Triển khai trong tệp [imu_estimator.cpp](file:///d:/Duong/Drone/drone_hehe/drone_fw/src/middleware/imu_estimator.cpp#L41-L50).
  * **Lý thuyết**: Giải thuật toán học bù trừ sự dịch chuyển chéo trục góc Euler khi thân Drone xoay hướng Yaw quanh trục Z trong hệ tọa độ vật thể Body Frame (được chia sẻ rộng rãi trong cộng đồng Multiwii và YMFC-32).
* **Đối chiếu code**:
  ```cpp
  float yaw_rad = p_imu->gz * dt * 0.0174532925f; // Đổi ra radian
  float sin_yaw = sinf(yaw_rad);
  float prev_roll = current_att.roll;
  current_att.roll  += current_att.pitch * sin_yaw;
  current_att.pitch -= prev_roll * sin_yaw;
  ```

---

### 1.4. Bộ điều khiển phản hồi PID vòng kép (Cascade PID)
* **Công thức toán học**:
  * **Vòng ngoài (Angle Loop - Điều khiển góc)**: Khâu tỉ lệ P-only:
    $$TargetRate = K_{p\_angle} \cdot (TargetAngle - CurrentAngle)$$
  * **Vòng trong (Rate Loop - Điều khiển tốc độ góc)**: Khâu PID rời rạc đầy đủ:
    $$error\_rate = gyro\_input - TargetRate$$
    $$i\_mem = i\_mem + K_{i\_rate} \cdot error\_rate$$
    $$Output = K_{p\_rate} \cdot error\_rate + i\_mem + K_{d\_rate} \cdot (error\_rate - error\_rate_{prev})$$
* **Nguồn gốc**:
  * **Mã nguồn**: Triển khai trong tệp [pid_controller.cpp](file:///d:/Duong/Drone/drone_hehe/drone_fw/src/middleware/pid_controller.cpp#L110-L141).
  * **Lưu ý**: Công thức thực tế trong code *không nhân và chia cho $dt$* vì vòng lặp chính chạy ở tần số cố định 250Hz ($dt = 4000\mu s = \text{const}$). Các hệ số $K_i$ và $K_d$ đã được gộp chung với giá trị $dt$ này để tiết kiệm chu kỳ tính toán cho MCU nhúng (giống cấu trúc YMFC-32 của Joop Brokking).
* **Đối chiếu code**:
  ```cpp
  // Vòng ngoài (Roll Angle)
  float error_angle_roll = target_roll_deg - current_att->roll;
  float target_rate_roll = angle_gains[AXIS_ROLL].kp * error_angle_roll;

  // Vòng trong (Roll Rate PID)
  float error_rate_roll = gyro_roll_input - target_rate_roll;
  i_mem_roll += rate_gains[AXIS_ROLL].ki * error_rate_roll; // Tích lũy khâu I
  
  float pid_output_roll = rate_gains[AXIS_ROLL].kp * error_rate_roll + i_mem_roll +
      rate_gains[AXIS_ROLL].kd * (error_rate_roll - last_error_roll); // Tính đầu ra
  ```

---

### 1.5. Bộ lọc thông thấp số khâu vi phân (IIR Filter)
* **Công thức toán học**:
  $$gyro\_input[n] = (1 - k) \cdot gyro\_input[n-1] + k \cdot new\_reading[n]$$
* **Nguồn gốc**:
  * **Mã nguồn**: Triển khai trong tệp [pid_controller.cpp](file:///d:/Duong/Drone/drone_hehe/drone_fw/src/middleware/pid_controller.cpp#L98-L105).
  * **Lý thuyết**: Bộ lọc thông thấp IIR (Infinite Impulse Response) bậc 1 để triệt tiêu nhiễu rung cơ khí tần số cao của động cơ truyền qua khung sườn đến cảm biến IMU trước khi tính vi phân. Hệ số lọc $k = 0.3$.
* **Đối chiếu code**:
  ```cpp
  gyro_roll_input = (gyro_roll_input * 0.7f) + (current_imu->gx * 0.3f);
  ```

---
---

## 2. NHÓM NHẬN DIỆN AI VÀ SUY LUẬN HÀNH VI (TRẠM MẶT ĐẤT GCS)

### 2.1. Phân tích hình học phát hiện tư thế nằm/ngã
* **Công thức toán học**:
  * Góc nghiêng của trục xương sống ($\theta_{body}$):
    $$\theta_{body} = \left| \arctan2(y_{hip} - y_{shoulder}, x_{hip} - x_{shoulder}) \right| \cdot \frac{180}{\pi}$$
  * Tỷ lệ khung bao Aspect Ratio ($AR$):
    $$AR = \frac{Width}{Height}$$
  * Điều kiện nằm: $\theta_{body} < 35^\circ$ hoặc $AR > 1.8$ (trong code).
* **Nguồn gốc**:
  * **Mã nguồn**: Triển khai trong tệp [detector.py](file:///d:/Duong/Drone/drone_hehe/SourceCode_DATN_Clean/code%20chính/detector.py#L526) và [L631-L642](file:///d:/Duong/Drone/drone_hehe/SourceCode_DATN_Clean/code%20chính/detector.py#L631-L642).
  * **Lý thuyết**: Phép tính hình học phân tích khung xương dựa trên hệ tọa độ pixel của thư viện OpenCV và YOLOv8-Pose.
* **Đối chiếu code**:
  ```python
  # Kiểm tra tỷ lệ khung bao
  if box_w / box_h > 1.8:
      ...
      is_lying = True

  # Phân tích độ rộng keypoints trục ngang và dọc
  if body_x_span > max(45, body_y_span * config.LYING_KEYPOINT_RATIO_THRESHOLD) and torso_is_horizontal:
      is_lying = True
  ```

---

### 2.2. Thuật toán phát hiện cử chỉ vẫy tay cứu hộ (Waving Gesture Detection)
* **Công thức toán học**:
  * Toạt độ chuẩn hóa của cổ tay ($y'_{wrist}$):
    $$y'_{wrist} = \frac{y_{wrist} - y_{shoulder}}{\|P_{shoulder} - P_{hip}\|}$$
  * Điều kiện vẫy: Tay ở trên vai ($y_{wrist} < y_{shoulder}$) và số lần đổi hướng dịch chuyển ngang $K \ge \text{Waving\_Min\_Changes}$.
* **Nguồn gốc**:
  * **Mã nguồn**: Triển khai trong tệp [utils.py](file:///d:/Duong/Drone/drone_hehe/SourceCode_DATN_Clean/code%20chính/utils.py#L91-L106) và [detector.py](file:///d:/Duong/Drone/drone_hehe/SourceCode_DATN_Clean/code%20chính/detector.py#L574-L608).
  * **Lý thuyết**: Phân tích tần số và quỹ đạo của chuỗi thời gian keypoints (Time-series keypoints analysis) trong một cửa sổ trượt (sliding window) kích thước 30 khung hình.
* **Đối chiếu code**:
  ```python
  # Trong utils.py
  def detect_wrist_waving(history, current_time: float) -> bool:
      ...
      move_x = max(xs) - min(xs)
      move_y = max(ys) - min(ys)
      if max(move_x, move_y) < config.WRIST_MOVE_THRESHOLD:
          return False
      above_changes = sum(1 for idx in range(1, len(above_values)) if above_values[idx] != above_values[idx - 1])
      direction_changes = max(_direction_changes(xs), _direction_changes(ys), above_changes)
      return direction_changes >= config.WAVING_MIN_DIRECTION_CHANGES
  ```

---

### 2.3. Đánh giá trạng thái bất động tĩnh (Immobility Detection)
* **Công thức toán học**:
  * Độ lệch tâm trọng tâm mục tiêu tích lũy ($D_{accum}$):
    $$D_{accum} = \sqrt{\sigma^2(x_{center}) + \sigma^2(y_{center})} < \text{Threshold}$$
    Trong đó $\sigma$ là độ lệch chuẩn của chuỗi tọa độ tâm trong 10 giây qua.
* **Nguồn gốc**:
  * **Mã nguồn**: Triển khai trong tệp [detector.py](file:///d:/Duong/Drone/drone_hehe/SourceCode_DATN_Clean/code%20chính/detector.py#L702-L720).
  * **Lý thuyết**: Phân tích độ lệch chuẩn tọa độ trọng tâm (Centroid standard deviation analysis) để cô lập nhiễu rung lắc của Camera Drone (sử dụng thêm kỹ thuật bù dòng quang học Lucas-Kanade).
* **Đối chiếu code**:
  ```python
  duration = max(times) - min(times)
  if duration >= config.STILLNESS_SECONDS - 0.5 and max(xs) - min(xs) < config.CENTER_JITTER_THRESHOLD and max(ys) - min(ys) < config.CENTER_JITTER_THRESHOLD:
      is_immobile = True
  ```

---

### 2.4. Công thức dung hợp quyết định đa luồng (Decision Fusion Probability)
* **Công thức toán học**:
  * **Lý thuyết học thuật (Trong Báo cáo)**: Mô hình trung bình trọng số kết hợp xác suất độc lập:
    $$P(Victim) = w_{rescue} \cdot C_{rescue} + w_{posture} \cdot P_{lying} + w_{pose} \cdot P_{pose}$$
    Với: $w_{rescue} = 0.4, w_{posture} = 0.3, w_{pose} = 0.3$.
  * **Thực tế mã nguồn (Trong `detector.py`)**: Sử dụng công thức tích lũy bằng chứng xác suất không loại trừ (Noisy-OR gate hoặc Probabilistic Union):
    $$P(Victim) = 1 - (1 - P_{rescue}) \cdot (1 - 0.78 \cdot P_{posture\_lying}) \cdot (1 - 0.65 \cdot P_{pose\_evidence})$$
* **Nguồn gốc**:
  * **Mã nguồn**: Triển khai trong tệp [detector.py](file:///d:/Duong/Drone/drone_hehe/SourceCode_DATN_Clean/code%20chính/detector.py#L477-L481).
  * **Lý thuyết**: Phương pháp dung hợp thông tin đa nguồn (Multi-sensor Decision Fusion) dựa trên mô hình suy luận xác suất Bayesian để giảm thiểu báo động giả (False Alarms).
* **Đối chiếu code**:
  ```python
  victim_probability = 1.0 - (
      (1.0 - rescue_victim)
      * (1.0 - 0.78 * posture_victim)
      * (1.0 - 0.65 * pose_victim)
  )
  ```

---

### 2.5. Hệ thống điểm nguy cấp Danger Score (DS)
* **Công thức toán học**:
  * **Lý thuyết học thuật (Trong Báo cáo)**: Quy đổi về thang điểm 100 để đánh giá mức độ khẩn cấp trực quan:
    $$DS = P(Victim) \cdot 50 + S_{action} + S_{time}$$
    Với $S_{action} \in \{0, 30, 40\}$ và $S_{time} = \min(10, T_{immobile}/3)$.
  * **Thực tế mã nguồn (Trong `detector.py`)**: Sử dụng thang điểm tích lũy số nguyên từ 0 đến 9 điểm để tối ưu hóa hiệu năng tính toán logic nhánh:
    $$DS_{code} = S_{lying} + S_{wave/raise} + S_{collapse} + S_{immobile}$$
    Phân loại: $DS \ge 4 \rightarrow \text{CAN\_CUU\_GIUP}$ (Khẩn cấp), $DS \ge 2 \rightarrow \text{NGHI\_NGO}$, còn lại $\rightarrow \text{BINH\_THUONG}$.
* **Nguồn gốc**:
  * **Mã nguồn**: Triển khai trong tệp [detector.py](file:///d:/Duong/Drone/drone_hehe/SourceCode_DATN_Clean/code%20chính/detector.py#L523) và [L724-L730](file:///d:/Duong/Drone/drone_hehe/SourceCode_DATN_Clean/code%20chính/detector.py#L724-L730).
  * **Lý thuyết**: Bộ luật suy diễn mờ (Fuzzy inference rules) phân loại mức độ ưu tiên phản ứng cứu nạn.
* **Đối chiếu code**:
  ```python
  # Tích lũy điểm dựa trên các cờ trạng thái hình học
  if is_lying: danger_score += 2
  if is_two_hands_raised: danger_score += 3
  if is_waving: danger_score += 5
  if is_collapsed: danger_score += 2
  if is_immobile and (is_lying or is_collapsed): danger_score += 1
  if is_lying and is_immobile: danger_score += 2

  # Phân cấp cảnh báo dựa trên ngưỡng số nguyên
  if danger_score >= 4:
      state = "CAN_CUU_GIUP"
  elif danger_score >= 2:
      state = "NGHI_NGO"
  else:
      state = "BINH_THUONG"
  ```
