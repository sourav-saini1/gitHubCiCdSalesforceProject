/*public class ObjectUploadingComponentBatch implements Database.Batchable<Map<String, String>>, Database.Stateful {
private List<Map<String, String>> inputData;
private String objectFieldSetName;
private String insertObjectName;
private String jobId;

private Integer successCount = 0;
private Integer errorCount = 0;
private List<Map<String, Object>> failedRecords = new List<Map<String, Object>>(); // Changed to Map<String, Object> for field values + error message
private List<Map<String, Object>> successRecords = new List<Map<String, Object>>(); // Changed to Map<String, Object> for field values

public ObjectUploadingComponentBatch(List<Map<String, String>> data, String objectFieldSetName, String insertObjectName) {
this.inputData = data;
this.objectFieldSetName = objectFieldSetName;
this.insertObjectName = insertObjectName;
}

public Iterable<Map<String, String>> start(Database.BatchableContext bc) {
jobId    = bc.getJobId();  

return inputData;
}

public void execute(Database.BatchableContext bc, List<Map<String, String>> scope) {
List<SObject> recordsToInsert = new List<SObject>();

try {
Map<String, Schema.SObjectField> fieldSetMap = getFieldSetMap(insertObjectName, objectFieldSetName);
for (Map<String, String> objData : scope) {
SObject record = Schema.getGlobalDescribe().get(insertObjectName).newSObject();
for (String fieldName : objData.keySet()) {
if (fieldSetMap.containsKey(fieldName)) {
Schema.SObjectField field = fieldSetMap.get(fieldName);
Schema.DisplayType fieldType = field.getDescribe().getType();
String value = objData.get(fieldName);

if (value != null && value != '') {
if (fieldType == Schema.DisplayType.String) {
record.put(fieldName, value);
} else if (fieldType == Schema.DisplayType.Boolean) {
record.put(fieldName, Boolean.valueOf(value));

} else if (fieldType == Schema.DisplayType.Integer) {
record.put(fieldName, Integer.valueOf(value));

} else if (fieldType == Schema.DisplayType.Double || fieldType == Schema.DisplayType.Currency) {
record.put(fieldName, Decimal.valueOf(value));
} else if (fieldType == Schema.DisplayType.Date) {
record.put(fieldName, Date.valueOf(value));
} else if (fieldType == Schema.DisplayType.DateTime) {
record.put(fieldName, DateTime.valueOf(value));
} else if (fieldType == Schema.DisplayType.Long) {
record.put(fieldName, Long.valueOf(value));
} else {
record.put(fieldName, value);

}


}
}
}
recordsToInsert.add(record);
}

Database.SaveResult[] saveResults = Database.insert(recordsToInsert, false);
//successCount += recordsToInsert.size();

for (Integer i = 0; i < saveResults.size(); i++) {
Database.SaveResult result = saveResults[i];
Map<String, Object> recordData = scope.get(i);

if (result.isSuccess()) {
recordData.put('Id', result.getId()); 
successRecords.add(recordData);
successCount++;
} else {
Map<String, Object> failedRecordMap = recordData.clone();
failedRecordMap.put('ErrorMessage', result.getErrors()[0].getMessage());
failedRecords.add(failedRecordMap);
errorCount++;
}
}

} catch (DmlException e) {
System.debug(e.getNumDml());
for (Integer i = 0; i < e.getNumDml(); i++) {
SObject failedRecord = recordsToInsert[e.getDmlIndex(i)];
Map<String, Object> failedRecordMap = new Map<String, Object>();
failedRecordMap.put('ErrorMessage', e.getMessage());
failedRecords.add(failedRecordMap);

errorCount++;
}
}
}


public void finish(Database.BatchableContext bc) {
Batch_Result_Log__c resultLog = new Batch_Result_Log__c(
Total_Records_Count__c = String.valueOf(inputData.size()),
Success_Records_Count__c = String.valueOf(successCount),
Failed_Records_Count__c = String.valueOf(errorCount),
Sobject__c = insertObjectName,
User_Id__c = UserInfo.getUserId(),
Creation_Date_Time__c = System.Now(),
jobId__c = jobId 
);
insert resultLog;

String successJson = JSON.serialize(successRecords);
String failedJson = JSON.serialize(failedRecords);

ContentVersion successContentVersion = new ContentVersion(
Title = 'Success Records',
PathOnClient = 'success_records.json',
VersionData = Blob.valueOf(successJson),
FirstPublishLocationId = resultLog.Id
);
insert successContentVersion;

ContentVersion failedContentVersion = new ContentVersion(
Title = 'Failed Records',
PathOnClient = 'failed_records.json',
VersionData = Blob.valueOf(failedJson),
FirstPublishLocationId = resultLog.Id
);
insert failedContentVersion;

}


private static Map<String, Schema.SObjectField> getFieldSetMap(String objectName, String fieldSetName) {
Map<String, Schema.SObjectField> fieldMap = new Map<String, Schema.SObjectField>();
Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
if (sObjectType == null) {
throw new AuraHandledException('Object ' + objectName + ' does not exist.');
}
Schema.FieldSet fieldSet = sObjectType.getDescribe().fieldSets.getMap().get(fieldSetName);
if (fieldSet == null) {
throw new AuraHandledException('Field set ' + fieldSetName + ' does not exist on object ' + objectName);
}
for (Schema.FieldSetMember field : fieldSet.getFields()) {
fieldMap.put(field.getFieldPath(), field.getSObjectField());
}
return fieldMap;
}
}*/

public class ObjectUploadingComponentBatch implements Database.Batchable<Map<String, String>>, Database.Stateful {
    private List<Map<String, String>> inputData;
    private String objectFieldSetName;
    private String insertObjectName;
    private String jobId;
    
    private Integer successCount = 0;
    private Integer errorCount = 0;
    
    private List<Map<String, Object>> failedRecords = new List<Map<String, Object>>();
    private List<Map<String, Object>> successRecords = new List<Map<String, Object>>();
    
    private Map<String, Schema.SObjectField> fieldSetMap;
    
    public ObjectUploadingComponentBatch(List<Map<String, String>> data, String objectFieldSetName, String insertObjectName) {
        this.inputData = data;
        this.objectFieldSetName = objectFieldSetName;
        this.insertObjectName = insertObjectName;
    }
    
    public Iterable<Map<String, String>> start(Database.BatchableContext bc) {
        jobId = bc.getJobId();
        fieldSetMap = getFieldSetMap(insertObjectName, objectFieldSetName); // cache once
        return inputData;
    }
    
    public void execute(Database.BatchableContext bc, List<Map<String, String>> scope) {
        List<SObject> recordsToInsert = new List<SObject>();
        Map<Integer, Map<String, String>> indexToInputData = new Map<Integer, Map<String, String>>();
        
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(insertObjectName);
        if (sObjectType == null) return;
        
        for (Integer i = 0; i < scope.size(); i++) {
            Map<String, String> objData = scope[i];
            SObject record = sObjectType.newSObject();
            
            for (String fieldName : objData.keySet()) {
                if (!fieldSetMap.containsKey(fieldName)) continue;
                
                Schema.SObjectField field = fieldSetMap.get(fieldName);
                String value = objData.get(fieldName);
                if (String.isBlank(value)) continue;
                
                try {
                    record.put(fieldName, parseValueByType(field.getDescribe().getType(), value));
                } catch (Exception e) {
                    Map<String, Object> errorMap = new Map<String, Object>();
                    
                    for (String key : objData.keySet()) {
                        errorMap.put(key, objData.get(key));
                    } 
                    //  errorMap = new Map<String, Object>(objData);
                    //  errorMap.put('ErrorMessage', 'Parsing Error: ' + e.getMessage());
                    failedRecords.add(errorMap);
                    errorCount++;
                    record = null;
                    break; // skip inserting this record
                }
            }
            
            if (record != null) {
                recordsToInsert.add(record);
                indexToInputData.put(recordsToInsert.size() - 1, objData);
            }
        }
        
        if (!recordsToInsert.isEmpty()) {
            Database.SaveResult[] saveResults = Database.insert(recordsToInsert, false);
            for (Integer i = 0; i < saveResults.size(); i++) {
                Map<String, String> originalData = indexToInputData.get(i);
                Map<String, Object> recordMap = new Map<String, Object>();
                
                for (String key : originalData.keySet()) {
                    recordMap.put(key, originalData.get(key));
                } 
                
                if (saveResults[i].isSuccess()) {
                    recordMap.put('Id', saveResults[i].getId());
                    successRecords.add(recordMap);
                    successCount++;
                } else {
                    recordMap.put('ErrorMessage', saveResults[i].getErrors()[0].getMessage());
                    failedRecords.add(recordMap);
                    errorCount++;
                }
            }
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        Batch_Result_Log__c resultLog = new Batch_Result_Log__c(
            Total_Records_Count__c = String.valueOf(inputData.size()),
            Success_Records_Count__c = String.valueOf(successCount),
            Failed_Records_Count__c = String.valueOf(errorCount),
            Sobject__c = insertObjectName,
            User_Id__c = UserInfo.getUserId(),
            Creation_Date_Time__c = System.Now(),
            jobId__c = jobId
        );
        insert resultLog;
        
        insertContentVersion('Success Records', 'success_records.json', successRecords, resultLog.Id);
        insertContentVersion('Failed Records', 'failed_records.json', failedRecords, resultLog.Id);
    }
    
    private static Object parseValueByType(Schema.DisplayType type1, String value) {
        switch on type1 {
            when String         { return value; }
            when Boolean        { return Boolean.valueOf(value); }
            when Integer        { return Integer.valueOf(value); }
            when Double,
                Currency       { return Decimal.valueOf(value); }
            when Date           { return Date.valueOf(value); }
            when DateTime       { return DateTime.valueOf(value); }
            when Long           { return Long.valueOf(value); }
            when else {return value; } 
        }
    }
    
    public static void insertContentVersion(String title, String fileName, List<Map<String, Object>> data, Id parentId) {
        String json = JSON.serialize(data);
        ContentVersion version = new ContentVersion(
            Title = title,
            PathOnClient = fileName,
            VersionData = Blob.valueOf(json),
            FirstPublishLocationId = parentId
        );
        insert version;
    }
    
    public static Map<String, Schema.SObjectField> getFieldSetMap(String objectName, String fieldSetName) {
        Map<String, Schema.SObjectField> fieldMap = new Map<String, Schema.SObjectField>();
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
        if (sObjectType == null) throw new AuraHandledException('Object ' + objectName + ' does not exist.');
        
        Schema.FieldSet fieldSet = sObjectType.getDescribe().fieldSets.getMap().get(fieldSetName);
        if (fieldSet == null) throw new AuraHandledException('Field set ' + fieldSetName + ' does not exist.');
        
        for (Schema.FieldSetMember field : fieldSet.getFields()) {
            fieldMap.put(field.getFieldPath(), field.getSObjectField());
        }
        return fieldMap;
    }
}