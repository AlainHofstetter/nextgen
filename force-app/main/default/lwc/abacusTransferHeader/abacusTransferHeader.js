import { LightningElement, wire } from "lwc";
import ABACUS_LOGO from "@salesforce/resourceUrl/abacus_logo";
import getHeaderData from "@salesforce/apex/AbacusTransferNGHeaderController.getHeaderData";

export default class AbacusTransferHeader extends LightningElement {
  @wire(getHeaderData) wiredHeader;

  get logoUrl() {
    return ABACUS_LOGO;
  }

  get pendingCount() {
    return this.wiredHeader?.data?.pendingCount ?? 0;
  }

  get totalGrossChf() {
    return this.wiredHeader?.data?.totalInvoiceGrossChf ?? 0;
  }

  get lastTransferAt() {
    return this.wiredHeader?.data?.lastTransferAt ?? null;
  }

  get hasLastTransfer() {
    return !!this.lastTransferAt;
  }

  get needsAttentionCount() {
    return this.wiredHeader?.data?.needsAttentionCount ?? 0;
  }

  get needsAttentionClass() {
    return this.needsAttentionCount > 0
      ? "slds-text-heading_medium slds-text-color_error"
      : "slds-text-heading_medium";
  }

  get oldestPendingCreatedAt() {
    return this.wiredHeader?.data?.oldestPendingCreatedAt ?? null;
  }

  get hasOldestPending() {
    return !!this.oldestPendingCreatedAt;
  }

  get oldestPendingAge() {
    if (!this.oldestPendingCreatedAt) {
      return "–";
    }
    const created = new Date(this.oldestPendingCreatedAt).getTime();
    const days = Math.floor((Date.now() - created) / 86400000);
    return `${Math.max(0, days)} d`;
  }

  get pendingInvoiceCount() {
    return this.wiredHeader?.data?.pendingInvoiceCount ?? 0;
  }

  get hasPendingInvoices() {
    return this.pendingInvoiceCount > 0;
  }

  get pendingInvoiceLabel() {
    const count = this.pendingInvoiceCount;
    return count === 1 ? `(${count} invoice)` : `(${count} invoices)`;
  }

  get errorMessage() {
    const error = this.wiredHeader?.error;
    if (!error) {
      return null;
    }
    if (Array.isArray(error.body)) {
      return error.body.map((e) => e.message).join(", ");
    }
    return (
      error.body?.message ?? error.statusText ?? "An unknown error occurred"
    );
  }
}
