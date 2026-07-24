import { createElement } from "lwc";
import AbacusTransferHeader from "c/abacusTransferHeader";
import getHeaderData from "@salesforce/apex/AbacusTransferNGHeaderController.getHeaderData";

// Force @salesforce/apex/... into an emit-able test wire adapter.
jest.mock(
  "@salesforce/apex/AbacusTransferNGHeaderController.getHeaderData",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

// Helper to wait for any asynchronous DOM updates.
async function flushPromises() {
  return Promise.resolve();
}

function createComponent() {
  const element = createElement("c-abacus-transfer-header", {
    is: AbacusTransferHeader
  });
  document.body.appendChild(element);
  return element;
}

describe("c-abacus-transfer-header", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders KPI values from the wire data", async () => {
    const element = createComponent();

    getHeaderData.emit({
      pendingCount: 2,
      totalInvoiceGrossChf: 1234.5,
      lastTransferAt: "2026-07-01T10:00:00.000Z",
      needsAttentionCount: 0,
      oldestPendingCreatedAt: null,
      pendingInvoiceCount: 0
    });

    await flushPromises();

    const numbers = element.shadowRoot.querySelectorAll(
      "lightning-formatted-number"
    );
    // pendingCount, totalGrossChf, needsAttentionCount.
    expect(numbers.length).toBe(3);
    expect(numbers[0].value).toBe(2);
    expect(numbers[1].value).toBe(1234.5);
    expect(numbers[1].currencyCode).toBe("CHF");
    expect(numbers[2].value).toBe(0);

    const dateTime = element.shadowRoot.querySelector(
      "lightning-formatted-date-time"
    );
    expect(dateTime).not.toBeNull();
    expect(dateTime.value).toBe("2026-07-01T10:00:00.000Z");
  });

  it("colours the Needs Attention value red only when count > 0", async () => {
    const element = createComponent();

    getHeaderData.emit({
      pendingCount: 0,
      totalInvoiceGrossChf: 0,
      lastTransferAt: null,
      needsAttentionCount: 3,
      oldestPendingCreatedAt: null,
      pendingInvoiceCount: 0
    });

    await flushPromises();

    let errorValue = element.shadowRoot.querySelector(
      ".slds-text-heading_medium.slds-text-color_error"
    );
    expect(errorValue).not.toBeNull();
    const numbers = element.shadowRoot.querySelectorAll(
      "lightning-formatted-number"
    );
    // Last formatted-number is the Needs Attention count.
    expect(numbers[numbers.length - 1].value).toBe(3);

    getHeaderData.emit({
      pendingCount: 0,
      totalInvoiceGrossChf: 0,
      lastTransferAt: null,
      needsAttentionCount: 0,
      oldestPendingCreatedAt: null,
      pendingInvoiceCount: 0
    });

    await flushPromises();

    errorValue = element.shadowRoot.querySelector(
      ".slds-text-heading_medium.slds-text-color_error"
    );
    expect(errorValue).toBeNull();
  });

  it("renders Oldest Pending age in whole days, and a dash when null", async () => {
    const element = createComponent();

    // A timestamp two days ago should floor to "2 d".
    const twoDaysAgo = new Date(Date.now() - 2 * 86400000).toISOString();
    getHeaderData.emit({
      pendingCount: 1,
      totalInvoiceGrossChf: 0,
      lastTransferAt: null,
      needsAttentionCount: 0,
      oldestPendingCreatedAt: twoDaysAgo,
      pendingInvoiceCount: 0
    });

    await flushPromises();
    expect(element.shadowRoot.textContent).toContain("2 d");

    getHeaderData.emit({
      pendingCount: 0,
      totalInvoiceGrossChf: 0,
      lastTransferAt: null,
      needsAttentionCount: 0,
      oldestPendingCreatedAt: null,
      pendingInvoiceCount: 0
    });

    await flushPromises();
    // Oldest Pending cell shows a dash; find it by the title-less heading text.
    const cells = element.shadowRoot.querySelectorAll(".slds-text-title_caps");
    const oldestCell = Array.from(cells).find(
      (c) => c.textContent === "Oldest Pending"
    );
    expect(oldestCell.nextElementSibling.textContent.trim()).toBe("–");
  });

  it("appends a pluralized invoice count, omitted when zero", async () => {
    const element = createComponent();

    getHeaderData.emit({
      pendingCount: 1,
      totalInvoiceGrossChf: 500,
      lastTransferAt: null,
      needsAttentionCount: 0,
      oldestPendingCreatedAt: null,
      pendingInvoiceCount: 1
    });

    await flushPromises();
    expect(element.shadowRoot.textContent).toContain("(1 invoice)");
    expect(element.shadowRoot.textContent).not.toContain("(1 invoices)");

    getHeaderData.emit({
      pendingCount: 3,
      totalInvoiceGrossChf: 500,
      lastTransferAt: null,
      needsAttentionCount: 0,
      oldestPendingCreatedAt: null,
      pendingInvoiceCount: 3
    });

    await flushPromises();
    expect(element.shadowRoot.textContent).toContain("(3 invoices)");

    getHeaderData.emit({
      pendingCount: 0,
      totalInvoiceGrossChf: 0,
      lastTransferAt: null,
      needsAttentionCount: 0,
      oldestPendingCreatedAt: null,
      pendingInvoiceCount: 0
    });

    await flushPromises();
    expect(element.shadowRoot.textContent).not.toContain("invoice");
  });

  it("renders a dash when there is no last transfer", async () => {
    const element = createComponent();

    getHeaderData.emit({
      pendingCount: 0,
      totalInvoiceGrossChf: 0,
      lastTransferAt: null
    });

    await flushPromises();

    const dateTime = element.shadowRoot.querySelector(
      "lightning-formatted-date-time"
    );
    expect(dateTime).toBeNull();
    expect(element.shadowRoot.textContent).toContain("–");
  });

  it("renders an error message when the wire errors", async () => {
    const element = createComponent();

    getHeaderData.emitError({
      body: { message: "Something went wrong" },
      ok: false,
      status: 400,
      statusText: "Bad Request"
    });

    await flushPromises();

    const errorEl = element.shadowRoot.querySelector(".slds-text-color_error");
    expect(errorEl).not.toBeNull();
    expect(errorEl.textContent).toContain("Something went wrong");
  });

  it("points the logo image at the abacus_logo static resource", async () => {
    const element = createComponent();

    await flushPromises();

    const img = element.shadowRoot.querySelector("img.abacus-logo");
    expect(img).not.toBeNull();
    expect(img.src).toContain("abacus_logo");
  });
});
