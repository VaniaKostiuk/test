trigger TerrUserTrigger on TerrUser__c (after insert, after delete) {

    if(Trigger.isAfter){
        if(Trigger.isInsert){
            TerritoryManagementUtil.addGroupMembers(TerrUserTriggerHelper.generateGroupMembersIds(Trigger.new));
        }
        if(Trigger.isDelete){
            TerritoryManagementUtil.deleteGroupMembers(TerrUserTriggerHelper.generateGroupMembersIds(Trigger.old));
        }
    }
}