public with sharing class OndatoNaturalEntityModel {

	public enum Gender {
		MALE,
		FEMALE
	}

	public String name;
	public String dateOfBirth;
	public Gender gender;

	public OndatoNaturalEntityModel(Account account) {
		if(account.IsPersonAccount == false) {
			throw new HandledException('OndatoNaturalEntityModel only accepts person accounts as account parameter');
		}
		name = account.Name;
		dateOfBirth = String.valueOf(account.PersonBirthdate);
		switch on account.Salutation {
			when 'Mr.' {
				this.gender = OndatoNaturalEntityModel.Gender.MALE;
			}
			when 'Ms.', 'Mrs.' {
				this.gender = OndatoNaturalEntityModel.Gender.FEMALE;
			}
		}
	}
}