# 기여 명세 (CONTRIBUTIONS)

이 저장소의 모든 파일은 5인 팀 프로젝트 `sf-team-1to10/ot-cooling-crm`(비공개)에서
**이유민(dbals12)이 작성·설계·수정한 것만** `git log --author` 기준으로 (main + 작업 브랜치 6개에서) 추출한 것입니다.
AI 협업 도구(Agentforce Vibes · Claude Code)를 사용했으며 설계·의사결정·검증은 직접 수행했습니다.

> 표준 객체(Case·Asset·WorkOrder·WorkOrderLineItem·Product2·ServiceContract 등) 폴더에는
> 제가 추가한 **커스텀 필드만** 포함됩니다 (object-meta.xml 제외). 다른 트랙이 만든 스키마를 참조하는 부분이 있어 **단독 배포용이 아닙니다.**

## Flow (23)
**T3 구축·인수**
- `Technical_Baseline_Rev_A`
- `Baseline_Approve_ERP_Order`
- `WO_Install_LineItem_AutoCreate`
- `WO_Commission_LineItem_AutoCreate`
- `WOLI_Baseline_Spec_AutoLoad`
- `WOLI_Judgement_AutoSet`
- `WOLI_Retest_Create`
- `WOLI_Asset_Open_Punch_Recalc`
- `WOLI_WorkOrder_Open_Punch_Recalc`
- `Punch_Overdue_Task_Daily`
- `TB_D1_D2_Handoff`
- `TB_D1_D2_Handoff_Task`
- `WorkOrder_Evidence_Check`
- `WorkOrder_D6_Task_On_Completion`
- `WorkOrder_Service_Ready_On_Acceptance`
- `Asset_Warranty_On_Acceptance`
- `WO_Site_Issue_Escalate`

**T5 고도화**
- `T5_IoT_Reading_Subscribe`
- `T5_Sync_Asset_Trend_Summary`
- `T5_Agent_Search_Knowledge`
- `T5_Agent_Create_Case_From_Consultation`
- `Route_Inbound_to_Agent`
- `Route_to_Messaging_Queue`

## Apex (19 + 테스트 8)
- `OTEquipDashboardController`
- `OTEquipDetailController`
- `OTMyAssetsController`
- `OTOpsHomeController`
- `OtSalesDashboardController`
- `OtSalesSidebarController`
- `OtTrendAlertCardController`
- `T5AgentAssetContextAction`
- `T5AgentCaseIntakeAction`
- `T5AgentEntitlementContextAction`
- `T5AgentKnowledgeSearchAction`
- `T5AgentReplySuggestionAction`
- `T5AssetContextHandler`
- `T5CaseClosureSummaryAction`
- `T5HmiAlertAckWriter`
- `T5HmiAssetDetailController`
- `T5HmiAssetHomeController`
- `T5SetAssetContextService`
- `T5SyncAssetTrendSummary`

## LWC (47)
`otAgentSuggestedReply` · `otAssetPortal` · `otCaseSubtabOpener` · `otCoolingHome` · `otCoolingRca` · `otCoolingToday` · `otEquipDashboard` · `otEquipDetail` · `otEquipSidebar` · `otEquipStatusChip` · `otEquipUtilBar` · `otHallMiniview` · `otKpiCard` · `otLiveTelemetryStrip` · `otMsConvBanner` · `otMsSidebarCenter` · `otMsSidebarLeft` · `otMyAssets` · `otOpsKpiRow` · `otPinnedWidthOverride` · `otPortalHeader` · `otRecordBanner` · `otReportFault` · `otSalesContracts` · `otSalesCtaBanner` · `otSalesDashboard` · `otSalesHeader` · `otSalesHeroBanner` · `otSalesHomeGrid` · `otSalesKeyDeals` · `otSalesPipeline` · `otSalesQuarterly` · `otSalesRecentRecords` · `otSalesSidebar` · `otSalesTodayEvents` · `otSalesTodayTasks` · `otServiceRequestModal` · `otStatusBadge` · `otTrendAlertCard` · `t5GaugeSvg` · `t5HmiAssetDetail` · `t5HmiAssetHome` · `t5HmiAssetThumb` · `t5HmiScaleGauge` · `t5PortalSiteFooter` · `t5PortalSiteHeader` · `t5ServiceReplies`

## Aura (2)
`pinnedLeftNarrowTemplate` `t5ServiceRepliesUtility` 

## 커스텀 오브젝트 · Platform Event · Custom Metadata
- `Asset` — 표준 객체, 커스텀 필드 13개
- `Asset_Context_Event__e` — **Platform Event** (필드 0)
- `Asset_Context_Pending__c` — 커스텀 객체 (필드 2)
- `Case` — 표준 객체, 커스텀 필드 1개
- `Customer_Alert__c` — 커스텀 객체 (필드 15)
- `IoT_Reading__e` — **Platform Event** (필드 4)
- `Knowledge__kav` — 표준 객체, 커스텀 필드 0개
- `MessagingSession` — 표준 객체, 커스텀 필드 2개
- `Problem` — 표준 객체, 커스텀 필드 0개
- `Product2` — 표준 객체, 커스텀 필드 2개
- `ServiceAppointment` — 표준 객체, 커스텀 필드 0개
- `ServiceContract` — 표준 객체, 커스텀 필드 0개
- `T5_Feature_Flags__mdt` — **Custom Metadata Type**
- `Technical_Baseline_Spec__c` — 커스텀 객체 (필드 5)
- `Technical_Baseline__c` — 커스텀 객체 (필드 18)
- `WorkOrder` — 표준 객체, 커스텀 필드 12개
- `WorkOrderLineItem` — 표준 객체, 커스텀 필드 17개

## 기타 메타데이터
- **triggers** (4 파일)
- **reports** (5 파일)
- **dashboards** (2 파일)
- **bots** (2 파일)
- **aiAuthoringBundles** (2 파일)
- **digitalExperiences** (24 파일)
