public with sharing class AmlMatchUrlFieldPicklist extends VisualEditor.DynamicPickList {
	@TestVisible
	static final String DEFAULT_IMAGE_FIELD_NAME = 'Profile_Image__c';

	final static List<Schema.DisplayType> ALLOWED_MAPPING_FIELD_TYPES = new List<Schema.DisplayType>{
			Schema.DisplayType.URL
	};

	public override VisualEditor.DataRow getDefaultValue() {
		VisualEditor.DataRow defaultField;
		Schema.DescribeFieldResult fieldInformation = Schema.SObjectType.AML_Match__c.fields.getMap().get(DEFAULT_IMAGE_FIELD_NAME)?.getDescribe();
		if (fieldInformation != null) {
			defaultField = new VisualEditor.DataRow(fieldInformation.getLabel(), fieldInformation.getName());
		}
		return defaultField;
	}

	public override VisualEditor.DynamicPickListRows getValues() {
		VisualEditor.DynamicPickListRows availableFields = new VisualEditor.DynamicPickListRows();

		List<FieldOption> fieldOptions = getFieldsAsOptions(AML_Match__c.SObjectType.getDescribe().getName());
		fieldOptions.remove(0); //Removing first empty value
		for(FieldOption fieldOption : fieldOptions) {
			availableFields.addRow(new VisualEditor.DataRow(fieldOption.label, fieldOption.value));
		}
		return availableFields;
	}

	public with sharing class FieldOption implements Comparable {
		@AuraEnabled
		public String label;

		@AuraEnabled
		public String value;

		public Integer compareTo(Object other) {
			FieldOption otherObject = (FieldOption) other;
			if (this.label == null) {
				return -1;
			}
			return this.label.compareTo(otherObject.label);
		}
	}

	public static List<FieldOption> getFieldsAsOptions(String sObjectName) {
		List<FieldOption> fieldsAsOptions = new List<FieldOption>();
		Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap();
		FieldOption fieldAsOption = new FieldOption();
		fieldAsOption.label = null;
		fieldAsOption.value = null;
		fieldsAsOptions.add(fieldAsOption);
		for (String fieldName : fieldsMap.keySet()) {
			Schema.DescribeFieldResult fieldInformation = fieldsMap.get(fieldName).getDescribe();
			Boolean allowedFieldType = ALLOWED_MAPPING_FIELD_TYPES.contains(fieldInformation.getType());
			if(allowedFieldType) {
				fieldAsOption = new FieldOption();
				fieldAsOption.label = fieldInformation.getLabel();
				fieldAsOption.value = fieldInformation.getName();
				fieldsAsOptions.add(fieldAsOption);
			}
		}
		fieldsAsOptions.sort();
		return fieldsAsOptions;
	}
}