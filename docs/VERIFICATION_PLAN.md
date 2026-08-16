# Verification Plan — Minseong Scope

이 문서는 민성 담당 범위인 HC-SR04, Project Control Unit, Integrated Top의
검증 기준입니다. 모든 TB는 기대값을 직접 비교하고 실패 시 `$fatal`로 종료하는
self-checking 방식입니다.

## Verification principles

1. DUT 입력은 주로 `negedge clk`에서 바꿔 race를 방지합니다.
2. 정상값뿐 아니라 경계값, busy, timeout, backpressure를 함께 확인합니다.
3. 팀원 RTL은 수정하지 않고 공개 인터페이스를 통해서만 Top에 연결합니다.
4. Top TX 결과 검증은 정민님 encoder가 합류한 뒤 추가합니다.

## Scenario matrix

| DUT / TB | ID | 입력·조건 | 기대 결과 |
|---|---|---|---|
| Project Control / `tb_control_unit` | CTRL-01 | run/stop/clear/mode/save/load | 상태 또는 1-clock control pulse |
| | CTRL-02 | response consumer not ready | `response_valid/kind` 안정 유지 |
| | CTRL-03 | distance query, SR04 ready→done | start pulse 후 `RESP_DIST` |
| | CTRL-04 | SR04 not-ready/error | `RESP_ERROR` |
| | CTRL-05 | DHT11 valid/invalid completion | `RESP_DHT11`/`RESP_ERROR` |
| | CTRL-06 | switch별 board button | 선택된 datapath/sensor만 제어 |
| HC-SR04 / `tb_sr04_controller` | SR04-01 | 57/58/600/5820/23150 us echo | 0/1/10/100/399 cm |
| | SR04-02 | 측정 중 start 재입력 | 현재 측정 유지, trigger 추가 없음 |
| | SR04-03 | echo 없음 | start timeout, error pulse |
| | SR04-04 | 23.2 ms 초과 echo HIGH | overlong error, distance=0 |
| | SR04-05 | re-arm 중 start | 입력 무시 후 ready 복귀 |
| Top smoke / `tb_top_smoke` | TOP-01 | 전체 reset/elaboration | X 없는 기본 출력, 계층 생성 성공 |
| Top UART RX / `tb_top_uart` | TOP-UART-01 | serial `r` | 공개 decoder→Control, stopwatch run=1 |
| | TOP-UART-02 | serial `s` | stopwatch run=0 |
| | TOP-UART-03 | encoder 미합류 상태 | TX idle HIGH 유지 |
| Top SR04 / `tb_top_sr04_uart` | TOP-SR04-01 | serial `/get dist\n`, 580 us echo | target decode, trigger, 10 cm, `RESP_DIST` |

## Current result

2026-08-17 로컬 Icarus 호환 시뮬레이션 결과:

| TB | Result |
|---|---|
| `tb_control_unit` | PASS |
| `tb_sr04_controller` | PASS |
| `tb_top_smoke` | PASS |
| `tb_top_uart` | PASS |
| `tb_top_sr04_uart` | PASS |

Vivado 2020.2 및 실물 Basys3가 필요한 RTL Schematic, XSim, synthesis,
implementation, bitstream, programming 결과는
[`BOARD_TEST_RECORD.md`](BOARD_TEST_RECORD.md)에 별도로 기록합니다.

## Presentation waveforms

`docs/waveforms/`의 다음 PNG를 사용합니다.

1. `tb_sr04_controller.png`: 10 us trigger, echo width, distance, done/re-arm
2. `tb_control_unit.png`: command, sensor wait state, response handshake
3. `tb_top_uart.png`: UART RX `r/s`부터 stopwatch run/stop까지
4. `tb_top_sr04_uart.png`: `/get dist` decode부터 10 cm `RESP_DIST`까지

TX 문자열 파형은 정민님 encoder 합류 후 정민님 TB 또는 합의된 통합 TB에서
추가하는 것이 담당 구분상 안전합니다.
