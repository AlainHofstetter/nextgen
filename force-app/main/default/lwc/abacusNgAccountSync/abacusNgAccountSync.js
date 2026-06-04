import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getChangedAccounts from '@salesforce/apex/AbacusNgSyncController.getChangedAccounts';
import markAccountsSynced from '@salesforce/apex/AbacusNgSyncController.markAccountsSynced';

const COLUMNS = [
  {
    label: 'Account',
    fieldName: 'recordUrl',
    type: 'url',
    typeAttributes: { label: { fieldName: 'name' }, target: '_blank' },
    sortable: true
  },
  { label: 'Account #', fieldName: 'accountNumber', type: 'text' },
  { label: 'Owner', fieldName: 'ownerName', type: 'text' },
  {
    label: 'Last Modified',
    fieldName: 'lastModifiedDate',
    type: 'date',
    typeAttributes: {
      year: 'numeric', month: 'short', day: '2-digit',
      hour: '2-digit', minute: '2-digit'
    }
  },
  {
    label: 'Last AbacusNG Sync',
    fieldName: 'abacusNgSyncTimeStamp',
    type: 'date',
    typeAttributes: {
      year: 'numeric', month: 'short', day: '2-digit',
      hour: '2-digit', minute: '2-digit'
    }
  }
];

export default class AbacusNgAccountSync extends LightningElement {
  columns = COLUMNS;
  @track rows = [];
  @track selectedIds = [];
  isLoading = false;
  isSyncing = false;

  connectedCallback() {
    this.loadRows();
  }

  async loadRows() {
    this.isLoading = true;
    try {
      const result = await getChangedAccounts();
      this.rows = result.map((r) => ({
        ...r,
        recordUrl: `/lightning/r/Account/${r.id}/view`
      }));
      this.selectedIds = this.selectedIds.filter((id) =>
        this.rows.some((r) => r.id === id)
      );
    } catch (error) {
      this.showToast('Error', this.extractError(error), 'error');
    } finally {
      this.isLoading = false;
    }
  }

  handleRefresh() {
    this.loadRows();
  }

  handleRowSelection(event) {
    this.selectedIds = event.detail.selectedRows.map((r) => r.id);
  }

  async handleSynchronize() {
    if (this.selectedIds.length === 0) return;
    this.isSyncing = true;
    try {
      const count = await markAccountsSynced({ accountIds: this.selectedIds });
      this.showToast(
        'Synchronized',
        `${count} account${count === 1 ? '' : 's'} marked as synced to AbacusNG.`,
        'success'
      );
      this.selectedIds = [];
      await this.loadRows();
    } catch (error) {
      this.showToast('Synchronization failed', this.extractError(error), 'error');
    } finally {
      this.isSyncing = false;
    }
  }

  get hasRows() {
    return this.rows && this.rows.length > 0;
  }

  get rowCount() {
    return this.rows ? this.rows.length : 0;
  }

  get selectedCount() {
    return this.selectedIds.length;
  }

  get syncDisabled() {
    return this.isSyncing || this.isLoading || this.selectedIds.length === 0;
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  extractError(error) {
    if (!error) return 'Unknown error';
    if (typeof error === 'string') return error;
    if (error.body && error.body.message) return error.body.message;
    if (error.message) return error.message;
    return JSON.stringify(error);
  }
}
