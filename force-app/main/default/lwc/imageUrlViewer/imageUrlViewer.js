import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

export default class ImageUrlViewer extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api fieldName;
    @api cardIcon;

    imageUrl;
    cardLabel;
    error;

    imageLoaded = false;
    labelLoaded = false;

    get isLoading() {
        return !(this.imageLoaded && this.labelLoaded);
    }

    get showPlaceholder() {
        return !this.imageUrl && !this.isLoading && !this.error;
    }

    get imageUrlField() {
        return `${this.objectApiName}.${this.fieldName}`;
    }

    get fieldsToQuery() {
        return [this.imageUrlField];
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$fieldsToQuery' })
    wiredRecord({ error, data }) {
        this.imageLoaded = true;
        if (error) {
            this.error = error.body?.message || 'Unable to load image field.';
        } else if (data) {
            try {
                const fieldData = data.fields?.[this.fieldName];
                this.imageUrl = fieldData?.value || null;
            } catch (e) {
                this.error = `Error accessing field "${this.fieldName}"`;
            }
        }
    }

    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    wiredObjectInfo({ error, data }) {
        this.labelLoaded = true;
        if (data) {
            const fieldInfo = data.fields?.[this.fieldName];
            if (fieldInfo) {
                this.cardLabel = fieldInfo.label;
            }
        } else if (error) {
            console.error('Object info error:', error);
        }
    }

    handleImageError() {
        this.imageUrl = null;
    }
}