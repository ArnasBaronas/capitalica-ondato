import {api, LightningElement, track, wire} from 'lwc';
import sendMatchReview from '@salesforce/apex/OndatoService.sendMatchReview';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from 'lightning/actions';

const MATCH_STATUSES = [
    { label: 'Open', value: 'Open' },
    { label: 'True Positive', value: 'TruePositive' },
    { label: 'False Positive', value: 'FalsePositive' },
    { label: 'Discarded', value: 'Discarded' },
];

const DEFAULT_STATUS = 'FalsePositive';

export default class AmlMatchReviewCreateForm extends LightningElement {

    @api
    recordId;
    @api
    objectApiName;

    amlMatchReview = {
        status: DEFAULT_STATUS,
        clientRiskRating: undefined,
        clientComment: undefined,
        clientUserId: 'user@capitalica.lt'
    }

    get matchStatuses() {
        return MATCH_STATUSES;
    }


    createReview() {
        console.error((JSON.stringify(this.amlMatchReview)));
        sendMatchReview({amlMatchId: this.recordId, matchReview: this.amlMatchReview}).then(result => {
            if (result) {
                //TODO: update status via record ui API
                console.log('success');
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    //message: reduceErrors(error).join(', '),
                    variant: 'success'
                }));

            }
        }).catch(error => {
            console.error(error);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
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