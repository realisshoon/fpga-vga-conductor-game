# FPGA VGA 지휘 게임

OV7670 카메라, RGB 색상 검출, VGA 출력, UART 통신을 활용한 FPGA 기반 지휘 게임 프로젝트입니다.

## 브랜치 전략

- `main`: 정상 동작이 확인된 기준 코드 및 최종 안정 버전
- `integration`: 각 기능 모듈 통합 및 FPGA 검증용 브랜치
- `feat/*`: 각 기능별 개발 브랜치

## 개발 흐름

feat/\* → integration → main

## 기능별 브랜치

- `feat/ov7670-baseline`
- `feat/rgb-filter`
- `feat/xy-detection`
- `feat/stick-speed`
- `feat/volume-control`
- `feat/pattern-detection`
- `feat/uart`
