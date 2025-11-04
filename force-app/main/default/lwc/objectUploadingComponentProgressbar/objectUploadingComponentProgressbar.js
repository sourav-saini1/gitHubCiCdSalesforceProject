import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getBatchJobStatus from '@salesforce/apex/ObjectUploadingComponent.getBatchJobStatus';
import getFileData from '@salesforce/apex/ObjectUploadingComponent.getFileData';
import getRecordsDataInserted from '@salesforce/apex/ObjectUploadingComponent.getRecordsDataInserted';

export default class objectUploadingComponentProgressBar extends LightningElement {
    @api jobId;
    @track isLoading = false;
    @track isJobCompleted = false;
    @track successCount = 0;
    @track failedCount = 0;
    @track totalBatch = 0;
    @track successRecordCount = 0;
    @track failedRecordCount = 0;
    @track totalRecordCount = 0;

    @track jobStatus;

    get progressPercentage() {
        return Math.floor((this.successCount + this.failedCount) / this.totalBatch * 100);
    }

    get progressBarStyle() {
        return `width: ${this.progressPercentage}%;`;
    }

    connectedCallback() {
        if (this.jobId) {
            this.checkBatchJobStatus();
        }
    }

    checkBatchJobStatus() {
        this.isLoading = true;
        getBatchJobStatus({ jobId: this.jobId })
            .then((result) => {
                console.log('38 -- '+result.status);
                if (result.status === 'Completed') {
                    this.isLoading = false;
                    this.isJobCompleted = true;
                    this.successCount = result.itemsProcessed;
                    this.failedCount = result.numberOfErrors;
                    this.totalBatch = result.totalItems;
                    this.jobStatus = result.status;
                    this.checkBatchLogresult();
                } else if (result.status === 'Failed') {
                    this.isLoading = false;
                    this.isJobCompleted = true;
                    this.successCount = result.itemsProcessed;
                    this.failedCount = result.numberOfErrors;
                    this.totalBatch = result.totalItems;
                    this.jobStatus = result.status;
                    this.checkBatchLogresult();
                    this.showToast('Error', 'Batch job failed', 'error');
                } else {
                    this.successCount = result.itemsProcessed;
                    this.failedCount = result.numberOfErrors;
                    this.totalBatch = result.totalItems;
                    setTimeout(() => {
                        this.checkBatchJobStatus();
                    }, 10000);
                }
            })
            .catch((error) => {
                this.isLoading = false;
                this.showToast('Error', 'Error fetching batch job status', 'error');
                console.error('Error in checkBatchJobStatus:', error);
            });
    }

    checkBatchLogresult() {
        getRecordsDataInserted({ jobId: this.jobId })
            .then((result) => {
                this.isLoading = false;
                this.isJobCompleted = true;
                this.successRecordCount = result.successRecordsCount;
                this.failedRecordCount = result.failedRecordsCount;
                this.totalRecordCount = result.totalRecordsCount;
                this.jobStatus = result.status;
            })
            .catch((error) => {
                this.isLoading = false;
                this.showToast('Error', 'Error fetching batch job status', 'error');
                console.error('Error in checkBatchJobStatus:', error);
            });

    }

    handleDownload(event) {
        const fileType = event.target.dataset.type; // 'success' or 'failed'
        this.downloadFile(fileType);
    }

    downloadFile(fileType) {
        getFileData({ fileType: fileType, jobId: this.jobId })
            .then((base64Data) => {
                const decodedData = atob(base64Data); // Decode Base64 to raw string

                // Parse the JSON data
                let jsonData;
                try {
                    jsonData = JSON.parse(decodedData);
                } catch (error) {
                    this.showToast('Error', 'Failed to parse file data', 'error');
                    console.error('Error in JSON parsing:', error);
                    return;
                }

                // Convert JSON to CSV
                const csvData = this.convertJSONToCSV(jsonData);

                // Download CSV
                this.downloadCSV(csvData, `${fileType}_records.csv`);
            })
            .catch((error) => {
                this.showToast('Error', `Error downloading ${fileType} file`, 'error');
                console.error('Error in downloadFile:', error);
            });
    }

    convertJSONToCSV(jsonData) {
        if (!jsonData || jsonData.length === 0) {
            this.showToast('Error', 'No data to convert to CSV', 'error');
            return '';
        }

        const keys = Object.keys(jsonData[0]);
        const csvRows = [
            keys.join(','), // Header row
            ...jsonData.map((row) =>
                keys.map((key) => `"${row[key] || ''}"`).join(',')
            ),
        ];
        return csvRows.join('\n');
    }

    downloadCSV(csvData, fileName) {
        console.log('csvData' + csvData);
        console.log('fileName' + fileName);

        try {

            const downloadElement = document.createElement('a');
            downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvData);
            downloadElement.target = '_self';
            downloadElement.download = fileName;
            document.body.appendChild(downloadElement);
            downloadElement.click();
            document.body.removeChild(downloadElement); // Clean up

            /*      const blob = new Blob([csvData], { type: 'text/csv;charset=utf-8;' });
                    const link = document.createElement('a');
                    link.href = URL.createObjectURL(blob);
                    link.download = fileName;
                    document.body.appendChild(link);
                    link.click();
                    document.body.removeChild(link); // Clean up*/
        } catch (error) {
            this.showToast('Error', 'Error in downloading CSV file', 'error');
            console.error('Error in downloadCSV:', error);
        }
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(evt);
    }
}