public class EntityDetailsResponse {

	public String resourceId;

	public List<Address> addresses;

	@AuraEnabled
	public List<OndatoService.EvidenceDetails> evidences;

	public class Address {
		public String line1;
		public String line2;
		public String postCode;
		public String city;
		public String county;
		public String countryIsoCode;
	}
}