/**
 * @description This class part of Ondato x Salesforce integration. It provides a dynamic picklist of URL-type fields for the Ondato_AML_Match__c object,
 *              specifically intended for imageUrlViewer lwc component for configuration in lightning app builder. It allows users
 *              to select from valid fields (of type URL) and defines a default image field selection in lightning app builder.
 *
 * @author <a href="mailto:arnasbaronas@gmail.com">Arnas Baronas</a>
 */
public with sharing class OndatoAmlMatchUrlFieldPicklist extends VisualEditor.DynamicPickList {

	/** @description The default field name for image URLs used in the Ondato_AML_Match__c object. */
	@TestVisible
	static final String DEFAULT_IMAGE_FIELD_NAME = 'Profile_Image__c';

	/** @description Defines the allowed field types for the dynamic picklist. */
	final static List<Schema.DisplayType> ALLOWED_MAPPING_FIELD_TYPES = new List<Schema.DisplayType>{
			Schema.DisplayType.URL
	};

	/**
     * @description Returns the default selected field in the picklist, if available.
     *              Defaults to the field defined in DEFAULT_IMAGE_FIELD_NAME.
     *
     * @return VisualEditor.DataRow The default field's label and name if found, otherwise null.
     */
	public override VisualEditor.DataRow getDefaultValue() {
		VisualEditor.DataRow defaultField;
		Schema.DescribeFieldResult fieldInformation = Schema.SObjectType.Ondato_AML_Match__c.fields.getMap().get(DEFAULT_IMAGE_FIELD_NAME)?.getDescribe();
		if (fieldInformation != null) {
			defaultField = new VisualEditor.DataRow(fieldInformation.getLabel(), fieldInformation.getName());
		}
		return defaultField;
	}

	/**
	 * @description Returns all valid picklist options for the Ondato_AML_Match__c object,
	 *              filtering only fields of type URL and excluding the initial placeholder option.
	 *
	 * @return VisualEditor.DynamicPickListRows A list of picklist rows with label and value.
	 */
	public override VisualEditor.DynamicPickListRows getValues() {
		VisualEditor.DynamicPickListRows availableFields = new VisualEditor.DynamicPickListRows();

		List<FieldOption> fieldOptions = getFieldsAsOptions(Ondato_AML_Match__c.SObjectType.getDescribe().getName());
		fieldOptions.remove(0); //Removing first empty value
		for (FieldOption fieldOption : fieldOptions) {
			availableFields.addRow(new VisualEditor.DataRow(fieldOption.label, fieldOption.value));
		}
		return availableFields;
	}

	/**
	 * @description Inner class representing an individual field option with a label and value.
	 *              Implements Comparable to allow sorting by label.
	 */
	public with sharing class FieldOption implements Comparable {

		/** @description The user-facing label of the field. */
		@AuraEnabled
		public String label;

		/** @description The API name of the field used as the picklist value. */
		@AuraEnabled
		public String value;

		/**
		 * @description Compares FieldOption instances alphabetically by label.
		 *
		 * @param other Another FieldOption object.
		 * @return Integer Result of the comparison for sorting purposes.
		 */
		public Integer compareTo(Object other) {
			FieldOption otherObject = (FieldOption) other;
			if (this.label == null) {
				return -1;
			}
			return this.label.compareTo(otherObject.label);
		}
	}

	/**
	 * @description Retrieves all URL-type fields for a given SObject name, sorted alphabetically by label.
	 *
	 * @param sObjectName The API name of the SObject to retrieve fields from.
	 * @return List<FieldOption> List of fields represented as FieldOption objects.
	 */
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
			if (allowedFieldType) {
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