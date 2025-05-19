import {LightningElement, api, wire} from 'lwc';
import {getRecord} from 'lightning/uiRecordApi';
import {getObjectInfo} from "lightning/uiObjectInfoApi";

export default class ImageUrlViewer extends LightningElement {

    @api recordId;
    @api objectApiName;
    @api cardIcon;
    @api fieldName;

    cardLabel;
    imageUrl;
    error;
    fieldValueLoaded = false;

    get isLoading() {
        return !(this.cardLabel && this.fieldValueLoaded);
    }

    get imageUrlField() {
        return `${this.objectApiName}.${this.fieldName}`;
    }

    get fieldsToQuery() {
        return [this.imageUrlField];
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$fieldsToQuery'
    })
    wiredRecord({error, data}) {
        if (!this.fieldsToQuery) {
            return;
        }
        if (data) {
            try {
                this.imageUrl = data.fields[this.fieldName]?.value;
                if (!this.imageUrl) {
                    this.error = `Field "${this.fieldName}" is empty or not found.`;
                }
            } catch (e) {
                this.error = `Unable to read field "${this.fieldName}"`;
            }
        } else if (error) {
            this.error = error.body?.message || 'Unknown error';
        }
        this.fieldValueLoaded = true;
    }

    @wire(getObjectInfo, {
        objectApiName: '$objectApiName'
    })
    objectInfo({error, data}) {
        if (data) {
            const fieldInfo = data.fields[this.fieldName];
            if (fieldInfo) {
                this.cardLabel = fieldInfo.label;
            }
        } else if (error) {
            console.error('Error loading object info', error);
        }
    }
}