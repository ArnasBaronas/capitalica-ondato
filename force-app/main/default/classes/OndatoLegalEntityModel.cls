/**
 * @description Represents a business (legal entity) for transmission to Ondato.
 *
 * @author <a href="mailto:arnasbaronas@gmail.com">Arnas Baronas</a>
 */
public with sharing class OndatoLegalEntityModel {

	/** @description Name of business entity */
	public String name;

	/**
	 * @description Constructor that initializes the model from a Business Account.
	 * @param account A Business Account to map to the model.
	 */
	public OndatoLegalEntityModel(Account account) {
		if(account.IsPersonAccount == true) {
			throw new HandledException('OndatoLegalEntityModel only accepts business accounts as account parameter');
		}
		name = account.Name;
	}
}