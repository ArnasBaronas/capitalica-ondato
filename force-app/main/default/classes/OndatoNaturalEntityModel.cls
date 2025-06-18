/**
 * @description Represents a person (natural entity) for transmission to Ondato.
 *
 * @author <a href="mailto:arnasbaronas@gmail.com">Arnas Baronas</a>
 */
public with sharing class OndatoNaturalEntityModel {

	/**
     * @description Enumeration for gender options used by Ondato.
     */
	public enum Gender {
		MALE,
		FEMALE
	}

	/** @description Name of the person */
	public String name;
	/** @description Date of birth in string format */
	public String dateOfBirth;
	/** @description Gender derived from the salutation field */
	public Gender gender;

	/**
	 * @description Constructor that initializes the model from a Person Account.
	 * @param account A Person Account to map to the model.
	 */
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