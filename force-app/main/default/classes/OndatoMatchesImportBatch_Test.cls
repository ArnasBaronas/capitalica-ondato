@IsTest
private class OndatoMatchesImportBatch_Test {
	@TestSetup
	static void setup() {
		OndatoService_Test.setup();
	}

	@IsTest
	static void testBatchExecution() {
		System.runAs(TestUtility.prepareUserForTest(TestUtility.CAPITALICA_USER)) {
			StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
			mock.setStaticResource('ondato_matches_response_mock');
			mock.setStatusCode(200);
			Test.setMock(HttpCalloutMock.class, mock);
			Test.startTest();
			OndatoMatchesImportBatch.execute();
			Test.stopTest();
		}

		Assert.areEqual(0, [SELECT Id FROM Log__c].size(), 'Log should not be created');
		Assert.areEqual(1, [SELECT Id FROM Ondato_AML_Match__c].size(), '1 AML match should be created');
	}

	@IsTest
	static void testScheduledBatch() {
		String cronExpression = '0 0 0 1 1 ? 2030'; // Run once at midnight on January 1, 2030
		System.runAs(TestUtility.prepareUserForTest(TestUtility.CAPITALICA_USER)) {
			StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
			mock.setStaticResource('ondato_matches_response_mock');
			mock.setStatusCode(200);
			Test.setMock(HttpCalloutMock.class, mock);
			Test.startTest();
			OndatoMatchesImportBatch.scheduleBatch(cronExpression);
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