public with sharing class OndatoLegalEntityModel {

	public String name;
	//TODO: country is not being saved in Ondato
	public String country;

	public OndatoLegalEntityModel(Account account) {
		if(account.IsPersonAccount == true) {
			throw new HandledException('OndatoLegalEntityModel only accepts business accounts as account parameter');
		}
		name = account.Name;
		country = account.BillingCountry;
	}
}