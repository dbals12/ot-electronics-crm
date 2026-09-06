/**
 * Cooling Continuity 운영 홈("오늘" 탭)의 KPI 집계 컨트롤러.
 *
 * 통짜 대시보드 LWC 대신, 홈 FlexiPage 위의 작은 컴포넌트들이 각자
 * 실제 레코드를 @wire로 소비하도록 만든 컴포지트 구조의 데이터 공급원이다.
 * - otOpsKpiRow LWC 가 getToday() 를 @wire 로 소비한다.
 * Hall 미니뷰는 별도로 T5HallDashboardController.getHallSummary() 를 쓴다.
 */
public with sharing class OTOpsHomeController {

    private static final Set<String> OPEN_STATUS_EXCLUDE = new Set<String>{ 'Closed', 'Resolved' };

    @AuraEnabled(cacheable=true)
    public static OpsToday getToday() {
        OpsToday t = new OpsToday();
        Datetime now = Datetime.now();
        Date today = Date.today();
        Date weekAgo = today.addDays(-6);

        // ── SLA 위험 신호: 에스컬레이션된 열린 Case (SLA/Entitlement 미사용 org 호환) ──
        try {
            t.slaRiskCount = [
                SELECT COUNT()
                FROM Case
                WHERE IsClosed = false AND IsEscalated = true
                WITH USER_MODE
            ];
        } catch (Exception e) {
            t.slaRiskCount = 0;
        }

        // ── 내 Case 큐: 내가 소유한 열린 Case, 우선순위별 ──
        for (AggregateResult ar : [
            SELECT Priority pri, COUNT(Id) cnt
            FROM Case
            WHERE IsClosed = false AND OwnerId = :UserInfo.getUserId()
            WITH USER_MODE
            GROUP BY Priority
        ]) {
            String pri = (String) ar.get('pri');
            Integer cnt = (Integer) ar.get('cnt');
            t.myCaseCount += cnt;
            if (pri == 'High' || pri == 'P1') {
                t.myCaseP1 += cnt;
            } else if (pri == 'Medium' || pri == 'P2') {
                t.myCaseP2 += cnt;
            } else {
                t.myCaseP3 += cnt;
            }
        }

        // ── Agent 인계 대기함: 상담사 인계됐으나 아직 첫 응답 전 ──
        try {
            t.agentHandoffCount = [
                SELECT COUNT()
                FROM Case
                WHERE IsClosed = false
                  AND Agent_Handoff_At__c != null
                  AND Agent_First_Response_At__c = null
                WITH USER_MODE
            ];
        } catch (Exception e) {
            t.agentHandoffCount = 0;
        }

        // ── Critical Trend 알림: 최근 24h 내 생성된 '이상' 추세 WOLI ──
        try {
            t.criticalTrendCount = [
                SELECT COUNT()
                FROM WorkOrderLineItem
                WHERE Trend_Flag__c = '이상'
                  AND CreatedDate >= :now.addHours(-24)
                WITH USER_MODE
            ];
        } catch (Exception e) {
            t.criticalTrendCount = 0;
        }

        // ── 스파크라인: 최근 7일 일별 신규 Case 수 ──
        Map<Date, Integer> byDay = new Map<Date, Integer>();
        for (Date d = weekAgo; d <= today; d = d.addDays(1)) {
            byDay.put(d, 0);
        }
        for (AggregateResult ar : [
            SELECT DAY_ONLY(convertTimezone(CreatedDate)) d, COUNT(Id) cnt
            FROM Case
            WHERE CreatedDate = LAST_N_DAYS:7
            WITH USER_MODE
            GROUP BY DAY_ONLY(convertTimezone(CreatedDate))
        ]) {
            Date d = (Date) ar.get('d');
            if (byDay.containsKey(d)) {
                byDay.put(d, (Integer) ar.get('cnt'));
            }
        }
        List<Integer> spark = new List<Integer>();
        for (Date d = weekAgo; d <= today; d = d.addDays(1)) {
            spark.add(byDay.get(d));
        }
        t.caseSpark = spark;

        return t;
    }

    public class OpsToday {
        @AuraEnabled public Integer slaRiskCount = 0;
        @AuraEnabled public Integer slaNearestMinutes = 0;
        @AuraEnabled public Integer myCaseCount = 0;
        @AuraEnabled public Integer myCaseP1 = 0;
        @AuraEnabled public Integer myCaseP2 = 0;
        @AuraEnabled public Integer myCaseP3 = 0;
        @AuraEnabled public Integer agentHandoffCount = 0;
        @AuraEnabled public Integer criticalTrendCount = 0;
        @AuraEnabled public List<Integer> caseSpark = new List<Integer>();
    }
}
