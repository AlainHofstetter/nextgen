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
      lastTransferAt: "2026-07-01T10:00:00.000Z"
    });

    await flushPromises();

    const numbers = element.shadowRoot.querySelectorAll(
      "lightning-formatted-number"
    );
    expect(numbers.length).toBe(2);
    expect(numbers[0].value).toBe(2);
    expect(numbers[1].value).toBe(1234.5);
    expect(numbers[1].currencyCode).toBe("CHF");

    const dateTime = element.shadowRoot.querySelector(
      "lightning-formatted-date-time"
    );
    expect(dateTime).not.toBeNull();
    expect(dateTime.value).toBe("2026-07-01T10:00:00.000Z");
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
