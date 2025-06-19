import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, /*updateRecord,*/ notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { reduceErrors } from 'c/ldsUtils';
import sendMatchReview from '@salesforce/apex/OndatoService.sendMatchReview';

import USER_ID from '@salesforce/user/Id';
import USER_NAME_FIELD from '@salesforce/schema/User.Name';
import USER_EMAIL_FIELD from '@salesforce/schema/User.Email';
import AML_MATCH_OBJECT from '@salesforce/schema/Ondato_AML_Match__c';
import AML_MATCH_STATUS_FIELD from '@salesforce/schema/Ondato_AML_Match__c.Status__c';
import AML_MATCH_SCORE_FIELD from '@salesforce/schema/Ondato_AML_Match__c.Score__c';

const USER_FIELDS = [USER_NAME_FIELD, USER_EMAIL_FIELD];
const AML_MATCH_FIELDS = [AML_MATCH_STATUS_FIELD, AML_MATCH_SCORE_FIELD];

export default class OndatoAmlMatchReviewCreateForm extends LightningElement {
    @api recordId;
    @api objectApiName;

    @track amlMatchReview = {
        status: '',
        //clientRiskRating: '',
        clientComment: '',
        clientUserId: ''
    };

    @track matchStatusOptions = [];

    amlMatchScore;
    isSubmitDisabled = true;

    @wire(getRecord, { recordId: USER_ID, fields: USER_FIELDS })
    handleUser({ data, error }) {
        if (data) {
            this.amlMatchReview.clientUserId = data.fields.Email.value;
        } else if (error) {
            console.error('Error fetching user:', error);
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: AML_MATCH_FIELDS })
    handleAmlMatch({ data, error }) {
        if (data) {
            this.amlMatchReview.status = data.fields.Status__c.value;
            this.amlMatchScore = data.fields.Score__c.value;
        } else if (error) {
            console.error('Error fetching AML match:', error);
        }
    }

    @wire(getObjectInfo, { objectApiName: AML_MATCH_OBJECT })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: AML_MATCH_STATUS_FIELD
    })
    handlePicklist({ data, error }) {
        if (data) {
            let options = data.values.map(({ label, value }) => ({ label, value }));
            if (this.amlMatchScore !== 0) {
                options = options.filter(opt => opt.value !== 'Discarded');
            }
            this.matchStatusOptions = options;
        } else if (error) {
            console.error('Error loading picklist values', error);
        }
    }

    handleChange(event) {
        const { name, value } = event.target;
        this.amlMatchReview = { ...this.amlMatchReview, [name]: value };
        this.validateForm();
    }

    validateForm() {
        const { status, /*clientRiskRating,*/ clientComment, clientUserId } = this.amlMatchReview;
        this.isSubmitDisabled = !status /*|| !clientRiskRating*/ || !clientComment || !clientUserId;
    }

    createReview() {
        this.isSubmitDisabled = true;
        sendMatchReview({
            amlMatchId: this.recordId,
            amlMatchReview: this.amlMatchReview,
            performDML: true
        })
            .then(async () => {
                this.showToast('Success', 'Review created successfully', 'success');
                await notifyRecordUpdateAvailable([{recordId: this.recordId}]);
                this.closeForm();
            })
            // since field-level security was restricted for end-users,
            // status update DML is performed in apex with system context
            /*.then(matchReviewSendResult => {
                this.showToast('Success', 'Review created successfully', 'success');
                return updateRecord({
                    fields: { Id: this.recordId, Status__c: matchReviewSendResult.status }
                });
            })
            .then(() => {
                this.closeForm();
            })*/
            .catch(error => {
                this.showToast('Error', reduceErrors(error).join(', '), 'error');
                console.error(error);
            });
    }

    closeForm() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}