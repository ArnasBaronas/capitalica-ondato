/**
 * @description Batch Apex class responsible for exporting `Account` records to the Ondato system.
 *
 * Batch size is controlled by `Ondato_Settings__c.Accounts_Export_Batch_Size__c`.
 *
 * @author <a href="mailto:arnasbaronas@gmail.com">Arnas Baronas</a>
 */
public with sharing class OndatoAccountExportBatch implements Schedulable, Database.Batchable<Id>, Database.AllowsCallouts {

	/** @description Predefined relationship roles considered closely related to active investors. */
	static final List<String> CLOSELY_RELATED_ROLES = new List<String>{
			'Spouse', 'Authorised Representative', 'Executive', 'Authorised Representative', 'Beneficiary'
	};

	/**
     * @description Retrieves a list of Account IDs that are either direct investors (Stage__c = 'Active_Investing')
     * or are closely related to such investors via `AccountContactRelation`.
     *
     * @return List of Account Ids eligible for screening/export.
     */
	public static List<Id> getAccountIdsForScreening() {
		List<Id> directInvestors = new List<Id>(new Map<Id, SObject>([
				SELECT Id
				FROM Account
				WHERE Stage__c = 'Active_Investing'
				WITH SECURITY_ENFORCED
		]).keySet());


		List<Id> accountsCloselyRelatedToInvestors = new List<Id>(new Map<Id, SObject>([
				SELECT Id
				FROM Account
				WHERE PersonContactId IN (
						SELECT ContactId
						FROM AccountContactRelation
						WHERE
								Roles IN :CLOSELY_RELATED_ROLES AND
								Account.Stage__c = 'Active_Investing'
				)
				WITH SECURITY_ENFORCED
		]).keySet());

		List<Id> accountIdsForScreening = new List<Id>();
		accountIdsForScreening.addAll(directInvestors);
		accountIdsForScreening.addAll(accountsCloselyRelatedToInvestors);

		return accountIdsForScreening;
	}

	/** @description Executes the batch job immediately. */
	public static void execute() {
		new OndatoAccountExportBatch().execute(null);
	}

	/**
	 * @description Schedules the batch job using the provided cron expression.
	 * @param sContext SchedulableContext
	 */
	public void execute(SchedulableContext sContext) {
		OndatoAccountExportBatch batch = new OndatoAccountExportBatch();
		Database.executeBatch(batch, Integer.valueOf(Ondato_Settings__c.getInstance().Accounts_Export_Batch_Size__c));
	}

	/**
	 * @description Schedules the batch job with the given cron expression.
	 * @param cronExpression String representing the cron expression for scheduling the job.
	 */
	public static void scheduleBatch(String cronExpression) {
		OndatoAccountExportBatch batch = new OndatoAccountExportBatch();
		String jobName = Label.ONDATO_ACCOUNT_EXPORT_JOB_NAME;
		if (Test.isRunningTest()) {
			jobName += ' Test Scenario';
		}
		System.schedule(jobName, cronExpression, batch);
	}

	/**
     * @description Prepares the list of Account record IDs to be processed by the batch job.
     * This includes both direct investors and their closely related contacts.
     *
     * @param bContext The batch context (unused in this method).
     * @return List of Account Ids to export to Ondato.
     */
	public List<Id> start(Database.BatchableContext bContext) {
		return getAccountIdsForScreening();
	}

	/**
	 * @description Batch execute method to export a list of Accounts to the Ondato system.
	 * It handles both Person Accounts and Business Accounts, and updates each record
	 * with the returned Ondato ID and export timestamp.
	 *
	 * @param bContext   The batch context.
	 * @param accountIds List of Account record IDs to process in this batch.
	 */
	public void execute(Database.BatchableContext bContext, List<Id> accountIds) {
		List<Account> accountsToUpdate = new List<Account>();
		List<Account> accounts = [
				SELECT Id, Name, Salutation, IsPersonAccount,
						PersonBirthdate, Ondato_Id__c, Last_Exported_to_Ondato__c
				FROM Account
				WHERE Id IN :accountIds
		];

		for (Account account : accounts) {
			OndatoService.AccountSendResult transferResult = OndatoService.sendAccount(account, false, false);
			account.Ondato_Id__c = transferResult.ondatoId;
			account.Last_Exported_to_Ondato__c = transferResult.exportDateTime;
			accountsToUpdate.add(account);
		}

		Logger.saveLog();
		Database.update(accountsToUpdate);
	}

	/**
     * @description Finalizes the batch process by logging the job details.
     * @param bContext Database.BatchableContext
     */
	@SuppressWarnings('PMD.AvoidDebugStatements')
	public void finish(Database.BatchableContext bContext) {
		AsyncApexJob apexJob = [
				SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems
				FROM AsyncApexJob
				WHERE Id = :bContext.getJobId()
				WITH SECURITY_ENFORCED
		];
		System.debug(LoggingLevel.INTERNAL, 'Batch job finished. Number of records processed: ' + apexJob.TotalJobItems);
		System.debug(LoggingLevel.INTERNAL, 'Number of batches failed: ' + apexJob.NumberOfErrors);
	}
}