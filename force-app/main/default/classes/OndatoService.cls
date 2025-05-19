public with sharing class OndatoService {

	public static final String worklistId = Ondato_Settings__c.getInstance().Worklist_Id__c;

	public class AccountTransferResult {
		public String ondatoId;
		public Datetime exportDateTime;
		public Boolean isSuccessful;
	}

	public static AccountTransferResult sendPersonAccount(Account account, Boolean performDML, Boolean throwException) {
		HttpRequest request = new HttpRequest();
		request.setEndpoint('callout:Ondato/v1/worklists/' + worklistId + '/natural-entity-records');
		if(account.Ondato_Id__c == null) {
			request.setMethod('POST');
		}
		else {
			request.setMethod('PUT');
			request.setEndpoint(request.getEndpoint() + '/' + account.Ondato_Id__c);
		}

		request.setHeader('Content-Type', 'application/json');
		String requestBody;
		Logger.info('Creating person account "' + account.Name + '" in Ondato', account.Id);
		try {
			requestBody = JSON.serialize(new OndatoNaturalEntityModel(account));
			request.setBody(requestBody);
			HttpResponse response = new Http().send(request);
			if(request.getMethod() == 'POST') {
				account.Ondato_Id__c = String.valueOf(((Map<String, Object>) JSON.deserializeUntyped(response.getBody())).get('id'));
			}
			account.Last_Exported_to_Ondato__c = Datetime.now();
			Logger.flushBuffer();
		} catch (Exception exc) {
			Logger.info('Request endpoint');
			Logger.info(request.getEndpoint());
			Logger.info('Request body');
			Logger.info(requestBody);
			Logger.error('Error during callout', exc);
		}
		if(performDML) {
			Logger.saveLog();
			//TODO: change into user mode
			Database.update(account, AccessLevel.SYSTEM_MODE);
		}

		AccountTransferResult result = new AccountTransferResult();
		result.ondatoId = account.Ondato_Id__c;
		result.exportDateTime = account.Last_Exported_to_Ondato__c;
		result.isSuccessful = true;

		return result;
	}

	public static Boolean deletePersonAccount() {


		return true;
	}

	public static AccountTransferResult sendBusinessAccount(Account account, Boolean performDML, Boolean throwException) {
		HttpRequest request = new HttpRequest();
		request.setEndpoint('callout:Ondato/v1/worklists/' + worklistId + '/legal-entity-records');
		if(account.Ondato_Id__c == null) {
			request.setMethod('POST');
		}
		else {
			request.setMethod('PUT');
			request.setEndpoint(request.getEndpoint() + '/' + account.Ondato_Id__c);
		}
		request.setHeader('Content-Type', 'application/json');
		String requestBody;
		Logger.info('Creating person account "' + account.Name + '" in Ondato', account.Id);
		try {
			requestBody = JSON.serialize(new OndatoLegalEntityModel(account));
			request.setBody(requestBody);
			HttpResponse response = new Http().send(request);
			if(request.getMethod() == 'POST') {
				account.Ondato_Id__c = String.valueOf(((Map<String, Object>) JSON.deserializeUntyped(response.getBody())).get('id'));
			}
			account.Last_Exported_to_Ondato__c = Datetime.now();
			Logger.flushBuffer();
		} catch (Exception exc) {
			Logger.info('Request endpoint');
			Logger.info(request.getEndpoint());
			Logger.info('Request body');
			Logger.info(requestBody);
			Logger.error('Error during callout', exc);
		}
		if(performDML) {
			Logger.saveLog();
			//TODO: change into user mode
			Database.update(account, AccessLevel.SYSTEM_MODE);
		}

		AccountTransferResult result = new AccountTransferResult();
		result.ondatoId = account.Ondato_Id__c;
		result.exportDateTime = account.Last_Exported_to_Ondato__c;
		result.isSuccessful = true;

		return result;
	}

	public void deleteBusinessAccount() {

	}

	public static List<AML_Match__c> getPersonAccountMatches(Account account, Boolean performDML, Boolean throwException) {
		HttpRequest request = new HttpRequest();
		request.setEndpoint('callout:Ondato/v1/worklists/' + worklistId + '/natural-entity-records/' + account.Ondato_Id__c + '/search');
		request.setMethod('GET');
		request.setHeader('Content-Type', 'application/json');
		Logger.info('Fetching "' + account.Name + '" AML matches from Ondato', account.Id);
		if(account.Ondato_Id__c == null) {
			Logger.error('Cannot retrieve matches for account "' + account.Name +  '" — it does not exist in the Ondato worklist.', account.Id);
		}
		List<AML_Match__c> matchRecords = new List<AML_Match__c>();
		String responseBody;
		try {
			HttpResponse response = new Http().send(request);
			responseBody = response.getBody();
			OndatoMatchModel.Response matchesResponse = (OndatoMatchModel.Response) JSON.deserialize(responseBody, OndatoMatchModel.class);
			for(OndatoMatchModel matchInResponse : matchesResponse.matches) {
				AML_Match__c matchRecord = matchInResponse.getAmlMatch();
				matchRecords.add(matchRecord);
			}
			Logger.flushBuffer();
		} catch (Exception exc) {
			Logger.info('Request endpoint');
			Logger.info(request.getEndpoint());
			Logger.info('Response body');
			Logger.info(responseBody);
			Logger.error('Error during or processing callout', exc);
		}
		if(performDML) {
			Logger.saveLog();
			//TODO: change into user mode
			Database.upsert(matchRecords, AML_Match__c.Match_ID__c);
		}

		return matchRecords;
	}
}