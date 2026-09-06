# T5-E — Field Service Mobile 고도화

> 근거: `ADR-T5-00` 5장(T5-E), DEC-T5-07, RG-02
> 선행조건: T5-0, T5-D(WO 알림 채널로 Slack 재사용)

## 목표 방향 (확정)

강시공이 운전 중 브리핑을 음성으로 듣고, 현장에서 손쉽게(가급적 손 안 대고) 정비 결과를 입력한다. Work Order 발생을 놓치지 않고, 복구 결과가 Case/Asset/RCA로 정확히 돌아간다. 근거: Salesforce Field Service의 **Pre-Work Brief playback**(현장 도착 전 Agentforce가 만든 브리핑을 음성으로 재생)과 Winter'26 **hands-free voice commands**(음성으로 업데이트 기록·WO 닫기)가 정확히 이 경험을 공식 기능으로 제공.

## 구현 경로 (미확정 — org 확인 후 결정)

| | 경로 A: Agentforce for Field Service(음성 브리핑·hands-free) | 경로 B: 기존 Punch/WOLI 화면 입력(현재 설계) |
|---|---|---|
| 상태 | ⚠️ 관련 라이선스("Einstein for Field Service"·"Einstein for Field Service Mobile", 각 10석) **존재 확인됨**(ADR 6.5장) — 단 이게 리서치가 말한 "Agentforce for Field Service" 브랜드 기능과 정확히 같은지, 실제 Setup에서 활성화됐는지는 미확인 | ✅ 항상 가능 |
| 전제조건 | T5-E 착수 시 Setup → Field Service 설정에서 Pre-Work Brief playback·hands-free 기능이 실제로 켜져 있는지 확인 | 없음 |
| 우리가 만든 브리핑(`Case_Dispatch_Briefing_Generate`)과의 관계 | 경로 A는 Salesforce가 자체적으로 브리핑을 생성할 가능성 있음 — 있으면 T4-19 작업과 **중복**될 수 있어 grounding 소스로 연결 가능한지 확인 필요 | 기존 브리핑을 그대로 읽어주는 가벼운 컴포넌트로 재사용(중복 없음) |
| 채택 조건 | 라이선스 활성화 + 기존 브리핑과 중복 없이 연결 가능하면 채택 | 경로 A가 없거나 중복 문제 해결 안 되면 그대로 진행 |

## 지금 당장 착수 가능한 것 (경로 B 기준, 블로킹 없음)

경로 B는 라이선스 확인과 무관하게 항상 만들 수 있어서 먼저 착수한다 — 나중에 경로 A가 확인돼도 손해 없음(안 쓰면 그만), 확인 안 되면 경로 B가 그대로 최종이 됨.

## 범위

- **6A**: WO 알림 채널 — Slack으로 강시공에게 알림(DEC-T5-07, T5-D 인프라 재사용)
- **6B**: Field Service Mobile에서 WO 수신·열람 확인(신규 개발 아님 — 기존 FSM 라이선스·앱 그대로 사용, 확인만)
- **6C**: 브리핑 청취 + 측정·조치·재시험·증빙 입력 — **경로 A(Einstein for Field Service, 라이선스 확인됨) 먼저 시도**: Setup → Field Service 설정에서 Pre-Work Brief playback·hands-free voice commands 활성화 여부 확인 후, 되면 이걸로 브리핑 음성 재생·손 안 대고 입력을 시연. **안 되거나 활성화가 안 돼 있으면 경로 B(기존 Punch/WOLI 화면 입력)로 그대로 진행** — 이 경우도 신규 화면 개발은 아님(기존 흐름 재사용)
- **6D**: 입력 결과 → Case/Asset/RCA 연결 E2E QA (경로 A/B 어느 쪽으로 입력했든 동일)

## 비범위

- 신규 FSM 모바일 앱/화면 개발(기존 FSM 그대로 사용, 경로 A도 기존 앱 내장 기능일 뿐 별도 앱 아님)
- 커스텀 TTS·음성인식 파이프라인 직접 구현(경로 A가 없으면 음성 기능 자체를 포기 — 자체 구축은 안 함, 이 부분만 T5-X 후속으로 남김)
- FSM 자체 라이선스/설정 변경(이미 확인됨 — 접속 가능 상태)

## 트리거 조건과 데이터 계약

**입력**: Work Order 생성(T5-B/직접접수 어느 경로든)
**출력**: 없음(기존 WOLI/Punch 필드에 현장 담당자가 입력하는 기존 방식 그대로)

## 기존 T0~T4와의 관계

- 기존 WorkOrderLineItem·Punch·재시험 흐름을 **그대로 재사용** — T5-E는 "알림이 실제로 강시공에게 도달하는가"만 새로 검증하는 것이지 현장 입력 로직을 새로 만드는 게 아님

## Feature Flag

WO 알림(6A)만 Feature Flag 대상(`Slack_Alert_Enabled__c` 공유). 6B~6D는 기존 표준 기능이라 별도 플래그 불필요.

## 데모 데이터

CDU-A-07 관련 Work Order 1건 → 강시공 역할 사용자에게 Slack 알림 → FSM에서 열람 → 측정값(F-07 등) 입력 → Case/Asset에 반영 확인

## 완료 조건 · QA

- WO 생성 후 Slack 알림이 강시공에게 실제 도달(스크린샷/로그로 확인)
- FSM에서 WO 열람 가능 확인
- 기존 Punch/재시험 흐름으로 입력한 값이 Case/Asset 이력에 정상 반영(RG-02 — 기존 계산 안 깨짐)
- **경로 A 확인 시에만 추가로**: 브리핑 음성 재생이 실제로 동작(현장에서 직접 청취 확인), hands-free 명령으로 WO 업데이트·종료가 실제로 됨(육안 확인). **경로 A가 없으면 이 두 항목은 완료조건에서 제외**하고 경로 B(기존 화면 입력)만으로 완료 처리
