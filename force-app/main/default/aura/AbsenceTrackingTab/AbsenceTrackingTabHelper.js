({
    /*
        Resets form!
    */
    resetForm: function(component, helper){

        console.log('entered reset form');

        // clear all fields
        var formFields = component.get('v.formFields');
        for (var i = formFields.length - 1; i >= 0; i--) {
            component.find(formFields[i]).set('v.value', null);
        }

        var currentUser = component.get('v.currentUser');

        // if the user can track for others
        if(currentUser.CanTrackTimeForOthers__c === true){
            // unhide the toggle
            $A.util.removeClass(component.find('Timetracker__c'), 'hidden');
        }
        else {
            // else set the value to the current user's id
            component.find('Timetracker__c').set('v.value', currentUser.InternalContactID__c);
        }

        // set some convenient field defaults
        component.find('DateFrom__c').set('v.value', moment().format('YYYY-MM-DD'));
        // component.find('StartHhMm__c').set('v.value', moment().subtract(2, 'hours').format('HH:mm'));
        // component.find('EndHhMm__c').set('v.value', moment().format('HH:mm'));
        // helper.calculateTimeDifference(component, helper);

    },

    /*
        Populates form with object
        used for edit and clone functions
    */
    populateFormWithObject: function(component, object){

        var formFields = component.get('v.formFields');

        // manually set the lookup value labels
        // component.find('BillingViaCompany__c').set('v.valueLabel', object.BillingViaCompany__r.Name);
        component.find('ProjectName__c').set('v.valueLabel', object.ProjectName__r.Name);
        component.find('Package__c').set('v.valueLabel', object.Package__r.Name);
        component.find('Timetracker__c').set('v.valueLabel', object.Timetracker__r.Name);

        // clone fields into form
        for (var i = formFields.length - 1; i >= 0; i--) {
            component.find(formFields[i]).set('v.value', object[formFields[i]]);
        }

    },

    /*
        Time difference calcuation
    */
    calculateDateDifference: function(component, helper){

        console.log('entered calculateDateDifference');

        // get times
        var rawStartDate = component.find('DateFrom__c').get('v.value'),
            rawEndDate = component.find('DateUntil__c').get('v.value'),
            // parse Dates into moment objects
            parsedStartDate = moment(rawStartDate),
            parsedEndDate = moment(rawEndDate);

        // only continue if we have valid dates entered
        if(parsedStartDate.isValid() && parsedEndDate.isValid()){

            var formattedDifference = '04:00';
            if(parsedEndDate.diff(parsedStartDate, 'days') > 1){
                formattedDifference = '08:00';
            }

            component.find('DurationHhMm__c').set('v.value', formattedDifference);

        }

    },
    // needed to format duration correctly
    padNumber: function(n, width, z) {
      z = z || '0';
      n = n + '';
      return n.length >= width ? n : new Array(width - n.length + 1).join(z) + n;
    },

    /*
        Load entries!
    */
    loadEntries: function(component, helper){

        console.log('calling load entries');

        var action = component.get('c.getTimeEntries'),
            dateRangeStart = component.find('entriesDateRangeStart').get('v.value'),
            dateRangeEnd = component.find('entriesDateRangeEnd').get('v.value');

        action.setParams({
            'dateRangeStart': dateRangeStart,
            'dateRangeEnd': dateRangeEnd
        });

        action.setCallback(this, function(response){

            var results = response.getReturnValue(),
                totalDuration = moment.duration('0:00');

            for (var i = results.length - 1; i >= 0; i--) {
                results[i].stringified = JSON.stringify(results[i]);
                totalDuration.add(results[i].DurationHhMm__c);
            }


            if(results.length === 0) {
                $A.util.removeClass(component.find('noEntriesError'), 'hidden');
            }
            else {
                $A.util.addClass(component.find('noEntriesError'), 'hidden');
            }

            console.log('setting title', moment(dateRangeStart).format('dddd, L') + ' - ' + moment(dateRangeEnd).format('dddd, L'));
            component.set('v.dateRangeTitle', moment(dateRangeStart).format('dddd, L') + ' - ' + moment(dateRangeEnd).format('dddd, L'));

            // calculating total duration
            var totalDurationInMinutes = helper.padNumber(totalDuration.minutes() % 60, 2),
                formattedTotalDuration = totalDuration.hours() + ':' + totalDurationInMinutes;
            component.set('v.dateRangeTotalTime', formattedTotalDuration);

            component.set('v.entries', results);

        });

        $A.enqueueAction(action);

    },

    /*
        Error handling!
    */
    addError: function(component, errorMessage){
        var errors = component.get('v.errors');
        errors.push(errorMessage);
        component.set('v.errors', errors);
    },
    clearErrors: function(component){
        component.set('v.errors', []);
    }
})