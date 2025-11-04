import { LightningElement, wire } from 'lwc';
import { api, track } from 'lwc';
import PARSER from '@salesforce/resourceUrl/PapaParser';
import getFieldSet from "@salesforce/apex/ObjectUploadingComponent.getFieldSet";
import { loadScript } from 'lightning/platformResourceLoader';
import createRecordForObjects from '@salesforce/apex/ObjectUploadingComponent.createRecordForObjects';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { FlowNavigationFinishEvent, FlowNavigationNextEvent } from "lightning/flowSupport";


export default class ObjectUploadingComponent extends LightningElement {
    @api ObjectName;
    @api FieldSetName;
    @api recordId;
    
    parserInitialized = false;

    @track message = '';
    @track messageVisible = false;
    messageClass = '';
    iconName = '';
    @track jobIdToReturn;
    @track jobIdToReturnTrue = false;

    get acceptedFormats() {
        return ['.csv'];
    }

    renderedCallback() {
        if (!this.parserInitialized) {
            loadScript(this, PARSER)
                .then(() => {
                    this.parserInitialized = true;
                })
                .catch(error => console.error(error));
        }
    }

    handleDownload(event) {
        getFieldSet({ fieldSetName: this.FieldSetName, objectName: this.ObjectName })
            .then((fields) => {
                if (!fields || fields.length === 0) {
                    throw new Error('No fields found in the specified field set.');
                }

                const fieldNames = fields.map(field => field.apiName);
                const fieldTypes = fields.map(field => field.type); // Now includes the field type
                console.log('Fields:', JSON.stringify(fields));
                console.log('Field Names:', JSON.stringify(fieldNames));

                // Build the CSV string
                let csvString = fieldNames.join(',') + '\n'; // Header row

                // Create a dynamic record based on field types
                const record = {};
                fieldNames.forEach((fieldName, index) => {
                    record[fieldName] = this.getTestValueByType(fieldTypes[index]); // Use the correct type
                });

                // Create the CSV row for the record
                const row = fieldNames.map(field => record[field] || '').join(',');
                csvString += row;

                console.log('CSV String:', csvString);
                console.log(this.ObjectName + 'DataUpload.csv');
                // Creating anchor element to download
                const downloadElement = document.createElement('a');
                downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvString);
                downloadElement.target = '_self';
                downloadElement.download = this.ObjectName + 'DataUpload.csv';
                document.body.appendChild(downloadElement);
                downloadElement.click();
                document.body.removeChild(downloadElement); // Clean up
                this.showToast('Success', 'CSV Generated SuccessFully', 'success'); // Show toast



            })
            .catch((error) => {
                console.error('Error fetching field set or generating CSV:', error);
                this.showToast('Error', `Failed to generate CSV: ${error.message}`, 'error');
                this.showToast('Error', `Failed to generate CSV: ${error.message}`, 'error');

            });
    }

    handleInputChange(event) {
        if (event.detail.files.length > 0) {
            const file = event.detail.files[0];
            console.log('File - ' + JSON.stringify(file));
            if (file.type === 'text/csv') {
                Papa.parse(file, {
                    quoteChar: '"',
                    header: true,
                    complete: (results) => {
                        let filteredData = results.data.filter(row => {
                            return Object.values(row).some(value => value && value.trim() !== ""); // Filter out empty rows
                        });

                        console.log('Filtered Data: ', JSON.stringify(filteredData));

                        if (filteredData.length > 0) {

                            console.log('Transformed Data:', JSON.stringify(filteredData));
                            console.log('PO RECORD ID',this.recordId);
                            createRecordForObjects({
                                objectList: filteredData,
                                objectFieldSetName: this.FieldSetName,
                                insertObjectName: this.ObjectName,
                                recordid: this.recordId,
                            })
                                .then((result) => {
                                    if (result.isError === false) {
                                        this.jobIdToReturn = result.jobId;

                                        setTimeout(() => {
                                        this.jobIdToReturnTrue = true;
                                        }, 5000);
                                        this.showMessage('Success', result.message, 'success');
                                        this.showToast('Success', result.message, 'success');

                                    } else {
                                        this.showMessage('Error', result.message, 'error');
                                        this.showToast('Error', result.message, 'error');
                                    }
                                })
                                .catch((error) => {
                                    console.error('Error:', error);
                                    this.showToast('Error', error.message, 'error');
                                });
                        } else {
                            this.showToast('Error', 'The uploaded file contains no valid data.', 'error');
                        }
                    },
                    error: (error) => {
                        this.showToast('Error', `Parsing error: ${error.message}`, 'error');
                    }
                });
            } else {
                this.showToast('Warning', 'Please upload a .csv file. The current file type is: ' + file.type, 'warning');
            }
        }
    }


    //Handle Parsing of the Data
    handleParsedData(data) {

        let rdData = [];
        let lastElement = false;
        if (this.checkValue(data)) {
            for (let i = 0; i < (data.length); i++) {
                if (this.checkValue(data[i]) == false) {
                    break
                }
                if (data[i].length > 0) {
                    const lastIndex = data[i].length - 1;
                    data[i][lastIndex] = data[i][lastIndex].replace(/\s+$/, '');
                }

                rdData.push(data[i]);

            }
        }
        console.log(JSON.stringify(rdData));
        return rdData;
    }

    handleNext() {
        if (this.availableActions.find((action) => action === "NEXT")) {
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
        }
        else if (this.availableActions.find((action) => action === "FINISH")) {
            const navigateNextEvent = new FlowNavigationFinishEvent();
            this.dispatchEvent(navigateNextEvent);
        }
    }

    checkValue(data) {
        if (data != undefined && data != null && data != '') {
            return true;
        } else {
            return false;
        }
    }

    getTestValueByType(fieldType) {
        switch (fieldType) {
            case 'STRING':
                return 'TestData'; // Example for String type
            case 'TEXTAREA':
                return 'TestData'; // Example for String type
            case 'BOOLEAN':
                return 'TRUE'; // Example for Boolean type
            case 'DATE':
                return '2024-09-26'; // Example for Date type
            case 'DATETIME':
                return '2024-09-26T12:00:00Z'; // Example for DateTime type
            case 'CURRENCY':
                return '100.00'; // Example for Currency type
            case 'INTEGER':
                return '123'; // Example for Integer type
            case 'REFERENCE':
                return '0xxxxxxxxxxxxx'

            // Add more cases as needed for different field types
            default:
                return ''; // Default to an empty string if type is unknown
        }
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }


    showMessage(title, msg, type) {
        this.message = msg;
        this.messageVisible = true;

        switch (type) {
            case 'success':
                this.messageClass = 'slds-notify slds-notify_alert slds-theme_success';
                this.iconName = 'utility:success';
                break;
            case 'error':
                this.messageClass = 'slds-notify slds-notify_alert slds-theme_error';
                this.iconName = 'utility:error';
                break;
            case 'warning':
                this.messageClass = 'slds-notify slds-notify_alert slds-theme_warning';
                this.iconName = 'utility:warning';
                break;
            case 'info':
                this.messageClass = 'slds-notify slds-notify_alert slds-theme_info';
                this.iconName = 'utility:info';
                break;
            default:
                this.messageClass = '';
                this.iconName = '';
                break;
        }

        // Hide message after a few seconds
        setTimeout(() => {
            this.messageVisible = false;
            this.message = '';
        }, 10000); // Adjust duration as needed
    }


}