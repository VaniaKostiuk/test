public with sharing class TerrUserTriggerHelper {

    public static Set<String> generateGroupMembersIds(List<TerrUser__c> terrUsers){
        Set<Id> territoryIds = new Set<Id>();
        for(TerrUser__c tu : terrUsers){
            territoryIds.add(tu.Territory__c);
        }
        Map<Id, String> groupNameByTerritoryId = new Map<Id, String>();
        for(Territory__c territory : [SELECT Id, Unique_Name__c FROM Territory__c WHERE Id IN: territoryIds]){
            groupNameByTerritoryId.put(territory.Id, territory.Unique_Name__c);
        }
        Map<String, Group> groupByName = new Map<String, Group>();
        for(Group gr : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN: groupNameByTerritoryId.values()]){
            groupByName.put(gr.DeveloperName, gr);
        }
        Set<String> compositeIds = new Set<String>();
        for(TerrUser__c tu : terrUsers){
            compositeIds.add(groupByName.get(groupNameByTerritoryId.get(tu.Territory__c)).Id+ '_'+ tu.User__c);
        }
        return compositeIds;
    }

}