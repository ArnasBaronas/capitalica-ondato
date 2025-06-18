/**
 * @description Represents a single AML match retrieved from the Ondato system.
 * Includes methods to convert the Ondato response into a Salesforce AML match object.
 *
 * @author <a href="mailto:arnasbaronas@gmail.com">Arnas Baronas</a>
 */
public with sharing class OndatoMatchModel {

	/** @description Current status of the match in the Ondato system (e.g. Open, Closed) */
	public String currentStatus;

	/** @description Unique identifier of the match */
	public String matchId;

	/** @description Resource ID from Ondato */
	public String resourceId;

	/** @description Match score indicating the strength of the match */
	public Integer score;

	/** @description Name or description of the matched entity */
	public String match;

	/** @description Name of the matched individual or entity */
	public String name;

	/** @description URL to the matched profile's image, if available */
	public String profileImage;

	/** @description List of dates of birth associated with the matched entity */
	public List<String> datesOfBirth;

	/** @description List of countries associated with the matched entity */
	public List<String> countries;

	/** @description List of datasets that contributed to the match */
	public List<String> dataSets;

	/**
	 * @description Wrapper class representing the entire Ondato match API response.
	 */
	public class Response {
		/** @description Total number of matches returned in the response */
		public Integer totalCount;

		/** @description List of matched records from Ondato */
		public List<OndatoMatchModel> matches;
	}

	/**
	 * @description Converts this model into a Salesforce `Ondato_AML_Match__c` record.
	 *
	 * @param accountId The Salesforce Account ID to associate with the match.
	 * @return A populated `Ondato_AML_Match__c` object based on the match model.
	 */
	public Ondato_AML_Match__c getAmlMatch(Id accountId) {
		Ondato_AML_Match__c amlMatch = new Ondato_AML_Match__c();
		amlMatch.Match_Name__c = match;
		amlMatch.Status__c = currentStatus;
		amlMatch.Name = matchId;
		amlMatch.Match_ID__c = matchId;
		amlMatch.Profile_Image__c = profileImage;
		amlMatch.Worklist_Id__c = resourceId;
		amlMatch.Account__c = accountId;
		amlMatch.Score__c = score;
		amlMatch.Source_List__c = String.join(dataSets ??  new List<String>(), ';\n');
		amlMatch.Dates_of_Birth__c = String.join(datesOfBirth ??  new List<String>(), ';\n');
		amlMatch.Countries_List__c = String.join(countries ??  new List<String>(), ';\n');
		return amlMatch;
	}
}