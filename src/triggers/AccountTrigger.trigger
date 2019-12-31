trigger AccountTrigger on Account (after insert, after update) {
    
    if(Trigger.isAfter){
       if(Trigger.isInsert){
            Set<String> parentTerritoryNames = new Set<String>();
            Set<Id> parentTerritoryIds = new Set<Id>();
            for(Account acc : Trigger.new){
                if(acc.Territory__c != null){
                    parentTerritoryIds.add(acc.Territory__c);
                }
            }
            Map<Id, Territory__c> parentTerritoriesMap = new Map<Id, Territory__c>([SELECT Id, Unique_Name__c
                                                                                    FROM Territory__c
                                                                                    WHERE Id IN: parentTerritoryIds]);
            	for(Territory__c terr : parentTerritoriesMap.values()){
                	parentTerritoryNames.add(terr.Unique_Name__c);
            }
            Map<String, Group> groupsByNameMap = new Map<String, Group>();
            	for(Group userGroup : [SELECT Id, DeveloperName
                                       FROM Group 
                                       WHERE DeveloperName IN: parentTerritoryNames]){
                	groupsByNameMap.put(userGroup.DeveloperName, userGroup);
            }
            List<AccountShare> accountSharingList = new List<AccountShare>();
            	for(Account acc : Trigger.new){
                	if(acc.Territory__c != null){
                    	accountSharingList.add(new AccountShare(AccountAccessLevel = 'Edit', 
                                                           		AccountId = acc.Id,
                                                            	RowCause = 'Manual', 
                                                            	UserOrGroupId = groupsByNameMap.get(parentTerritoriesMap.get(acc.Territory__c).Unique_Name__c).Id,
                                                            	OpportunityAccessLevel = 'None')
                                              );
                }
            }
            insert accountSharingList;
    	}
        if(Trigger.isUpdate){
            Map<String,Set<Id>> accountsToAddSharingByTerritory = new Map<String,Set<Id>>();
            Map<String,Set<Id>> accountsToRemoveSharingByTerritory = new Map<String,Set<Id>>();
            for(Account acc : Trigger.new){
                Id oldTerritoryValue = Trigger.oldMap.get(acc.Id).Territory__c;
                if(acc.Territory__c != oldTerritoryValue){
                    if(acc.Territory__c != null) {
                        Set<Id> accountIdsToAdd = accountsToAddSharingByTerritory.get(acc.Territory__c);
                        if (accountIdsToAdd == null) {
                            accountIdsToAdd = new Set<Id>();
                            accountsToAddSharingByTerritory.put(acc.Territory__c, accountIdsToAdd);
                        }
                        accountIdsToAdd.add(acc.Id);
                    }
                    if(oldTerritoryValue != null) {
                        Set<Id> accountIdsToRemove = accountsToRemoveSharingByTerritory.get(oldTerritoryValue);
                        if (accountIdsToRemove == null) {
                            accountIdsToRemove = new Set<Id>();
                            accountsToRemoveSharingByTerritory.put(oldTerritoryValue, accountIdsToRemove);
                        }
                        accountIdsToRemove.add(acc.Id);
                    }
                    }
                }
            Map<Id, Territory__c> territoriesMap = new Map<Id, Territory__c>([SELECT Id, Unique_Name__c FROM Territory__c WHERE Id IN: accountsToAddSharingByTerritory.keySet() OR
                                                                                                Id IN: accountsToRemoveSharingByTerritory.keySet()]);
            for(Id terrId : territoriesMap.keySet()){
                if(accountsToAddSharingByTerritory.containsKey(terrId)){
                    accountsToAddSharingByTerritory.put(territoriesMap.get(terrId).Unique_Name__c, accountsToAddSharingByTerritory.remove(terrId));
                }
                if(accountsToRemoveSharingByTerritory.containsKey(terrId)){
                    accountsToRemoveSharingByTerritory.put(territoriesMap.get(terrId).Unique_Name__c, accountsToRemoveSharingByTerritory.remove(terrId));
                }
            }
            for(Group gr : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN: accountsToAddSharingByTerritory.keySet() OR
                                                                        DeveloperName IN: accountsToRemoveSharingByTerritory.keySet()]){
                if(accountsToAddSharingByTerritory.containsKey(gr.DeveloperName)){
                    accountsToAddSharingByTerritory.put(gr.Id, accountsToAddSharingByTerritory.remove(gr.DeveloperName));
                }
                if(accountsToRemoveSharingByTerritory.containsKey(gr.DeveloperName)){
                    accountsToRemoveSharingByTerritory.put(gr.Id, accountsToRemoveSharingByTerritory.remove(gr.DeveloperName));
                }
            }
            Set<Id> allContacts = new Set<Id>();
            Map<Id, Set<Id>> contactsByAccountMap = new Map<Id, Set<Id>>();
            for(Reference__c ref : [SELECT Id, Account__c, Contact__c FROM Reference__c WHERE Account__c IN: Trigger.new]){
                Set<Id> contactIds = contactsByAccountMap.get(ref.Account__c);
                if(contactIds == null){
                    contactIds = new Set<Id>();
                    contactsByAccountMap.put(ref.Account__c, contactIds);
                }
                contactIds.add(ref.Contact__c);
                allContacts.add(ref.Contact__c);
            }
            List<AccountShare> accountSharesToRemove = new List<AccountShare>();
            List<ContactShare> contactSharesToRemove = new List<ContactShare>();
            Map<Id, ContactShare> contactShareMap = new Map<Id, ContactShare>();
            for(ContactShare cshare : [SELECT Id, ContactId, UserOrGroupId FROM ContactShare WHERE UserOrGroupId IN: accountsToRemoveSharingByTerritory.keySet() AND ContactId IN: allContacts]){
                contactShareMap.put(cshare.ContactId, cshare);
            }
            for(AccountShare share : [SELECT Id, UserOrGroupId, AccountId FROM AccountShare WHERE UserOrGroupId IN: accountsToRemoveSharingByTerritory.keySet()
            AND AccountId IN: Trigger.new]){
                Set<Id> accountIds = accountsToRemoveSharingByTerritory.get(share.UserOrGroupId);
                if(accountIds != null && accountIds.contains(share.AccountId)){
                    accountSharesToRemove.add(share);
                }
                for(Id contactId : contactsByAccountMap.get(share.AccountId)){
                    ContactShare cshare = contactShareMap.get(contactId);
                    if(cshare != null) {
                        contactSharesToRemove.add(cshare);
                    }
                }
            }

            List<AccountShare> accountSharesToAdd = new List<AccountShare>();
            List<ContactShare> contactSharesToAdd = new List<ContactShare>();
            for(String groupId : accountsToAddSharingByTerritory.keySet()){
                for(Id accountId : accountsToAddSharingByTerritory.get(groupId)){
                    accountSharesToAdd.add(new AccountShare(AccountAccessLevel = 'Edit',
                            AccountId = accountId,
                            RowCause = 'Manual',
                            UserOrGroupId = groupId,
                            OpportunityAccessLevel = 'None')
                    );
                    for(Id contactId : contactsByAccountMap.get(accountId)){
                        contactSharesToAdd.add(
                                new ContactShare(ContactAccessLevel = 'Edit',
                                        ContactId = contactId,
                                        RowCause = 'Manual',
                                        UserOrGroupId = groupId
                                )
                        );
                    }
                }
            }
            delete accountSharesToRemove;
            delete contactSharesToRemove;
            insert accountSharesToAdd;
            insert contactSharesToAdd;
            }
    	}
    }