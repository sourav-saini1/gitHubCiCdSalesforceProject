trigger OrderEventTrigger on Order_Event__e (after insert) {
    List<Task> taskList = New List<Task>();
    For(Order_Event__e orderEvent : Trigger.New){
        if(orderEvent.Has_Shipped__C == true){
            Task tsk = new Task();
            tsk.Priority= 'Medium';
            tsk.Subject= 'Follow up on shipped order 105';
            tsk.OwnerId= orderEvent.CreatedById;
            taskList.add(tsk);
        }
        
    }
    
    if(!taskList.isEmpty()){ 
        insert taskList;
    }
}