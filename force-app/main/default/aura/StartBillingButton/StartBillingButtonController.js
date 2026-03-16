({
    init : function(component, event, helper) {
        var get = component.get('c.get');

        get.setParams({
            recordId: component.get('v.recordId'),
        });

        console.log('send record id', component.get('v.recordId'));

        get.setCallback(this, function(response) {
            var id = response.getReturnValue();

            console.log('id', id);

            // •   Current format:  /one/one.app/#/sObject/Account/home
            // •   New format:      /lightning/o/Account/home
            //                      /lightning/n/SkywalkApp?projectId=a0f0X00000Up5xDQAR&0.tab=billing

            if (id) {
                window.location.replace('/lightning/n/SkywalkApp?c__projectId=' + id + '&c__tab=billing');
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