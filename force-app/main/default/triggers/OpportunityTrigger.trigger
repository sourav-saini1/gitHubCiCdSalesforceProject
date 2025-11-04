trigger OpportunityTrigger on Opportunity (after insert , after update ) {
    opportunityShare oppshare = new opportunityShare();
    for(Opportunity opp : Trigger.new){
        oppshare.OpportunityId = opp.id;
        oppshare.UserOrGroupId = opp.user_to_Share__c;
        oppshare.OpportunityAccessLevel = 'Read';
        System.debug(oppshare.OpportunityAccessLevel);
        System.debug(oppshare.UserOrGroupId);
    }
    insert oppshare;
}