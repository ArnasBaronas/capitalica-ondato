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
	 * Batch execute method to delete a list of unnecessary Accounts form the Ondato system.
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