/**
 * @description This handler class processes changes to `Ondato_AML_Match__c` records and
 *  creates corresponding `Ondato_AML_Match_History__c` records to maintain an audit trail.
 *
 * The handler runs in the context of system mode to ensure audit records are created
 * regardless of field-level security or sharing rules.
 *
 * @author <a href="mailto:arnasbaronas@gmail.com">Arnas Baronas</a>
 */
public with sharing class OndatoAmlMatchHistoryHandler {

	/**
     * @description Handles the processing of `Ondato_AML_Match__c` change events (INSERT/UPDATE).
     * This method generates `Ondato_AML_Match_History__c` records for each provided AML match,
     *
     * @param amlMatches  List of `Ondato_AML_Match__c` records that were inserted or updated.
     * @param operation   The trigger operation type (AFTER_INSERT or AFTER_UPDATE).
     */
	public static void handleChangeEvent(List<Ondato_AML_Match__c> amlMatches, TriggerOperation operation) {
		if(Ondato_Settings__c.getInstance().Create_History_Records__c == false) {
			return;
		}
		Map<String, String> statusValueToLabelMap = new Map<String, String>();
		Schema.DescribeFieldResult fieldResult = Ondato_AML_Match__c.Status__c.getDescribe();
		for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
			statusValueToLabelMap.put(entry.getValue(), entry.getLabel());
		}

		Set<Id> userIds = new Set<Id>();
		for(Ondato_AML_Match__c amlMatch : amlMatches) {
			userIds.add(amlMatch.LastModifiedById);
		}
		Map<Id, User> userNameByIdMap = new Map<Id, User>([
				SELECT Id, Name
				FROM User
				WHERE Id IN :userIds
				WITH SECURITY_ENFORCED
		]);

		List<Ondato_AML_Match_History__c> amlMatchHistories = new List<Ondato_AML_Match_History__c>();
		for(Ondato_AML_Match__c amlMatch : amlMatches) {
			Ondato_AML_Match_History__c matchHistory = new Ondato_AML_Match_History__c();
			String operationName = (operation == TriggerOperation.AFTER_UPDATE) ? 'UPDATE' : (operation == TriggerOperation.AFTER_INSERT) ? 'INSERT' : 'UNKNOWN';
			matchHistory.Operation__c = operationName;
			matchHistory.AML_Match__c = amlMatch.Id;
			matchHistory.Status__c = statusValueToLabelMap.get(amlMatch.Status__c);
			matchHistory.Author__c = userNameByIdMap.get(amlMatch.LastModifiedById).Name;
			amlMatchHistories.add(matchHistory);
		}
		Database.insert(amlMatchHistories, AccessLevel.SYSTEM_MODE);
	}
}