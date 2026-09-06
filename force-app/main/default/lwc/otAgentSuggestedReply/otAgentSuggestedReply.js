import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import generateReply from '@salesforce/apex/T5AgentReplySuggestionAction.generateForLwc';
import generateClosure from '@salesforce/apex/T5CaseClosureSummaryAction.generateForLwc';
import CASE_FIELD from '@salesforce/schema/MessagingSession.CaseId';

export default class OtAgentSuggestedReply extends LightningElement {
    @api recordId;
    @track suggestion = '';
    @track isLoading = false;
    @track error = '';
    @track isCollapsed = false;
    _caseId;

    @wire(getRecord, { recordId: '$recordId', fields: [CASE_FIELD] })
    wiredRecord({ data, error }) {
        if (data) {
            this._caseId = getFieldValue(data, CASE_FIELD);
        }
        if (error) {
            this.error = 'MessagingSession 로드 실패';
        }
    }

    get collapseIcon() {
        return this.isCollapsed ? 'utility:chevrondown' : 'utility:chevronup';
    }

    get hasSuggestion() {
        return this.suggestion.length > 0;
    }

    get noCaseLinked() {
        return !this._caseId;
    }

    get statusMessage() {
        if (this.noCaseLinked) return 'Case가 연결되면 AI 추천이 활성화됩니다.';
        return '';
    }

    handleToggleCollapse() {
        this.isCollapsed = !this.isCollapsed;
    }

    async handleGenerate() {
        if (!this._caseId) {
            this.error = 'Case가 연결되지 않았습니다. 고객이 서비스 요청을 접수해야 합니다.';
            return;
        }
        this.isLoading = true;
        this.error = '';
        this.suggestion = '';

        try {
            const r = await generateReply({
                caseId: this._caseId,
                conversationSummary: '',
                stage: ''
            });
            if (r.success) {
                this.suggestion = r.suggestedReply;
            } else {
                this.error = r.errorMessage || 'AI 생성 실패';
            }
        } catch (e) {
            this.error = e.body ? e.body.message : e.message;
        } finally {
            this.isLoading = false;
        }
    }

    async handleGenerateClosure() {
        if (!this._caseId) {
            this.error = 'Case가 연결되지 않았습니다.';
            return;
        }
        this.isLoading = true;
        this.error = '';
        this.suggestion = '';

        try {
            const r = await generateClosure({ caseId: this._caseId });
            if (r.success) {
                this.suggestion = r.closureSummary;
            } else {
                this.error = r.errorMessage || '종결 카드 생성 실패';
            }
        } catch (e) {
            this.error = e.body ? e.body.message : e.message;
        } finally {
            this.isLoading = false;
        }
    }

    async handleFill() {
        if (!this.suggestion || !this.recordId) return;
        try {
            await setAgentInput(this.recordId, { text: this.suggestion });
        } catch (e) {
            if (navigator.clipboard) {
                await navigator.clipboard.writeText(this.suggestion);
            }
        }
    }

    handleClear() {
        this.suggestion = '';
        this.error = '';
    }
}
