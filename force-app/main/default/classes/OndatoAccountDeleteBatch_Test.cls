@IsTest
private class OndatoAccountDeleteBatch_Test {

	@TestSetup
	static void setup() {
		OndatoService_Test.setup();
		Account account = [SELECT Id FROM Account LIMIT 1];
		account.Stage__c = 'Closed';
		Database.update(account, AccessLevel.SYSTEM_MODE);
	}

	@IsTest
	static void testBatchExecution() {
		System.runAs(TestUtility.prepareUserForTest(TestUtility.CAPITALICA_USER)) {
			Test.setMock(HttpCalloutMock.class, new CalloutTestUtility.SingleHttpMock(200, ''));
			Test.startTest();
			OndatoAccountDeleteBatch.execute();
			Test.stopTest();
		}

		Assert.areEqual(1, [SELECT Id FROM Account WHERE Ondato_Id__c = NULL].size(), 'Account Ondato Id should be removed');
		Assert.areEqual(0, [SELECT Id FROM Log__c].size(), 'Log should not be created');
	}

	@IsTest
	static void testScheduledBatch() {
		String cronExpression = '0 0 0 1 1 ? 2030'; // Run once at midnight on January 1, 2030
		System.runAs(TestUtility.prepareUserForTest(TestUtility.CAPITALICA_USER)) {
			Test.setMock(HttpCalloutMock.class, new CalloutTestUtility.SingleHttpMock(200, ''));
			Test.startTest();
			OndatoAccountDeleteBatch.scheduleBatch(cronExpression);
			Test.stopTest();
		}

		CronTrigger ct = [
				SELECT Id, CronExpression, TimesTriggered, NextFireTime
				FROM CronTrigger
				WHERE CronExpression = :cronExpression
		];
		Assert.areEqual(cronExpression, ct.CronExpression, 'Cron expression should match');
	}
}