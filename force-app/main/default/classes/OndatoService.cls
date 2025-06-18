@SuppressWarnings('PMD.CyclomaticComplexity, PMD.CognitiveComplexity')
public with sharing class OndatoService {

	public static final String WORKLIST_ID = Ondato_Settings__c.getInstance().Worklist_Id__c;

	public class AccountSendResult {
		public Id salesforceId;
		public String ondatoId;
		public Datetime exportDateTime;
		public Boolean isSuccessful;
	}

	public static AccountSendResult sendAccount(Id accountId, Boolean performDML, Boolean throwException) {
		Account account = [
				SELECT
						Id, Name, Ondato_Id__c, Salutation,
						IsPersonAccount, PersonBirthdate
				FROM Account
				WHERE Id = :accountId
				WITH SECURITY_ENFORCED
		];
		return sendAccount(account, performDML, throwException);
	}

	@SuppressWarnings('PMD.NcssMethodCount, PMD.CyclomaticComplexity')
	// In order to keep the code easy to read and avoid excessive fragmentation into helper methods,
	// some cyclomatic complexity rules may be intentionally violated. This approach prioritizes clarity
	// over strict adherence to complexity metrics.
	public static AccountSendResult sendAccount(Account account, Boolean performDML, Boolean throwException) {
		AccountSendResult result = new AccountSendResult();
		HttpRequest request = new HttpRequest();
		HttpResponse response;
		Exception caughtException;

		try {
			Logger.info('Sending "' + account.Name + '" account to Ondato', account.Id);

			String baseEndpoint = 'callout:Ondato/v1/worklists/' + WORKLIST_ID + getEntityPath(account);
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

			response = new Http().send(request);
			if (String.valueOf(response.getStatusCode()).startsWith('2') == false) {
				throw new CalloutException(response.getBody());
			}

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
			Logger.error('Error during or processing callout ', exc);
			result.isSuccessful = false;
			if (performDML) {
				Logger.saveLog();
			}
			if (throwException) {
				throw exc;
			}
		}

		result.salesforceId = account.Id;
		result.ondatoId = account.Ondato_Id__c;
		result.exportDateTime = account.Last_Exported_to_Ondato__c;
		return result;
	}

	public class AccountDeleteResult {
		public Id salesforceId;
		public String ondatoId;
		public Datetime deleteDateTime;
		public Boolean isSuccessful;
	}

	public static AccountDeleteResult deleteAccount(Id accountId, Boolean performDML, Boolean throwException) {
		Account account = [
				SELECT
						Id, Name, Ondato_Id__c,
						IsPersonAccount
				FROM Account
				WHERE Id = :accountId
				WITH SECURITY_ENFORCED
		];
		return deleteAccount(account, performDML, throwException);
	}

	@SuppressWarnings('PMD.NcssMethodCount, PMD.CyclomaticComplexity')
	// In order to keep the code easy to read and avoid excessive fragmentation into helper methods,
	// some cyclomatic complexity rules may be intentionally violated. This approach prioritizes clarity
	// over strict adherence to complexity metrics.
	public static AccountDeleteResult deleteAccount(Account account, Boolean performDML, Boolean throwException) {
		AccountDeleteResult result = new AccountDeleteResult();
		result.salesforceId = account.Id;
		result.ondatoId = account.Ondato_Id__c;
		HttpRequest request = new HttpRequest();
		HttpResponse response;

		try {
			Logger.info('Deleting "' + account.Name + '" account from Ondato', account.Id);
			if (String.isBlank(account.Ondato_Id__c)) {
				throw new HandledException('Account does not have Ondato Id');
			}

			request.setMethod('DELETE');
			String baseEndpoint = 'callout:Ondato/v1/worklists/' + WORKLIST_ID + getEntityPath(account);
			request.setEndpoint(baseEndpoint + account.Ondato_Id__c);

			Logger.info('Request endpoint: ' + request.getEndpoint());

			//TODO: validate status code
			response = new Http().send(request);

			if (String.valueOf(response.getStatusCode()).startsWith('2') == false) {
				throw new CalloutException(response.getBody());
			}

			account.Ondato_Id__c = null;
			result.isSuccessful = true;
			result.deleteDateTime = Datetime.now();

			if (performDML) {
				Database.update(account, AccessLevel.SYSTEM_MODE);
			}
			Logger.flushBuffer();
		} catch (Exception exc) {
			Logger.error('Error during or processing callout ', exc);
			result.isSuccessful = false;
			if (performDML) {
				Logger.saveLog();
			}
			if (throwException) {
				throw exc;
			}
		}


		return result;
	}

	public static List<Ondato_AML_Match__c> getAmlMatches(Id accountId, Boolean performDML, Boolean throwException) {
		Account account = [
				SELECT
						Id, Name, Ondato_Id__c,
						IsPersonAccount
				FROM Account
				WHERE Id = :accountId
				WITH SECURITY_ENFORCED
		];
		return getAmlMatches(account, performDML, throwException);
	}

	@SuppressWarnings('PMD.NcssMethodCount, PMD.CyclomaticComplexity')
	// In order to keep the code easy to read and avoid excessive fragmentation into helper methods,
	// some cyclomatic complexity rules may be intentionally violated. This approach prioritizes clarity
	// over strict adherence to complexity metrics.
	public static List<Ondato_AML_Match__c> getAmlMatches(Account account, Boolean performDML, Boolean throwException) {

		HttpRequest request = new HttpRequest();
		{
			String endpoint = 'callout:Ondato/v1/worklists/' + WORKLIST_ID;
			endpoint += getEntityPath(account);
			endpoint += account.Ondato_Id__c + '/search';
			request.setEndpoint(endpoint);
		}
		request.setMethod('POST');
		request.setBody('{}');
		request.setHeader('Content-Type', 'application/json');
		Logger.info('Fetching "' + account.Name + '" AML matches from Ondato', account.Id);
		if (account.Ondato_Id__c == null) {
			Logger.error('Cannot retrieve matches for account "' + account.Name + '" — it does not exist in the Ondato worklist.', account.Id);
		}
		List<Ondato_AML_Match__c> matchRecords = new List<Ondato_AML_Match__c>();

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
				Ondato_AML_Match__c matchRecord = matchInResponse.getAmlMatch(account.Id);
				matchRecords.add(matchRecord);
			}
			Logger.flushBuffer();
		} catch (Exception exc) {
			Logger.info('Response status code');
			Logger.info(String.valueOf(response.getStatusCode()));
			Logger.info('Response body');
			Logger.info(response?.getBody());
			Logger.error('Error during or processing callout', exc);
			if(performDML) {
				Logger.saveLog();
			}
			if (throwException) {
				throw exc;
			}
		}
		if (performDML) {
			Database.upsert(matchRecords, Ondato_AML_Match__c.Match_ID__c, AccessLevel.SYSTEM_MODE);
		}
		return matchRecords;
	}

	public class MatchReviewSendResult {
		@AuraEnabled
		public String status;
		@AuraEnabled
		public Id salesforceAccountId;
		@AuraEnabled
		public String ondatoAccountId;
		@AuraEnabled
		public Id salesforceMatchId;
		@AuraEnabled
		public String ondatoMatchId;
	}

	@SuppressWarnings('PMD.NcssMethodCount')
	// In order to keep the code easy to read and avoid excessive fragmentation into helper methods,
	// some cyclomatic complexity rules may be intentionally violated. This approach prioritizes clarity
	// over strict adherence to complexity metrics.
	@AuraEnabled(Cacheable=false)
	public static MatchReviewSendResult sendMatchReview(Id amlMatchId, OndatoAmlMatchReviewModel amlMatchReview, Boolean performDML) {
		Exception caughtException;
		HttpRequest request = new HttpRequest();
		HttpResponse response;
		Ondato_AML_Match__c amlMatch;

		try {
			amlMatch = [
					SELECT
							Id, Match_ID__c,
							Account__r.Id, Account__r.IsPersonAccount, Account__r.Ondato_Id__c
					FROM Ondato_AML_Match__c
					WHERE Id = :amlMatchId
					WITH SECURITY_ENFORCED
			];
			Logger.info('Sending "' + amlMatch.Match_ID__c + '" AML match review in Ondato', amlMatchId);

			request.setMethod('POST');
			request.setHeader('Content-Type', 'application/json');
			request.setBody(JSON.serialize(amlMatchReview, true));

			{
				String endpoint = 'callout:Ondato/v1/worklists/' + WORKLIST_ID;
				endpoint += getEntityPath(amlMatch.Account__r);
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
				Database.update(new Ondato_AML_Match__c(
						Id = amlMatchId,
						Status__c = amlMatchReview.status
				), AccessLevel.SYSTEM_MODE);
			} catch (Exception ex) {
				caughtException = ex;
				Logger.error('Failed to update Ondato_AML_Match__c with review status', ex);
				Logger.saveLog();
				throw caughtException;
			}
		}
		Logger.flushBuffer();
		MatchReviewSendResult result = new MatchReviewSendResult();
		result.status = amlMatchReview.status;
		result.salesforceAccountId = amlMatch.Account__r.Id;
		result.ondatoAccountId = amlMatch.Account__r.Ondato_Id__c;
		result.salesforceMatchId = amlMatch.Id;
		result.ondatoMatchId = amlMatch.Match_ID__c;

		return result;
	}

	private static String getEntityPath(Account account) {
		if (account.IsPersonAccount) {
			return '/natural-entity-records/';
		}
		return '/legal-entity-records/';
	}
}