# Hướng dẫn đọc hiểu source Verilog - Digital Safe Lock dùng SRAM

Tài liệu này giải thích toàn bộ các file trong thư mục `design/` theo thứ tự nên học. Mình giả sử bạn đã biết C, nhưng chưa quen tư duy Verilog/FPGA.

Điểm quan trọng nhất: Verilog không giống C ở chỗ không có một chương trình chạy từ trên xuống dưới. Mỗi `module` là một khối phần cứng. Các module được nối dây với nhau và chạy song song. Khi một input đổi, phần cứng liên quan tự phản ứng theo clock hoặc theo logic tổ hợp.

## 1. Tổng quan hệ thống

Dự án là khóa két điện tử trên FPGA:

- `SW[7:0]`: nhập mật khẩu 8 bit.
- `KEY[0]`: reset, active-low.
- `KEY[1]`: Enter.
- `KEY[2]`: Change password.
- `LEDR[0]`: báo khóa/lỗi.
- `LEDG[0]`: báo mở khóa.
- `HEX2`, `HEX1`, `HEX0`: hiện `---`, `OPn`, `Err`, `Chg`.
- LCD 16x2: hiện text trạng thái.
- SRAM ngoài: lưu mật khẩu.

Luồng khối:

```text
KEY[1] --> button_debounce --> enter_tick  --+
KEY[2] --> button_debounce --> change_tick --+
SW[7:0] -------------------------------------+--> lock_fsm
                                                 |
                                                 +--> LEDR[0], LEDG[0]
                                                 +--> display_state
                                                 |       |
                                                 |       +--> hex_display --> HEX2/HEX1/HEX0
                                                 |       |
                                                 |       +--> lcd_controller --> LCD
                                                 |
                                                 +--> sram_controller <--> SRAM ngoài
```

## 2. Thứ tự nên đọc code

Nên đọc theo thứ tự này:

1. `hex_display.v`
   - Dễ nhất. Học logic tổ hợp `always @(*)` và `case`.
2. `button_debounce.v`
   - Học clock, reset, thanh ghi, nút bấm active-low, và xung `tick`.
3. `internal_ram.v`
   - Học giao diện bộ nhớ đơn giản: `rd_en`, `wr_en`, `ready`.
4. `sram_controller.v`
   - Học cách biến giao diện bộ nhớ đơn giản thành tín hiệu SRAM vật lý.
5. `lock_fsm.v`
   - Phần thuật toán chính của khóa. Đây là file quan trọng nhất.
6. `digital_safe_lock.v`
   - Top-level nối tất cả module lại với nhau.
7. `lcd_controller.v`
   - Dài nhất và nhiều timing. Đọc sau cùng.

Nếu chỉ muốn hiểu thuật toán khóa, hãy tập trung vào `lock_fsm.v`. Nếu muốn hiểu toàn hệ thống, đọc đủ theo thứ tự trên.

## 3. Một số khái niệm Verilog cần nhớ

### `module`

`module` giống một linh kiện hoặc một khối mạch. Ví dụ:

```verilog
module hex_display (...);
```

Khi dùng module trong module khác, ta không "gọi hàm" như C. Ta **instantiate** nó, tức tạo một khối phần cứng con:

```verilog
hex_display hex_inst (
    .i_state(display_state),
    .o_hex2(HEX2),
    .o_hex1(HEX1),
    .o_hex0(HEX0)
);
```

`hex_display` là tên loại module. `hex_inst` là tên instance cụ thể.

### `wire` và `reg`

- `wire`: dây nối giữa các module hoặc giữa các biểu thức.
- `reg`: biến lưu giá trị trong `always`, thường là thanh ghi nếu dùng với clock.

Trong code hiện tại:

```verilog
wire enter_tick;
reg [3:0] state;
```

`enter_tick` là dây nối từ debounce sang FSM. `state` là trạng thái hiện tại của FSM.

### `always @(*)`

Đây là logic tổ hợp. Output tự đổi khi input đổi. Gần giống một hàm tính liên tục.

Ví dụ trong `hex_display.v`, khi `i_state` đổi thì `o_hex2/o_hex1/o_hex0` đổi theo.

### `always @(posedge i_clk or negedge i_rst_n)`

Đây là logic tuần tự có clock và reset. Code bên trong chạy tại cạnh lên clock, hoặc reset tại cạnh xuống `i_rst_n`.

Gần giống:

```c
while (1) {
    wait_for_clock_edge();
    update_registers();
}
```

Nhưng thực tế là phần cứng, không phải CPU chạy vòng lặp.

### `<=` và `=`

- Dùng `<=` trong logic có clock.
- Dùng `=` trong logic tổ hợp.

Ví dụ:

```verilog
state <= S_IDLE;
```

Nghĩa là thanh ghi `state` sẽ nhận giá trị mới ở cạnh clock.

## 4. File `hex_display.v`

Đây là file dễ nhất, nên đọc đầu tiên.

### Vai trò

`hex_display` nhận mã trạng thái 3 bit từ FSM và đổi thành mẫu LED 7 đoạn.

Input/output:

```verilog
input  wire [2:0] i_state
output reg  [6:0] o_hex2
output reg  [6:0] o_hex1
output reg  [6:0] o_hex0
```

`i_state` có ý nghĩa:

| `i_state` | Hiển thị |
| --- | --- |
| `3'd0` | `---` |
| `3'd1` | `OPn` |
| `3'd2` | `Err` |
| `3'd3` | `Chg` |

### Mã LED 7 đoạn

Các dòng như:

```verilog
localparam CHAR_O = 7'h40;
localparam CHAR_P = 7'h0C;
```

không phải mã ASCII. Đây là mẫu bật/tắt 7 đoạn LED.

Comment trong file nói:

```verilog
// active-low (0 = ON, 1 = OFF)
```

Tức là bit `0` làm đoạn sáng, bit `1` làm đoạn tắt.

### Logic chính

```verilog
always @(*) begin
    case (i_state)
        3'd0: begin
            o_hex2 = CHAR_DASH;
            o_hex1 = CHAR_DASH;
            o_hex0 = CHAR_DASH;
        end
        ...
    endcase
end
```

Không có hàm `set_led()` nào được gọi. Module này luôn theo dõi `i_state`. Khi `i_state` đổi, output tự đổi.

Tư duy gần giống C:

```c
switch (i_state) {
case 0:
    HEX2 = DASH;
    HEX1 = DASH;
    HEX0 = DASH;
    break;
case 1:
    HEX2 = O;
    HEX1 = P;
    HEX0 = n;
    break;
}
```

Nhưng trong Verilog, đây là mạch tổ hợp chạy liên tục.

## 5. File `button_debounce.v`

### Vai trò

Nút bấm vật lý bị rung tiếp điểm. Một lần nhấn có thể tạo nhiều xung nhiễu rất nhanh. `button_debounce` lọc nhiễu đó và tạo ra:

- `o_btn_state`: trạng thái nút đã lọc.
- `o_btn_tick`: xung 1 clock khi vừa nhấn.

Input/output:

```verilog
input  wire i_clk
input  wire i_rst_n
input  wire i_btn
output reg  o_btn_state
output wire o_btn_tick
```

Nút `KEY` trên board là active-low:

```text
Không nhấn: 1
Nhấn:      0
```

### Parameter debounce

```verilog
parameter DELAY_CYCLES = 20'd1_000_000
```

Với clock 50 MHz:

```text
1_000_000 chu kỳ * 20 ns = 20 ms
```

Nút phải ổn định khoảng 20 ms thì mới được công nhận.

### Đồng bộ input ngoài

```verilog
btn_sync_0 <= i_btn;
btn_sync_1 <= btn_sync_0;
```

Nút bấm là tín hiệu ngoài FPGA, không đồng bộ với clock. Cho đi qua 2 flip-flop giúp giảm rủi ro metastability.

Luồng:

```text
i_btn --> btn_sync_0 --> btn_sync_1 --> debounce logic
```

### Logic lọc nhiễu

Nếu tín hiệu mới giống trạng thái đang công nhận:

```verilog
if (btn_sync_1 == o_btn_state) begin
    counter <= 20'd0;
end
```

Không có thay đổi thật, reset counter.

Nếu khác:

```verilog
counter <= counter + 1'b1;
```

Bắt đầu đếm. Nếu giữ khác đủ lâu:

```verilog
if (counter == (DELAY_CYCLES - 1)) begin
    o_btn_state <= btn_sync_1;
    counter <= 20'd0;
end
```

Lúc đó mới cập nhật trạng thái nút.

### Tạo tick 1 clock

```verilog
assign o_btn_tick = (btn_state_prev == 1'b1) && (o_btn_state == 1'b0);
```

Vì nút active-low, cạnh nhấn là `1 -> 0`. `tick` chỉ lên `1` đúng một chu kỳ clock.

FSM dùng `tick` để một lần nhấn chỉ xử lý một lần, dù người dùng giữ nút lâu.

## 6. File `internal_ram.v`

File này hiện có trong `design/`, nhưng `digital_safe_lock.v` bản hiện tại không instantiate nó. Top-level đang dùng `sram_controller.v` để nói chuyện với SRAM ngoài.

### Vai trò

`internal_ram` là RAM đơn giản bên trong FPGA hoặc dùng cho mô phỏng/thay thế SRAM. Nó dùng cùng kiểu giao diện với SRAM controller:

```verilog
i_rd_en
i_wr_en
i_addr
i_data
o_data
o_ready
```

Điều này có nghĩa là `lock_fsm` không cần biết phía sau là RAM nội bộ hay SRAM ngoài. Nó chỉ cần bật read/write và đợi `ready`.

### Bộ nhớ thật sự

```verilog
reg [15:0] memory;
```

Code chỉ lưu một word 16 bit, vì dự án chỉ cần lưu mật khẩu ở địa chỉ 0.

Nếu muốn nhiều ô nhớ hơn, có thể dùng:

```verilog
reg [15:0] mem [0:1023];
```

Nhưng hiện tại chưa cần.

### FSM nhỏ bên trong

State:

```verilog
localparam IDLE = 2'd0;
localparam WAIT = 2'd1;
localparam DONE = 2'd2;
```

Luồng ghi:

```text
IDLE thấy i_wr_en = 1
-> memory <= i_data
-> WAIT
-> o_ready = 1
-> DONE
-> đợi i_wr_en hạ xuống 0
-> IDLE
```

Luồng đọc:

```text
IDLE thấy i_rd_en = 1
-> o_data <= memory
-> WAIT
-> o_ready = 1
-> DONE
-> đợi i_rd_en hạ xuống 0
-> IDLE
```

Điểm đáng học ở file này là handshake `enable/ready`. Đây là mẫu giao tiếp rất phổ biến trong thiết kế số.

## 7. File `sram_controller.v`

Đây là module nối FSM với SRAM ngoài bất đồng bộ.

### Vai trò

`lock_fsm` muốn giao tiếp bộ nhớ theo kiểu đơn giản:

```text
rd_en/wr_en, addr, data, ready
```

Nhưng SRAM ngoài cần tín hiệu vật lý:

```text
SRAM_ADDR
SRAM_DQ
SRAM_CE_N
SRAM_OE_N
SRAM_WE_N
SRAM_LB_N
SRAM_UB_N
```

`sram_controller` đứng giữa để chuyển đổi hai kiểu giao tiếp này.

### Giao diện phía FSM

```verilog
input  wire        i_rd_en
input  wire        i_wr_en
input  wire [18:0] i_addr
input  wire [15:0] i_data
output reg  [15:0] o_data
output reg         o_ready
```

FSM chỉ cần:

```text
Muốn đọc: bật i_rd_en, đặt i_addr, đợi o_ready.
Muốn ghi: bật i_wr_en, đặt i_addr/i_data, đợi o_ready.
```

### Giao diện phía SRAM

```verilog
output reg  [18:0] SRAM_ADDR
inout  wire [15:0] SRAM_DQ
output reg         SRAM_CE_N
output reg         SRAM_OE_N
output reg         SRAM_WE_N
output reg         SRAM_LB_N
output reg         SRAM_UB_N
```

Các tín hiệu có `_N` là active-low:

| Tín hiệu | Ý nghĩa |
| --- | --- |
| `SRAM_CE_N` | Chip Enable, `0` là bật chip |
| `SRAM_OE_N` | Output Enable, `0` là SRAM được phép xuất dữ liệu |
| `SRAM_WE_N` | Write Enable, `0` là ghi |
| `SRAM_LB_N` | Lower Byte enable |
| `SRAM_UB_N` | Upper Byte enable |

### Bus hai chiều `SRAM_DQ`

```verilog
assign SRAM_DQ = dq_drive ? dq_out : 16'hzzzz;
```

Đây là dòng rất quan trọng.

- Khi ghi, FPGA phải lái dữ liệu ra bus: `dq_drive = 1`.
- Khi đọc, SRAM lái dữ liệu ra bus, FPGA phải nhả bus: `dq_drive = 0`, tức high-Z.

Nếu cả FPGA và SRAM cùng lái bus, có thể gây tranh chấp điện.

### FSM trong SRAM controller

State:

```verilog
S_IDLE
S_READ_WAIT
S_READ_DONE
S_WRITE_WAIT
S_DONE
```

### Luồng ghi SRAM

Ở `S_IDLE`, nếu thấy `i_wr_en`:

```verilog
SRAM_ADDR <= i_addr;
dq_out <= i_data;
dq_drive <= 1'b1;
SRAM_CE_N <= 1'b0;
SRAM_OE_N <= 1'b1;
SRAM_WE_N <= 1'b0;
SRAM_LB_N <= 1'b0;
SRAM_UB_N <= 1'b0;
state <= S_WRITE_WAIT;
```

Ý nghĩa:

```text
Đặt địa chỉ
Đưa dữ liệu ra bus
Bật chip
Tắt output SRAM
Bật write
Bật cả byte thấp và byte cao
Đợi vài chu kỳ
```

Sau `WAIT_CYCLES`, controller tắt write và báo xong:

```verilog
SRAM_WE_N <= 1'b1;
SRAM_CE_N <= 1'b1;
dq_drive <= 1'b0;
o_ready <= 1'b1;
```

### Luồng đọc SRAM

Ở `S_IDLE`, nếu thấy `i_rd_en`:

```verilog
SRAM_ADDR <= i_addr;
dq_drive <= 1'b0;
SRAM_CE_N <= 1'b0;
SRAM_OE_N <= 1'b0;
SRAM_WE_N <= 1'b1;
SRAM_LB_N <= 1'b0;
SRAM_UB_N <= 1'b0;
state <= S_READ_WAIT;
```

Ý nghĩa:

```text
Đặt địa chỉ
Nhả bus data
Bật chip
Cho SRAM xuất dữ liệu
Không ghi
Đợi dữ liệu ổn định
```

Sau `WAIT_CYCLES`, lấy dữ liệu:

```verilog
o_data <= SRAM_DQ;
```

Rồi tắt SRAM và báo:

```verilog
o_ready <= 1'b1;
```

### Vì sao có `S_DONE`?

```verilog
if (!i_rd_en && !i_wr_en) begin
    o_ready <= 1'b0;
    state <= S_IDLE;
end
```

Controller giữ `ready = 1` cho tới khi FSM hạ `rd_en/wr_en` xuống. Đây là handshake sạch, tránh việc FSM bỏ lỡ xung `ready`.

## 8. File `lock_fsm.v`

Đây là file quan trọng nhất. Nó chứa thuật toán của khóa.

### Vai trò

`lock_fsm` quyết định hệ thống đang:

- mới reset và ghi mật khẩu mặc định,
- đang khóa,
- đang đọc mật khẩu,
- đã mở,
- báo lỗi,
- đang đổi mật khẩu,
- báo đổi mật khẩu xong.

Input chính:

```verilog
i_sw
i_enter_tick
i_change_tick
i_sram_data
i_sram_ready
```

Output chính:

```verilog
o_sram_rd_en
o_sram_wr_en
o_sram_addr
o_sram_data_out
o_ledr
o_ledg
o_display_state
```

### Các state

```verilog
S_INIT_WR
S_INIT_WAIT
S_IDLE
S_READ_CHECK
S_UNLOCKED
S_ERR
S_WRITE_CHG
S_CHG_DONE
```

Ý nghĩa:

| State | Ý nghĩa |
| --- | --- |
| `S_INIT_WR` | Ghi mật khẩu mặc định `00` vào SRAM |
| `S_INIT_WAIT` | Đợi SRAM ghi xong |
| `S_IDLE` | Đang khóa, chờ Enter |
| `S_READ_CHECK` | Đọc mật khẩu từ SRAM và so sánh |
| `S_UNLOCKED` | Đã mở khóa |
| `S_ERR` | Sai mật khẩu |
| `S_WRITE_CHG` | Ghi mật khẩu mới |
| `S_CHG_DONE` | Báo đổi mật khẩu xong |

### Reset

Khi reset:

```verilog
state <= S_INIT_WR;
o_ledr <= 1'b1;
o_ledg <= 1'b0;
o_display_state <= 3'd0;
```

Hệ thống mặc định ở trạng thái khóa, đèn đỏ bật, display `---`.

### Khởi tạo mật khẩu mặc định

Ở `S_INIT_WR`:

```verilog
o_sram_wr_en <= 1'b1;
o_sram_addr <= 19'd0;
o_sram_data_out <= 16'h0000;
state <= S_INIT_WAIT;
```

FSM yêu cầu ghi `0000` vào địa chỉ 0 của SRAM. Mật khẩu thực tế dùng 8 bit thấp, nên password mặc định là `00`.

Ở `S_INIT_WAIT`, FSM chờ:

```verilog
if (i_sram_ready) begin
    o_sram_wr_en <= 1'b0;
    state <= S_IDLE;
end
```

### Trạng thái khóa `S_IDLE`

```verilog
o_ledr <= 1'b1;
o_ledg <= 1'b0;
o_display_state <= 3'd0;
```

Nếu nhấn Enter:

```verilog
o_sram_rd_en <= 1'b1;
o_sram_addr <= 19'd0;
state <= S_READ_CHECK;
```

Nó không tự so sánh ngay, mà yêu cầu SRAM controller đọc password đã lưu.

### Kiểm tra mật khẩu `S_READ_CHECK`

Khi SRAM báo ready:

```verilog
if (i_sram_data[7:0] == i_sw) begin
    state <= S_UNLOCKED;
end else begin
    state <= S_ERR;
end
o_sram_rd_en <= 1'b0;
```

Chỉ 8 bit thấp được dùng:

```verilog
i_sram_data[7:0]
```

Ví dụ SRAM lưu `16'h00A5`, switch là `8'hA5`, thì mở khóa.

### Trạng thái mở khóa `S_UNLOCKED`

```verilog
o_ledr <= 1'b0;
o_ledg <= 1'b1;
o_display_state <= 3'd1;
```

Nếu nhấn Change:

```verilog
o_sram_wr_en <= 1'b1;
o_sram_addr <= 19'd0;
o_sram_data_out <= {8'h00, i_sw};
state <= S_WRITE_CHG;
```

`{8'h00, i_sw}` là nối bit. Nếu `i_sw = 8'hA5`, kết quả là `16'h00A5`.

Nếu nhấn Enter khi đang mở:

```verilog
state <= S_IDLE;
```

Tức là khóa lại.

### Trạng thái lỗi `S_ERR`

```verilog
o_ledr <= 1'b1;
o_ledg <= 1'b0;
o_display_state <= 3'd2;
```

Giữ trạng thái lỗi cho tới khi:

```verilog
if (timer_done || i_enter_tick) begin
    state <= S_IDLE;
end
```

Nghĩa là hết timer thì quay lại khóa, hoặc người dùng nhấn Enter để bỏ qua chờ.

### Đổi mật khẩu xong

Ở `S_WRITE_CHG`, FSM chờ SRAM ghi xong:

```verilog
if (i_sram_ready) begin
    o_sram_wr_en <= 1'b0;
    state <= S_CHG_DONE;
end
```

Ở `S_CHG_DONE`:

```verilog
o_ledr <= 1'b0;
o_ledg <= 1'b1;
o_display_state <= 3'd3;
```

Sau timer:

```verilog
state <= S_UNLOCKED;
```

### Timer

Timer chỉ chạy trong `S_ERR` và `S_CHG_DONE`:

```verilog
wire timer_en = (state == S_ERR) || (state == S_CHG_DONE);
wire timer_done = (timer >= TIMER_CYCLES);
```

Nếu không ở hai state đó, timer reset về 0.

## 9. File `digital_safe_lock.v`

Đây là top-level core của hệ thống. Nó không chứa thuật toán chi tiết, mà nối các module lại.

### Parameter

```verilog
parameter DB_DELAY = 20'd1_000_000
parameter TIMER_CYCLES = 28'd100_000_000
parameter SRAM_WAIT_CYCLES = 2
```

Ý nghĩa:

| Parameter | Ý nghĩa |
| --- | --- |
| `DB_DELAY` | thời gian lọc nút bấm |
| `TIMER_CYCLES` | thời gian giữ `Err`/`Chg` |
| `SRAM_WAIT_CYCLES` | số chu kỳ đợi SRAM ổn định |

Trong testbench các giá trị này được giảm nhỏ để mô phỏng nhanh.

### Input/output board

Input:

```verilog
CLOCK_50
SW[17:0]
KEY[3:0]
```

Output:

```verilog
LEDR
LEDG
HEX2/HEX1/HEX0
LCD
SRAM
```

### Tắt LED không dùng

```verilog
assign LEDR[17:1] = 17'd0;
assign LEDG[8:1] = 8'd0;
```

Chỉ dùng `LEDR[0]` và `LEDG[0]`, các LED còn lại tắt.

### Reset

```verilog
wire rst_n = KEY[0];
```

`KEY[0]` active-low nên tên là `rst_n`, trong đó `_n` thường nghĩa là active-low.

### Debounce nút Enter và Change

```verilog
button_debounce db_enter (...)
button_debounce db_change (...)
```

Hai instance giống nhau, chỉ khác input:

- `KEY[1]` tạo `enter_tick`.
- `KEY[2]` tạo `change_tick`.

### Nối SRAM controller

```verilog
sram_controller sram_ctrl (...)
```

Module này nhận giao diện đơn giản từ FSM:

```text
sram_rd_en
sram_wr_en
sram_addr_internal
sram_data_to_ctrl
sram_data_from_ctrl
sram_ready
```

Rồi điều khiển chân SRAM vật lý:

```text
SRAM_ADDR
SRAM_DQ
SRAM_CE_N
SRAM_OE_N
SRAM_WE_N
SRAM_LB_N
SRAM_UB_N
```

### Nối FSM

```verilog
lock_fsm fsm_inst (...)
```

FSM nhận:

```text
SW[7:0]
enter_tick
change_tick
sram_ready
sram_data_from_ctrl
```

FSM xuất:

```text
sram_rd_en
sram_wr_en
sram_addr_internal
sram_data_to_ctrl
LEDR[0]
LEDG[0]
display_state
```

### Nối HEX và LCD

```verilog
hex_display hex_inst (
    .i_state(display_state),
    ...
);
```

```verilog
lcd_controller lcd_inst (
    .i_state(display_state),
    ...
);
```

`display_state` là một dây chung từ FSM sang cả HEX và LCD. FSM chỉ xuất mã trạng thái; module hiển thị tự dịch mã đó thành chữ.

## 10. File `lcd_controller.v`

Đọc file này sau cùng vì nó dài và chủ yếu là timing LCD.

### Vai trò

LCD controller nhận `i_state` từ FSM và in text ra LCD 16x2.

Output:

```verilog
o_lcd_rs
o_lcd_rw
o_lcd_en
o_lcd_data
```

`o_lcd_rw` luôn bằng 0:

```verilog
assign o_lcd_rw = 1'b0;
```

Tức là chỉ ghi ra LCD, không đọc từ LCD.

### Delay LCD

LCD HD44780 cần đợi giữa các lệnh:

```verilog
localparam DELAY_20MS = CLK_FREQ / 50;
localparam DELAY_2MS  = CLK_FREQ / 500;
localparam DELAY_50US = CLK_FREQ / 20_000;
```

Với `CLK_FREQ = 50_000_000`:

- `DELAY_20MS`: đợi sau bật nguồn.
- `DELAY_2MS`: lệnh clear display.
- `DELAY_50US`: lệnh bình thường.

### State chính

```verilog
S_PWR_ON
S_INIT_1
S_INIT_2
S_INIT_3
S_INIT_4
S_LINE1
S_PRINT1
S_LINE2
S_PRINT2
S_WAIT
```

Luồng:

```text
Đợi LCD bật nguồn
-> gửi lệnh khởi tạo
-> set địa chỉ dòng 1
-> in 16 ký tự dòng 1
-> set địa chỉ dòng 2
-> in 16 ký tự dòng 2
-> chờ i_state đổi
-> nếu đổi thì in lại dòng 2
```

### Nội dung dòng 1

Dòng 1 cố định:

```text
" DIGITAL SAFE   "
```

Trong code là mảng `line1_char[0:15]`.

### Nội dung dòng 2

Dòng 2 phụ thuộc trạng thái:

| `i_state` | LCD line 2 |
| --- | --- |
| `3'd0` | `STATUS: LOCKED  ` |
| `3'd1` | `STATUS: OPEN    ` |
| `3'd2` | `WRONG PASSWORD! ` |
| `3'd3` | `NEW PASS SAVED! ` |

Code dùng `current_fsm_state`, không dùng trực tiếp `i_state` trong mảng:

```verilog
case(current_fsm_state)
```

Khi phát hiện `i_state` đổi:

```verilog
if (current_fsm_state != i_state) begin
    current_fsm_state <= i_state;
    state <= S_LINE2;
end
```

Nó cập nhật state hiện tại rồi in lại dòng 2.

### Sequence nhỏ để gửi một byte

Ngoài FSM chính, file còn có `seq`:

```verilog
SEQ_SETUP
SEQ_EN_HI
SEQ_EN_LO
SEQ_DELAY
SEQ_DONE
```

Đây là trình tự gửi một command/ký tự:

```text
Setup RS và DATA
-> kéo EN lên 1
-> kéo EN xuống 0
-> đợi delay
-> xong
```

LCD không nhận dữ liệu chỉ bằng cách đặt `DATA`; phải có xung `EN`.

## 11. Luồng thuật toán toàn hệ thống

Dưới đây là cách nghĩ gần giống C:

```c
reset:
    password = 0x00;       // ghi vào SRAM address 0
    state = IDLE;

IDLE:
    red = 1;
    green = 0;
    display = "---";
    if (enter_tick) {
        saved = sram_read(0);
        if ((saved & 0xff) == SW[7:0])
            state = UNLOCKED;
        else
            state = ERR;
    }

UNLOCKED:
    red = 0;
    green = 1;
    display = "OPn";
    if (change_tick) {
        sram_write(0, SW[7:0]);
        state = CHG_DONE;
    } else if (enter_tick) {
        state = IDLE;
    }

ERR:
    red = 1;
    green = 0;
    display = "Err";
    if (timer_done || enter_tick)
        state = IDLE;

CHG_DONE:
    red = 0;
    green = 1;
    display = "Chg";
    if (timer_done)
        state = UNLOCKED;
```

Nhưng trong Verilog, `sram_read()` và `sram_write()` không trả kết quả ngay như function C. Chúng là handshake:

```text
FSM bật rd_en hoặc wr_en
SRAM controller chạy bus cycle
SRAM controller bật ready
FSM lấy data hoặc chuyển state
FSM hạ rd_en/wr_en
Controller quay về IDLE
```

## 12. Ghi chú về testbench hiện tại

Testbench `tb/tb_digital_safe_lock.v` hiện đã có SRAM model:

```verilog
reg [15:0] sram_mem [0:1];
```

Nó mô phỏng SRAM ngoài bằng cách lái `SRAM_DQ` khi đọc:

```verilog
assign SRAM_DQ = (!SRAM_CE_N && !SRAM_OE_N && SRAM_WE_N)
               ? sram_mem[SRAM_ADDR[0]]
               : 16'hzzzz;
```

Và ghi vào `sram_mem` khi `WE_N = 0`.

Lệnh compile/mô phỏng đã kiểm tra:

```powershell
iverilog -g2012 -o sim\tb_sram_current_check.vvp `
  tb\tb_digital_safe_lock.v `
  design\digital_safe_lock.v `
  design\button_debounce.v `
  design\lock_fsm.v `
  design\hex_display.v `
  design\lcd_controller.v `
  design\sram_controller.v `
  design\internal_ram.v

vvp sim\tb_sram_current_check.vvp
```

Kết quả hiện tại: các test unlock default, đổi password sang `A5`, sai password, unlock bằng password mới, spam sai password, rồi unlock lại đều pass.

## 13. Tóm tắt từng file

| File | Nên hiểu như |
| --- | --- |
| `hex_display.v` | Bộ dịch trạng thái sang LED 7 đoạn |
| `button_debounce.v` | Bộ lọc nút bấm và tạo event nhấn 1 clock |
| `internal_ram.v` | RAM đơn giản dùng giao diện `rd/wr/ready`, hiện không được top-level dùng |
| `sram_controller.v` | Driver cho SRAM ngoài, quản lý bus data hai chiều |
| `lock_fsm.v` | Bộ não thuật toán khóa |
| `digital_safe_lock.v` | File nối dây toàn hệ thống |
| `lcd_controller.v` | Driver LCD 16x2 |

Nếu học để sửa code, thứ tự thực tế nên là:

```text
hex_display.v
-> button_debounce.v
-> internal_ram.v
-> sram_controller.v
-> lock_fsm.v
-> digital_safe_lock.v
-> lcd_controller.v
```

Nếu học để hiểu nhanh sản phẩm hoạt động ra sao:

```text
lock_fsm.v
-> digital_safe_lock.v
-> sram_controller.v
-> button_debounce.v
-> hex_display.v
-> lcd_controller.v
```
