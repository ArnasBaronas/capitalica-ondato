import {api, LightningElement, track} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import { reduceErrors } from 'c/ldsUtils';

import getMatchEvidences from '@salesforce/apex/OndatoService.getMatchEvidences';

const LIST_TITLE = 'Evidences';

const CREDIBILITY_SORT_ORDER = {
    'High': 1,
    'Medium': 2,
    'Low': 3,
    '': 4,
    null: 4,
    undefined: 4
};

export default class OndatoAmlMatchEvidenceViewer extends LightningElement {

    //TODO: write unit tests
    //TODO: fix all evidences disable feature
    //TODO: change worklist Id field into resource Id
    //TODO: fix width bug on expansion https://capitalica--partial.sandbox.lightning.force.com/lightning/r/Ondato_AML_Match__c/a0FJW000008afjX2AQ/view

    connectedCallback() {
        this.loadEvidences();
    }

    @api
    recordId;

    listTitle = LIST_TITLE;

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
                result = result.map((item) => {
                    return {
                        ...item,
                        // modifying credibility value
                        credibility: item.credibility ? `${String(item.credibility).charAt(0).toUpperCase() + String(item.credibility).slice(1)} Credibility` : null,
                        // for sorting by credibility
                        _credibilitySortKey: CREDIBILITY_SORT_ORDER[item.credibility] ?? 4
                    };
                });

                // removing evidence if do not contain originalUrl
                result = result.filter(item => item.originalUrl?.trim());

                //sorting by credibility
                result.sort((a, b) => a._credibilitySortKey - b._credibilitySortKey);
                result.forEach(item => delete item._credibilitySortKey);

                result = result.map((item, index) => {
                    return {
                        ...item,
                        // adding fake title if it is blank
                        title: item.title?.trim() ? item.title : `Evidence #${index + 1}`,
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
                this.showToast('Error', `Error while getting evidences: '${reduceErrors(error).join(', ')}`, 'error');
            });
    }

    openEvidenceSource(event) {
        const evidenceId = event.currentTarget.dataset.evidenceId;
        const matchedEvidence = this.evidences.find(
            evidence => evidence.evidenceId === evidenceId
        );
        if (matchedEvidence?.originalUrl) {
            window.open(matchedEvidence.originalUrl, '_blank');
        } else {
            this.showToast('Warning', 'Evidence source not found', 'warning');
        }
    }

    get isViewAllDisabled() {
        return this.recordsToDisplay >= this.evidencesCount;
    }

    get viewAllLinkStyle() {
        return this.isViewAllDisabled ? 'cursor: not-allowed; pointer-events: none; opacity: 0.6;' : '';
    }

    handleViewAllClick() {
        if (this.isViewAllDisabled) {
            //event.preventDefault();
            return;
        }
        this.viewAllEvidences();
    }

    viewAllEvidences() {
        this.isEvidenceListExpanded = true;
        this.evidences = [...this.evidencesAll];
    }

    showLessEvidences() {
        this.isEvidenceListExpanded = false;
        this.evidences.splice(this.recordsToDisplay);
    }

    refreshView() {
        this.showSpinner = true;
        this.loadEvidences();
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}