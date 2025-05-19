import sendMatchReview from '@salesforce/apex/OndatoService.sendMatchReview';

import {reduceErrors} from 'c/ldsUtils';
import {getPicklistValues, getObjectInfo} from "lightning/uiObjectInfoApi";
import {getRecord, updateRecord} from 'lightning/uiRecordApi';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {CloseActionScreenEvent} from 'lightning/actions';
import {api, LightningElement, track, wire} from 'lwc';

import USER_ID from '@salesforce/user/Id';
import USER_NAME_FIELD from '@salesforce/schema/User.Name';
import USER_EMAIL_FIELD from '@salesforce/schema/User.Email';
import AML_MATCH_OBJECT from '@salesforce/schema/AML_Match__c';
import AML_MATCH_STATUS_FIELD from '@salesforce/schema/AML_Match__c.Status__c';
import AML_MATCH_SCORE_FIELD from '@salesforce/schema/AML_Match__c.Score__c';

const USER_FIELDS_TO_QUERY = [USER_NAME_FIELD, USER_EMAIL_FIELD];
const AML_MATCH_FIELDS_TO_QUERY = [AML_MATCH_STATUS_FIELD, AML_MATCH_SCORE_FIELD];

export default class AmlMatchReviewCreateForm extends LightningElement {

    @api
    recordId;
    @api
    objectApiName;

    @track amlMatchReview = {
        status: undefined,
        clientRiskRating: undefined,
        clientComment: undefined,
        clientUserId: undefined
    };

    isSubmitDisabled = true;

    @wire(getRecord, {recordId: USER_ID, fields: USER_FIELDS_TO_QUERY})
    wiredUser({error, data}) {
        if (data) {
            this.amlMatchReview.clientUserId = data.fields.Email.value;
        } else if (error) {
            console.error('Error fetching user:', error);
        }
    }

    @wire(getRecord, {recordId: '$recordId', fields: AML_MATCH_FIELDS_TO_QUERY})
    wiredAmlMatch({error, data}) {
        if (data) {
            this.amlMatchReview.status = data.fields.Status__c.value;
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
    wiredPicklistValues({ error, data }) {
        if (data) {
            // TODO: Discarded can only be set to matches with the score 0
            this.matchStatusOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            console.error('Error loading picklist values', error);
        }
    }

    @track
    matchStatusOptions = [];

    handleChange(event) {
        const field = event.target.name || 'status';
        const value = event.detail.value || event.target.value;

        this.amlMatchReview = {
            ...this.amlMatchReview,
            [field]: value
        };

        this.validateForm();
    }

    validateForm() {
        this.isSubmitDisabled = Object.values(this.amlMatchReview).some(
            value => value === null || value === undefined || value === ''
        );
    }

    createReview() {
        sendMatchReview({
            amlMatchId: this.recordId,
            amlMatchReviewMap: this.amlMatchReview,
            performDML: false
        }).then(matchStatus => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Review created successfully',
                variant: 'success'
            }));
            let fields = {
                Id: this.recordId,
                Status__c: matchStatus
            };
            let recordToUpdate = {fields: fields}
            updateRecord(recordToUpdate)
                .then(() => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Success",
                            message: "Match successfully updated.",
                            variant: "success",
                        }),
                    );
                    this.dispatchEvent(new CloseActionScreenEvent());
                })
                .catch((error) => {
                    console.error(error);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Error updating AML match",
                            message: error.body.message,
                            variant: "error",
                        }),
                    );
                });
        }).catch(error => {
            console.error(error);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: reduceErrors(error).join(', '),
                variant: 'error'
            }));
        }).finally(() => {
            this.dispatchEvent(new CloseActionScreenEvent());
        });
    }

    closeForm() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}