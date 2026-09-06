# T5-A — 가상 IoT + Asset 운영 모니터링

> 근거: `ADR-T5-00` 5장(T5-A), DEC-T5-17/19, RG-02
> 선행조건: T5-0 완료

## Data Cloud 대신 Platform Event를 쓰는 이유 (DEC-T5-19)

- 진짜 외부 API가 없음(가상 IoT라 "받을" 대상 자체가 없음)
- `T4_운영AI.md` T4-22가 이미 "Data Cloud 연계(L3)는 계약·보안(VPN·MFA·DMZ) 전제 필요, 범위 밖"이라고 명시 — 목업 API로 이 경로를 흉내내도 진짜 장벽(고객사 계약)은 재현 안 됨
- 발행자·소비자를 전부 우리가 통제해서 Identity Resolution 같은 자동 매칭 엔진이 불필요(SOQL 조건 한 줄로 충분)
- **나중에 필요해지면(T5-8) Data Cloud로 저비용 전환 가능**: Platform Event는 발행자가 누구든 상관없는 구조라, 구독 Flow 이후(WOLI 생성 → Trend 계산 → Alert → 포털 → 대시보드 → Agent)는 전부 그대로 재사용됨. 교체 비용은 발행부뿐

## 목표 방향 (확정)

서정비·유신이 분기 1회 수기 측정을 기다리지 않고, 장비 상태 변화를 실시간에 가까운 주기로 확인할 수 있다. 근거: Salesforce Connected Assets/Asset Service Prediction이 "IoT·정비이력을 통합해 자산의 실시간 통합 뷰를 제공하고, 고장 전 유지보수 필요성을 예측"하는 걸 정식 제품으로 제공 — 우리가 이미 만든 `Trend_Flag__c` 로직(하락률·연속하락 규칙)이 개념적으로 이 방향과 같다.

## 구현 경로 (미확정 — org 확인 후 결정)

| | 경로 A: Connected Assets / Data Cloud | 경로 B: Platform Event(현재 설계) |
|---|---|---|
| 상태 | ❌ PermissionSetLicense에서 확인 안 됨(ADR 6.5장) — 없을 가능성 높음 | ✅ 항상 가능(표준 기능, 라이선스 불필요) |
| 전제조건 | 라이선스 프로비저닝 + 외부 API 필요(지금은 진짜 외부 API 자체가 없음) | 없음 |
| 채택 조건 | Connected Assets 라이선스가 실제로 확인되고, 실제 IoT 연동 필요성이 생길 때(T5-8) | 지금 바로 |

## 지금 당장 착수 가능한 것 (경로 B 기준, 블로킹 없음)

이건 실제 IoT 도입이 아니라 **Trend 계산·Alert 로직을 검증하기 위한 데모 입력 채널**이다. 경로 B는 라이선스 확인과 무관하게 항상 만들 수 있어서 먼저 착수한다 — 나중에 경로 A가 확인돼도 경로 B가 버려지지 않고, 발행자만 교체하면 됨(DEC-T5-19, 아래).

## 범위

- Platform Event(가상 센서 이벤트) 발행 → `WorkOrderLineItem` 레코드 생성 → 기존 `WOLI_Trend_Flag_Evaluate` Flow가 그대로 판정
- `Source__c = SIMULATOR` 태그로 기존 분기점검 WOLI와 구분(DEC-T5-17)
- CDU-A-07 단일 Asset, 소량 이벤트로 한정(데모 규모)

## 비범위

- 별도 IoT 로그 객체·롤업 아키텍처(T5-X/T5-8 후속) — 지금 만들면 과설계
- 실제 센서·BMS 연동
- Trend 판정 로직 수정(기존 Flow 그대로 재사용)
- 여러 Asset 동시 시뮬레이션(CDU-A-07 하나로 충분)

## 트리거 조건과 데이터 계약

**입력**: Platform Event(`IoT_Reading__e` 가칭) — Asset Id, 측정값, 타임스탬프
**출력**: `WorkOrderLineItem` 신규 레코드
- `Measurement_Item_Code__c`, `Measured_Value__c`, `Drift_From_Baseline__c` 등 기존 필드 채움
- `Source__c = "SIMULATOR"` (신규 필드, T5 전용)
- 저장 즉시 기존 `WOLI_Trend_Flag_Evaluate` Flow가 `Trend_Flag__c` 판정(로직 무수정)

## ⚠️ "실시간" 표기 정정(2026-08-27)

T5-A가 만드는 건 **백엔드 데이터 갱신 속도**(이벤트 발행 즉시 WOLI·`Trend_Flag__c` 갱신)이지, **화면에 자동으로 밀어주는 실시간 스트리밍이 아니다.** 포털·Hall 대시보드는 페이지를 열거나 새로고침해야 최신값을 본다(Pull). 화면까지 자동 갱신하려면 클라이언트가 Platform Event를 직접 구독(`empApi`)해야 하는데 현재 범위 밖 — 상세는 T5-B spec 참고.

## 기존 T0~T4와의 관계

- `WOLI_Trend_Flag_Evaluate` Flow: **읽기만, 수정 안 함**. T5-A는 이 Flow의 입력(WOLI 레코드)만 자동 생성
- 기존 분기점검 WOLI와 물리적으로 같은 객체를 쓰지만 `Source__c`로 명확히 구분되므로 정기점검 이력 집계에 섞이지 않도록 리포트/뷰에서 필터 기준 명시 필요(QA 시나리오에 포함)

## Feature Flag

`T5_Feature_Flags__mdt.Virtual_IoT_Enabled__c` — false면 Platform Event 구독 Flow가 아무 것도 안 함(RG-01)

## 데모 데이터

CDU-A-07, 3~5개 이벤트로 정상→주의 전환을 재현할 수 있는 하락 패턴(기존 `Trend_Threshold__mdt` 임계치 기준)

## 완료 조건 · QA

- `[SIMULATOR]` 태그가 붙은 WOLI가 실측 쿼리로 확인됨
- Trend_Flag__c가 정상→주의로 실제 전환됨(재쿼리로 확인)
- Feature Flag Off 시 이벤트 발행해도 WOLI가 안 생김(RG-02 회귀 QA)
- 기존 분기점검 WOLI 집계(Punch/Acceptance 등)에 영향 없음
