import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getToday from '@salesforce/apex/OTOpsHomeController.getToday';

/**
 * "오늘" 탭 상단 KPI 4장. OTOpsHomeController.getToday() 의 실제 집계를 표시하고,
 * 각 스파크라인은 인라인 SVG 로 그린다. 타일 클릭 시 관련 리스트뷰로 이동.
 */
export default class OtOpsKpiRow extends NavigationMixin(LightningElement) {
    data;
    error;

    @wire(getToday)
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
        return this.error?.body?.message || 'KPI 데이터를 불러오지 못했습니다.';
    }

    get tiles() {
        const d = this.data || {};
        const spark = d.caseSpark && d.caseSpark.length ? d.caseSpark : [1, 1, 1, 1, 1, 1, 1];
        return [
            {
                key: 'sla',
                label: 'SLA 위험 신호',
                value: d.slaRiskCount ?? 0,
                unit: '건',
                foot:
                    d.slaNearestMinutes > 0
                        ? `가장 가까운 SLA ${d.slaNearestMinutes}분`
                        : '에스컬레이션된 열린 Case',
                cls: 'tile tile--critical',
                spark: this.spark(spark, '#ea4b3b')
            },
            {
                key: 'queue',
                label: '내 Case 큐',
                value: d.myCaseCount ?? 0,
                unit: '건',
                foot: `P1 ${d.myCaseP1 ?? 0} · P2 ${d.myCaseP2 ?? 0} · P3 ${d.myCaseP3 ?? 0}`,
                cls: 'tile',
                spark: this.spark(spark, '#2f6fed')
            },
            {
                key: 'handoff',
                label: 'Agent 인계 대기함',
                value: d.agentHandoffCount ?? 0,
                unit: '건',
                foot: '상담사 첫 응답 전',
                cls: 'tile',
                spark: this.spark(spark, '#2f6fed')
            },
            {
                key: 'trend',
                label: 'Critical Trend 알림',
                value: d.criticalTrendCount ?? 0,
                unit: '건',
                foot: '최근 24시간 · 추세 이상',
                cls: 'tile tile--warning',
                spark: this.spark(spark, '#e8912f')
            }
        ];
    }

    // 정수 배열 → 40x16 뷰박스의 폴리라인 points 문자열
    spark(values, color) {
        const w = 72;
        const h = 22;
        const max = Math.max(...values, 1);
        const min = Math.min(...values, 0);
        const range = max - min || 1;
        const step = values.length > 1 ? w / (values.length - 1) : w;
        const points = values
            .map((v, i) => {
                const x = (i * step).toFixed(1);
                const y = (h - ((v - min) / range) * (h - 4) - 2).toFixed(1);
                return `${x},${y}`;
            })
            .join(' ');
        return { points, color, viewBox: `0 0 ${w} ${h}` };
    }

    handleTileClick(event) {
        const key = event.currentTarget.dataset.key;
        const filterMap = {
            sla: { objectApiName: 'Case', filterName: 'AllOpenCases' },
            queue: { objectApiName: 'Case', filterName: 'MyOpenCases' },
            handoff: { objectApiName: 'Case', filterName: 'MyOpenCases' },
            trend: { objectApiName: 'WorkOrderLineItem', filterName: 'Recent' }
        };
        const target = filterMap[key];
        if (!target) {
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: { objectApiName: target.objectApiName, actionName: 'list' },
            state: { filterName: target.filterName }
        });
    }
}
