@IsTest
private class OndatoAmlMatchHistoryHandler_Test {

	@TestSetup
	static void setup() {
		OndatoService_Test.setup();
	}

	@IsTest
	private static void handleChangeEvent() {
		Ondato_AML_Match__c amlMatch = new Ondato_AML_Match__c(
				Name = '001',
				Match_ID__c = '001',
				Match_Name__c = 'Test Tester',
				Status__c = 'Open',
				Account__c = [SELECT Id FROM Account].Id
		);
		Database.insert(amlMatch);
		Assert.areEqual(1, [SELECT Id FROM Ondato_AML_Match_History__c].size(), '1 AML match history should be created');
	}
}