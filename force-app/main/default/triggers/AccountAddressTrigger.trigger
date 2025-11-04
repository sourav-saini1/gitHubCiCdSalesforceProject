trigger AccountAddressTrigger on Account (before insert, before update) {
	for(account a : Trigger.New){
        If(a.Match_Billing_Address__c == true	){
				a.ShippingPostalCode = a.BillingPostalCode;
        	}
    }
}