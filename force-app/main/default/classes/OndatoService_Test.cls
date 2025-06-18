@TestVisible
@IsTest
private class OndatoService_Test {

	@TestVisible
	@TestSetup
	static void setup() {
		Database.insert(new Ondato_Settings__c(
				Accounts_Delete_Batch_Size__c = 10,
				Accounts_Export_Batch_Size__c = 10,
				Matches_Import_Batch_Size__c = 10,
				Worklist_Id__c = 'WORKLIST_ID'
		));
		Database.insert(new Account(
				Salutation = 'Mr.',
				FirstName = 'Test',
				LastName = 'Tester',
				Stage__c = 'Active_Investing',
				Ondato_Id__c = '09516c2ef15c4ebdaedf3eecb70de86a',
				Last_Exported_to_Ondato__c = Datetime.now().addYears(-1)
		));
	}

	@IsTest
	@SuppressWarnings('PMD.MethodNamingConventions') // method name after underscore represents test scenario
	static void sendAccount_newNaturalEntitySuccess() {
		Account account = [SELECT Id FROM Account];
		account.Last_Exported_to_Ondato__c = null;
		account.Ondato_Id__c = null;
		Database.update(account, AccessLevel.USER_MODE);

		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('ondato_entity_response_mock');
		mock.setStatusCode(200);
		Test.setMock(HttpCalloutMock.class, mock);
		Test.startTest();
		OndatoService.sendAccount(account.Id, true, true);
		Test.stopTest();
		Assert.areEqual(0, [SELECT Id FROM Log__c].size(), 'Log should not be created');
		Assert.isNotNull([SELECT Ondato_Id__c FROM Account].Ondato_Id__c, 'Account Ondato Id should be updated');
		Assert.isNotNull([SELECT Last_Exported_to_Ondato__c FROM Account].Last_Exported_to_Ondato__c, 'Last Exported to Ondato date time should be updated');
	}

	@IsTest
	@SuppressWarnings('PMD.MethodNamingConventions') // method name after underscore represents test scenario
	static void sendAccount_existingNaturalEntitySuccess() {
		Test.setMock(HttpCalloutMock.class, new CalloutTestUtility.SingleHttpMock(200, ''));
		Test.startTest();
		OndatoService.sendAccount([SELECT Id FROM Account].Id, true, true);
		Test.stopTest();
		Assert.areEqual(0, [SELECT Id FROM Log__c].size(), 'Log should not be created');
		Datetime lastExportedDatetime = [SELECT Last_Exported_to_Ondato__c FROM Account].Last_Exported_to_Ondato__c;
		Assert.areEqual(Date.today(), Date.newInstance(lastExportedDatetime.year(), lastExportedDatetime.month(), lastExportedDatetime.day()), 'Last Exported to Ondato date time should be updated');
	}

	@IsTest
	@SuppressWarnings('PMD.MethodNamingConventions') // method name after underscore represents test scenario
	static void sendAccount_newLegalEntitySuccess() {
		Database.delete([SELECT Id FROM Account]);
		Id accountId = Database.insert(
				new Account(
						Name = 'Test inc.',
						Stage__c = 'Active_Investing'
				)
		).getId();

		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('ondato_entity_response_mock');
		mock.setStatusCode(200);
		Test.setMock(HttpCalloutMock.class, mock);
		Test.startTest();
		OndatoService.sendAccount(accountId, true, true);
		Test.stopTest();
		Assert.areEqual(0, [SELECT Id FROM Log__c].size(), 'Log should not be created');
		Assert.isNotNull([SELECT Ondato_Id__c FROM Account].Ondato_Id__c, 'Account Ondato Id should be updated');
		Assert.isNotNull([SELECT Last_Exported_to_Ondato__c FROM Account].Last_Exported_to_Ondato__c, 'Last Exported to Ondato date time should be updated');
	}

	@IsTest
	@SuppressWarnings('PMD.MethodNamingConventions') // method name after underscore represents test scenario
	static void sendAccount_existingLegalEntitySuccess() {
		Account personAccountToDelete = [
				SELECT Id, Ondato_Id__c, Last_Exported_to_Ondato__c, Stage__c
				FROM Account
				WITH SECURITY_ENFORCED
		];
		Database.delete(personAccountToDelete.Id);
		Id accountId = Database.insert(
				new Account(
						Name = 'Test inc.',
						Stage__c = personAccountToDelete.Stage__c,
						Ondato_Id__c = personAccountToDelete.Ondato_Id__c,
						Last_Exported_to_Ondato__c = personAccountToDelete.Last_Exported_to_Ondato__c
				)
		).getId();

		Test.setMock(HttpCalloutMock.class, new CalloutTestUtility.SingleHttpMock(200, ''));
		Test.startTest();
		OndatoService.sendAccount(accountId, true, true);
		Test.stopTest();
		Assert.areEqual(0, [SELECT Id FROM Log__c].size(), 'Log should not be created');
		Datetime lastExportedDatetime = [SELECT Last_Exported_to_Ondato__c FROM Account].Last_Exported_to_Ondato__c;
		Assert.areEqual(Date.today(), Date.newInstance(lastExportedDatetime.year(), lastExportedDatetime.month(), lastExportedDatetime.day()), 'Last Exported to Ondato date time should be updated');
	}

	@IsTest
	@SuppressWarnings('PMD.MethodNamingConventions') // method name after underscore represents test scenario
	static void sendAccount_calloutFailure() {
		Boolean exceptionThrown = false;
		Test.setMock(HttpCalloutMock.class, new CalloutTestUtility.SingleHttpMock(500, '{ "message": "everything went wrong :(" }'));
		Test.startTest();
		try {
			OndatoService.sendAccount([SELECT Id FROM Account].Id, true, true);
		}
		catch (Exception exc) {
			exceptionThrown = true;
		}
		Test.stopTest();
		Assert.isTrue(exceptionThrown, 'Exception had to be thrown');
		Assert.areEqual(1, [SELECT Id FROM Log__c].size(), 'Log should be created');
	}

	@IsTest
	@SuppressWarnings('PMD.MethodNamingConventions') // method name after underscore represents test scenario
	static void deleteAccount_success() {
		Account account = [SELECT Id FROM Account];
		account.Stage__c = 'Closed';
		Database.update(account, AccessLevel.USER_MODE);

		Test.setMock(HttpCalloutMock.class, new CalloutTestUtility.SingleHttpMock(204, ''));
		Test.startTest();
		OndatoService.deleteAccount([SELECT Id FROM Account].Id, true, true);
		Test.stopTest();
		Assert.areEqual(0, [SELECT Id FROM Log__c].size(), 'Log should not be created');
		Assert.isNull([SELECT Ondato_Id__c FROM Account].Ondato_Id__c, 'Account Ondato Id should be removed');
	}

	@IsTest
	@SuppressWarnings('PMD.MethodNamingConventions') // method name after underscore represents test scenario
	static void deleteAccount_calloutFailure() {
		Account account = [SELECT Id FROM Account];
		account.Stage__c = 'Closed';
		Database.update(account, AccessLevel.USER_MODE);

		Boolean exceptionThrown = false;
		Test.setMock(HttpCalloutMock.class, new CalloutTestUtility.SingleHttpMock(500, '{ "message": "everything went wrong :(" }'));
		Test.startTest();
		try {
			OndatoService.deleteAccount(account.Id, true, true);
		}
		catch (Exception exc) {
			exceptionThrown = true;
		}
		Test.stopTest();
		Assert.isTrue(exceptionThrown, 'Exception had to be thrown');
		Assert.areEqual(1, [SELECT Id FROM Log__c].size(), 'Log should be created');
	}

	@IsTest
	@SuppressWarnings('PMD.MethodNamingConventions') // method name after underscore represents test scenario
	static void getAmlMatches_success() {
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('ondato_matches_response_mock');
		mock.setStatusCode(200);
		Test.setMock(HttpCalloutMock.class, mock);
		Test.startTest();
		OndatoService.getAmlMatches([SELECT Id FROM Account].Id, true, true);
		Test.stopTest();
		Assert.areEqual(0, [SELECT Id FROM Log__c].size(), 'Log should not be created');
		Assert.areEqual(1, [SELECT Id FROM Ondato_AML_Match__c].size(), '1 AML match should be created');
	}

	@IsTest
	@SuppressWarnings('PMD.MethodNamingConventions') // method name after underscore represents test scenario
	static void getAmlMatches_calloutFailure() {
		Boolean exceptionThrown = false;
		Test.setMock(HttpCalloutMock.class, new CalloutTestUtility.SingleHttpMock(500, '{ "message": "everything went wrong :(" }'));
		Test.startTest();
		try {
			OndatoService.getAmlMatches([SELECT Id FROM Account].Id, true, true);
		}
		catch (Exception exc) {
			exceptionThrown = true;
		}
		Test.stopTest();

		Assert.isTrue(exceptionThrown, 'An exception must be thrown.');
		Assert.areEqual(1, [SELECT Id FROM Log__c].size(), 'Log should be created');
		Assert.areEqual(0, [SELECT Id FROM Ondato_AML_Match__c].size(), 'No AML matches should be created');
	}

	@IsTest
	@SuppressWarnings('PMD.MethodNamingConventions') // method name after underscore represents test scenario
	static void sendMatchReview_success() {
		Ondato_AML_Match__c amlMatch = new Ondato_AML_Match__c(
				Name = '001',
				Match_ID__c = '001',
				Match_Name__c = 'Test Tester',
				Status__c = 'Open',
				Account__c = [SELECT Id FROM Account].Id
		);
		Database.insert(amlMatch);

		OndatoAmlMatchReviewModel reviewModel = new OndatoAmlMatchReviewModel();
		reviewModel.status = 'TruePositive';
		reviewModel.clientRiskRating = 'High-Risk';
		reviewModel.clientComment = 'Reviewed as true positive, no risk to the business';
		reviewModel.clientUserId = UserInfo.getUserEmail();

		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('ondato_matches_response_mock');
		mock.setStatusCode(200);
		Test.setMock(HttpCalloutMock.class, mock);
		Test.startTest();
		OndatoService.sendMatchReview(amlMatch.Id, reviewModel, true);
		Test.stopTest();

		Assert.areEqual(0, [SELECT Id FROM Log__c].size(), 'Log should not be created');
		Assert.areEqual(1, [SELECT Id FROM Ondato_AML_Match__c WHERE Status__c = 'TruePositive'].size(), 'AML match status was not updated');
	}

	@IsTest
	@SuppressWarnings('PMD.MethodNamingConventions') // method name after underscore represents test scenario
	static void sendMatchReview_calloutFailure() {
		Ondato_AML_Match__c amlMatch = new Ondato_AML_Match__c(
				Name = '001',
				Match_ID__c = '001',
				Match_Name__c = 'Test Tester',
				Status__c = 'Open',
				Account__c = [SELECT Id FROM Account].Id
		);
		Database.insert(amlMatch);

		OndatoAmlMatchReviewModel reviewModel = new OndatoAmlMatchReviewModel();
		reviewModel.status = 'FalsePositive';
		reviewModel.clientRiskRating = 'High-Risk';
		reviewModel.clientComment = 'Reviewed as true positive, no risk to the business';
		reviewModel.clientUserId = UserInfo.getUserEmail();

		Boolean exceptionThrown = false;
		Test.setMock(HttpCalloutMock.class, new CalloutTestUtility.SingleHttpMock(500, '{ "message": "everything went wrong :(" }'));
		Test.startTest();
		try {
			OndatoService.sendMatchReview(amlMatch.Id, reviewModel, true);
		}
		catch (CalloutException exc) {
			exceptionThrown = true;
		}
		Test.stopTest();

		Assert.isTrue(exceptionThrown, 'An exception must be thrown.');
		Assert.areEqual(1, [SELECT Id FROM Log__c].size(), 'Log should be created');
		Assert.areEqual(0, [SELECT Id FROM Ondato_AML_Match__c WHERE Status__c = 'Invalid'].size(), 'AML match status was updated');
	}

	@IsTest
	@SuppressWarnings('PMD.MethodNamingConventions') // method name after underscore represents test scenario
	static void sendMatchReview_dmlFailure() {
		Ondato_AML_Match__c amlMatch = new Ondato_AML_Match__c(
				Name = '001',
				Match_ID__c = '001',
				Match_Name__c = 'Test Tester',
				Status__c = 'Open',
				Account__c = [SELECT Id FROM Account].Id
		);
		Database.insert(amlMatch);

		OndatoAmlMatchReviewModel reviewModel = new OndatoAmlMatchReviewModel();
		reviewModel.status = 'Invalid';
		reviewModel.clientRiskRating = 'High-Risk';
		reviewModel.clientComment = 'Reviewed as true positive, no risk to the business';
		reviewModel.clientUserId = UserInfo.getUserEmail();

		Boolean exceptionThrown = false;
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('ondato_matches_response_mock');
		mock.setStatusCode(200);
		Test.setMock(HttpCalloutMock.class, mock);
		Test.startTest();
		try {
			OndatoService.sendMatchReview(amlMatch.Id, reviewModel, true);
		}
		catch (DmlException exc) {
			exceptionThrown = true;
		}
		Test.stopTest();

		Assert.isTrue(exceptionThrown, 'An exception must be thrown.');
		Assert.areEqual(1, [SELECT Id FROM Log__c].size(), 'Log should be created');
		Assert.areEqual(0, [SELECT Id FROM Ondato_AML_Match__c WHERE Status__c = 'Invalid'].size(), 'AML match status was updated');
	}
}