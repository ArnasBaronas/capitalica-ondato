/**
 * @description Response wrapper class used to return evidence details from the OndatoService.
 *              This class is intended to be used in Aura-enabled components or LWC where Ondato-related
 *              evidence details are required.
 * @author <a href="mailto:arnasbaronas@gmail.com">Arnas Baronas</a>
 */
public class EntityDetailsResponse {

	/**
     * @description A list of evidence details returned from the OndatoService.
     *              Each entry represents an individual piece of evidence related to an entity.
     * @see OndatoService.EvidenceDetails
     */
	@AuraEnabled
	public List<OndatoService.EvidenceDetails> evidences;
}