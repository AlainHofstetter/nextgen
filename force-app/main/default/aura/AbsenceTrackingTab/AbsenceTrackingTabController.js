({
    /*
        In the beginning...
    */
	init : function(component, event, helper) {

        console.log('init!');

        component.set('v.formFields', ['Id', 'Timetracker__c', 'DateFrom__c', 'DateUntil__c', 'DurationHhMm__c', 'ProjectName__c', 'Package__c', 'Description__c']);

        // set defaults to the date range filter
        component.find('entriesDateRangeStart').set('v.value', moment().subtract(3, 'days').format());
        component.find('entriesDateRangeEnd').set('v.value', moment().format());

        // make sure the list of entries gets populated
        helper.loadEntries(component, helper);

        // get initial user information
        var action = component.get('c.getInitialUserInfo');
        action.setCallback(this, function(response){

            // store for later use
            component.set('v.currentUser', response.returnValue);

            helper.resetForm(component, helper);

        });
        $A.enqueueAction(action);

    },

    // calculate time difference when time fields are changing
    onDateFieldChange: function(component, event, helper) {
        helper.calculateDateDifference(component, helper);
    },

    // handle lookup value changes for the interconnectivity between them
    onLookupValueChange: function(component, event){

        var lookupType = event.getParam('lookupType'),
            valueObject = JSON.parse(event.getParam('valueObject'));

        console.log('LOOKUP VALUE CHANGE!!!', lookupType, valueObject, valueObject.Id);

        // if lookup is package
        if(lookupType.indexOf('Package') >= 0){

            component.set('v.customerValue', valueObject.ProjectName__r.ContractPartner__r.Id);
            component.set('v.customerValueLabel', valueObject.ProjectName__r.ContractPartner__r.Name);
            component.set('v.projectValue', valueObject.ProjectName__r.Id);
            component.set('v.projectValueLabel', valueObject.ProjectName__r.Name);

        }

    },

    onDateRangeSelect: function(component, event, helper){
        console.log('calling this function');
        helper.loadEntries(component, helper);
    },

    onCloneButtonClick: function(component, event, helper) {

        var entryToBeCloned = JSON.parse(event.currentTarget.parentNode.parentNode.getAttribute('data-entry'));
        helper.populateFormWithObject(component, entryToBeCloned);

        // set date to today
        component.find('DateFrom__c').set('v.value', moment().format('YYYY-MM-DD'));

        // and empty ID
        component.find('Id').set('v.value', null);

    },

    onEditButtonClick: function(component, event, helper) {

        var entryToBeCloned = JSON.parse(event.currentTarget.parentNode.parentNode.getAttribute('data-entry'));
        helper.populateFormWithObject(component, entryToBeCloned);

    },

    // the big save time entry method
    save: function(component, event, helper){

        // clear any existing errors
        helper.clearErrors(component);

        // fields to loop through to send to apex
        var fieldsToSave = component.get('v.formFields'),
            timeEntry = {},
            fieldsNotFilledOut = [];

        // loop through fields to save
        for (var i = fieldsToSave.length - 1; i >= 0; i--) {

            // get value + label
            var fieldComponent = component.find(fieldsToSave[i]),
                value = fieldComponent.get('v.value'),
                label = fieldComponent.get('v.label');

            // if empty, add to the field empty list
            if((value === null || value === '') && fieldsToSave[i] !== 'Id'){
                console.log('help with ', fieldsToSave[i]);
                fieldsNotFilledOut.push(label);
            }

            // add to time entry object
            timeEntry[fieldsToSave[i]] = value;

        }

        // put the error on the screen
        if(fieldsNotFilledOut.length > 0){
            helper.addError(component, $A.get('$Label.c.SkyPleasefilloutthesefieldscorrectly') + fieldsNotFilledOut.join(', '));
        }

        // continue if no errors
        if(component.get('v.errors').length == 0){

            // dont confuse salesforce
            timeEntry.sobjectType = 'Time__c';

            // build the request
            var request = component.get('c.saveTimeEntry');
            request.setParams({
                'timeEntry': timeEntry
            });
            request.setCallback(this, function(response) {

                // clear any errors
                helper.clearErrors(component);

                // handle errors
                if(response.getState() === 'ERROR'){
                    console.log('ERROR: ', response);
                    helper.addError(component, $A.get('$Label.c.SkySomethingwentwrongandwewerenotabletosavetheabsencetimeentry'));
                }
                else {
                    // on success, load the entries
                    helper.loadEntries(component, helper);
                    helper.resetForm(component, helper);
                }

                $A.util.addClass(component.find('spinner'), 'hidden');

            });
            $A.util.removeClass(component.find('spinner'), 'hidden');
            $A.enqueueAction(request);

        }

    },

    delete: function(component, event, helper){

        var request = component.get('c.deleteTimeEntry'),
            entryToBeDeleted = JSON.parse(event.currentTarget.parentNode.parentNode.getAttribute('data-entry'));

        entryToBeDeleted.sobjectType = 'Time__c';

        request.setParams({ 'timeEntry': entryToBeDeleted });

        request.setCallback(this, function(response) {
            helper.loadEntries(component, helper);
            $A.util.addClass(component.find('spinner'), 'hidden');
        });

        $A.util.removeClass(component.find('spinner'), 'hidden');
        $A.enqueueAction(request);

    }
})