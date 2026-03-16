({
    onButtonPress : function(component, event, helper) {

        var bubbleEvent = component.getEvent('onButtonWithDataClick');
        bubbleEvent.setParams({
            data: component.get('v.data'),
            name: component.get('v.name'),
            action: component.get('v.action')
        });
        bubbleEvent.fire();

    }
})