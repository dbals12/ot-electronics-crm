import { LightningElement, wire } from 'lwc';
import getHallSummary from '@salesforce/apex/T5HallDashboardController.getHallSummary';

/**
 * 두 탭("오늘" / "성과·RCA") 공통으로 페이지 상단에 놓이는 얇은 텔레메트리 스트립.
 * Tabs 컴포넌트 밖(상단 리전)에 배치해 탭 전환과 무관하게 항상 보이게 한다.
 */
export default class OtLiveTelemetryStrip extends LightningElement {
    summary;
    updatedLabel = this.now();

    @wire(getHallSummary)
    wired({ data }) {
        if (data) {
            this.summary = data;
            this.updatedLabel = this.now();
        }
    }

    get statusText() {
        const s = this.summary;
        if (!s) {
            return '연결 확인 중';
        }
        const watch = s.warningCount + s.criticalCount;
        return watch > 0 ? `Normal / Watch ${watch}` : 'Normal';
    }

    get statusClass() {
        return this.summary && this.summary.warningCount + this.summary.criticalCount > 0
            ? 'strip__status strip__status--watch'
            : 'strip__status';
    }

    now() {
        const d = new Date();
        return d.toLocaleTimeString('ko-KR', { hour12: false });
    }
}
