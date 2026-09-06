public with sharing class T5CaseClosureSummaryAction {

    public class Input {
        @InvocableVariable(required=true)
        public Id caseId;
    }

    public class Output {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String closureSummary;
        @InvocableVariable public String errorMessage;
    }

    @InvocableMethod(label='Case 종결 요약 생성' description='Case/WO/WOLI/Problem 종합 최종 조치 결과 카드')
    public static List<Output> generate(List<Input> inputs) {
        List<Output> results = new List<Output>();
        for (Input inp : inputs) {
            results.add(generateOne(inp));
        }
        return results;
    }

    @AuraEnabled
    public static Output generateForLwc(Id caseId) {
        Input inp = new Input();
        inp.caseId = caseId;
        return generateOne(inp);
    }

    private static Output generateOne(Input inp) {
        Output out = new Output();
        try {
            Case c = [
                SELECT Id, CaseNumber, Subject, Status, Priority,
                       Reported_Symptom__c, Symptom_Category__c, Impact_Level__c,
                       Resolution_Hours__c, Billable__c, Coverage_Type__c,
                       Warranty_Decision__c,
                       Account.Name, Asset.Name, Asset.SerialNumber
                FROM Case WHERE Id = :inp.caseId
                WITH USER_MODE LIMIT 1
            ];

            List<WorkOrder> workOrders = [
                SELECT Id, WorkOrderNumber, Subject, Status,
                       Action_Taken__c, Problem__c, Root_Cause_Draft__c,
                       Repair_Result__c
                FROM WorkOrder WHERE CaseId = :inp.caseId
                WITH USER_MODE ORDER BY CreatedDate DESC LIMIT 5
            ];

            List<WorkOrderLineItem> wolis = new List<WorkOrderLineItem>();
            if (!workOrders.isEmpty()) {
                Set<Id> woIds = new Set<Id>();
                for (WorkOrder wo : workOrders) woIds.add(wo.Id);
                wolis = [
                    SELECT Measurement_Item_Code__c, Measured_Value__c,
                           Baseline_Value__c, Previous_Measured_Value__c,
                           Delta_From_Previous__c, Trend_Flag__c
                    FROM WorkOrderLineItem
                    WHERE WorkOrderId IN :woIds
                      AND Measured_Value__c != null
                    WITH USER_MODE
                    ORDER BY CreatedDate DESC LIMIT 20
                ];
            }

            List<Problem> problems = [
                SELECT Subject, Priority, Description
                FROM Problem
                WITH USER_MODE
                ORDER BY CreatedDate DESC LIMIT 3
            ];

            List<ServiceContract> contracts = [
                SELECT ContractNumber, EndDate, Status
                FROM ServiceContract
                WHERE AccountId = :c.AccountId AND Status = 'Active'
                WITH USER_MODE LIMIT 1
            ];

            String context = buildContext(c, workOrders, wolis, problems, contracts);

            ConnectApi.EinsteinPromptTemplateGenerationsInput genInput =
                new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            genInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            genInput.additionalConfig.applicationName = 'PromptTemplateGenerationsInvocable';
            genInput.isPreview = false;

            Map<String, ConnectApi.WrappedValue> params =
                new Map<String, ConnectApi.WrappedValue>();
            params.put('Input:Case_Summary', toWrapped(context));
            genInput.inputParams = params;

            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation result =
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
                    'Case_Closure_Summary', genInput);

            out.closureSummary = result.generations[0].text;
            out.success = true;
        } catch (Exception e) {
            out.success = false;
            out.errorMessage = e.getMessage();
        }
        return out;
    }

    private static String buildContext(Case c, List<WorkOrder> wos,
            List<WorkOrderLineItem> wolis, List<Problem> problems,
            List<ServiceContract> contracts) {
        List<String> lines = new List<String>();
        lines.add('[Case]');
        lines.add(c.CaseNumber + ' / ' + c.Subject);
        lines.add('고객: ' + c.Account.Name + ' / 자산: ' + c.Asset.Name);
        lines.add('증상: ' + c.Reported_Symptom__c);
        lines.add('영향도: ' + c.Impact_Level__c);
        if (c.Coverage_Type__c != null)
            lines.add('적용범위: ' + c.Coverage_Type__c);
        if (c.Warranty_Decision__c != null)
            lines.add('보증: ' + c.Warranty_Decision__c);
        if (c.Billable__c != null)
            lines.add('청구: ' + (c.Billable__c ? '유상' : '무상'));

        if (!contracts.isEmpty()) {
            lines.add('\n[서비스 계약]');
            lines.add(contracts[0].ContractNumber + ' / 종료: ' + String.valueOf(contracts[0].EndDate));
        }

        if (!wos.isEmpty()) {
            lines.add('\n[Work Orders]');
            for (WorkOrder wo : wos) {
                lines.add(wo.WorkOrderNumber + ' / ' + wo.Subject + ' / ' + wo.Status);
                if (wo.Action_Taken__c != null)
                    lines.add('  조치: ' + wo.Action_Taken__c);
                if (wo.Repair_Result__c != null)
                    lines.add('  결과: ' + wo.Repair_Result__c);
            }
        }

        if (!wolis.isEmpty()) {
            lines.add('\n[측정값]');
            for (WorkOrderLineItem woli : wolis) {
                lines.add(woli.Measurement_Item_Code__c + ': '
                    + woli.Measured_Value__c
                    + (woli.Baseline_Value__c != null ? ' (기준선: ' + woli.Baseline_Value__c + ')' : '')
                    + (woli.Trend_Flag__c != null ? ' [' + woli.Trend_Flag__c + ']' : ''));
            }
        }

        if (!problems.isEmpty()) {
            lines.add('\n[Problem/RCA]');
            for (Problem p : problems) {
                lines.add(p.Subject + ' / ' + p.Priority);
                if (p.Description != null)
                    lines.add('  ' + p.Description);
            }
        }

        return String.join(lines, '\n');
    }

    private static ConnectApi.WrappedValue toWrapped(String val) {
        ConnectApi.WrappedValue w = new ConnectApi.WrappedValue();
        w.value = val;
        return w;
    }
}
