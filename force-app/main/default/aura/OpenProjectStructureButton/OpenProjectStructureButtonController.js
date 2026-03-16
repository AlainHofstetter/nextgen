({
    init : function(component, event, helper) {
        var id = component.get('v.recordId');
        var isUserAllowed = component.get('c.isUserAllowed');

        isUserAllowed.setCallback(this, function(response) {
            var isAllowed = response.getReturnValue();

            console.log('isAllowed', isAllowed);

            if (isAllowed) {
                window.location.replace('/lightning/n/SkywalkApp?c__projectId=' + id + '&c__tab=projectStructure');
            } else {
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();

                var resultsToast = $A.get('e.force:showToast');

                resultsToast.setParams({
                    'title': $A.get('$Label.c.SkyPermissionError') ,
                    'message': $A.get('$Label.c.SkyYouarenotallowedtoopentheProjectStructure') ,
                    'type': 'error'
                });
                resultsToast.fire();
            }
        });

        $A.enqueueAction(isUserAllowed);
    }
})