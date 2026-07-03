# Hướng dẫn chạy testbench và GTKWave

Các lệnh dưới đây chạy trong PowerShell tại thư mục gốc project:

```powershell
cd D:\digital_safe_lock
```

## 1. Kiểm tra Icarus Verilog và GTKWave

```powershell
iverilog -V
vvp -V
gtkwave --version
```

Nếu PowerShell báo không nhận ra lệnh, kiểm tra lại PATH của bộ `oss-cad-suite`:

```powershell
$env:Path -split ';' | Select-String 'oss-cad-suite'
```

Nếu chưa có, thêm tạm cho cửa sổ PowerShell hiện tại:

```powershell
$env:Path = 'C:\oss-cad-suite\bin;' + $env:Path
```

## 2. Tạo thư mục mô phỏng

```powershell
if (!(Test-Path sim)) { New-Item -ItemType Directory sim | Out-Null }
```

## 3. Compile testbench

```powershell
iverilog -g2012 -Wall -o sim\tb_digital_safe_lock.vvp `
  tb\tb_digital_safe_lock.v `
  design\digital_safe_lock.v `
  design\button_debounce.v `
  design\lock_fsm.v `
  design\sram_controller.v `
  design\hex_display.v `
  design\lcd_controller.v
```

Nếu chỉ có warning `timescale inherited` thì vẫn chạy tiếp được.

## 4. Chạy mô phỏng

```powershell
vvp sim\tb_digital_safe_lock.vvp
```

Khi chạy đúng, terminal sẽ in các dòng `Pass: Test ...` và tạo file:

```text
waveform.vcd
```

## 5. Mở waveform bằng GTKWave

```powershell
gtkwave waveform.vcd
```

Trong GTKWave, chọn các tín hiệu quan trọng như:

```text
tb_digital_safe_lock.CLOCK_50
tb_digital_safe_lock.KEY[3:0]
tb_digital_safe_lock.SW[17:0]
tb_digital_safe_lock.dut.fsm_inst.state[3:0]
tb_digital_safe_lock.dut.fsm_inst.o_display_state[2:0]
tb_digital_safe_lock.dut.fsm_inst.o_sram_rd_en
tb_digital_safe_lock.dut.fsm_inst.o_sram_wr_en
tb_digital_safe_lock.dut.fsm_inst.i_sram_ready
tb_digital_safe_lock.SRAM_ADDR[18:0]
tb_digital_safe_lock.SRAM_DQ[15:0]
tb_digital_safe_lock.LEDG[8:0]
tb_digital_safe_lock.LEDR[17:0]
```

## 6. Chạy nhanh lại từ đầu

```powershell
cd D:\digital_safe_lock

if (!(Test-Path sim)) { New-Item -ItemType Directory sim | Out-Null }

iverilog -g2012 -Wall -o sim\tb_digital_safe_lock.vvp `
  tb\tb_digital_safe_lock.v `
  design\digital_safe_lock.v `
  design\button_debounce.v `
  design\lock_fsm.v `
  design\sram_controller.v `
  design\hex_display.v `
  design\lcd_controller.v

vvp sim\tb_digital_safe_lock.vvp

gtkwave waveform.vcd
```

## 7. Lỗi thường gặp

Nếu `iverilog` hoặc `vvp` không nhận lệnh:

```powershell
$env:Path = 'C:\oss-cad-suite\bin;' + $env:Path
```

Nếu GTKWave mở nhưng không thấy tín hiệu, kiểm tra file `waveform.vcd` đã được tạo chưa:

```powershell
Get-Item waveform.vcd
```

Nếu compile báo thiếu module, kiểm tra đã thêm đủ file `.v` trong lệnh `iverilog`, đặc biệt là:

```text
design\sram_controller.v
design\lcd_controller.v
```
