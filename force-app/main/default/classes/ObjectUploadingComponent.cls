public class ObjectUploadingComponent {
    @AuraEnabled
    public static Map<String, Object> getRecordsDataInserted(String jobId) {
        Map<String, Object> batchLogmap = new Map<String, Object>();
        
        List<Batch_Result_Log__c> batchJobList = [
            SELECT Failed_Records_Count__c, Success_Records_Count__c, Total_Records_Count__c, jobId__c 
            FROM Batch_Result_Log__c 
            WHERE jobId__c = :jobId 
            LIMIT 1
        ];
        if(!batchJobList.isEmpty()){
            Batch_Result_Log__c job = batchJobList[0];
            batchLogmap.put('failedRecordsCount', job.Failed_Records_Count__c);
            batchLogmap.put('successRecordsCount', job.Success_Records_Count__c);
            batchLogmap.put('totalRecordsCount', job.Total_Records_Count__c);
            return batchLogmap;
        }
        
        return null;        
        
    }
    
    @AuraEnabled
    public static String getFileData(String fileType, String jobId) {
        try {
            
            List<Batch_Result_Log__c> batchJob = [
                SELECT Failed_Records_Count__c, Success_Records_Count__c, Total_Records_Count__c, jobId__c 
                FROM Batch_Result_Log__c 
                WHERE jobId__c = :jobId 
                LIMIT 1
            ];
            
            if(!batchJob.isEmpty()){
                ContentVersion conVer = [
                    SELECT VersionData, Title
                    FROM ContentVersion
                    WHERE FirstPublishLocationId = :batchJob[0].id AND Title LIKE :('%' + fileType + '%')
                    LIMIT 1
                ];
                return EncodingUtil.base64Encode(conVer.VersionData);
            }else{
                return null;
            }
            
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching file content: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getBatchJobDetails(String jobId) {
        Map<String, Object> response = new Map<String, Object>();
        try {
            
            List<Batch_Result_Log__c> batchJob = [
                SELECT Failed_Records_Count__c, Success_Records_Count__c, Total_Records_Count__c, jobId__c 
                FROM Batch_Result_Log__c 
                WHERE jobId__c = :jobId 
                LIMIT 1
            ];
            
            if(!batchJob.isEmpty()){
                List<ContentVersion> relatedFiles = [
                    SELECT Id, Title, FileType ,versionData 
                    FROM ContentVersion 
                    where FirstPublishLocationId =: batchJob[0].id
                ];
                
                // Prepare response
                response.put('batchJob', batchJob);
                response.put('files', relatedFiles);
            }
            
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching batch job details: ' + e.getMessage());
        }
        
        return response;
    }
    
    @AuraEnabled
    public static Map<String, Object> getBatchJobStatus(String jobId) {
        Map<String, Object> jobStatusMap = new Map<String, Object>();
        if (jobId == null) {
            return jobStatusMap;
        }
        
        
        List<AsyncApexJob> jobs = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedDate
                                   FROM AsyncApexJob
                                   WHERE Id = :jobId];
        
        if (jobs.isEmpty()) {
            jobStatusMap.put('status', 'Not Found');
            return jobStatusMap;
        }
        
        AsyncApexJob job = jobs[0];
        
        jobStatusMap.put('status', job.Status);
        jobStatusMap.put('numberOfErrors', job.NumberOfErrors);
        jobStatusMap.put('itemsProcessed', job.JobItemsProcessed);
        jobStatusMap.put('totalItems', job.TotalJobItems);
        return jobStatusMap;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<FieldSetField> getFieldSet(String objectName, String fieldSetName) {
        
        if (String.isEmpty(objectName) || String.isEmpty(fieldSetName)) {
            
            throw new IllegalArgumentException('Object name and field set name must not be empty.');
            
        }
        System.debug(objectName);

        Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(objectName).getDescribe();
                System.debug(describeResult);

        Schema.FieldSet fieldSet = describeResult.fieldSets.getMap().get(fieldSetName);
                        System.debug(fieldSet);

        if (fieldSet == null) {
            
            throw new IllegalArgumentException('Field set not found: ' + fieldSetName);
            
        }
        
        List<FieldSetField> fieldSetFields = new List<FieldSetField>();
        
        for (Schema.FieldSetMember field : fieldSet.getFields()) {
            
            Schema.SObjectField sObjectField = describeResult.fields.getMap().get(field.getFieldPath());
            
            Schema.DescribeFieldResult fieldResult = sObjectField.getDescribe();
            
            // Add field details including field type
            fieldSetFields.add(new FieldSetField(field.getFieldPath(), field.getLabel(), fieldResult.getType().name()));   
        }
        // System.debug(fieldSetFields);
        return fieldSetFields;
    }
    
    
    @AuraEnabled
    public static returnData createRecordForObjects(List<Map<String, String>> objectList, String objectFieldSetName, String insertObjectName) {
        returnData thisData = new returnData();
        Set<String> beatCodes = new Set<String>();
        Set<String> employeeCodes = new Set<String>();
        Map<String, String> employeeCodeIdMap = new Map<String, String>();
        try {
            if (objectList == null || objectList.isEmpty()) {
                thisData.isError = true;
                thisData.message = 'No records provided for processing.';
                return thisData;
            }
            ObjectUploadingComponentBatch batch = new ObjectUploadingComponentBatch(objectList, objectFieldSetName, insertObjectName);
            Id batchProcessId = Database.executeBatch(batch, 200); 
            
            thisData.isError = false;
            thisData.message = 'Batch job initiated successfully for inserting records.';
            thisData.jobId = batchProcessId;
        } catch (Exception e) {
            //  System.debug('Error: ' + e.getMessage());
            thisData.isError = true;
            thisData.message = 'Failed to initiate batch job: ' + e.getMessage();
            thisData.jobId ='';
        }
        return thisData;
    }
    
   
    
    public class returnData{
        @AuraEnabled
        public String message;
        @AuraEnabled
        public Boolean isError;
        @AuraEnabled
        public String jobId;
    }
    
    public class FieldSetField {
        @AuraEnabled
        public String apiName { get; set; }
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String type { get; set; }
        
        public FieldSetField(String apiName, String label, String type) {
            this.apiName = apiName;
            this.label = label;
            this.type = type; 
        }
    }    
    
    
}