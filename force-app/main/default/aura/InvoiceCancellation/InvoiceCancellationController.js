({
    go: function(component, event, helper) {
        var action = component.get('c.cancel');
        action.setParams({
            'invoiceId': component.get('v.recordId')
        });

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state === "SUCCESS") {
                $A.get("e.force:closeQuickAction").fire();

                var urlEvent = $A.get('e.force:navigateToURL');
                urlEvent.setParams({
                    'url': '/' + response.getReturnValue()
                });
                urlEvent.fire();
            } else {
                var errors = response.getError();
                console.log(errors);
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": "Error",
                    "message": errors[0] && errors[0].pageErrors ? errors[0].pageErrors[0].message : 'Unknown error',
                    "type": "error"
                });
                $A.get("e.force:closeQuickAction").fire();
                resultsToast.fire();
            }
        });


        $A.util.toggleClass(component.find('spinner'), 'slds-hide');
        $A.util.toggleClass(component.find('btns'), 'slds-hide');
        $A.enqueueAction(action);

    },

    close: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})