# OT전자 냉각장비 CRM — 구축·인수(T3) & AI 고도화(T5) 트랙

> AI 데이터센터용 냉각장비를 제조·설치·운영하는 가상 기업 **OT전자**의 Salesforce CRM 구축 프로젝트.
> 5인 팀 프로젝트에서 **구축·인수(T3) 트랙을 단독 담당**하고, 발표 범위 밖의 **AI 고도화(T5) 이니셔티브를 별도로 주도**했습니다.
> 이 저장소는 팀 저장소(`sf-team-1to10/ot-cooling-crm`)에서 **제가 작성·설계한 컴포넌트만** 추출한 것입니다. (→ [CONTRIBUTIONS.md](./CONTRIBUTIONS.md))

- **기간**: 2026.08 ~ 2026.09 (약 6주)
- **팀**: 5인 / 트랙 분리 (T0 플랫폼 · T1 영업 · T2 변경관리 · **T3 구축·인수 (담당)** · T4 운영·AI) + **T5 고도화 (개인 주도 → 3~4인 분업으로 확장)**
- **스택**: Record-Triggered Flow · Apex (Invocable Action / Controller) · LWC · Platform Event · Agentforce · Experience Cloud · Service Cloud for Slack · Field Service
- **협업 도구**: Agentforce Vibes · Claude Code — AI 페어링으로 트랙 단독 구축 (설계·의사결정·검증은 직접)

---

## 1. 문제

OT전자는 "장비를 팔았는데 그 다음이 안 보이는" 회사였습니다.

- 계약이 확정돼도 **설계 기준선(Technical Baseline)**이 시스템에 없어, 현장에서 "무슨 스펙으로 시운전해야 하는지"를 매번 사람이 문서로 찾음
- 설치 → 시운전 → 인수 과정의 **잔여 작업(Punch)·재시험**이 엑셀로 관리돼, 인수 판정이 담당자 감(感)에 의존
- 인수 후 운영 단계에서 장비 이상이 **사고가 터진 뒤에야** 접수됨 (사전 경보 없음)
- 동일 장비군에 같은 결함이 있어도 **수평 전파를 막을 근거**가 흩어져 있음

## 2. 내 역할

### T3 — 구축·인수 트랙 (단독)

계약 확정부터 보증 개시까지의 **데이터 체인과 자동화**를 설계·구축.

| 구간 | 만든 것 |
|---|---|
| 기준선 | `Technical_Baseline__c` 필드 설계 + `Technical_Baseline_Rev_A` Flow — **Contract가 `Activated`(법적 구속력 발생)되는 시점의 스냅샷**으로 Rev.A 생성 |
| ERP 연계 | `Baseline_Approve_ERP_Order` — 승인 시 발주 상태 전이 (Fast Field Update) |
| 작업 자동화 | `WO_Install_LineItem_AutoCreate`(설치: 자산 1대당 1줄) / `WO_Commission_LineItem_AutoCreate`(시운전: 측정항목 1건당 1줄) — 같은 WorkOrder라도 **업무 성격에 따라 라인아이템 생성 축이 다름** |
| 시험·판정 | `WOLI_Baseline_Spec_AutoLoad`(적용 리비전 → 허용범위 자동 적재) · `WOLI_Judgement_AutoSet`(측정값 → 합격/불합격) · `WOLI_Retest_Create`(불합격 → 재시험 체인) |
| Punch 관리 | `WOLI_*_Open_Punch_Recalc` 상시 집계 + `Punch_Overdue_Task_Daily` 기한 초과 자동 노출 + Validation Rule (검증완료 시 검증자 필수) |
| 핸드오프 게이트 | `TB_D1_D2_Handoff` · `WorkOrder_Evidence_Check` · `WorkOrder_D6_Task_On_Completion` — 완료조건 미충족 시 다음 단계 진입 차단 |
| 보증 자동화 | `Asset_Warranty_On_Acceptance` — **조건부인수 시점에 보증 기산일을 1회 기록하고, 최종인수로 레코드가 재저장돼도 절대 재기록하지 않음** (아래 3번) |

### T5 — AI 고도화 (개인 주도)

발표 범위 밖에서 "가상 IoT → 조기경보 → 협업 → AI 상담 → 현장"의 **통합 서비스 루프**를 설계. ADR로 5개 축을 정의하고, 이후 3~4인 팀 분업으로 확장(트랙별 백로그·주말 분업표 작성).

| 축 | 만든 것 |
|---|---|
| 가상 IoT · 운영 모니터링 | `IoT_Reading__e` Platform Event → `T5_IoT_Reading_Subscribe` Flow → WOLI 기록 → `Trend_Flag__c` 추세 판정 → `T5_Sync_Asset_Trend_Summary` 자산 요약 동기화. `OtTrendAlertCardController` + `otTrendAlertCard`(게이지 위젯) |
| 고객 포털 (Experience Cloud) | `T5HmiAssetHomeController` / `T5HmiAssetDetailController` + `otEquip*` / `otMyAssets` / `otAssetPortal` LWC — 고객이 자기 장비 상태·이력·게이지를 보고 이상 시 상담 진입 |
| 통합 Service Agent (Agentforce) | 고객·내부 상담을 **하나의 에이전트 + Topic 분리**로 처리. `T5Agent*Action` 6종 (자산 컨텍스트 / Case 인테이크 / 계약 컨텍스트 / Knowledge 검색 / 답변 추천 / Case 종결 요약) |
| 상담사 콘솔 (MIAW) | `OtMs*Controller` + `otMs*` LWC 15종 — MessagingSession 좌측 고정 + Case 서브탭 자동 오픈, 상담사 이관 UX |
| Slack 협업 · FSM | 담당자 확정 → Slack Swarm 채널 자동 생성·초대·요약, FSM 모바일 배정 연동 + SA/WO 상태 동기화 |
| 운영 홈 · 영업 홈 | `OTOpsHomeController` / `OtSalesDashboardController` + `otCooling*` / `otSales*` / `coolinxOverview` LWC |

## 3. 핵심 의사결정

가장 자신 있는 부분입니다. "무엇을 만들었나"보다 **"왜 이 선택을 했나"**.

**① 보증 기산일 불변성**
인수는 조건부인수(사소한 잔여 작업이 남아도 고객이 일단 받아들이는 시점) → 최종인수(잔여 작업까지 완료) 2단계입니다. "보증 시작일 = 최종인수일"로 잡으면, 잔여 작업이 늦어질수록 보증 시작일도 밀리면서 **회사가 자기 지연 때문에 보증 부담을 스스로 키우게 됩니다.** 그래서 보증 기산일은 조건부인수 시점에 딱 한 번 기록되고, 이후 레코드가 재저장돼도 재기록되지 않도록 Flow를 설계했습니다 — 이 불변성 자체가 완료조건의 핵심.

**② Technical Baseline = 계약 확정 시점의 스냅샷**
아직 협상 중일 수 있는 `Quote`·`Customer_Commitment__c`를 기준으로 기준선을 만들면 안 됩니다. **`Contract.Status`가 `Activated`로 바뀌는 순간 = 법적 구속력이 생기는 확정 시점**이고, 기준선은 정확히 이 시점의 스냅샷이어야 합니다. Flow 트리거를 여기에 걸었습니다.

**③ Clicks-before-Code를 "미리 계획"이 아니라 "트리거 조건"으로 관리**
백로그의 모든 요구사항이 Flow·Validation Rule로 커버되고, 진짜 코드가 필요한 이유(복잡한 대량 처리, 동기 외부 콜아웃, 표준 화면 불가 UI)가 하나도 없다면 커스터마이징 단계를 미리 넣지 않았습니다. 대신 "이 조건이 생기면 그때 논의한다"는 트리거(예: 실제 ERP/BMS 외부 연동 승인)만 정의. Flow 일부를 나중에 Apex로 바꾸는 건 부분 교체로 가능해 되돌릴 게 없습니다.

**④ "예방"에는 두 축이 있다**
팀은 "예방 기능이 없다"고 봤지만, 정확히는 **수평적 예방**(사고 후 동종 장비 확산 방지 — 이미 있음)과 **수직적 조기경보**(사고 전, 추세만으로 트리거 — 없음)로 나뉩니다. T5의 IoT → Trend 루프가 후자를 채우는 것으로 범위를 정확히 정의했습니다.

**⑤ org 실측은 Tooling API 우선**
진단 계정에 FLS가 없으면 `sf sobject describe`·일반 SOQL이 "필드 없음"이라는 **거짓 음성**을 냅니다(실제로는 배포·Active인데). Tooling API(`CustomField`, `FieldPermissions`, `FlowDefinitionView`)는 FLS와 무관하게 메타데이터 존재를 보여줘 이걸 기준으로 삼았습니다.

**⑥ git worktree로 5개 병렬 트랙 관리**
하나의 저장소에서 트랙별 브랜치를 별도 폴더(worktree)로 체크아웃해, 트랙 간 파일 겹침·merge 대기를 관리했습니다.

## 4. 아키텍처

```
계약 확정(Contract Activated)
   └─ Technical Baseline (Rev.A 스냅샷) ──> ERP 발주
        └─ WorkOrder (설치 / 시운전)
             ├─ WOLI 자동 생성 (업무 성격별 축)
             ├─ 기준값 자동 적재 → 측정 → 합격/불합격 판정 → 재시험 체인
             └─ Punch 집계 → 핸드오프 게이트(D1→D2→D6) → Service Ready → 보증 개시

[T5] IoT_Reading__e (가상 센서)
   └─ 구독 Flow → WOLI 기록 → Trend_Flag 조기경보
        ├─ 고객 포털: 게이지·이력·상담 진입
        ├─ Slack Swarm: 담당자 채널 자동 개설
        ├─ 통합 Agent: 자산 컨텍스트 + Knowledge 검색 + Case 인테이크
        └─ FSM: 모바일 배정 → SA/WO 상태 동기화
```

상세 설계는 [`docs/`](./docs) 참고:
- [T3 시스템이해노트](./docs/T3_시스템이해노트.md) — 플랫폼 동작 원리·설계 의도
- [T5 시스템 아키텍처 총정리](./docs/T5_시스템아키텍처.md)
- [ADR-T5-00 통합 루프 MVP](./docs/ADR-T5-00-integrated-loop.md)
- [통합 Service Agent 구조](./docs/T5_통합_Service_Agent_구조.md) · [실시간 알림 구조](./docs/T5_실시간알림_구조.md)
- [T5 A~E 스펙](./docs/specs)

## 5. 화면

`screenshots/` 참고. (데모 영상 링크 예정)

## 6. 배운 점

- **선언형(Flow) vs 코드(Apex)의 경계**를 요구사항이 아니라 "되돌릴 수 있는가 / 트리거 조건이 왔는가"로 판단하게 됨
- 표준 객체에 여러 트랙이 필드를 붙일 때 **FlexiPage가 Page Layout을 덮어써서** 필드가 안 보이는 함정 — org 실측 습관의 중요성
- AI 협업 도구로 트랙을 단독 구축할 때, **결과물만으로는 내 판단을 증명 못 한다** → 모든 결정을 "무엇을/왜/어떻게"로 기록하는 습관

## 7. 이 저장소에 대해

- **단독 배포 대상이 아닙니다.** 팀 저장소에서 제 작업만 추출했기 때문에, 다른 트랙이 만든 오브젝트·필드를 참조하는 부분이 있습니다. 코드·설계를 보여주기 위한 것입니다.
- 표준 객체(`Case`, `WorkOrder` 등) 폴더에는 **제가 추가한 커스텀 필드만** 포함했습니다.
- 원 팀 저장소: `sf-team-1to10/ot-cooling-crm` (비공개)
