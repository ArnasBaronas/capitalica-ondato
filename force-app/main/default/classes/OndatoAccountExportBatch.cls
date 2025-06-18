public with sharing class OndatoAccountExportBatch implements Schedulable, Database.Batchable<Id>, Database.AllowsCallouts {

	static final List<String> CLOSELY_RELATED_ROLES = new List<String>{
			'Spouse', 'Authorised Representative', 'Executive', 'Authorised Representative', 'Beneficiary'
	};

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

	public List<Id> start(Database.BatchableContext bContext) {
		return getAccountIdsForScreening();
	}

	/**
	 * Batch execute method to export a list of Accounts to the Ondato system.
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