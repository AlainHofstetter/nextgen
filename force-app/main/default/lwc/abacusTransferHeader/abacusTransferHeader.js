import { LightningElement, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { refreshApex } from "@salesforce/apex";
import ABACUS_LOGO from "@salesforce/resourceUrl/abacus_logo";
import getHeaderData from "@salesforce/apex/AbacusTransferNGHeaderController.getHeaderData";

export default class AbacusTransferHeader extends NavigationMixin(
  LightningElement
) {
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

  handleOpenFullList() {
    this[NavigationMixin.Navigate]({
      type: "standard__objectPage",
      attributes: {
        objectApiName: "AbacusTransferNG__c",
        actionName: "list"
      },
      state: {
        filterName: "PendingApproval"
      }
    });
  }

  handleRefresh() {
    return refreshApex(this.wiredHeader);
  }
}
