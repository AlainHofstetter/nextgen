({
  // Flip the lazy-instantiation flag for a tab so its list view renders. The
  // default (pendingApproval) has no flag and needs no toggling.
  markRendered: function (component, tabId) {
    var rendered;
    if (!tabId || tabId === "pendingApproval") {
      return;
    }
    rendered = component.get("v.rendered");
    if (rendered && rendered[tabId] !== true) {
      rendered[tabId] = true;
      component.set("v.rendered", rendered);
    }
  },

  // Fetch the status counts and rebuild the tab labels. On error, leave the
  // current labels in place (safe "(0)" defaults) so we never show "undefined".
  loadCounts: function (component) {
    var self = this;
    var action;
    action = component.get("c.getStatusCounts");
    action.setCallback(this, function (response) {
      var counts;
      if (response.getState() !== "SUCCESS") {
        return;
      }
      counts = response.getReturnValue() || {};
      self.applyLabels(component, counts);
    });
    $A.enqueueAction(action);
  },

  // Build the label object from a counts map keyed by raw Status__c value. A
  // missing key counts as 0. Sent and All show no count.
  applyLabels: function (component, counts) {
    var countFor = function (status) {
      var value = counts[status];
      return typeof value === "number" ? value : 0;
    };
    component.set("v.labels", {
      pendingApproval: "Pending Approval (" + countFor("PendingApproval") + ")",
      pending: "Pending (" + countFor("Pending") + ")",
      inFlight: "In Flight (" + countFor("InFlight") + ")",
      failed: "Failed (" + countFor("Failed") + ")",
      deadLettered: "Dead Lettered (" + countFor("DeadLettered") + ")",
      sent: "Sent",
      all: "All"
    });
  }
});
