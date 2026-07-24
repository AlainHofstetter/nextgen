({
  doInit: function (component, event, helper) {
    helper.loadCounts(component);
  },

  onTabActive: function (component, event, helper) {
    // lazily instantiate this tab's list view on first activation
    var tabId = event.getSource().get("v.id");
    helper.markRendered(component, tabId);

    // keep the tab-label counts fresh as users approve / replay rows
    helper.loadCounts(component);
  }
});
