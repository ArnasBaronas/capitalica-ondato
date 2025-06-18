/**
 * @description Batch Apex job for deleting `Account` records that are no longer needed in the Ondato system.
 * It identifies accounts with an `Ondato_Id__c`, checks whether they are still used in screening,
 * and sends deletion requests to Ondato via `OndatoService`. If deletion succeeds, it clears the `Ondato_Id__c` field.
 *
 * Batch size is controlled by a custom setting `Ondato_Settings__c.Accounts_Delete_Batch_Size__c`.
 *
* @author <a href="mailto:arnasbaronas@gmail.com">Arnas Baronas</a>
*/
public with sharing class OndatoAccountDeleteBatch implements Schedulable, Database.Batchable<Id>, Database.AllowsCallouts {

	/** @description Executes the batch job immediately. */
	public static void execute() {
		new OndatoAccountDeleteBatch().execute(null);
	}

	/**
	 * @description Schedules the batch job using the provided cron expression.
	 * @param sContext SchedulableContext
	 */
	public void execute(SchedulableContext sContext) {
		OndatoAccountDeleteBatch batch = new OndatoAccountDeleteBatch();
		Database.executeBatch(batch, Integer.valueOf(Ondato_Settings__c.getInstance().Accounts_Delete_Batch_Size__c));
	}

	/**
	 * @description Schedules the batch job with the given cron expression.
	 * @param cronExpression String representing the cron expression for scheduling the job.
	 */
	public static void scheduleBatch(String cronExpression) {
		OndatoAccountDeleteBatch batch = new OndatoAccountDeleteBatch();
		String jobName = Label.ONDATO_ACCOUNT_DELETE_JOB_NAME;
		if (Test.isRunningTest()) {
			jobName += ' Test Scenario';
		}
		System.schedule(jobName, cronExpression, batch);
	}

	/**
     * @description Prepares the list of Account record IDs to be processed by the batch job.
     * Only includes accounts with a non-null `Ondato_Id__c` that are not currently
     * included in an active Ondato screening process.
     *
     * @param bContext Database.BatchableContext
     * @return List of Account Ids to process.
     */
	public List<Id> start(Database.BatchableContext bContext) {
		List<Id> accountsToDeleteFromOndato = new List<Id>(new Map<Id, SObject>([
				SELECT Id
				FROM Account
				WHERE
						Ondato_Id__c != NULL
						AND
						Id NOT IN :OndatoAccountExportBatch.getAccountIdsForScreening()
				WITH SECURITY_ENFORCED
		]).keySet());

		return accountsToDeleteFromOndato;
	}

	/**
	 * @description Batch execute method to delete a list of unnecessary Accounts form the Ondato system.
	 * It handles both Person Accounts and Business Accounts.
	 *
	 * @param bContext   The batch context.
	 * @param accountIds List of Account record IDs to process in this batch.
	 */
	public void execute(Database.BatchableContext bContext, List<Id> accountIds) {
		List<Account> accountsToUpdate = new List<Account>();
		List<Account> accounts = [
				SELECT
						Id, IsPersonAccount,
						Name, Ondato_Id__c
				FROM Account
				WHERE Id IN :accountIds
		];

		for (Account account : accounts) {
			OndatoService.AccountDeleteResult deleteResult;
			deleteResult = OndatoService.deleteAccount(account, false, false);
			if(deleteResult.isSuccessful) {
				account.Ondato_Id__c = null;
				accountsToUpdate.add(account);
			}
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