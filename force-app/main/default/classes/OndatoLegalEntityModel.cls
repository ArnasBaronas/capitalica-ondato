public with sharing class OndatoLegalEntityModel {

	public String name;

	public OndatoLegalEntityModel(Account account) {
		if(account.IsPersonAccount == true) {
			throw new HandledException('OndatoLegalEntityModel only accepts business accounts as account parameter');
		}
		name = account.Name;
	}
}