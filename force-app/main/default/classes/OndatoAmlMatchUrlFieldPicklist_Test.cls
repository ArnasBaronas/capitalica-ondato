@IsTest
private class OndatoAmlMatchUrlFieldPicklist_Test {
	@IsTest
	static void testVisualEditorValues() {
		VisualEditor.DynamicPickList dynamicPickList = new OndatoAmlMatchUrlFieldPicklist();
		Assert.areEqual(OndatoAmlMatchUrlFieldPicklist.DEFAULT_IMAGE_FIELD_NAME, dynamicPickList.getDefaultValue().getValue());
		Assert.isTrue(dynamicPickList.getValues().size() > 0);
	}

	@IsTest
	static void testFieldAsOptions() {
		Assert.isTrue(OndatoAmlMatchUrlFieldPicklist.getFieldsAsOptions(Account.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getName()).size() > 1);
	}
}