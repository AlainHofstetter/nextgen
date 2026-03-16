({

    init: function(component, event, helper){

        moment.locale($A.get('$Locale.language'));

        component.find('showTime').set('v.value', true);
        component.find('showExpense').set('v.value', true);
        component.find('showSupplierCosts').set('v.value', true);

        component.set('v.errors', []);
        component.set('v.showSuccessMessage', false);

        // listen for a project id
        var projectId = null,
            magicURLmatches = window.location.href.match(/\?c__projectId=(.+)&c__tab=(.+)/);

        if(magicURLmatches && magicURLmatches.length === 3) {

            // demystifying
            var projectId = magicURLmatches[1];

            $A.util.removeClass(component.find('spinner'), 'hidden');

            component.set('v.projectValue', projectId);

            helper.listCosts(component, helper);

        }

    },

    onListCostsClick: function(component, event, helper){
        helper.listCosts(component, helper);
    },

    onValidatedSelectedCostsClick: function(component, event, helper){
        helper.validateSelectedCosts(component, helper);
    },

    onLookupValueChange: function(component, event, helper) {

        var lookupType = event.getParam('lookupType'),
            valueObject = event.getParam('valueObject');

        // bubbling up!
        if(valueObject){

            console.log('valueObject',valueObject);
            if(valueObject.ProjectCurrency__c !== undefined){
                component.set('v.projectCurrency', valueObject.ProjectCurrency__c);
            }

            // if lookup is user
            if(lookupType === 'Package'){
                component.find('accountId').set('v.value', valueObject.ProjectName__r.ProjectPartner__r.Id);
                component.find('accountId').set('v.valueLabel', valueObject.ProjectName__r.ProjectPartner__r.Name);
                component.find('projectId').set('v.value', valueObject.ProjectName__r.Id);
                component.find('projectId').set('v.valueLabel', valueObject.ProjectName__r.ProjectNr__c + ' - ' + valueObject.ProjectName__r.Name);
            }

            if(lookupType.indexOf('project') > 0){
                component.find('accountId').set('v.value', valueObject.ProjectPartner__r.Id);
                component.find('accountId').set('v.valueLabel', valueObject.ProjectPartner__r.Name);
            }

        }
        // we don't have a value object = the user deselected a lookup
        else {

            if(lookupType === 'Account' || lookupType.indexOf('project') > 0) {
                component.find('packageId').set('v.value', null);
                component.find('packageId').set('v.valueLabel', null);
            }

            if(lookupType === 'Account') {
                component.find('projectId').set('v.value', null);
                component.find('projectId').set('v.valueLabel', null);
            }

        }

    },

    dataButtonWasPressed: function(component, event, helper){

        var params = event.getParams();
        if(params.name == 'sortColumn'){

            var sortOptions = component.get('v.sortOptions'),
                explodedData = params.data.split(':'),
                section = explodedData[0],
                field = explodedData[1];

            // creating object structure if we dont have one already
            if(sortOptions === null) sortOptions = {};

            if(sortOptions[section] === undefined) {
                sortOptions[section] = {
                    field: '',
                    desc: false
                };
            }

            // toggle sorting order
            sortOptions[section].desc = !sortOptions[section].desc;
            // reset to default if switching ordering fields
            if(sortOptions[section].field !== field) sortOptions[section].desc = true;

            // save field
            sortOptions[section].field = field;

            // saving options to component
            console.log('setting sort options', field, !sortOptions[section].desc);
            component.set('v.sortOptions', sortOptions);

            // reloading the cached data and order them
            helper.listCachedData(component, helper);


        }

    }
})