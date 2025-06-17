public with sharing class OndatoAmlMatchReviewModel {

	@AuraEnabled
	public String status;
	@AuraEnabled
	public String clientRiskRating;
	@AuraEnabled
	public String clientComment;
	@AuraEnabled
	public String clientUserId;
}