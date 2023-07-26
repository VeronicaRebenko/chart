import { LightningElement, wire, track, api } from 'lwc';
import getScheduleData from '@salesforce/apex/ChartController.getCostData';

export default class DataChart extends LightningElement {
    @track chartConfiguration;
    selectedWeek = 'Week 1';
    updateChart = false;

    get options() {
        return [
            { label: 'Week 1', value: 'Week 1' },
            { label: 'Week 2', value: 'Week 2' },
            { label: 'Week 3', value: 'Week 3' },
            { label: 'Week 4', value: 'Week 4' }
        ];
    }

    handleChange(event) {
        this.selectedWeek = event.target.value;
        this.updateChart = true;  
    }

    @wire(getScheduleData, { week: '$selectedWeek' })
    wiredGetScheduleData({ error, data }) {
        if (error) {
            this.error = error;
            this.chartConfiguration = undefined;
        } else if (data) {
            // Process the data and set chartConfiguration
            this.chartConfiguration = this.processChartData(data);
            this.error = undefined; 
            if (this.updateChart) { 
                this.template.querySelector('c-gen-chart').setChartConfig(this.chartConfiguration);
                this.updateChart = false;
            }
        }
    }

    processChartData(data) {
        // Code to process the data and create the chartConfiguration
        let chartScheduleCost = [];
        let chartLabel = [];
        data.forEach(sched => {
            chartScheduleCost.push(sched.scheduleCost);
            chartLabel.push(sched.algorithmName);
        });

        return {
            type: 'line',
            data: {
                datasets: [{
                    label: 'Schedule Cost',
                    backgroundColor: [
                        'rgb(119, 185, 242, 0.3)',
                        'rgb(195, 152, 245, 0.3)',
                        'rgb(78, 212, 205, 0.3)'
                      ],
                    data: chartScheduleCost,
                }
                ],
                labels: chartLabel,
            },
            options: {
                scales: {
                    yAxes: [{
                        ticks: {
                            beginAtZero: true
                        }
                    }]
                }
            }
        };
        
    }
}
