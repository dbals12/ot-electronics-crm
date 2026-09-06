# 다이어그램

전체 프로젝트의 시스템 아키텍처와 ERD. **직접 설계·작성**했습니다.
(ERD는 최종 org 상태를 기준으로 정합성을 맞춘 버전. 표준 객체 + 5개 트랙의 커스텀 객체·필드 포함)

| 파일 | 내용 |
|---|---|
| `01_시스템_아키텍처.png` | Salesforce Platform 4계층(Business App / Data Layer / Automation·Decision / Process Hub) + Experience·Channel + 외부 시스템(PLM·ERP·BMS). "Asset = E2E 기준점", "AI Recommendation → Human Review → Official Record" |
| `03_전체여정_Object_ERD.svg` | 리드~재영업 전체 여정의 Object 관계도 |
| `04_설치인수운영_상세_ERD.svg` | **설치·인수·운영·재영업 증대 루프 상세** — Technical Baseline · WorkOrder · WOLI(Trend_Flag / Drift_From_Baseline) · IoT_Reading_Event · Customer_Alert · Case · Entitlement (내 담당 구간 중심) |
| `05_8클러스터_ERD.svg` | 8개 클러스터로 그룹핑한 상세 필드 ERD |

SVG는 GitHub에서 바로 렌더링됩니다. 큰 화면은 파일을 열어 확대해서 보세요.
