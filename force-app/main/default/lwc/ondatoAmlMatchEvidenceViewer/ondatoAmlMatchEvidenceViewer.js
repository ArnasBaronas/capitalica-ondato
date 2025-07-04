import {api, LightningElement, track} from 'lwc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import { reduceErrors } from 'c/ldsUtils';

import getMatchEvidences from '@salesforce/apex/OndatoService.getMatchEvidences';

export default class OndatoAmlMatchEvidenceViewer extends LightningElement {

    //TODO: hide blank Source
    //TODO: hide blank Publication Date
    //TODO: hide blank summary
    //TODO: hide blank credibility
    //TODO: change card icon
    //TODO: add component icon

    connectedCallback() {
        this.loadEvidences();
    }

    @api
    recordId;

    @api
    listTitle = 'Evidences';

    @api
    recordsToDisplay;

    @api
    linesToClamp;

    @track
    evidences;

    evidencesAll;

    @track
    isEvidenceListExpanded = false;

    @track
    evidencesCount;

    @track
    showSpinner = false;

    hasError = false;

    get isLoading() {
        return !this.hasError && this.evidencesCount === undefined;
    }

    get cardTitle() {
        if (this.evidencesCount && !this.hasError) {
            let countText;

            if (this.isEvidenceListExpanded) {
                countText = this.evidencesCount;
            } else {
                const displayCount = Math.min(this.evidencesCount, this.recordsToDisplay);
                countText = this.recordsToDisplay < this.evidencesCount ? `${displayCount}+` : displayCount;
            }

            return `${this.listTitle} (${countText})`;
        }

        return this.listTitle;
    }

    get evidenceListEmpty() {
        return this.evidencesCount > 0 || this.isLoading;
    }

    get clampStyling() {
        return `-webkit-line-clamp: ${this.linesToClamp}`;
    }

    loadEvidences() {
        getMatchEvidences({
            amlMatchId: this.recordId
        })
            .then(result => {
                this.isEvidenceListExpanded = false;
                this.evidencesCount = result?.length;
                result = result.map((item, index) => {
                    return {
                        ...item,
                        title: item.title?.trim() ? item.title : `Evidence #${index + 1}`,
                        credibility: item.credibility ? `${String(item.credibility).charAt(0).toUpperCase() + String(item.credibility).slice(1)} Credibility` : null
                    };
                });

                this.evidencesAll = [...result];
                result.splice(this.recordsToDisplay);
                this.evidences = result;
                this.showSpinner = false;
                this.hasError = false;
            })
            .catch(error => {
                this.showSpinner = false;
                this.hasError = true;
                this.showToast('Error', reduceErrors(error).join(', '), 'error');
            });
    }

    viewAllEvidences() {
        this.isEvidenceListExpanded = true;
        this.evidences = this.evidencesAll;
    }

    refreshView() {
        this.showSpinner = true;
        this.loadEvidences();
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}