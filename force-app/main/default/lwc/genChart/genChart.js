import { LightningElement, api, track } from 'lwc';
import chartjs from '@salesforce/resourceUrl/ChartJS';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class GenChart extends LightningElement {
    @api chartConfig;

    isChartJsInitialized = false;
    chart;

    renderedCallback() {
        if (!this.isChartJsInitialized) {
            this.initializeChart();
        }
    }

    initializeChart() {
        Promise.all([loadScript(this, chartjs)])
            .then(() => {
                this.isChartJsInitialized = true;
                const ctx = this.template.querySelector('canvas.barChart').getContext('2d');
                this.chart = new window.Chart(ctx, JSON.parse(JSON.stringify(this.chartConfig)));
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error loading Chart',
                        message: error.message,
                        variant: 'error',
                    })
                );
            });
    }

    // to update chart
    @api
    setChartConfig(newConfig) {
        this.chartConfig = newConfig;
        if (this.isChartJsInitialized) {
            this.chart.data = JSON.parse(JSON.stringify(newConfig.data));
            this.chart.update();
        } else {
            this.initializeChart();
        }
    }
}
