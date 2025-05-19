public with sharing class OndatoMatchModel {

	public class Response {
		public Integer totalCount;
		public List<OndatoMatchModel> matches;
	}

	public String currentStatus;
	public String matchId;
	public String resourceId;
	public Integer score;
	public String match;
	public String name;
	public List<String> countries;
	public List<String> dataSets;

	public AML_Match__c getAmlMatch() {
		AML_Match__c amlMatch = new AML_Match__c();
		amlMatch.Match_Name__c = match;
		amlMatch.Status__c = currentStatus;
		amlMatch.Match_ID__c = matchId;
		amlMatch.Account__r = new Account(Ondato_Id__c = resourceId);
		amlMatch.Score__c = score;
		amlMatch.Source_List__c = String.join(dataSets, ';\n');

		return amlMatch;
	}
}