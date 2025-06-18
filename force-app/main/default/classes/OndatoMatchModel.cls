public with sharing class OndatoMatchModel {

	public String currentStatus;
	public String matchId;
	public String resourceId;
	public Integer score;
	public String match;
	public String name;
	public String profileImage;
	public List<String> datesOfBirth;
	public List<String> countries;
	public List<String> dataSets;

	public class Response {
		public Integer totalCount;
		public List<OndatoMatchModel> matches;
	}

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