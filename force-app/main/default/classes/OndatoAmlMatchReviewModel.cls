/**
 * @description A wrapper class used for transferring AML match review data between a Lightning Web Component (LWC) and Apex controller methods.
 *
 * This class is intended to be serialized/deserialized when invoking Apex methods from LWC, allowing structured
 * transport of review data related to AML matches. It includes information such as the new status, risk rating,
 * user comments, and the reviewing user's ID.
 *
 * @author <a href="mailto:arnasbaronas@gmail.com">Arnas Baronas</a>
 */
public with sharing class OndatoAmlMatchReviewModel {

	/**
     * @description New status of the AML match.
     */
	@AuraEnabled
	public String status { get; set; }

	/**
     * @description Reviewer's assigned risk rating.
     */
	@AuraEnabled
	public String clientRiskRating { get; set; }

	/**
     * @description Reviewer’s comment providing context or explanation for the review decision.
     */
	@AuraEnabled
	public String clientComment { get; set; }

	/**
     * @description Salesforce username of the person performing the review.
     */
	@AuraEnabled
	public String clientUserId { get; set; }
}