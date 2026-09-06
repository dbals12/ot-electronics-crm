# T5-D — Slack 협업

> 근거: `ADR-T5-00` 5장(T5-D), DEC-T5-03/04/15, RG-03
> 선행조건: T5-0, T5-A(Trend Alert 발신 대상 필요)

## 목표 방향 (확정)

이상 신호가 발견되면 서비스팀(서정비)→설계팀(오도면)→현장팀(강시공)으로 신속하게 인계되고, 각자 전문성으로 협업해서 판단한다. 근거: Salesforce Service Cloud for Slack의 Case Swarming 모델이 "케이스 오너가 필요할 때 전문가를 Slack 채널로 끌어들이는" 정확히 같은 패턴을 정식 기능으로 제공(Expert Finder로 스킬 기반 자동 라우팅까지 포함), 케이스 해결시간 26% 단축 사례도 있음.

## 구현 경로 — Case Swarming을 목표로, 멘션은 최후 폴백

| | 경로 A+(있으면 최상): Agentforce가 Slack에 직접 상주 | 경로 A(우선 목표): Service Cloud for Slack(Case Swarming, Expert Finder) | 경로 B(최후 폴백): 단순 멘션 기반 인계 |
|---|---|---|---|
| 상태 | ⚠️ 확인 불가(라이선스 체계 밖) — Slack 워크스페이스 직접 확인 필요 | ⚠️ **PermissionSetLicense로 확인 불가**(Slack 앱은 워크스페이스 설치 여부라 이 방법으론 안 보임, ADR 6.5장) | ✅ 항상 가능 |
| 전제조건 | Service Cloud for Slack + Agentforce in Slack 둘 다 설치·연동 필요 | Slack 워크스페이스에 Service Cloud for Slack 앱 설치 확인 필요(사람이 직접 Slack 관리자 화면에서 봐야 함) | 없음 |
| 채택 조건 | 둘 다 확인되면 Expert Finder 자동 라우팅 + Agent가 Swarm 채널에서 직접 맥락 제공까지 시도 | **Swarming이 확인되면 이걸 기본 채택 대상으로 한다** — 3B(멘션)는 대안이 아니라 진짜 없을 때만 쓰는 최후 수단 | A/A+가 전혀 안 될 때만 이걸로 확정 |

## 지금 당장 착수 가능한 것 (경로 B 기준, 블로킹 없음)

Trend 전환·Case 발생을 놓치지 않게 알리고(3A), 서정비→오도면→강시공으로 이어지는 인계를 가시화한다(3B, PoC 수준) — **Slack 워크스페이스 확인이 될 때까지 임시로 경로 B부터 착수**하되, Swarming이 확인되는 즉시 3B를 걷어내고 경로 A로 전환하는 걸 기본 방침으로 한다.

## 범위

### 3A — 필수: Alert (범위 축소, 2026-08-26)
- **정상→주의(Warning) 전환: Slack 없음.** 포털 카드(T5-B `otTrendAlertCard`)와 Hall 대시보드(T5-C)에만 표시 — 사람이 화면을 볼 때만 보이는 Pull 방식(DEC-T5-01)
- **주의→이상(Critical) 전환: Slack Alert 발신**(Asset/Case/브리핑 링크 포함), 수신자는 서정비(DEC-T5-20)
- Case 생성 시 요약 Alert(기존 유지)
- 판정 기준은 기존 `WOLI_Trend_Flag_Evaluate` 로직 그대로(하락률≥5% 또는 연속하락≥3회, `Trend_Threshold__mdt` 임계치) — T5는 판정 로직을 안 건드리고 알림 발신만 추가
- **나중에 Warning도 Slack으로 확장하고 싶으면**: `Slack_Alert_Enabled__c`류 Feature Flag가 이미 있어서, 이 Flow의 분기 조건 하나만 추가하면 됨(빠른 확장 가능)

### 3B — 선택 PoC: 역할 인계
- 서정비→오도면→강시공 멘션 기반 인계(단순 멘션, Swarming 앱 아님)
- Agent 인계 요청(T5-B DEC-T5-15)도 같은 채널·메커니즘 재사용

## 비범위 (T5-X/후속)

- Slack Swarming 정식 운영 앱(3C)
- Interactive Button/Workflow 자동화
- 고객향 Slack 노출(내부 전용 채널)

## 트리거 조건과 데이터 계약

**입력**: `Trend_Flag__c` 변경(전환 시점만, 동일 값 반복 저장은 제외 — 중복 방지), Case 생성 이벤트
**출력**: Slack 메시지(Salesforce 레코드에 쓰기 없음 — 순수 알림)

## 기존 T0~T4와의 관계

기존 Case/WorkOrder 흐름에 쓰기 작업 없음 — Slack 발신 실패해도 Case/WO 생성·상태 전환은 영향받지 않음(RG-03).

## Feature Flag

`Slack_Alert_Enabled__c` — false면 Alert Flow가 조용히 스킵

## 데모 데이터

CDU-A-07 **주의→이상(Critical) 전환 1건**(Slack 발신 확인용) + **정상→주의(Warning) 전환 1건**(Slack 안 감, 포털/대시보드에만 뜨는 것 확인용) + Case 생성 1건으로 Alert 텍스트·링크 정확성 시연

## 완료 조건 · QA

- **Warning 전환 시 Slack에 아무 메시지도 안 감**(오탐지 방지 확인 — 이번 범위 축소의 핵심 회귀 포인트)
- Critical 전환 시에만 Slack Alert 발신, 동일 Trend 값 재저장 시 중복 Alert 없음
- Slack 웹훅 실패를 인위로 재현해도 Case 생성은 정상 진행(RG-03)
- Feature Flag Off 시 Critical Alert도 전송 안 됨
