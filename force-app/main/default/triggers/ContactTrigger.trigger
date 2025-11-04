trigger ContactTrigger on Contact (after insert, before Insert, before update, after update) {
    if ((Trigger.isInsert || Trigger.isUpdate) && Trigger.isBefore) {
        Set<Id> setofAccountId = new Set<Id>();
        for(Contact objCon : trigger.new)
            setofAccountId.add(objCon.accountid);
        //Get all account contact related values
        Map<Id,Account> mapofAccIdToContacts = new Map<Id,Account>([Select Id,(Select Id From Contacts) From Account Where Id IN : setofAccountId]);
        List<Account> accList = [SELECT id , Max_no_of_contacts__c From Account where id IN : setOfAccountId];
        for(Account acc : accList ){ 
            for(Contact objCon : trigger.new){
                if(mapofAccIdToContacts.containskey(objCon.accountID) && mapofAccIdToContacts.get(objCon.accountID).Contacts.size() > acc.Max_no_of_contacts__c )
                    objCon.addError('cannot have more than contacts per account');
            }
        }
    }
    
    if ((Trigger.isInsert || Trigger.isUpdate) && Trigger.isAfter) {
        Set<Id> setofAccountId = new Set<Id>();
        for(Contact objCon : trigger.new)
            setofAccountId.add(objCon.accountid);
        
        List<Contact> idtoContactMapActive  = [Select AccountId , Name,Active__c from Contact Where AccountId IN: setofAccountId ];
        map<id,list<Contact>> idToContactListMapActive = new map <id, List<contact>>();
        map<id,list<Contact>> idToContactListMapInActive = new map <id, List<contact>>();
        if(!idtoContactMapActive.isEmpty())
            for(Contact conobj : idtoContactMapActive){
                if(conobj.Active__c == True){ 
                    if(idToContactListMapActive.containsKey(conObj.accountid)){
                        idToContactListMapActive.get(conObj.AccountId).add(conObj);
                    }
                    else{
                        // this is the way to add the contact to the list of the map 
                        idToContactListMapActive.put(conObj.AccountId,new List<Contact>{conObj}); //important 
                    }
                }
                else{
                    if(idToContactListMapInActive.containsKey(conObj.accountid)){
                        idToContactListMapInActive.get(conObj.AccountId).add(conObj);
                    }
                    else{
                        // this is the way to add the contact to the list of the map 
                        idToContactListMapInActive.put(conObj.AccountId,new List<Contact>{conObj}); //important 
                    }
                }
            }
        
        list<Account> accList = [Select id , name ,Active_Contacts__c , inactive__c from Account where id IN: setofAccountId];
        if(!accList.isEmpty())
            for(Account accObj : accList )
        {   
            if(idToContactListMapActive.keySet() != null && idToContactListMapActive.get(accObj.id) != null )
                accObj.Active_Contacts__c = idToContactListMapActive.get(accObj.id).size();
            if(idToContactListMapInActive.keySet() != null && idToContactListMapInActive.get(accObj.id) != null)
                accObj.InActive__c = idToContactListMapInActive.get(accObj.id).size();
        }
        update accList;
    }
}