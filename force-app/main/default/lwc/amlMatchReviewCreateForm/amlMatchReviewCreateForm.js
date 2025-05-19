import {api, LightningElement, track, wire} from 'lwc';
import sendMatchReview from '@salesforce/apex/OndatoService.sendMatchReview';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from 'lightning/actions';

//TODO: get values from match status fields
const MATCH_STATUSES = [
    { label: 'Open', value: 'Open' },
    { label: 'True Positive', value: 'TruePositive' },
    { label: 'False Positive', value: 'FalsePositive' },
    { label: 'Discarded', value: 'Discarded' },
];

//TODO: mark existing status as default
const DEFAULT_STATUS = 'FalsePositive';

export default class AmlMatchReviewCreateForm extends LightningElement {

    @api
    recordId;
    @api
    objectApiName;

    //TODO: change values on input changes
    amlMatchReview = {
        status: DEFAULT_STATUS,
        clientRiskRating: null,
        clientComment: null,
        //TODO: put current user name as clientUserId
        clientUserId: 'user@capitalica.lt'
    }

    get matchStatuses() {
        return MATCH_STATUSES;
    }


    createReview() {
        sendMatchReview({amlMatchId: this.recordId, amlMatchReviewMap: this.amlMatchReview}).then(result => {
            if (result) {
                //TODO: update status via record ui API
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    variant: 'success'
                }));
            }
        }).catch(error => {
            console.error(error);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                //TODO: import reduceErrors class
                //message: reduceErrors(error).join(', '),
                variant: 'error'
            }));
        }).then(() => {
            this.dispatchEvent(new CloseActionScreenEvent());
        });
    }

    closeForm() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

}