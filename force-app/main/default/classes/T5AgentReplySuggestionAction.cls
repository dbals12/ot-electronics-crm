public with sharing class T5AgentReplySuggestionAction {

    public class Input {
        @InvocableVariable(required=true)
        public Id caseId;

        @InvocableVariable
        public String conversationSummary;

        @InvocableVariable
        public String stage;
    }

    public class Output {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String suggestedReply;
        @InvocableVariable public String errorMessage;
    }

    @InvocableMethod(label='AI 추천 응답 생성' description='Case 컨텍스트 기반 상담사 추천 응답')
    public static List<Output> generate(List<Input> inputs) {
        List<Output> results = new List<Output>();
        for (Input inp : inputs) {
            results.add(generateOne(inp));
        }
        return results;
    }

    @AuraEnabled
    public static Output generateForLwc(Id caseId, String conversationSummary, String stage) {
        Input inp = new Input();
        inp.caseId = caseId;
        inp.conversationSummary = conversationSummary;
        inp.stage = stage;
        return generateOne(inp);
    }

    private static Output generateOne(Input inp) {
        Output out = new Output();
        try {
            Case c = [
                SELECT Id, CaseNumber, Subject, Status, Priority,
                       Reported_Symptom__c, Symptom_Category__c, Impact_Level__c,
                       Account.Name, Asset.Name, Asset.SerialNumber,
                       Asset.Site_Location__c, Asset.Latest_Gauges_JSON__c,
                       Coverage_Type__c, Warranty_Decision__c, Billable__c
                FROM Case WHERE Id = :inp.caseId
                WITH USER_MODE LIMIT 1
            ];

            List<ServiceContract> contracts = [
                SELECT ContractNumber, EndDate, Status
                FROM ServiceContract
                WHERE AccountId = :c.AccountId AND Status = 'Active'
                WITH USER_MODE LIMIT 1
            ];

            String caseContext = buildCaseContext(c, contracts);
            String stageHint = String.isNotBlank(inp.stage) ? inp.stage : '상담 진행 중';
            String convSummary = String.isNotBlank(inp.conversationSummary)
                ? inp.conversationSummary : '(대화 요약 없음)';

            ConnectApi.EinsteinPromptTemplateGenerationsInput genInput =
                new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            genInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            genInput.additionalConfig.applicationName = 'PromptTemplateGenerationsInvocable';
            genInput.isPreview = false;

            Map<String, ConnectApi.WrappedValue> params =
                new Map<String, ConnectApi.WrappedValue>();
            params.put('Input:Case_Context', toWrapped(caseContext));
            params.put('Input:Conversation_Summary', toWrapped(convSummary));
            params.put('Input:Stage', toWrapped(stageHint));
            genInput.inputParams = params;

            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation result =
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
                    'Agent_Reply_Suggestion', genInput);

            out.suggestedReply = result.generations[0].text;
            out.success = true;
        } catch (Exception e) {
            out.success = false;
            out.errorMessage = e.getMessage();
        }
        return out;
    }

    private static String buildCaseContext(Case c, List<ServiceContract> contracts) {
        List<String> lines = new List<String>();
        lines.add('Case: ' + c.CaseNumber + ' / ' + c.Subject);
        lines.add('Status: ' + c.Status + ' / Priority: ' + c.Priority);
        lines.add('고객: ' + c.Account.Name);
        lines.add('자산: ' + c.Asset.Name + ' (S/N: ' + c.Asset.SerialNumber + ')');
        if (c.Asset.Site_Location__c != null)
            lines.add('위치: ' + c.Asset.Site_Location__c);
        if (c.Reported_Symptom__c != null)
            lines.add('증상: ' + c.Reported_Symptom__c);
        if (c.Symptom_Category__c != null)
            lines.add('증상 분류: ' + c.Symptom_Category__c);
        if (c.Impact_Level__c != null)
            lines.add('영향도: ' + c.Impact_Level__c);
        if (c.Coverage_Type__c != null)
            lines.add('적용범위: ' + c.Coverage_Type__c);
        if (c.Warranty_Decision__c != null)
            lines.add('보증 판정: ' + c.Warranty_Decision__c);
        if (c.Asset.Latest_Gauges_JSON__c != null)
            lines.add('게이지: ' + c.Asset.Latest_Gauges_JSON__c);
        if (!contracts.isEmpty()) {
            ServiceContract sc = contracts[0];
            lines.add('서비스 계약: ' + sc.ContractNumber + ' / 종료: ' + String.valueOf(sc.EndDate));
        }
        return String.join(lines, '\n');
    }

    private static ConnectApi.WrappedValue toWrapped(String val) {
        ConnectApi.WrappedValue w = new ConnectApi.WrappedValue();
        w.value = val;
        return w;
    }
}
