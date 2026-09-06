/**
 * OTOpsHomeController.getToday() 의 집계 경로를 검증한다.
 * 내 Case 큐(우선순위 분류), Agent 인계 대기, 7일 스파크라인 배열 길이,
 * Critical Trend 카운트가 예외 없이 반환되는지 확인한다.
 *
 * SlaExitDate 는 표준적으로 직접 세팅이 제한되므로 SLA 위험 카운트는
 * "예외 없이 정수를 반환한다" 수준만 검증한다.
 */
@isTest
private class OTOpsHomeControllerTest {

    @testSetup
    static void setup() {
        Account acc = new Account(Name = 'OT Ops Test');
        insert acc;

        List<Case> cases = new List<Case>();
        cases.add(new Case(Subject = '내 케이스 M', Status = 'New', Priority = 'Medium', AccountId = acc.Id));
        cases.add(new Case(Subject = '내 케이스 L', Status = 'New', Priority = 'Low', AccountId = acc.Id));
        cases.add(new Case(Subject = '내 케이스 H', Status = 'New', Priority = 'High', AccountId = acc.Id));
        // Agent 인계 대기: 인계됐고 첫 응답 전
        cases.add(new Case(
            Subject = '인계 대기', Status = 'New', Priority = 'Medium', AccountId = acc.Id,
            Agent_Handoff_At__c = Datetime.now().addMinutes(-30)
        ));
        insert cases;
    }

    @isTest
    static void getToday_aggregates() {
        Test.startTest();
        OTOpsHomeController.OpsToday t = OTOpsHomeController.getToday();
        Test.stopTest();

        System.assertNotEquals(null, t, '결과가 반환되어야 한다');
        System.assert(t.slaRiskCount >= 0, 'SLA 위험 카운트는 정수');
        System.assert(t.myCaseCount >= 4, '내 큐 Case 4건 이상 집계');
        System.assert(t.myCaseP1 >= 1, 'High → P1 버킷');
        System.assert(t.myCaseP2 >= 2, 'Medium → P2 버킷 (2건: 내 케이스 M + 인계 대기)');
        System.assert(t.myCaseP3 >= 1, 'Low → P3 버킷');
        System.assertEquals(1, t.agentHandoffCount, '인계 대기 Case 1건');
        System.assert(t.criticalTrendCount >= 0, 'Critical Trend 카운트는 정수');
        System.assertEquals(7, t.caseSpark.size(), '스파크라인은 7일치');
    }
}
