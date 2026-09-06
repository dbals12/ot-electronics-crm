import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getHallSummary from '@salesforce/apex/T5HallDashboardController.getHallSummary';

const TREND_META = {
    정상: { label: 'Normal', cls: 'cell cell--normal', dot: 'dot dot--normal' },
    주의: { label: 'Watch', cls: 'cell cell--watch', dot: 'dot dot--watch' },
    이상: { label: 'Critical', cls: 'cell cell--critical', dot: 'dot dot--critical' },
    미점검: { label: 'Unknown', cls: 'cell cell--unknown', dot: 'dot dot--unknown' }
};

/**
 * Hall 자산 상태 미니뷰. 통짜 배경 이미지 대신, 실제 Asset 레코드를
 * (T5HallDashboardController.getHallSummary) CSS Grid 도면에 배치한다.
 * 자산 클릭 시 해당 Asset 레코드로 이동.
 */
export default class OtHallMiniview extends NavigationMixin(LightningElement) {
    data;
    error;

    @wire(getHallSummary)
    wired({ data, error }) {
        if (data) {
            this.data = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.data = undefined;
        }
    }

    get isLoading() {
        return !this.data && !this.error;
    }

    get errorMessage() {
        return this.error?.body?.message || 'Hall 자산 데이터를 불러오지 못했습니다.';
    }

    get hasAssets() {
        return this.data && this.data.totalAssets > 0;
    }

    get summaryLine() {
        const d = this.data;
        if (!d) {
            return '';
        }
        return `${d.totalAssets} assets · ${d.normalCount} Normal · ${d.warningCount + d.criticalCount} Watch`;
    }

    get cells() {
        if (!this.data) {
            return [];
        }
        return this.data.assets.map((a) => {
            const meta = TREND_META[a.trend] || TREND_META['미점검'];
            const seq = this.sequence(a.name);
            return {
                id: a.id,
                name: a.name,
                statusLabel: meta.label,
                cls: meta.cls,
                dotCls: meta.dot,
                style: `grid-column: ${((seq - 1) % 4) + 1}; grid-row: ${Math.floor((seq - 1) / 4) + 1};`
            };
        });
    }

    get legend() {
        return [
            { key: 'n', label: 'Normal', cls: 'dot dot--normal' },
            { key: 'w', label: 'Watch', cls: 'dot dot--watch' },
            { key: 'c', label: 'Critical', cls: 'dot dot--critical' },
            { key: 'u', label: 'Unknown', cls: 'dot dot--unknown' }
        ];
    }

    // 자산명 끝의 숫자(CDU-A-07 → 7)를 그리드 순번으로. 못 뽑으면 이름 해시.
    sequence(name) {
        const m = /(\d+)\s*$/.exec(name || '');
        if (m) {
            return parseInt(m[1], 10);
        }
        let h = 0;
        for (let i = 0; i < (name || '').length; i++) {
            h = (h + name.charCodeAt(i)) % 8;
        }
        return h + 1;
    }

    handleCellClick(event) {
        const recordId = event.currentTarget.dataset.id;
        if (!recordId) {
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId, objectApiName: 'Asset', actionName: 'view' }
        });
    }

    handleViewAll() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: { objectApiName: 'Asset', actionName: 'list' },
            state: { filterName: 'Recent' }
        });
    }
}
