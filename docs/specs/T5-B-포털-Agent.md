# T5-B — 고객 포털 확장 + 통합 Service Agent

> 근거: `ADR-T5-00` 3-2장(개발 격리/통합 책임 분리), 4장(폐루프 다이어그램), 5장(T5-B), DEC-T5-05/09/13/14/16/18, RG-05/09~12
> 선행조건: T5-0 완료(Case.Dispatch_Briefing__c 존재해야 브리핑 Topic 연동 가능)
> **사용자 확정(2026-08-26)**: Agent는 유신용·서정비용을 **별개 에이전트로 안 나눈다** — 하나의 Agentforce 에이전트를 두 역할이 같이 쓰고, Topic으로만 역할을 나눈다.

## 목표 방향 (확정)

유신(고객)이 자기 Asset 상태를 실제 데이터로 확인하고, 증상이 명확하면 직접 접수, 불명확하면 Agent와 자연어로 상담한 뒤 필요할 때만 서정비에게 인계된다(Case를 강제로 만들지 않음). 서정비는 같은 Agent에게 상담 요약이 달린 Case 검토·출동 브리핑·유사사례 조회를 이어서 받아, 상담부터 출동 판단까지 한 대화 맥락으로 연결된다. 근거: Salesforce Agentforce Self-Service Portal("Help Agent")이 "지식베이스+고객 데이터에 근거해 Case를 강제로 만들지 않고 인라인으로 답하다가, 필요할 때만 인계"하는 정확히 같은 패턴을 정식 기능으로 제공 — DEC-T5-16(인계 기준)이 이미 이 문제의식과 같은 방향.

## 구현 경로 — "무엇을 만들까"가 아니라 "어떤 그릇에 담을까"

**중요한 재정의**: 아래 경로 A/B는 서로 다른 Agent를 만드는 게 아니다. **Topic 맵(내 장비 상태 확인·증상 상담·담당자 인계요청·Case 검토·출동 브리핑·Slack 인계·유사사례조회)은 어느 경로든 동일하게 유지된다.** 달라지는 건 그 Topic들을 고객에게 보여주는 **화면(컨테이너)**뿐이다 — 사용자가 원한 "Service Agent"가 정확히 Agentforce Self-Service Portal이므로, 이 네이티브 표면을 우리가 만든 Topic 맵의 기본 채택 대상으로 삼는다.

| | 경로 A(우선 채택 목표): Agentforce Self-Service Portal(네이티브 "Help Agent") | 경로 B(대체용): 독립 커스텀 컴포넌트 |
|---|---|---|
| 상태 | ✅ 라이선스 확인됨("Help Agent Configuration", 10석, ADR 6.5장) — 단 실제 설정 완료 여부는 미확인 | ✅ 항상 가능 |
| 전제조건 | Setup에서 실제 활성화·Experience Cloud 페이지 연결 확인 필요 | 없음 |
| 채택 조건 | **T5-B 착수 시 최우선으로 Help Agent 활성화부터 확인**하고, 되면 우리 Topic 맵을 이 표면에 그대로 연결(2D). Topic 설계·`Case_Dispatch_Briefing_Generate` 재사용 로직은 안 바뀜 | Help Agent가 비활성이거나 설정이 막혀 있을 때만 독립 컴포넌트로 진행 — 이 경우도 같은 Topic 맵을 그대로 씀 |

## 지금 당장 착수 가능한 것 (경로 B 기준, 블로킹 없음)

아래 2A~2D는 경로 B(독립 컴포넌트) 기준 상세 설계 — 라이선스 확인과 무관하게 항상 만들 수 있어서 먼저 착수한다.

## 통합 Agent 설계 — Topic 맵

**단일 Agentforce 에이전트**, Topic만 사용자 Profile/권한에 따라 노출 여부가 갈린다(별도 Agent 인스턴스 아님).

| Topic | 사용자 | 하는 일 | 기존 자산 재사용 |
|---|---|---|---|
| 내 장비 상태 확인 | 유신 | Asset 상태·보증·최근 점검·미조치 항목 설명 | Asset/`Trend_Flag__c` 조회만 |
| 증상 상담 | 유신 | 증상·운영영향·발생시점 수집, 인계 기준 판단 | 신규 |
| 담당자 인계 요청 | 유신→서정비 | 상담 요약과 함께 Case 생성 호출(아래 트리거 참고) | 기존 Case 생성 메커니즘 |
| Case 검토 지원 | 서정비 | 상담 맥락 + Asset 이력 + 보증/SLA + 최근 WO를 한 화면에 | 기존 Case/Asset/Entitlement 조회 |
| **출동 브리핑** | 서정비 | 가설·근거·점검 순서 생성 | **`Case_Dispatch_Briefing_Generate` Flow를 Invocable Action으로 감싸서 등록** — 로직 그대로 재사용, 새로 안 만듦(원문 데모6 기술 패턴) |
| Slack 인계 요청 | 서정비 | "오도면/강시공에게 넘겨줘" 요청 시 T5-D Slack 메시지 발신 | T5-D 인프라 재사용(같은 채널·메커니즘) |
| 유사사례 조회 (선택) | 서정비 | 과거 유사 Case/Problem 인용 | DEC-T5-10: Data Cloud(T5-X, 있으면) 또는 SOQL 구조화 검색(기본) |

**핵심 재사용 지점**: `Case_Dispatch_Briefing_Generate`는 이미 T4가 만든 Flow + Prompt Builder 조합이다(T5-0에서 merge 대기 중인 그 Flow). T5-B는 이걸 새로 만들지 않고 **Invocable Action 래퍼만 추가**해서 Agentforce Studio Topic에 등록한다 — 나머지 Topic도 전부 "기존 조회/기존 Flow를 대화형 진입점에 연결"하는 방식이지, 새 판정·승인 로직을 만들지 않는다(3장 Plus-Alpha 원칙).

## 범위 — 개발 격리 원칙 (3-2장 그대로 적용)

**지금(개발 단계)**: 기존 4개 LWC(`otMyAssets`/`otAssetPortal`/`otReportFault`/`otPortalHeader`)는 **읽기 전용 감사만**, 수정 안 함. 아래를 독립 컴포넌트로 T3DLV에서 개발:

- **2A**: 기존 LWC 4종의 데이터 계약(무슨 필드를 어떻게 쓰는지) 문서화만, 코드 수정 없음
- **2B**: 포털 공개 Asset 필드 확정(DEC-T5-18, 갱신): 자산명·Hall·상태배지·**장비 이미지**·설치일·보증·최근점검일+결과·다음점검일·미조치건수
- **2C**: `otTrendAlertCard` — 독립 LWC, `@api assetId` 하나만 받아 동작(기존 컴포넌트 내부 구현 의존 금지, RG-11)
- **2D**: Service Agent 상담 진입점 — **T0INT에 "Help Agent Configuration" 라이선스 실제 확인됨**(10석, 2026-08-26 Tooling API 실측, ADR 6.5장). 사용자가 원한 "Service Agent"가 정확히 이 네이티브 표면이므로, **활성화 확인이 최우선 순서** — 되면 위 Topic 맵을 그대로 이 표면에 연결. 개발 격리 원칙(3-2장)은 동일하게 적용해 독립 페이지에서 먼저 검증하고, 안 되거나 막히면 그때만 커스텀 컴포넌트로 대체

**나중(통합 단계, T5 채택 후)**: 별도 통합 PR로 기존 포털 페이지에 배치, 이때 T0 트랙 담당자와 페이지 위치·공개 데이터·접수 흐름·권한·모바일 UX 조정(RG-12)

## 비범위

- 기존 포털 로그인/인증 로직 신규 구현(기존 Community 사용자 재사용)
- Agent가 Case를 직접 생성(사람 확정 원칙, DEC-T5-06 유지)
- `Service_Consultation__c` 신규 객체(DEC-T5-14 — 기각, Case 필드 확장으로 대체)

## 트리거 조건과 데이터 계약

### ⚠️ "실시간" 표기 정정(2026-08-27)

`otTrendAlertCard`가 보여주는 값은 **최신 데이터이지 실시간 스트리밍이 아니다.** 가상 IoT 이벤트가 발행되면 백엔드(`WorkOrderLineItem`·`Trend_Flag__c`)는 즉시 갱신되지만, **고객 화면은 페이지를 열거나 새로고침해야만 그 값을 반영**한다(Pull). 화면이 켜진 채로 자동 갱신되게 하려면 LWC에 Platform Event 구독(`empApi`)을 추가해야 하는데, 이건 현재 범위 밖 — 필요해지면 T5-X 후보로 추가.

**고객에게 가는 능동 알림은 없다.** DEC-T5-01(Warning: Slack 없음)·DEC-T5-20(Critical: Slack은 서정비에게만)이 내부 인력용이지 고객용이 아니라서, **고객은 포털에 스스로 들어가야만 이상을 알 수 있다.** 이건 이 프로젝트가 처음부터 "능동 알림 없음, 수동 확인형"으로 확인해온 것과 동일한 구조이며, T5도 이 지점을 해결하지 않는다(고객용 알림은 범위 밖 — 필요해지면 별도 검토 대상).

### 직접 접수 경로 (기존 유지)
`otReportFault` → 기존 Case 생성 메커니즘 → SLA 시작. **T5는 이 경로를 수정하지 않는다.**

### Agent 상담 경로 (신규)
1. 유신이 포털을 열거나 새로고침 → 자산 카드(`otTrendAlertCard`)에서 주의/이상 배지·게이지를 봄(아래 "실시간 표기 정정" 참고, Pull 방식) → 카드 옆 "Agent 상담" 버튼 클릭 → Asset 맥락(assetId) 자동 전달
2. Agent가 증상·운영영향·발생시점 수집(대화)
3. **인계 기준(DEC-T5-16)** 충족 시에만 인계:
   - 고객이 "상담원 연결" 직접 요청
   - 가동중단 위험 증상 선택
   - 최근 Trend가 Warning 이상
   - 허용 범위 밖 질문
4. 인계 시 **기존 Case 생성 메커니즘을 그 시점에 호출**하며 아래 신규 필드를 동시에 채움(사후 추가 아님):
   - `Case.Consultation_Notes__c` (Long Text)
   - `Case.Intake_Source__c` (Agent / Direct)
5. 인계 기준 미충족 시 Case 생성 없이 Agent 세션 기록(Agentforce 네이티브)만 남음

**중요**: Trend 상태나 Slack Alert가 Case를 직접 만들지 않는다(DEC-T5-01/02) — 전부 "서정비 검토" 노드를 거친다(4장 다이어그램).

## 기존 T0~T4와의 관계

- 기존 4개 LWC: 수정 안 함, 감사만
- 기존 Case 생성 로직: 그대로 재사용, 새 로직 안 만듦
- `Case.Dispatch_Briefing__c` / `Case_Dispatch_Briefing_Generate`: T5-0 완료(merge) 후 참조. **Flow 자체는 수정하지 않고 Invocable Action 래퍼만 추가**(T4 소유 로직 그대로)
- T5-D(Slack): "Slack 인계 요청" Topic이 T5-D의 발신 메커니즘을 호출 — 별도 채널/로직 신설 안 함

## Feature Flag

`Service_Agent_Enabled__c` — false면 포털에 Agent 진입 버튼 자체가 안 보임(RG-10: 꺼져도 직접 접수 경로는 정상 작동)

## 데모 데이터

CDU-A-07 기준, Warning 상태의 유신 계정으로 상담 시나리오(증상 불명확 → 인계 기준 충족 → Case 생성) 시연

## 완료 조건 · QA

- T5-SC-05A~E(ADR 8.5장) 전부 통과
- RG-05, RG-09, RG-10, RG-11 회귀 QA 전부 통과
- Agent 세션만으로 끝난 경우 Case가 생성되지 않음을 쿼리로 확인
- 인계된 경우 Case 생성 시점에 `Consultation_Notes__c`/`Intake_Source__c`가 함께 채워짐을 확인(사후 UPDATE 아님)
- **Topic 권한 QA**: 유신 Profile로 로그인 시 "출동 브리핑"/"Case 검토 지원"/"Slack 인계" Topic이 안 보임, 서정비 Profile로는 전부 보임 — 같은 에이전트, 다른 Topic 노출로 확인
- "출동 브리핑" Topic 실행 결과가 기존 `Case_Dispatch_Briefing_Generate`를 Flow Builder에서 직접 실행한 결과와 동일(Invocable Action이 로직을 안 바꿨는지 대조)
