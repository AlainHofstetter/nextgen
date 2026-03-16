({

    searchLookup: function(component, helper){

        // set the params
        var params = {
                'query': component.find('searchField').get('v.value'),
                'type': component.get('v.type')
            },
            filterById = component.get('v.filterById');

        // only filter for filterById if its set
        if(filterById && filterById !== '') params['filterById'] = filterById;

        // Create the action
        var request = component.get('c.searchLookup');
        request.setParams(params);

        // Add callback behavior for when response is received
        request.setCallback(this, function(response) {

            var state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {

                var results = response.getReturnValue();

                // we need to do this for the car + cc name change
                // stringifying every entry so we can pass data around without spamming data attributes
                for (var i = results.length - 1; i >= 0; i--) {

                    // because i couldnt do this in APEX :(
                    if(results[i].Car__c !== undefined){
                        results[i].Name = results[i].Name + ' - ' + results[i].Car__c;
                    }

                    // because i couldnt do this in APEX :(
                    if(results[i].PackageNr__c !== undefined){
                        results[i].Name = results[i].PackageNr__c + ' - ' + results[i].Name;
                    }

                    // because i couldnt do this in APEX :(
                    if(results[i].ProjectNr__c !== undefined){
                        results[i].Name = results[i].ProjectNr__c + ' - ' + results[i].Name;
                    }

                    // because i couldnt do this in APEX :(
                    if(results[i].CreditCard__c !== undefined){
                        results[i].Name = results[i].Name + ' - ' + results[i].CreditCard__c;
                    }

                    results[i].selected = false;
                    results[i].stringified = JSON.stringify(results[i]);
                }

                // if there is only one result, select that one
                if(results.length === 1){
                    // select the item
                    helper.select(component, helper, results[0]);
                }
                else {
                    // update so dropdown displays
                    component.set('v.results', results);

                    if(results.length > 0){
                        $A.util.addClass(component.find('no-results-message'), 'hidden');
                    }
                    else {
                        $A.util.removeClass(component.find('no-results-message'), 'hidden');
                    }

                }

            }
            else {
                console.error('Failed with state: ' + state);
            }

        });

        // Send action off to be executed
        $A.enqueueAction(request);

    },

	select: function(component, helper, valueObject){

        component.set('v.value', valueObject.Id);
        component.set('v.valueLabel', valueObject.Name);

        helper.renderSelected(component);

        // bubble up the event
        var bubbleEvent = component.getEvent('bubbleLookupValueChange');
        bubbleEvent.setParams({
            'lookupType': component.get('v.type'),
            'valueObject': valueObject
        });
        bubbleEvent.fire();

	},
	deselect: function(component, helper){

        component.set('v.results', []);
        component.set('v.value', null);
        component.set('v.valueLabel', null);
        component.set('v.keyboardResultCurrentlySelected', -1);

        helper.renderNotSelected(component);

        // bubble up the event
        var bubbleEvent = component.getEvent('bubbleLookupValueChange');
        bubbleEvent.setParams({
            'lookupType': component.get('v.type'),
            'valueObject': null
        });
        bubbleEvent.fire();

	},
	renderSelected: function(component){
        component.find('searchField').set('v.value', '');
	    $A.util.addClass(component.find('searchField'), 'hidden');
        $A.util.addClass(component.find('filterResultsDropdown'), 'hidden');
        $A.util.removeClass(component.find('selectedValuePill'), 'hidden');
	},
	renderNotSelected: function(component){
        $A.util.removeClass(component.find('searchField'), 'hidden');
        $A.util.addClass(component.find('selectedValuePill'), 'hidden');
	},
    copy: function(obj) {
        return JSON.parse(JSON.stringify(obj)); // trick to copy the defaul JSON and don't overried the default :)
    },
})