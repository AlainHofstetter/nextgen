({
    init : function(component, event, helper) {
        var get = component.get('c.get');

        get.setParams({
            recordId: component.get('v.recordId'),
        });

        get.setCallback(this, function(response) {
            var id = response.getReturnValue();

            console.log('id', id);

            if (id) {
                window.location.replace('/lightning/n/SkywalkApp?c__projectId=' + id + '&c__tab=ilv');
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

        $A.enqueueAction(get);
    }
})