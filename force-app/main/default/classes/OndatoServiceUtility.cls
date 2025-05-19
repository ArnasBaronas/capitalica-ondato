public with sharing class OndatoServiceUtility {

	public static String getEntityPath(Account account) {
		if (account.IsPersonAccount) {
			return '/natural-entity-records/';
		}
		return '/legal-entity-records/';
	}
}