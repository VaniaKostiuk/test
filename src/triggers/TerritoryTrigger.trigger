trigger TerritoryTrigger on Territory__c (before insert, after insert) {
    
    if(Trigger.isInsert){
    	if(Trigger.isBefore){
        	Set<Id> parentTerritoryIds =new Set<Id>();
        	for(Territory__c terr : Trigger.new){
            	if(terr.Parent_Territory__c != null){
                    parentTerritoryIds.add(terr.Parent_Territory__c);
            	}
    		}
        Map<Id, Territory__c> parentTerritoryMap =new Map<Id, Territory__c>([SELECT Id, Unique_Name__c FROM Territory__c WHERE Id IN: parentTerritoryIds]);
        for(Territory__c terr : Trigger.new){
            if(terr.Parent_Territory__c != null){
                terr.Unique_Name__c = parentTerritoryMap.get(terr.Parent_Territory__c).Unique_Name__c + '_'+ terr.Name;
            }
            else{
                terr.Unique_Name__c = terr.Name;
            }
    	}
    }
    
    if(Trigger.isAfter){
    	Map<String, List<Group>> territoryGroupMap = new Map<String, List<Group>>();
    	for(Territory__c terr : Trigger.new){
            String parent = terr.Parent_Territory__c == null ? 'TOP' : terr.Parent_Territory__c;
            List<Group> groups = territoryGroupMap.get(parent);
            if(groups == null){
                groups = new List<Group>();
                territoryGroupMap.put(parent, groups);
            }
            groups.add(new Group(Name = terr.Unique_Name__c, DeveloperName = terr.Unique_Name__c, Type = 'Regular'));
    	}
        for(Territory__c parentTerritory : [SELECT Id, Unique_Name__c FROM Territory__c WHERE Id IN: territoryGroupMap.keySet() AND Unique_Name__c != 'TOP']){
            territoryGroupMap.put(parentTerritory.Unique_Name__c, territoryGroupMap.remove(parentTerritory.Id));
        }
        for(Group parentGroup : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN: territoryGroupMap.keySet() AND DeveloperName != 'TOP']){
            territoryGroupMap.put(parentGroup.Id, territoryGroupMap.remove(parentGroup.DeveloperName));
        }

        List<Group> territoryGroup = new List<Group>();
        for(List<Group> groups : territoryGroupMap.values()){
            territoryGroup.addAll(groups);
        }
        insert territoryGroup;

        Set<String> compositeIds = new Set<String>();
        for(String groupId : territoryGroupMap.keySet()){
            if(groupId == 'TOP'){
                continue;
            }
            for(Group gr : territoryGroupMap.get(groupId)){
                compositeIds.add(gr.Id+ '_'+ groupId);
            }
        }
        TerritoryManagementUtil.addGroupMembers(compositeIds);
    }
    }

}