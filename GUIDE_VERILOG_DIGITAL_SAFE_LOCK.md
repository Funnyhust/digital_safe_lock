# Hướng dẫn đọc code Digital Safe Lock - bản SSRAM hiện tại

Tài liệu này được viết theo trạng thái code hiện tại trong thư mục `design/`. Bản này không còn dùng `sram_controller.v` kiểu SRAM bất đồng bộ cũ nữa, mà đang dùng `ssram_controller.v` để giao tiếp SSRAM/Flash shared bus trên DE2i-150 qua `FS_DQ`, `FS_ADDR` và các tín hiệu `SSRAM_*`.

Tài liệu giả sử bạn đã biết C, nhưng mới học Verilog.

## 1. Nên đọc file theo thứ tự nào?

Thứ tự khuyến nghị để học từ dễ đến khó:

```text
1. design/hex_display.v
2. design/button_debounce.v
3. design/internal_ram.v
4. design/lock_fsm.v
5. design/ssram_controller.v
6. design/digital_safe_lock.v
7. design/lcd_controller.v
8. design/digital_safe_lock_3.qsf
```

Lý do:

- `hex_display.v`: dễ nhất, chỉ là logic tổ hợp đổi mã trạng thái thành LED 7 đoạn.
- `button_debounce.v`: học clock, reset, thanh ghi, lọc nút bấm và tạo xung 1 chu kỳ.
- `internal_ram.v`: học giao diện bộ nhớ `rd_en/wr_en/ready` đơn giản.
- `lock_fsm.v`: học thuật toán chính của khóa.
- `ssram_controller.v`: học cách FSM nói chuyện với SSRAM vật lý.
- `digital_safe_lock.v`: học cách nối tất cả module lại với nhau.
- `lcd_controller.v`: dài nhất, chủ yếu là timing LCD.
- `digital_safe_lock_3.qsf`: file cấu hình Quartus/pin assignment, không phải code logic.

Nếu muốn hiểu nhanh hệ thống hoạt động ra sao, có thể đọc:

```text
lock_fsm.v -> digital_safe_lock.v -> ssram_controller.v
```

## 2. Tư duy Verilog trước khi đọc

Trong C, bạn hay nghĩ theo kiểu chương trình chạy tuần tự:

```c
read_button();
check_password();
set_led();
```

Trong Verilog, bạn đang mô tả phần cứng. Các module chạy song song. Module này không "gọi hàm" module kia. Chúng được nối dây với nhau.

Ví dụ trong `digital_safe_lock.v`:

```verilog
hex_display hex_inst (
    .i_state(display_state),
    .o_hex2(HEX2),
    .o_hex1(HEX1),
    .o_hex0(HEX0)
);
```

Đây không phải gọi hàm `hex_display()`. Đây là tạo một instance phần cứng tên `hex_inst`. Từ đó trở đi, `hex_inst` luôn tồn tại và luôn theo dõi `display_state`.

Một số khái niệm:

| Verilog | C gần giống | Ý nghĩa |
| --- | --- | --- |
| `module` | struct/module/object | Một khối phần cứng |
| `wire` | dây nối | Không tự lưu trạng thái |
| `reg` | biến lưu | Có thể thành flip-flop/thanh ghi |
| `always @(*)` | hàm tính liên tục | Logic tổ hợp |
| `always @(posedge clk)` | update mỗi tick | Logic tuần tự theo clock |
| `<=` | cập nhật thanh ghi | Dùng trong always có clock |
| `=` | gán tức thời | Hay dùng trong logic tổ hợp |
| `inout` | bus hai chiều | Lúc đọc thì nhả bus, lúc ghi thì lái bus |

## 3. Sơ đồ tổng thể hiện tại

```text
SW[7:0] ---------------------------+
KEY[1] -> button_debounce -> tick -+
KEY[2] -> button_debounce -> tick -+
                                   |
                                   v
                              lock_fsm
                              |   |   |
                              |   |   +--> LEDR[0], LEDG[0]
                              |   |
                              |   +--> display_state --> hex_display --> HEX
                              |                       --> lcd_controller --> LCD
                              |
                              v
                         ssram_controller
                              |
                              v
             FS_DQ / FS_ADDR / SSRAM_* physical pins
```

`lock_fsm` là bộ não. Các module khác phục vụ nó:

- `button_debounce`: biến nút bấm nhiễu thành event sạch.
- `ssram_controller`: đọc/ghi password vào SSRAM.
- `hex_display`: hiển thị trạng thái ngắn trên LED 7 đoạn.
- `lcd_controller`: hiển thị trạng thái dài trên LCD.
- `digital_safe_lock`: nối dây toàn bộ.

## 4. `hex_display.v`

### Vai trò

File này nhận `i_state` 3 bit và xuất mã LED 7 đoạn cho `HEX2`, `HEX1`, `HEX0`.

```verilog
input  wire [2:0] i_state
output reg  [6:0] o_hex2
output reg  [6:0] o_hex1
output reg  [6:0] o_hex0
```

Mapping:

| `i_state` | Hiển thị |
| --- | --- |
| `3'd0` | `---` |
| `3'd1` | `OPn` |
| `3'd2` | `Err` |
| `3'd3` | `Chg` |

### Vì sao không cần gọi hàm set LED?

Logic chính:

```verilog
always @(*) begin
    case (i_state)
        ...
    endcase
end
```

`always @(*)` nghĩa là logic tổ hợp. Cứ khi `i_state` đổi, output sẽ tự tính lại. Nó không cần được gọi như C.

Tư duy gần giống:

```c
switch (i_state) {
case 0: HEX = "---"; break;
case 1: HEX = "OPn"; break;
case 2: HEX = "Err"; break;
case 3: HEX = "Chg"; break;
}
```

Nhưng trong phần cứng, mạch này luôn tồn tại.

### Active-low LED

Comment trong code:

```verilog
// active-low (0 = ON, 1 = OFF)
```

Tức là bit `0` làm segment sáng, bit `1` làm segment tắt. Vì vậy các hằng như `7'h40`, `7'h0C` là mẫu bật/tắt segment, không phải ASCII.

## 5. `button_debounce.v`

### Vai trò

Nút bấm vật lý bị rung tiếp điểm. Một lần nhấn có thể tạo nhiều xung giả. Module này lọc nhiễu và tạo:

- `o_btn_state`: trạng thái nút đã lọc.
- `o_btn_tick`: xung đúng 1 clock khi vừa nhấn.

Nút `KEY` là active-low:

```text
Không nhấn = 1
Nhấn      = 0
```

### Parameter

```verilog
parameter DELAY_CYCLES = 20'd1_000_000
```

Với clock 50 MHz:

```text
1 chu kỳ = 20 ns
1_000_000 chu kỳ = 20 ms
```

Nút phải ổn định khoảng 20 ms thì mới được công nhận. Trong testbench, `DB_DELAY` được đặt là `1` để mô phỏng nhanh.

### Đồng bộ tín hiệu ngoài

```verilog
btn_sync_0 <= i_btn;
btn_sync_1 <= btn_sync_0;
```

Nút bấm đến từ ngoài FPGA, không đồng bộ với clock. Hai flip-flop này đưa tín hiệu vào miền clock nội bộ và giảm rủi ro metastability.

Luồng:

```text
i_btn -> btn_sync_0 -> btn_sync_1 -> debounce logic
```

### Lọc nhiễu

Nếu tín hiệu đồng bộ giống trạng thái đã công nhận:

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

Nó bắt đầu đếm. Khi đếm đủ `DELAY_CYCLES - 1`:

```verilog
o_btn_state <= btn_sync_1;
counter <= 20'd0;
```

Lúc đó trạng thái nút mới được cập nhật.

### Tạo tick

```verilog
assign o_btn_tick = (btn_state_prev == 1'b1) && (o_btn_state == 1'b0);
```

Vì nút active-low, cạnh nhấn là `1 -> 0`. `tick` chỉ lên 1 trong đúng một clock. FSM dùng `tick` để một lần nhấn chỉ xử lý một lần, dù bạn giữ nút lâu.

## 6. `internal_ram.v`

### Vai trò

File này là RAM nội bộ/mô phỏng đơn giản dùng cùng giao diện với controller bộ nhớ:

```verilog
i_rd_en
i_wr_en
i_addr
i_data
o_data
o_ready
```

Trong `digital_safe_lock.v` hiện tại, module này không được instantiate. Top-level đang dùng `ssram_controller.v`. Tuy vậy, `internal_ram.v` vẫn hữu ích để hiểu giao diện bộ nhớ đơn giản mà `lock_fsm` mong muốn.

### Khác bản cũ ở điểm nào?

Bản hiện tại lưu 2 word:

```verilog
reg [15:0] memory [0:1];
```

Ý nghĩa:

- `memory[0]`: password.
- `memory[1]`: magic number.

Magic number là `16'h55AA`, dùng để biết RAM đã được khởi tạo chưa.

### Không xóa RAM khi reset

Trong reset:

```verilog
// IMPORTANT: Do NOT clear memory here. A soft reset should not erase SRAM.
```

Đây là ý tưởng quan trọng: reset logic FPGA không nên tự động xóa nội dung SRAM. Nếu đã có magic number, hệ thống không ghi đè password về mặc định.

### Initial X

```verilog
initial begin
    memory[0] = 16'hXXXX;
    memory[1] = 16'hXXXX;
end
```

Trong mô phỏng, `X` nghĩa là chưa biết/chưa khởi tạo. Khi FSM đọc magic number mà không thấy `55AA`, nó sẽ ghi default password và magic number.

### FSM nhỏ trong RAM

State:

```verilog
IDLE -> WAIT -> DONE
```

Luồng đọc:

```text
IDLE thấy i_rd_en
-> o_data <= memory[i_addr[0]]
-> WAIT
-> o_ready = 1
-> DONE
-> đợi i_rd_en hạ xuống 0
-> IDLE
```

Luồng ghi:

```text
IDLE thấy i_wr_en
-> memory[i_addr[0]] <= i_data
-> WAIT
-> o_ready = 1
-> DONE
-> đợi i_wr_en hạ xuống 0
-> IDLE
```

## 7. `lock_fsm.v`

Đây là file quan trọng nhất. Nó chứa thuật toán khóa.

### Giao diện input/output

Input từ người dùng:

```verilog
input wire [7:0] i_sw
input wire i_enter_tick
input wire i_change_tick
```

Giao diện bộ nhớ:

```verilog
output reg  o_sram_rd_en
output reg  o_sram_wr_en
output reg  [18:0] o_sram_addr
output reg  [15:0] o_sram_data_out
input  wire [15:0] i_sram_data
input  wire i_sram_ready
```

Output trạng thái:

```verilog
output reg o_ledr
output reg o_ledg
output reg [2:0] o_display_state
```

### Các state

```verilog
S_CHK_MAGIC_RD
S_CHK_MAGIC_WAIT
S_CHK_MAGIC_EVAL
S_INIT_WR
S_INIT_WAIT
S_INIT_WR_MAGIC
S_INIT_WAIT_MAGIC
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
| `S_CHK_MAGIC_RD` | Đọc địa chỉ 1 để kiểm tra magic number |
| `S_CHK_MAGIC_WAIT` | Đợi bộ nhớ đọc xong |
| `S_CHK_MAGIC_EVAL` | So sánh dữ liệu đọc với `16'h55AA` |
| `S_INIT_WR` | Ghi password mặc định `00` vào địa chỉ 0 |
| `S_INIT_WAIT` | Đợi ghi password xong |
| `S_INIT_WR_MAGIC` | Ghi `55AA` vào địa chỉ 1 |
| `S_INIT_WAIT_MAGIC` | Đợi ghi magic xong |
| `S_IDLE` | Đang khóa, chờ Enter |
| `S_READ_CHECK` | Đọc password và so sánh |
| `S_UNLOCKED` | Đã mở khóa |
| `S_ERR` | Sai mật khẩu |
| `S_WRITE_CHG` | Ghi mật khẩu mới |
| `S_CHG_DONE` | Báo đổi mật khẩu xong |

### Reset và magic number

Khi reset:

```verilog
state <= S_CHK_MAGIC_RD;
```

FSM không ghi password mặc định ngay. Nó đọc địa chỉ 1 trước:

```verilog
o_sram_rd_en <= 1'b1;
o_sram_addr <= 19'd1;
```

Nếu đọc được `16'h55AA`:

```verilog
state <= S_IDLE;
```

Nếu không:

```verilog
state <= S_INIT_WR;
```

Nghĩa là SRAM chưa được khởi tạo, cần ghi password mặc định và magic number.

### Khởi tạo SRAM

Password mặc định:

```verilog
o_sram_addr <= 19'd0;
o_sram_data_out <= 16'h0000;
```

Magic number:

```verilog
o_sram_addr <= 19'd1;
o_sram_data_out <= 16'h55AA;
```

Sau đó vào `S_IDLE`.

### `S_IDLE`

Trong trạng thái khóa:

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

FSM yêu cầu đọc password từ địa chỉ 0.

### `S_READ_CHECK`

Khi bộ nhớ báo `i_sram_ready`:

```verilog
if (i_sram_data[7:0] == i_sw) begin
    state <= S_UNLOCKED;
end else begin
    state <= S_ERR;
end
```

Chỉ 8 bit thấp của word 16 bit được dùng làm password.

Ví dụ:

```text
i_sram_data = 16'h00A5
i_sw        = 8'hA5
=> đúng mật khẩu
```

### `S_UNLOCKED`

Khi mở khóa:

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

`{8'h00, i_sw}` nối 8 bit 0 với 8 bit switch để thành word 16 bit.

Nếu nhấn Enter khi đang mở:

```verilog
state <= S_IDLE;
```

Tức là khóa lại.

### `S_ERR`

Sai password:

```verilog
o_ledr <= 1'b1;
o_ledg <= 1'b0;
o_display_state <= 3'd2;
```

Thoát lỗi khi hết timer hoặc nhấn Enter:

```verilog
if (timer_done || i_enter_tick) begin
    state <= S_IDLE;
end
```

Testbench hiện có test riêng cho hành vi "nhấn Enter để thoát ERR sớm".

### `S_CHG_DONE`

Đổi password xong:

```verilog
o_ledr <= 1'b0;
o_ledg <= 1'b1;
o_display_state <= 3'd3;
```

Hết timer thì quay lại `S_UNLOCKED`.

### Timer

Timer chỉ chạy trong `S_ERR` và `S_CHG_DONE`:

```verilog
wire timer_en = (state == S_ERR) || (state == S_CHG_DONE);
wire timer_done = (timer >= TIMER_CYCLES);
```

Nếu không ở 2 state này, timer reset về 0.

## 8. `ssram_controller.v`

File này thay thế `sram_controller.v` cũ. Nó điều khiển SSRAM đồng bộ/pipelined trên DE2i-150.

### Vai trò

Phía FSM dùng giao diện đơn giản:

```verilog
i_rd_en
i_wr_en
i_addr
i_data
o_data
o_ready
```

Phía board dùng interface vật lý:

```verilog
FS_DQ[31:0]
FS_ADDR[26:1]
SSRAM0_CE_N
SSRAM1_CE_N
SSRAM_ADSC_N
SSRAM_ADSP_N
SSRAM_ADV_N
SSRAM_BE[3:0]
SSRAM_CLK
SSRAM_GW_N
SSRAM_OE_N
SSRAM_WE_N
```

Controller này đứng giữa để đổi request đọc/ghi của FSM thành chu kỳ SSRAM.

### Static signals

```verilog
assign SSRAM0_CE_N = 1'b0;
assign SSRAM1_CE_N = 1'b0;
assign SSRAM_ADSP_N = 1'b1;
assign SSRAM_ADV_N = 1'b1;
assign SSRAM_GW_N = 1'b1;
assign SSRAM_BE = 4'b1100;
assign SSRAM_CLK = clk;
```

Ý nghĩa:

- Bật cả hai chip enable.
- Không dùng processor mode.
- Không dùng burst.
- Không dùng global write.
- Chỉ enable lower 2 bytes. Vì password chỉ dùng 16 bit thấp trong bus 32 bit.
- SSRAM nhận clock từ `CLOCK_50`.

`SSRAM_BE` active-low. `4'b1100` nghĩa là byte enable thấp đang bật, hai byte cao tắt.

### Bus hai chiều `FS_DQ`

```verilog
assign FS_DQ = data_oe ? data_out_reg : 32'bz;
```

- Khi ghi: `data_oe = 1`, FPGA lái data ra bus.
- Khi đọc: `data_oe = 0`, FPGA nhả bus, SSRAM/mock SSRAM lái data.

Đây là phần quan trọng để tránh tranh chấp bus.

### State

```verilog
IDLE
R1
R2
R3
W1
W2
WAIT_IDLE
```

### Ghi SSRAM

Khi `i_wr_en` ở `IDLE`:

```verilog
addr_reg[20:1] <= i_addr;
adsc_n_reg <= 1'b0;
we_n_reg <= 1'b0;
state <= W1;
```

Ý nghĩa:

```text
Đặt địa chỉ
Kéo ADSC_N xuống để latch address
Kéo WE_N xuống để đăng ký lệnh ghi
```

Ở `W1`:

```verilog
adsc_n_reg <= 1'b1;
we_n_reg <= 1'b1;
data_out_reg <= {16'd0, i_data};
data_oe <= 1'b1;
state <= W2;
```

Vì SSRAM pipelined, data được đưa ra sau chu kỳ address/command.

Ở `W2`:

```verilog
data_oe <= 1'b0;
o_ready <= 1'b1;
state <= WAIT_IDLE;
```

### Đọc SSRAM

Khi `i_rd_en` ở `IDLE`:

```verilog
addr_reg[20:1] <= i_addr;
adsc_n_reg <= 1'b0;
we_n_reg <= 1'b1;
oe_n_reg <= 1'b0;
state <= R1;
```

Sau đó chờ pipeline:

```text
R1 -> R2 -> R3
```

Ở `R3`:

```verilog
o_data <= FS_DQ[15:0];
oe_n_reg <= 1'b1;
o_ready <= 1'b1;
```

Chỉ lấy 16 bit thấp từ bus 32 bit.

### `WAIT_IDLE`

```verilog
if (!i_rd_en && !i_wr_en) begin
    o_ready <= 1'b0;
    state <= IDLE;
end
```

Controller giữ `ready = 1` cho tới khi FSM hạ request xuống. Đây là handshake tránh mất tín hiệu ready.

### Lưu ý warning hiện tại

Khi compile bằng Icarus, có warning:

```text
Port 5 (i_addr) of module ssram_controller expects 20 bit(s), given 19.
Padding 1 high bits of the port.
```

Nguyên nhân:

- `lock_fsm` xuất `o_sram_addr` rộng 19 bit.
- `ssram_controller` nhận `i_addr` rộng 20 bit.

Hiện mô phỏng vẫn pass vì địa chỉ dùng chỉ là 0 và 1. Nhưng để sạch hơn, nên thống nhất độ rộng địa chỉ sau này.

## 9. `digital_safe_lock.v`

Đây là top-level core, nối các module lại với nhau.

### Parameter

```verilog
parameter DB_DELAY = 20'd1_000_000
parameter TIMER_CYCLES = 28'd100_000_000
```

Không còn `SRAM_WAIT_CYCLES` như bản SRAM bất đồng bộ trước. SSRAM controller hiện có timing pipeline cố định trong state machine.

### I/O chính

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
FS_DQ / FS_ADDR / SSRAM_*
```

### LED và LCD power

```verilog
assign LEDR[17:1] = 17'd0;
assign LEDG[8:1] = 8'd0;
assign LCD_ON = 1'b1;
```

Chỉ dùng `LEDR[0]`, `LEDG[0]`. LCD được bật nguồn/backlight.

### Reset

```verilog
wire rst_n = KEY[0];
```

`KEY[0]` là reset active-low.

### Debounce

Hai instance:

```verilog
button_debounce db_enter (...)
button_debounce db_change (...)
```

- `KEY[1]` -> `enter_tick`
- `KEY[2]` -> `change_tick`

### SSRAM controller

```verilog
ssram_controller sram_ctrl (...)
```

Tên instance vẫn là `sram_ctrl`, nhưng module thật là `ssram_controller`.

Giao diện nội bộ:

```text
sram_rd_en
sram_wr_en
sram_addr_internal
sram_data_to_ctrl
sram_data_from_ctrl
sram_ready
```

Giao diện vật lý:

```text
FS_DQ
FS_ADDR
SSRAM0_CE_N
SSRAM1_CE_N
SSRAM_ADSC_N
SSRAM_ADSP_N
SSRAM_ADV_N
SSRAM_BE
SSRAM_CLK
SSRAM_GW_N
SSRAM_OE_N
SSRAM_WE_N
```

### FSM

```verilog
lock_fsm fsm_inst (...)
```

FSM nhận:

```text
SW[7:0]
enter_tick
change_tick
sram_data_from_ctrl
sram_ready
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

### HEX và LCD

`display_state` đi song song tới:

```verilog
hex_display
lcd_controller
```

FSM không cần biết từng segment LED hay từng byte LCD. Nó chỉ xuất mã trạng thái 0/1/2/3.

### Comment cũ cần chú ý

Trong file vẫn còn comment:

```verilog
// I2C EEPROM Controller Instantiation
// Replaces the physical SRAM with an I2C EEPROM interface
```

Comment này đã lỗi thời. Code thực tế đang dùng `ssram_controller`, không dùng I2C EEPROM.

## 10. `lcd_controller.v`

File này dài vì phải làm đúng timing LCD HD44780.

### Vai trò

Nhận `i_state` từ FSM và in ra LCD 16x2.

Output:

```verilog
o_lcd_rs
o_lcd_rw
o_lcd_en
o_lcd_data
```

`o_lcd_rw` luôn là 0:

```verilog
assign o_lcd_rw = 1'b0;
```

Tức là chỉ ghi ra LCD, không đọc.

### Delay

```verilog
localparam DELAY_20MS = CLK_FREQ / 50;
localparam DELAY_2MS  = CLK_FREQ / 500;
localparam DELAY_50US = CLK_FREQ / 20_000;
```

Với 50 MHz:

- 20 ms power-up delay.
- 2 ms cho clear display.
- 50 us cho lệnh thường.

### FSM LCD

State:

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
Đợi LCD lên nguồn
-> gửi lệnh init
-> set địa chỉ dòng 1
-> in dòng 1
-> set địa chỉ dòng 2
-> in dòng 2
-> chờ trạng thái đổi
-> nếu đổi thì in lại dòng 2
```

### Nội dung dòng 1

```text
" DIGITAL SAFE   "
```

### Nội dung dòng 2

| State | LCD line 2 |
| --- | --- |
| `3'd0` | `STATUS: LOCKED  ` |
| `3'd1` | `STATUS: OPEN    ` |
| `3'd2` | `WRONG PASSWORD! ` |
| `3'd3` | `NEW PASS SAVED! ` |

### Sequence gửi byte

LCD cần xung `EN`. Vì vậy file có sequence nhỏ:

```verilog
SEQ_SETUP
SEQ_EN_HI
SEQ_EN_LO
SEQ_DELAY
SEQ_DONE
```

Tức là:

```text
Đặt RS/DATA
-> EN = 1
-> EN = 0
-> đợi delay
-> xong
```

## 11. `digital_safe_lock_3.qsf`

Đây không phải file Verilog. Đây là file Quartus Settings File.

Vai trò:

- Chọn FPGA family/device.
- Chọn top-level entity.
- Khai báo pin assignment cho LED, switch, key, LCD, SSRAM, bus `FS_DQ/FS_ADDR`.
- Khai báo chuẩn điện áp I/O.

Điểm cần chú ý:

```text
set_global_assignment -name TOP_LEVEL_ENTITY "digital_safe_lock_3"
```

Trong khi module Verilog top hiện tại tên là:

```verilog
module digital_safe_lock #(...)
```

Nếu build Quartus bằng file `.qsf` này, cần đảm bảo top-level entity trong QSF khớp với module top thật, hoặc có wrapper `digital_safe_lock_3` ở nơi khác. Nếu không, Quartus sẽ không tìm thấy top-level.

## 12. Testbench hiện tại

Ngoài `design/`, bản hiện tại có:

```text
tb/tb_digital_safe_lock.v
tb/mock_ssram.v
```

### `tb_digital_safe_lock.v`

Testbench instantiate `digital_safe_lock` với:

```verilog
.DB_DELAY(20'd1),
.TIMER_CYCLES(28'd200_000)
```

Tức:

- Debounce gần như tức thì.
- Timer ERR/CHG khoảng 4 ms trong mô phỏng.

Testbench kiểm tra:

1. Mở bằng password mặc định `00`.
2. Đổi password sang `A5`.
3. Khóa lại.
4. Nhập sai `11`.
5. Mở bằng password mới `A5`.
6. Spam password sai.
7. Đảm bảo không thể đổi password khi đang khóa.
8. Thoát ERR sớm bằng Enter.

### `mock_ssram.v`

Đây là model SSRAM để mô phỏng. Nó tạo RAM 256 word:

```verilog
reg [31:0] memory [0:255];
```

Ban đầu:

```verilog
memory[i] = 32'h0000_FFFF;
```

Vì địa chỉ magic ban đầu đọc ra `FFFF`, FSM hiểu bộ nhớ chưa init và ghi:

- password `0000` vào address 0.
- magic `55AA` vào address 1.

Mock này mô phỏng pipeline:

- Latch address khi `ADSC_N = 0`.
- Ghi data ở chu kỳ sau nếu command trước là write.
- Đưa read data ra `FS_DQ` khi `OE_N = 0`.

## 13. Kết quả mô phỏng hiện tại

Lệnh compile đã chạy:

```powershell
iverilog -g2012 -o sim\tb_current_guide_check.vvp `
  tb\tb_digital_safe_lock.v `
  tb\mock_ssram.v `
  design\digital_safe_lock.v `
  design\button_debounce.v `
  design\lock_fsm.v `
  design\hex_display.v `
  design\lcd_controller.v `
  design\ssram_controller.v `
  design\internal_ram.v
```

Có warning:

```text
ssram_controller expects 20-bit i_addr, top-level gives 19-bit address.
```

Mô phỏng:

```powershell
vvp sim\tb_current_guide_check.vvp
```

Kết quả: tất cả test hiện tại pass.

## 14. Thuật toán tổng quát

Viết gần giống C:

```c
on_reset:
    magic = memory_read(1);
    if (magic != 0x55AA) {
        memory_write(0, 0x0000); // default password
        memory_write(1, 0x55AA); // mark initialized
    }
    state = IDLE;

IDLE:
    red = 1;
    green = 0;
    display = "---";
    if (enter_tick) {
        saved = memory_read(0);
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
        memory_write(0, SW[7:0]);
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

Điểm khác C: `memory_read()` và `memory_write()` không trả kết quả ngay. Trong Verilog hiện tại, chúng là handshake:

```text
FSM bật rd_en/wr_en
ssram_controller chạy chu kỳ bus
ssram_controller bật ready
FSM lấy dữ liệu hoặc chuyển state
FSM hạ rd_en/wr_en
controller quay về IDLE
```

## 15. Tóm tắt từng file trong `design/`

| File | Vai trò |
| --- | --- |
| `hex_display.v` | Dịch `display_state` sang LED 7 đoạn |
| `button_debounce.v` | Lọc nhiễu nút bấm và tạo tick 1 clock |
| `internal_ram.v` | RAM nội bộ 2 word, hiện không được top-level dùng trực tiếp |
| `lock_fsm.v` | Bộ não thuật toán khóa, password, magic number |
| `ssram_controller.v` | Controller SSRAM pipeline cho bus `FS_DQ/FS_ADDR/SSRAM_*` |
| `digital_safe_lock.v` | Top-level nối debounce, FSM, SSRAM, HEX, LCD |
| `lcd_controller.v` | Driver LCD 16x2 |
| `digital_safe_lock_3.qsf` | File cấu hình Quartus/pin assignment, không phải logic Verilog |

Các điểm nên sửa/kiểm tra sau:

- Đồng bộ độ rộng địa chỉ: `lock_fsm` đang xuất 19 bit, `ssram_controller` nhận 20 bit.
- Cập nhật comment cũ trong `digital_safe_lock.v` còn nhắc I2C EEPROM.
- Kiểm tra top-level entity trong `digital_safe_lock_3.qsf` có khớp với module top thật không.
