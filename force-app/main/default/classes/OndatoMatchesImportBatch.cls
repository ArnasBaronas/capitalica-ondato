public with sharing class OndatoMatchesImportBatch implements Schedulable, Database.Batchable<Id>, Database.AllowsCallouts {

	/** @description Executes the batch job immediately. */
	public static void execute() {
		new OndatoMatchesImportBatch().execute(null);
	}

	/**
	 * @description Schedules the batch job using the provided cron expression.
	 * @param sContext SchedulableContext
	 */
	public void execute(SchedulableContext sContext) {
		OndatoMatchesImportBatch batch = new OndatoMatchesImportBatch();
		Database.executeBatch(batch, Integer.valueOf(Ondato_Settings__c.getInstance().Matches_Import_Batch_Size__c));
	}

	/**
	 * @description Schedules the batch job with the given cron expression.
	 * @param cronExpression String representing the cron expression for scheduling the job.
	 */
	public static void scheduleBatch(String cronExpression) {
		OndatoMatchesImportBatch batch = new OndatoMatchesImportBatch();
		String jobName = Label.ONDATO_MATCHES_IMPORT_JOB_NAME;
		if (Test.isRunningTest()) {
			jobName += ' Test Scenario';
		}
		System.schedule(jobName, cronExpression, batch);
	}

	public List<Id> start(Database.BatchableContext bContext) {
		List<Id> accountInOndatoWorklist = new List<Id>(new Map<Id, SObject>([
				SELECT Id
				FROM Account
				WHERE Ondato_Id__c != NULL
				WITH SECURITY_ENFORCED
		]).keySet());

		return accountInOndatoWorklist;
	}

	/**
	 * Batch execute method to retrieve AML matches form the Ondato
	 * system and create/update them on Salesforce.
	 * It handles both Person Accounts and Business Accounts.
	 *
	 * @param bContext   The batch context.
	 * @param accountIds List of Account record IDs to process in this batch.
	 */
	public void execute(Database.BatchableContext bContext, List<Id> accountIds) {
		List<AML_Match__c> amlMatches = new List<AML_Match__c>();
		List<Account> accounts = [
				SELECT Id, Name, Ondato_Id__c, IsPersonAccount
				FROM Account
				WHERE Id IN :accountIds
		];

		for (Account account : accounts) {
			amlMatches.addAll(OndatoService.getAmlMatches(account, false, false));
		}

		Logger.saveLog();
		Database.upsert(amlMatches, AML_Match__c.Match_ID__c);
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