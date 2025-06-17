@IsTest
private class AmlMatchUrlFieldPicklist_Test {
	@IsTest
	static void testVisualEditorValues() {
		VisualEditor.DynamicPickList dynamicPickList = new AmlMatchUrlFieldPicklist();
		Assert.areEqual(AmlMatchUrlFieldPicklist.DEFAULT_IMAGE_FIELD_NAME, dynamicPickList.getDefaultValue().getValue());
		Assert.isTrue(dynamicPickList.getValues().size() > 0);
	}

	@IsTest
	static void testFieldAsOptions() {
		Assert.isTrue(AmlMatchUrlFieldPicklist.getFieldsAsOptions(Account.SObjectType.getDescribe().getName()).size() > 1);
	}
}