public with sharing class OndatoService {

	public static final String worklistId = Ondato_Settings__c.getInstance().Worklist_Id__c;

	public class AccountTransferResult {
		public String ondatoId;
		public Datetime exportDateTime;
		public Boolean isSuccessful;
	}

	public static AccountTransferResult sendAccount(Account account, Boolean performDML, Boolean throwException) {
		AccountTransferResult result = new AccountTransferResult();
		HttpRequest request = new HttpRequest();
		HttpResponse response;
		Exception caughtException;

		try {
			Logger.info('Sending "' + account.Name + '" account to Ondato', account.Id);

			String baseEndpoint = 'callout:Ondato/v1/worklists/' + worklistId + OndatoServiceUtility.getEntityPath(account);
			Boolean isNew = String.isBlank(account.Ondato_Id__c);

			if (isNew) {
				request.setMethod('POST');
				request.setEndpoint(baseEndpoint);
			} else {
				request.setMethod('PUT');
				request.setEndpoint(baseEndpoint + account.Ondato_Id__c);
			}

			request.setHeader('Content-Type', 'application/json');

			String requestBody = account.IsPersonAccount
					? JSON.serialize(new OndatoNaturalEntityModel(account))
					: JSON.serialize(new OndatoLegalEntityModel(account));

			request.setBody(requestBody);

			Logger.info('Request endpoint: ' + request.getEndpoint());
			Logger.info('Request body: ' + requestBody);

			//TODO: validate status code
			response = new Http().send(request);

			if (isNew) {
				Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
				Object idValue = responseMap.get('id');
				if (idValue != null) {
					account.Ondato_Id__c = String.valueOf(idValue);
				} else {
					throw new CalloutException('Missing "id" in response when creating account on Ondato');
				}
			}

			account.Last_Exported_to_Ondato__c = Datetime.now();
			result.isSuccessful = true;

			if (performDML) {
				Database.update(account, AccessLevel.SYSTEM_MODE);
			}
			Logger.flushBuffer();
		} catch (Exception exc) {
			caughtException = exc;
			Logger.error('Error during callout or processing', exc);
			result.isSuccessful = false;
			if (performDML) {
				Logger.saveLog();
			}
			if(throwException) {
				throw exc;
			}
		}

		// Return result
		result.ondatoId = account.Ondato_Id__c;
		result.exportDateTime = account.Last_Exported_to_Ondato__c;
		return result;
	}

	public static Boolean deleteAccount(Account account, Boolean performDML, Boolean throwException) {
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

	@AuraEnabled(Cacheable=false)
	public static String sendMatchReview(Id amlMatchId, Object amlMatchReviewMap, Boolean performDML) {
		//TODO: Accept AmlMatchReviewModel as parameter.
		AmlMatchReviewModel matchReview = (AmlMatchReviewModel) JSON.deserialize(JSON.serialize(amlMatchReviewMap), AmlMatchReviewModel.class);

		Exception caughtException;
		HttpRequest request = new HttpRequest();
		HttpResponse response;
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

			response = new Http().send(request);
			if (String.valueOf(response.getStatusCode()).startsWith('2') == false) {
				throw new CalloutException('HTTP - ' + response.getStatusCode() + '. Response: ' + response.getBody());
			}
		} catch (Exception exc) {
			caughtException = exc;

			if (response != null) {
				Logger.info('Response status code');
				Logger.info(String.valueOf(response.getStatusCode()));
				Logger.info('Response body');
				Logger.info(response?.getBody());
				Logger.error('Error preparing or executing callout', exc);
			}

			Logger.saveLog();
			throw caughtException;
		}

		if (performDML) {
			try {
				Database.update(new AML_Match__c(
						Id = amlMatchId,
						Status__c = matchReview.status
				));
			} catch (Exception ex) {
				caughtException = ex;
				Logger.error('Failed to update AML_Match__c with review status', ex);
				Logger.saveLog();
				throw caughtException;
			}
		}
		Logger.flushBuffer();
		return matchReview.status;
	}
}