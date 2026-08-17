# Basys3 Board Verification Record

이 문서는 실제 Basys3 보드에서 bitstream을 다운로드한 뒤 결과를 기록하는 양식입니다.
보드와 Vivado Hardware Manager가 필요한 항목은 실행 전 `PENDING`, 실행 후 `PASS` 또는
`FAIL`로 바꾸고 증빙 파일명을 함께 적습니다.

## Environment

| 항목 | 기록 |
|---|---|
| Board | Digilent Basys3 (XC7A35T-1CPG236C) |
| Vivado | 2020.2 |
| RTL commit |  |
| Test date / operator |  |
| USB/UART terminal | Open Port Master, 9600 bps, 8-N-1 |

## Build evidence

| 단계 | 상태 | 확인할 결과 / 증빙 |
|---|---|---|
| RTL elaboration | PENDING | `build/vivado/reports/top_rtl_elaborated.dcp`, RTL Schematic 캡처 |
| RTL simulations | PENDING | `build/vivado/simulations.log`, 파형 캡처 |
| Synthesis | PENDING | `build/vivado/reports/post_synth_utilization.rpt`, schematic 캡처 |
| Implementation | PENDING | `build/vivado/reports/post_route_timing_summary.rpt`, WNS >= 0 ns |
| DRC | PENDING | `build/vivado/reports/post_route_drc.rpt`, 치명적 violation 0건 |
| Bitstream | PENDING | `build/vivado/output/top_basys3.bit` |
| Programming | PENDING | Hardware Manager PROGRAM 성공 화면 |

## Functional board test

조회 UART 명령은 LF(`\n`)로 종료합니다. 한 글자 동작 명령은 현재 decoder에서
문자 수신 직후 처리합니다.

| ID | 조작 / 명령 | 기대 결과 | 상태 | 증빙 |
|---|---|---|---|---|
| B01 | 전원 인가 후 `reset` | FND/LED가 초기 상태, 오동작 없음 | PENDING |  |
| B02 | `sw[1:0]=00`, `r` | Stopwatch 증가, `led[0]=1` | PENDING |  |
| B03 | `s` | Stopwatch 정지, `led[0]=0` | PENDING |  |
| B04 | `0`, `c`, `1` | 저장, 초기화, 저장값 복원 | PENDING |  |
| B05 | `sw[1:0]=01`, 방향 버튼 | Watch 시간/선택 위치 변경 | PENDING |  |
| B06 | `sw[1:0]=10`, `/get dist\n` | Trigger 약 10 us, FND 거리 표시 | PENDING |  |
| B07 | SR04 ECHO 없음 | timeout 뒤 `led[1]` ready 복귀 | PENDING |  |
| B08 | `sw[1:0]=11`, `/get temp_hum\n` | DHT11 측정 및 FND 표시 | PENDING |  |
| B09 | DHT11 분리/체크섬 오류 | timeout/invalid 뒤 재측정 가능 | PENDING |  |
| B10 | 명령 중 연속 UART 입력 | RX FIFO overflow(`led[3]`) 없음 | PENDING |  |
| B11 | `sw[2]` 전환 | 해당 모드의 보조 표시 정상 | PENDING |  |
| B12 | 정민 decoder/encoder 합류 후 목표 명령 | `/get_run` 등과 TX 응답 | BLOCKED | 정민 branch/ref 필요 |

## Presentation checklist

- [ ] RTL Schematic에서 UART RX → decoder → Control Unit 경로 캡처
- [ ] SR04 정상/timeout 파형 캡처
- [ ] `/get dist` → trigger → distance 파형과 FND 사진을 같은 슬라이드에 배치
- [ ] 정민 encoder 합류 후 Control Unit → encoder → UART TX 경로 추가 캡처
- [ ] Synthesis utilization 표와 implementation timing summary 캡처
- [ ] Hardware Manager programming 성공 화면 캡처
- [ ] 보드 FND, 센서 배선, UART 터미널이 보이는 실기 사진 또는 영상 첨부

## Notes / failures

| 시각 | 현상 | 원인 | 수정 commit / 재시험 결과 |
|---|---|---|---|
|  |  |  |  |
