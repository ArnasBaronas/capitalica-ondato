@IsTest
private class OndatoEntityModel_Test {

	@IsTest
	static void naturalEntityModel() {
		Account malePersonAccount = new Account(
				Salutation = 'Mr.',
				FirstName = 'Test',
				LastName = 'Tester',
				PersonBirthdate = Date.newInstance(1990, 01, 01)
		);
		Database.insert(malePersonAccount);
		malePersonAccount = [
				SELECT Id, Salutation, Name, PersonBirthdate, IsPersonAccount
				FROM Account
				WHERE Id = :malePersonAccount.Id
				WITH SECURITY_ENFORCED
		];

		OndatoNaturalEntityModel maleNaturalEntityModel = new OndatoNaturalEntityModel(malePersonAccount);
		Assert.areEqual(OndatoNaturalEntityModel.Gender.Male, maleNaturalEntityModel.gender);

		Account femalePersonAccount = new Account(
				Salutation = 'Ms.',
				FirstName = 'Test',
				LastName = 'Tester',
				PersonBirthdate = Date.newInstance(1990, 01, 01)
		);
		Database.insert(femalePersonAccount);
		femalePersonAccount = [
				SELECT Id, Salutation, Name, PersonBirthdate, IsPersonAccount
				FROM Account
				WHERE Id = :femalePersonAccount.Id
				WITH SECURITY_ENFORCED
		];

		OndatoNaturalEntityModel femaleNaturalEntityModel = new OndatoNaturalEntityModel(femalePersonAccount);
		Assert.areEqual(OndatoNaturalEntityModel.Gender.Female, femaleNaturalEntityModel.gender);
	}

	@IsTest
	static void naturalEntityModel_error() {
		Account businessAccount = new Account(
				Name = 'Test inc.'
		);
		Database.insert(businessAccount);
		businessAccount = [
				SELECT Id, Name, IsPersonAccount
				FROM Account
				WHERE Id = :businessAccount.Id
				WITH SECURITY_ENFORCED
		];

		Boolean exceptionThrown = false;
		try {
			new OndatoNaturalEntityModel(businessAccount);
		}
		catch (Exception exc) {
			exceptionThrown = true;
		}
		Assert.isTrue(exceptionThrown, 'Exception has not been thrown');
	}

	@IsTest
	static void legalEntityModel() {
		Account businessAccount = new Account(
				Name = 'Test inc.'
		);
		Database.insert(businessAccount);
		businessAccount = [
				SELECT Id, Name, IsPersonAccount
				FROM Account
				WHERE Id = :businessAccount.Id
				WITH SECURITY_ENFORCED
		];

		OndatoLegalEntityModel legalEntityModel = new OndatoLegalEntityModel(businessAccount);
		Assert.areEqual(businessAccount.Name, legalEntityModel.name);
	}

	@IsTest
	static void legalEntityModel_error() {
		Account malePersonAccount = new Account(
				Salutation = 'Mr.',
				FirstName = 'Test',
				LastName = 'Tester',
				PersonBirthdate = Date.newInstance(1990, 01, 01)
		);
		Database.insert(malePersonAccount);
		malePersonAccount = [
				SELECT Id, Salutation, Name, PersonBirthdate, IsPersonAccount
				FROM Account
				WHERE Id = :malePersonAccount.Id
				WITH SECURITY_ENFORCED
		];

		Boolean exceptionThrown = false;
		try {
			new OndatoLegalEntityModel(malePersonAccount);
		}
		catch (Exception exc) {
			exceptionThrown = true;
		}
		Assert.isTrue(exceptionThrown, 'Exception has not been thrown');
	}
}