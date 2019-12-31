public with sharing class TerritoryTriggerHelper {

    @future
    public static void addGroupMembers(Set<String> compositeIds){
        List<GroupMember> groupMembers = new List<GroupMember>();
        for(String compositeId : compositeIds){
            List<String> groupIdMemberId = compositeId.split('_');
            groupMembers.add(new GroupMember(GroupId = groupIdMemberId[0], UserOrGroupId = groupIdMemberId[1]));
        }
        insert groupMembers;
    }

    @future
    public static void deleteGroupMembers(Set<String> compositeIds){
        Map<String, Set<String>> membersByGroupMap = new Map<String, Set<String>>();
        Set<String> allMembers = new Set<String>();
        for(String compositeId : compositeIds){
            List<String> splitedIds = compositeId.split('_');
            Set<String> members = membersByGroupMap.get(splitedIds[0]);
            if(members == null){
                members = new Set<String>();
                membersByGroupMap.put(splitedIds[0], members);
            }
            members.add(splitedIds[1]);
            allMembers.add(splitedIds[1]);
        }
        List<GroupMember> membersToRemove = new List<GroupMember>();
        for(GroupMember gm : [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE UserOrGroupId IN: allMembers AND GroupId IN: membersByGroupMap.keySet()]){
            Set<String> members = membersByGroupMap.get(gm.GroupId);
            if(members != null && members.contains(gm.UserOrGroupId)){
                membersToRemove.add(gm);
            }
        }
        delete  membersToRemove;
    }

}