/**
 * @description Batch Apex implementation for importing AML match records from the Ondato system into Salesforce.
 * This job processes accounts with a non-null Ondato ID and retrieves their corresponding AML match records via callouts.
 *
 * Match records are upserted using the external ID field `Match_ID__c` on `Ondato_AML_Match__c`.
 *  Batch size is controlled by `Ondato_Settings__c.Matches_Import_Batch_Size__c`.
 *
 * @author <a href="mailto:arnasbaronas@gmail.com">Arnas Baronas</a>
 */
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

	/**
	 * @description Start method to define the scope of the batch process.
	 * Retrieves all Account records that have a value in the `Ondato_Id__c` field.
	 * @param bContext Batchable context object.
	 * @return A list of Account record IDs that need to be processed.
	 */
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
	 * @description Batch execute method to retrieve AML matches form the Ondato
	 * system and create/update them on Salesforce.
	 * It handles both Person Accounts and Business Accounts.
	 *
	 * @param bContext   The batch context.
	 * @param accountIds List of Account record IDs to process in this batch.
	 */
	public void execute(Database.BatchableContext bContext, List<Id> accountIds) {
		List<Ondato_AML_Match__c> amlMatches = new List<Ondato_AML_Match__c>();
		List<Account> accounts = [
				SELECT Id, Name, Ondato_Id__c, IsPersonAccount
				FROM Account
				WHERE Id IN :accountIds
		];

		for (Account account : accounts) {
			amlMatches.addAll(OndatoService.getAmlMatches(account, false, false));
		}

		Logger.saveLog();
		Database.upsert(amlMatches, Ondato_AML_Match__c.Match_ID__c);
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