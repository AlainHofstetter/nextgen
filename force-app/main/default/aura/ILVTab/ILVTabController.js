({

    init : function(component, event, helper) {

        moment.locale($A.get('$Locale.userLocaleLang'));

        console.log('init!');

        // defaults
        component.set('v.errors', []);

        // listen for a project id so we point them to the billing tab
        // again, because passing from app component is too slow
        var projectId = null,
            magicURLmatches = window.location.href.match(/\?c__projectId=(.+)&c__tab=(.+)/);

        if(magicURLmatches.length === 3) {
            component.set('v.projectId', magicURLmatches[1]);
        }

        // load ILV recordType id so we can save
        var action = component.get('c.getILVRecordTypeId');
        action.setCallback(this, function(data){
            component.set('v.ILVRecordTypeId', data.getReturnValue());
        });
        $A.enqueueAction(action);

        // loading initial data
        helper.loadData(component, helper);

    },

    onInvoiceProgressFocus: function(component, event, helper){

        var value = helper.giveMeANumberOrGiveMeZero(event.getSource().get('v.value'));
        if(value === 0) event.getSource().set('v.value', '');

    },

    onInvoiceInProgressBlurred: function(component, event, helper){

        // when we have an empty string, show a pretty zero
        var value = helper.giveMeANumberOrGiveMeZero(event.getSource().get('v.value'));
        if(value === 0) event.getSource().set('v.value', value);

        helper.calculateColumns(component, helper);

    },

    onDateRangeBlurred: function(component, event, helper){

        var data = component.get('v.data');

        if(data !== null){
            component.set('v.keepUserEnteredDateRange', true);
        }

    },

    onLoadPackagesClick: function(component, event, helper) {
        helper.loadData(component, helper);
    },

    onUpdateInvoiceClick: function(component, event, helper){
        helper.saveInvoice(component, helper);
    }

})