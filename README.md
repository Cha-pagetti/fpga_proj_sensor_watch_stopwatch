# FPGA Sensor / Watch / Stopwatch

Basys3에서 UART/FIFO, stopwatch, digital watch, HC-SR04, DHT11을 통합하는
프로젝트입니다. 이 브랜치의 담당 범위는 **SR04 정리, Project Control Unit,
전체 Top 통합**입니다.

## Ownership rule

다음 팀원 담당 RTL은 upstream `main`과 byte-for-byte 동일하게 유지합니다.

- `ascii_decoder.v`, 추후 합류할 `ascii_encoder.v`
- `fifo.v`, `uart_rx.v`, `uart_tx.v`, `uart_loop_back.v`
- `dht11_controller.v`, `clock.v`, `stopwatch_*.v`, 공용 FND/button RTL

현재 파일의 충돌이나 elaboration 잔재는 원본을 고치지 않고
`scripts/prepare_integration_sources.py`와 `vivado/prepare_integration_sources.tcl`이
`build/generated/`에 만드는 통합용 사본에서만 처리합니다. 자세한 연결 조건은
[`docs/INTEGRATION_CONTRACT.md`](docs/INTEGRATION_CONTRACT.md)에 있습니다.

## Integrated Top

- 합성 Top: `src/top.v`의 `top`
- 기준 클럭: 100 MHz
- UART RX: 9,600 bps, 8-N-1
- `sw[1:0]`: `00` stopwatch / `01` watch / `10` SR04 / `11` DHT11
- `sw[2]`: 각 모드의 보조 화면 선택
- 센서 모드에서 `btn_DOWN`: 수동 측정 시작

현재 upstream decoder 공개 규격은 한 글자 동작 명령
`r/s/c/m/0/1/U/D/L/R`과 조회 명령 `/get sw_time`, `/get time`,
`/get dist`, `/get temp_hum`입니다. 목표 명령 `/get_run`, `/get_stop`,
`/get_dist` 등은 정민님 decoder에서 같은 `o_signals/o_target` 규격으로
매핑되면 Control Unit 변경 없이 동작합니다.

ASCII encoder는 아직 upstream `main`에 없으므로 이 브랜치에서 대체 구현하지
않습니다. 그 전까지 `tx`는 idle HIGH이며, 센서 시작·Control 응답 종류까지를
통합 TB에서 확인합니다.

## Verification

담당 범위의 self-checking TB 5개를 실행합니다.

```bash
make test
```

검증 범위와 기대 결과는 [`docs/VERIFICATION_PLAN.md`](docs/VERIFICATION_PLAN.md),
발표자료용 PASS 파형은 [`docs/waveforms`](docs/waveforms)에 정리되어 있습니다.

## Basys3 / Vivado 2020.2

핀 제약은 [`constraints/Basys3.xdc`](constraints/Basys3.xdc)에 있습니다. Windows에서
다음 파일을 실행하면 통합용 사본 생성, 5개 시뮬레이션, RTL elaboration,
synthesis, implementation, bitstream 생성을 순서대로 수행합니다.

```bat
vivado\run_all_2020_2.bat
```

생성된 bitstream을 연결된 Basys3에 쓰려면 다음을 실행합니다.

```bat
vivado\program_basys3.bat
```

상세 절차는 [`docs/BASYS3_VIVADO_2020_2_GUIDE.md`](docs/BASYS3_VIVADO_2020_2_GUIDE.md),
실기 기록 양식은 [`docs/BOARD_TEST_RECORD.md`](docs/BOARD_TEST_RECORD.md)를 참고합니다.

> HC-SR04 ECHO는 5 V이므로 Basys3 입력에 직접 연결하지 말고 반드시 3.3 V 이하로
> 낮추는 레벨 시프터 또는 저항 분압기를 사용해야 합니다.

## Block diagrams

SR04 Controller, Control Unit, 전체 Top의 3개 페이지 블록도는
[`docs/Minseong_BlockDiagram.drawio`](docs/Minseong_BlockDiagram.drawio)에 있습니다.
