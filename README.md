# FPGA Sensor / Watch / Stopwatch

UART FIFO, stopwatch, digital watch, HC-SR04, DHT11을 하나의 Top으로 통합한 프로젝트입니다.

## Top

- 합성 Top: `src/top.v`의 `top`
- 기준 클럭: 100 MHz
- UART: 9,600 bps, 8-N-1
- `sw[1:0]`: `00` stopwatch / `01` watch / `10` SR04 / `11` DHT11
- `sw[2]`: 각 모드의 보조 화면 선택
- 센서 모드에서 `btn_DOWN`: 수동 측정 시작

## UART commands

명령 마지막에는 LF(`\n`)를 전송합니다. CR+LF도 사용할 수 있습니다.

| 기능 | 명령 |
|---|---|
| Stopwatch 실행/정지 | `/get_run`, `/get_stop` |
| 초기화/방향 전환 | `/get_clear`, `/get_mode` |
| 저장/불러오기 | `/get_save`, `/get_load` |
| Watch 조정 | `/get_up`, `/get_down`, `/get_left`, `/get_right` |
| Stopwatch 값 조회 | `/get_sw_time` |
| Watch 값 조회 | `/get_time` |
| 거리 측정 후 조회 | `/get_dist` |
| 온·습도 측정 후 조회 | `/get_temp_hum` |

`r`, `s`, `c`, `m`, `0`, `1`, `U`, `D`, `L`, `R` 한 글자 명령도 이전 버전 호환을 위해 지원합니다.

명령 처리 결과는 `OK` 또는 `ERR`로 회신합니다. 조회 명령은 각각
`SW HH:MM:SS.CC`, `TIME HH:MM:SS`, `DIST 000cm`,
`TEMP 00.00C HUM 00.00%` 형식으로 회신합니다.

## Source ownership

- SR04 정리 및 검증: 차민성
- Project Control Unit 및 전체 Top 통합: 차민성
- DHT11 / UART 기반 코드: 팀 기존 소스 반영
- Stopwatch / Watch 기반 코드: 팀 기존 소스 반영

## Verification

Icarus Verilog가 설치된 환경에서는 아래 명령으로 단위 및 Top smoke test를 실행합니다.

```bash
make test
```

테스트에는 FIFO 경계 조건, 명령 디코딩, Control Unit 센서 대기 흐름,
SR04 10/100/399 cm 및 timeout, Top reset smoke test, UART 직렬 입력부터
응답 송신까지의 end-to-end 통합 검증이 포함됩니다.

Vivado에서는 `src/*.v`를 Design Sources로, 필요한 `tb/*.v`를 Simulation Sources로 추가합니다. ILA는 합성 계층에서 분리했으므로 별도의 ILA IP 없이 RTL 시뮬레이션할 수 있습니다.
