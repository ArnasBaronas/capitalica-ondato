public with sharing class AmlMatchReviewModel {

	@AuraEnabled
	public String status;
	@AuraEnabled
	public String clientRiskRating;
	@AuraEnabled
	public String clientComment;
	@AuraEnabled
	public String clientUserId;
}