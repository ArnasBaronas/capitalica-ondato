public with sharing class OndatoNaturalEntityModel {

	public enum Gender {
		Male,
		Female
	}

	public String name;
	public String dateOfBirth;
	public Gender gender;
	//TODO: country is not being saved in Ondato
	public String country;

	public OndatoNaturalEntityModel(Account account) {
		if(account.IsPersonAccount == false) {
			throw new HandledException('OndatoNaturalEntityModel only accepts person accounts as account parameter');
		}
		name = account.Name;
		dateOfBirth = String.valueOf(account.PersonBirthdate);
		country = account.BillingCountry;
		switch on account.Salutation {
			when 'Mr.' {
				this.gender = OndatoNaturalEntityModel.Gender.Male;
			}
			when 'Ms.', 'Mrs.' {
				this.gender = OndatoNaturalEntityModel.Gender.Female;
			}
		}
	}
}