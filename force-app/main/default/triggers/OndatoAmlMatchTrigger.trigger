trigger OndatoAmlMatchTrigger on Ondato_AML_Match__c (after insert, after update) {
	OndatoAmlMatchHistoryHandler.handleChangeEvent(Trigger.new, Trigger.operationType);
}