public with sharing class OndatoService {

	public static final String worklistId = Ondato_Settings__c.getInstance().Worklist_Id__c;

	public class AccountTransferResult {
		public String ondatoId;
		public Datetime exportDateTime;
		public Boolean isSuccessful;
	}

	public static AccountTransferResult sendBusinessAccount(Account account, Boolean performDML, Boolean throwException) {
		HttpRequest request = new HttpRequest();
		request.setEndpoint('callout:Ondato/v1/worklists/' + worklistId + '/legal-entity-records');
		if (account.Ondato_Id__c == null) {
			request.setMethod('POST');
		} else {
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
			if (request.getMethod() == 'POST') {
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
		if (performDML) {
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

	public static AccountTransferResult sendPersonAccount(Account account, Boolean performDML, Boolean throwException) {
		HttpRequest request = new HttpRequest();
		request.setEndpoint('callout:Ondato/v1/worklists/' + worklistId + '/natural-entity-records');
		if (account.Ondato_Id__c == null) {
			request.setMethod('POST');
		} else {
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
			if (request.getMethod() == 'POST') {
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
		if (performDML) {
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

	public static Boolean deletePersonAccount(Account account, Boolean performDML, Boolean throwException) {
		return true;
	}

	public static Boolean deleteBusinessAccount(Account account, Boolean performDML, Boolean throwException) {
		return true;
	}

	public static List<AML_Match__c> getPersonAccountMatches(Account account, Boolean performDML, Boolean throwException) {
		HttpRequest request = new HttpRequest();
		request.setEndpoint('callout:Ondato/v1/worklists/' + worklistId + '/natural-entity-records/' + account.Ondato_Id__c + '/search');
		request.setMethod('POST');
		request.setBody('{}');
		request.setHeader('Content-Type', 'application/json');
		Logger.info('Fetching "' + account.Name + '" AML matches from Ondato', account.Id);
		if (account.Ondato_Id__c == null) {
			Logger.error('Cannot retrieve matches for account "' + account.Name + '" — it does not exist in the Ondato worklist.', account.Id);
		}
		List<AML_Match__c> matchRecords = new List<AML_Match__c>();

		Logger.info('Request endpoint');
		Logger.info(request.getEndpoint());
		HttpResponse response;
		try {
			response = new Http().send(request);
			if (String.valueOf(response.getStatusCode()).startsWith('2') == false) {
				throw new CalloutException('HTTP - ' + response.getStatusCode() + '. Response: ' + response.getBody());

			}
			OndatoMatchModel.Response matchesResponse = (OndatoMatchModel.Response) JSON.deserialize(response.getBody(), OndatoMatchModel.Response.class);
			for (OndatoMatchModel matchInResponse : matchesResponse.matches) {
				AML_Match__c matchRecord = matchInResponse.getAmlMatch(account.Id);
				matchRecords.add(matchRecord);
			}
			Logger.flushBuffer();
		} catch (Exception exc) {
			Logger.info('Response status code');
			Logger.info(String.valueOf(response.getStatusCode()));
			Logger.info('Response body');
			Logger.info(response?.getBody());
			Logger.error('Error during or processing callout', exc);
			if (throwException) {
				throw exc;
			}
		}
		if (performDML) {
			Logger.saveLog();
			Database.upsert(matchRecords, AML_Match__c.Match_ID__c);
		}
		return matchRecords;
	}

	public static List<AML_Match__c> getBusinessAccountMatches(Account account, Boolean performDML, Boolean throwException) {
		return null;
	}

	@AuraEnabled(Cacheable=false)
	public static String sendMatchReview(Id amlMatchId, Object amlMatchReviewMap, Boolean performDML) {
		//TODO: Accept AmlMatchReviewModel as parameter.
		AmlMatchReviewModel matchReview = (AmlMatchReviewModel) JSON.deserialize(JSON.serialize(amlMatchReviewMap), AmlMatchReviewModel.class);

		Exception caughtException;
		HttpRequest request = new HttpRequest();
		AML_Match__c amlMatch;
		try {
			amlMatch = [
					SELECT
							Id, Match_ID__c,
							Account__r.Id, Account__r.IsPersonAccount, Account__r.Ondato_Id__c
					FROM AML_Match__c
					WHERE Id = :amlMatchId
					WITH SECURITY_ENFORCED
			];
			Logger.info('Sending "' + amlMatch.Match_ID__c + '" AML match review in Ondato', amlMatchId);

			request.setMethod('POST');
			request.setHeader('Content-Type', 'application/json');
			request.setBody(JSON.serialize(matchReview, true));

			{
				String endpoint = 'callout:Ondato/v1/worklists/' + worklistId;
				endpoint += OndatoServiceUtility.getEntityPath(amlMatch.Account__r);
				endpoint += amlMatch.Account__r.Ondato_Id__c + '/matches/';
				endpoint += amlMatch.Match_ID__c + '/reviews';
				request.setEndpoint(endpoint);
			}

			Logger.info('Request endpoint');
			Logger.info(request.getEndpoint());
			Logger.info('Request body');
			Logger.info(request.getBody());
		} catch (Exception exc) {
			Logger.error('Error preparing HTTP request', exc);
			Logger.saveLog();
			throw caughtException;
		}

		HttpResponse response;
		try {
			response = new Http().send(request);
			if (String.valueOf(response.getStatusCode()).startsWith('2') == false) {
				throw new CalloutException('HTTP - ' + response.getStatusCode() + '. Response: ' + response.getBody());
			}
		} catch (Exception exc) {
			caughtException = exc;
			Logger.info('Response status code');
			Logger.info(String.valueOf(response.getStatusCode()));
			Logger.info('Response body');
			Logger.info(response?.getBody());
			Logger.error('Error during or processing callout', exc);
		}

		if (performDML && caughtException == null) {
			try {
				Database.update(new AML_Match__c(
						Id = amlMatchId,
						Status__c = matchReview.status
				));
			} catch (Exception exc) {
				caughtException = exc;
				Logger.error('Error during AML match update', exc);
			}
		}
		if (caughtException != null) {
			Logger.saveLog();
			throw caughtException;
		}
		else {
			Logger.flushBuffer();
		}
		return matchReview.status;
	}
}