@IsTest
private class OndatoAccountExportBatch_Test {
	@TestSetup
	static void setup() {
		OndatoService_Test.setup();
	}

	@IsTest
	static void testBatchExecution() {
		System.runAs(TestUtility.prepareUserForTest(TestUtility.CAPITALICA_USER)) {
			StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
			mock.setStaticResource('ondato_entity_response_mock');
			mock.setStatusCode(200);
			Test.setMock(HttpCalloutMock.class, mock);
			Test.startTest();
			OndatoAccountExportBatch.execute();
			Test.stopTest();
		}

		Assert.areEqual(0, [SELECT Id FROM Log__c].size(), 'Log should not be created');
		Datetime lastExportedDatetime = [SELECT Last_Exported_to_Ondato__c FROM Account].Last_Exported_to_Ondato__c;
		Assert.areEqual(Date.today(), Date.newInstance(lastExportedDatetime.year(), lastExportedDatetime.month(), lastExportedDatetime.day()), 'Last Exported to Ondato date time should be updated');
	}

	@IsTest
	static void testScheduledBatch() {
		String cronExpression = '0 0 0 1 1 ? 2030'; // Run once at midnight on January 1, 2030
		System.runAs(TestUtility.prepareUserForTest(TestUtility.CAPITALICA_USER)) {
			StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
			mock.setStaticResource('ondato_entity_response_mock');
			mock.setStatusCode(200);
			Test.setMock(HttpCalloutMock.class, mock);
			Test.startTest();
			OndatoAccountExportBatch.scheduleBatch(cronExpression);
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