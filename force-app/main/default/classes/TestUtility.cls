@TestVisible
@IsTest
private class TestUtility {

	@TestVisible
	static final String CAPITALICA_USER = 'Capitalica User';

	@TestVisible
	static User prepareUserForTest(String profileName) {
		return prepareUserForTest(profileName, new List<String>());
	}

	@TestVisible
	static User prepareUserForTest(String profileName, List<String> assignedPermissionSets) {
		Id profileId = [SELECT Id FROM Profile WHERE Name = :profileName].Id;
		Id roleId = [SELECT Id FROM UserRole WHERE DeveloperName = 'Capitalica_Lithuania'].Id;
		User user = new User(
				Alias = 'test',
				Email = 'tester@test.com',
				EmailEncodingKey = 'UTF-8',
				LastName = 'Testing',
				LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'lt',
				ProfileId = profileId,
				UserRoleId = roleId,
				TimeZoneSidKey = 'Europe/Helsinki',
				Username = 'test@bunny.com');

		Database.insert(user);

		List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();
		for (PermissionSet permissionSet : [SELECT Id FROM PermissionSet WHERE Name IN :assignedPermissionSets]) {
			permissionSetAssignments.add(new PermissionSetAssignment(
					AssigneeId = user.Id,
					PermissionSetId = permissionSet.Id));
		}
		Database.insert(permissionSetAssignments);

		return user;
	}

	/* Opportunity.Investment_Type__c field was deprecated on 2024-10-01. It has been replaced by Opportunity.Product__c.
	@TestVisible
	static List<String> getInvestmentTypesPicklistValues() {
		Schema.DescribeSObjectResult opportunityDescribe = Opportunity.SObjectType.getDescribe();

		Schema.DescribeFieldResult fieldDescribe = opportunityDescribe.fields.getMap().get('Investment_Type__c').getDescribe();
		List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();

		List<String> picklistValues = new List<String>();
		for (Schema.PicklistEntry entry : picklistEntries) {
			if(entry.isActive()) {
				picklistValues.add(entry.getValue());
			}
		}

		return picklistValues;
	}*/
}