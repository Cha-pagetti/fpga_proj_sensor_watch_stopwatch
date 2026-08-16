# Basys3 / Vivado 2020.2 Build and Board Guide

## 확정 환경

- FPGA board: Digilent Basys3 Rev. B
- FPGA part: `xc7a35tcpg236-1`
- Tool: Xilinx Vivado 2020.2
- RTL top: `src/top.v`의 `top`
- Clock: 100 MHz
- UART: 9,600 bps, 8-N-1, LF 또는 CRLF
- Constraint: `constraints/Basys3.xdc`

## 센서 배선

| 기능 | Basys3 | FPGA pin | 연결 |
|---|---|---|---|
| SR04 trigger | JA1 | J1 | FPGA → HC-SR04 TRIG |
| SR04 echo | JA2 | L2 | HC-SR04 ECHO → level shift → FPGA |
| DHT11 data | JA3 | J2 | DHT11 DATA, 4.7k~10kΩ으로 3.3V pull-up |
| Ground | JA GND | - | Basys3, SR04, DHT11 공통 GND |
| DHT11 power | JA 3.3V | - | DHT11 VCC 3.3V |

HC-SR04의 ECHO는 5V입니다. Basys3 FPGA 입력은 3.3V이므로 직결하면 안 됩니다.
예를 들어 ECHO와 FPGA 사이 1kΩ, FPGA 입력과 GND 사이 2kΩ의 분압기 또는
정식 level shifter를 사용합니다. HC-SR04 전원은 5V를 사용하고 Basys3와 GND를
공통으로 연결합니다.

## 일괄 실행

저장소 루트에서 `vivado/run_all_2020_2.bat`를 실행합니다. 설치 경로가 다르면
파일 첫 부분의 `VIVADO`만 수정합니다.

실행 순서:

1. 담당 범위 5개 behavioral simulation
2. RTL elaboration 및 `top_rtl_elaborated.dcp` 생성
3. Synthesis
4. Implementation: placement(배치) + routing(배선)
5. Timing/DRC/utilization/power report
6. `top_basys3.bit` 생성

주요 결과물:

```text
build/vivado/reports/top_rtl_elaborated.dcp
build/vivado/reports/top_post_synth.dcp
build/vivado/reports/top_post_route.dcp
build/vivado/reports/post_impl_timing_summary.rpt
build/vivado/reports/post_impl_drc.rpt
build/vivado/reports/post_impl_utilization.rpt
build/vivado/output/top_basys3.bit
```

## RTL/Synthesis schematic 캡처

RTL schematic:

1. Vivado 2020.2 실행
2. `File → Checkpoint → Open`에서 `top_rtl_elaborated.dcp`
3. Schematic 창에서 `top` 계층 확장
4. 담당 블록만 선택하여 발표용으로 캡처

합성 후 schematic:

1. `top_post_synth.dcp` 열기
2. `Schematic` 실행
3. RTL schematic과 비교하여 실제 register/mux/counter 구조 설명

## Bitstream 및 보드 programming

Basys3를 USB로 연결하고 전원을 켠 뒤 `vivado/program_basys3.bat`를 실행합니다.
성공 로그에는 `BOARD_PROGRAMMING_PASS`가 출력됩니다.

## 보드 검증 순서

1. BTN-C reset 후 LED/FND가 초기값인지 확인
2. `sw[1:0]=00`: stopwatch, BTN-L run/stop, BTN-R clear
3. `sw[1:0]=01`: watch, 좌/우 자리 선택, 위/아래 값 조정
4. `sw[1:0]=10`: BTN-D로 SR04 측정, FND 거리 확인
5. `sw[1:0]=11`: BTN-D로 DHT11 측정, `sw[2]`로 온도/습도 전환
6. Open Port Master에서 9,600 bps, 8-N-1 설정
7. 현재 decoder 규격으로 `r`, `s`, `/get dist\n`의 제어 경로 확인
8. `post_impl_timing_summary.rpt`에서 WNS가 0 이상인지 확인
9. `post_impl_drc.rpt`에서 critical DRC가 없는지 확인

목표 명령 `/get_run`, `/get_stop`, `/get_dist`, `/get_temp_hum`과 UART TX 문자열
응답은 정민님 decoder/encoder 합류 후 최종 보드 검증합니다. 현재 브랜치는 해당
소스를 임시 구현하지 않으며 `tx`를 idle HIGH로 유지합니다.

## 발표 시 용어 구분

- RTL simulation: 논리 기능과 clock 단위 동작 검증
- Synthesis(합성): RTL을 FPGA의 LUT/FF/BRAM 등 논리 소자로 변환
- Implementation(구현): 논리 소자를 실제 위치에 배치하고 배선
- Bitstream: 구현 결과를 FPGA에 설정하기 위한 programming file
- On-board verification: bitstream을 실제 Basys3에 올려 센서·UART·FND를 검증
