public with sharing class OndatoAmlMatchReviewModel {

	@AuraEnabled
	public String status { get; set; }
	@AuraEnabled
	public String clientRiskRating { get; set; }
	@AuraEnabled
	public String clientComment { get; set; }
	@AuraEnabled
	public String clientUserId { get; set; }
}