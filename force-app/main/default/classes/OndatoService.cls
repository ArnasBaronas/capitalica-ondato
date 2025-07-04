/**
 * @description Service class responsible for sending, deleting, and managing Account data
 * and AML match reviews with the Ondato KYC/AML external service.
 *
 * @author <a href="mailto:arnasbaronas@gmail.com">Arnas Baronas</a>
 */
@SuppressWarnings('PMD.CyclomaticComplexity, PMD.CognitiveComplexity, PMD.StdCyclomaticComplexity')
public with sharing class OndatoService {

	/** @description The ID of the Ondato worklist retrieved from custom settings */
	public static final String WORKLIST_ID = Ondato_Settings__c.getInstance().Worklist_Id__c;

	/**
     * @description DTO representing the result of sending an Account to Ondato.
     */
	public class AccountSendResult {
		/** @description Salesforce Account ID */
		public Id salesforceId;
		/** @description Ondato Account ID */
		public String ondatoId;
		/** @description Timestamp of when the account was exported */
		public Datetime exportDateTime;
		/** @description Indicates whether the send was successful */
		public Boolean isSuccessful;
	}

	/**
     * @description Sends an Account to Ondato by ID.
     *
     * @param accountId The Salesforce Account ID.
     * @param performDML If true, updates the Account record.
     * @param throwException If true, rethrows any caught exception.
     * @return Result object containing operation outcome.
     */
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

	/**
     * @description Sends a specified Account to Ondato.
     *
     * @param account Account record to send.
     * @param performDML If true, updates the Account record.
     * @param throwException If true, rethrows any caught exception.
     * @return Result object containing operation outcome.
     */
	@SuppressWarnings('PMD.NcssMethodCount, PMD.CyclomaticComplexity, PMD.StdCyclomaticComplexity')
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

			String baseEndpoint = 'callout:Ondato/v1/worklists/' + WORKLIST_ID + getEntityPath(account, PathType.RECORDS);
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

	/**
     * @description DTO representing the result of deleting an Account from Ondato.
     */
	public class AccountDeleteResult {
		/** @description Salesforce Account ID */
		public Id salesforceId;

		/** @description Ondato Account ID */
		public String ondatoId;

		/** @description Timestamp of deletion */
		public Datetime deleteDateTime;

		/** @description Indicates whether the delete was successful */
		public Boolean isSuccessful;
	}

	/**
     * @description Deletes an Account from Ondato by ID.
     *
     * @param accountId The Salesforce Account ID.
     * @param performDML If true, updates the Account record.
     * @param throwException If true, rethrows any caught exception.
     * @return Result object containing operation outcome.
     */
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

	/**
     * @description Deletes the given Account from Ondato.
     *
     * @param account Account record to delete.
     * @param performDML If true, updates the Account record.
     * @param throwException If true, rethrows any caught exception.
     * @return Result object containing operation outcome.
     */
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
			String baseEndpoint = 'callout:Ondato/v1/worklists/' + WORKLIST_ID + getEntityPath(account, PathType.RECORDS);
			request.setEndpoint(baseEndpoint + account.Ondato_Id__c);

			Logger.info('Request endpoint: ' + request.getEndpoint());

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

	/**
     * @description Retrieves AML match records for the given Account ID.
     *
     * @param accountId Salesforce Account ID.
     * @param performDML If true, persists match results.
     * @param throwException If true, rethrows any caught exception.
     * @return List of AML match records.
     */
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

	/**
     * @description Retrieves AML match records for a given Account.
     *
     * @param account The Account to retrieve matches for.
     * @param performDML If true, saves match records.
     * @param throwException If true, rethrows exceptions.
     * @return List of AML match records.
     */
	@SuppressWarnings('PMD.NcssMethodCount, PMD.CyclomaticComplexity')
	// In order to keep the code easy to read and avoid excessive fragmentation into helper methods,
	// some cyclomatic complexity rules may be intentionally violated. This approach prioritizes clarity
	// over strict adherence to complexity metrics.
	public static List<Ondato_AML_Match__c> getAmlMatches(Account account, Boolean performDML, Boolean throwException) {

		HttpRequest request = new HttpRequest();
		{
			String endpoint = 'callout:Ondato/v1/worklists/' + WORKLIST_ID;
			endpoint += getEntityPath(account, PathType.RECORDS);
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

	/**
     * @description DTO representing the result of sending an AML match review to Ondato.
     */
	public class MatchReviewSendResult {
		/** @description Review status sent to Ondato */
		@AuraEnabled
		public String status;

		/** @description Salesforce Account ID */
		@AuraEnabled
		public Id salesforceAccountId;

		/** @description Ondato Account ID */
		@AuraEnabled
		public String ondatoAccountId;

		/** @description Salesforce AML Match ID */
		@AuraEnabled
		public Id salesforceMatchId;

		/** @description Ondato Match ID */
		@AuraEnabled
		public String ondatoMatchId;
	}

	/**
     * @description Sends a review decision for an AML match to Ondato.
     *
     * @param amlMatchId Salesforce AML match record ID.
     * @param amlMatchReview Review payload to send.
     * @param performDML If true, updates local match status.
     * @return Result of the review operation.
     */
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
				endpoint += getEntityPath(amlMatch.Account__r, PathType.RECORDS);
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
			Logger.error('Error during or processing callout ', exc);
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


	/**
	 * @description DTO representing a single piece of evidence associated with an AML match.
	 */
	public class EvidenceDetails {

		/** @description Unique identifier of the evidence. */
		@AuraEnabled
		public String evidenceId;

		/** @description List of datasets from which the evidence is derived. */
		@AuraEnabled
		public List<String> dataSets;

		/** @description Original source URL of the evidence. */
		@AuraEnabled
		public String originalUrl;

		/** @description Title or headline of the evidence content. */
		@AuraEnabled
		public String title;

		/** @description Credibility assessment provided by the source or Ondato. */
		@AuraEnabled
		public String credibility;

		/** @description Language of the evidence content. */
		@AuraEnabled
		public String language;

		/** @description Summary or description of the evidence content. */
		@AuraEnabled
		public String summary;

		/** @description Keywords extracted or associated with the evidence. */
		@AuraEnabled
		public String keywords;

		/** @description Date when the evidence was captured, in ISO format. */
		@AuraEnabled
		public Date captureDateIso;

		/** @description Publication date of the evidence, in ISO format. */
		@AuraEnabled
		public Date publicationDateIso;

		/** @description URL to any asset associated with the evidence (e.g., image, document). */
		@AuraEnabled
		public String assetUrl;
	}

	/**
	 * @description Retrieves a list of evidences associated with a specific AML match.
	 *
	 * @param amlMatchId The Salesforce ID of the AML match record.
	 * @return A list of evidence details returned by Ondato.
	 * @throws Exception if the request fails or the response is invalid.
	 */
	@AuraEnabled(Cacheable=true)
	public static List<EvidenceDetails> getMatchEvidences(Id amlMatchId) {
		HttpRequest request = new HttpRequest();
		HttpResponse response;
		Ondato_AML_Match__c amlMatch;

		try {
			amlMatch = [
					SELECT
							Id, Match_ID__c, Worklist_Id__c,
							Account__r.Id, Account__r.IsPersonAccount, Account__r.Ondato_Id__c
					FROM Ondato_AML_Match__c
					WHERE Id = :amlMatchId
					WITH SECURITY_ENFORCED
			];
			Logger.info('Getting "' + amlMatch.Match_ID__c + '" AML match details from Ondato', amlMatchId);

			request.setMethod('GET');
			request.setHeader('Content-Type', 'application/json');
			request.setBody('{}');

			{
				String endpoint = 'callout:Ondato/v1';
				endpoint += getEntityPath(amlMatch.Account__r, PathType.DETAILS);
				endpoint += amlMatch.Worklist_Id__c;
				request.setEndpoint(endpoint);
			}
			Logger.info('Request endpoint');
			Logger.info(request.getEndpoint());

			response = new Http().send(request);
			if (String.valueOf(response.getStatusCode()).startsWith('2') == false) {
				throw new CalloutException('HTTP - ' + response.getStatusCode() + '. Response: ' + response.getBody());
			}
			EntityDetailsResponse entityDetailsResponse = (EntityDetailsResponse) JSON.deserialize(response.getBody(), EntityDetailsResponse.class);

			return entityDetailsResponse.evidences;
		} catch (Exception exc) {
			Logger.error('Error during or processing callout ', exc);
			if (response != null) {
				Logger.info('Response status code');
				Logger.info(String.valueOf(response.getStatusCode()));
				Logger.info('Response body');
				Logger.info(response?.getBody());
				Logger.error('Error preparing or executing callout', exc);
			}
			Logger.saveLog();
			throw exc;
		}
	}

	/**
	 * @description Returns the appropriate API path segment based on the account type and requested path type.
	 *
	 * @param account The Account being processed.
	 * @param path The type of API path (RECORDS or DETAILS).
	 * @return Corresponding API path segment.
	 * @throws HandledException if the path type is unsupported.
	 */
	private static String getEntityPath(Account account, PathType path) {
		Boolean isPerson = account.IsPersonAccount;

		if (path == PathType.RECORDS) {
			return isPerson ? '/natural-entity-records/' : '/legal-entity-records/';
		} else if (path == PathType.DETAILS) {
			return isPerson ? '/natural-entity-details/' : '/legal-entity-details/';
		}

		throw new HandledException('Unhandled path type: ' + String.valueOf(path));
	}

	private enum PathType {
		RECORDS,
		DETAILS
	}
}