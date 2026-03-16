({
    /*
     * In the beginning...
     */
    init : function(component, event, helper) {

        moment.locale($A.get('$Locale.language'));

        var formFields = {
            'WorkTime': ['Id', 'ServiceType__c', 'Timetracker__c', 'DateFrom__c', 'DateUntil__c', 'StartHhMm__c', 'EndHhMm__c', 'DurationHhMm__c', 'ProjectPartner__c', 'ProjectName__c', 'WorkPackage__c', 'OutOfScope__c', 'Description__c'],
            'TravelTime': ['Id', 'ServiceType__c', 'Timetracker__c', 'DateFrom__c', 'StartHhMm__c', 'EndHhMm__c', 'DurationHhMm__c', 'ProjectPartner__c', 'ProjectName__c', 'TravelPackage__c', 'OutOfScope__c', 'Description__c'],
            'AbsenceTime': ['Id', 'ServiceType__c', 'Timetracker__c', 'AbsenceDateFrom__c', 'AbsenceDateUntil__c', 'AbsenceDurationHhMm__c', 'AbsenceProjectName__c', 'AbsencePackage__c', 'Description__c']
        };

        component.set('v.formFields', formFields);

        // set defaults to the date range filter
        component.find('entriesDateRangeStart').set('v.value', moment().subtract(3, 'days').format('YYYY-MM-DD'));
        component.find('entriesDateRangeEnd').set('v.value', moment().add(1, 'days').format('YYYY-MM-DD'));
        component.find('entriesDateRangeTodayButton').set('v.label', moment().format('DD'));

        // get initial user information
        var action = component.get('c.getInitialUserInfo');
        action.setCallback(this, function(response){

            var currentUser = response.getReturnValue();
            if(!currentUser) return;

            // move properties from the user object up
            for(var p in currentUser.User__r){
                if(p !== 'Id'){
                    currentUser[p] = currentUser.User__r[p];
                }
            }

            // store for later use
            component.set('v.currentUser', currentUser);

            // reset form!
            helper.resetForm(component, helper);
            component.find('ServiceType__c').set('v.value', 'WorkTime');

            // if the user can track for others
            if(currentUser.CanTrackTimeForOthers__c === true){
                // unhide the toggle
                $A.util.removeClass(component.find('Timetracker__c'), 'hidden');
                component.find('Timetracker__c').set('v.value', currentUser.Id);
                component.find('Timetracker__c').set('v.valueLabel', currentUser.Name);
            }
            else {
                // else set the value to the current user's id
                component.find('Timetracker__c').set('v.value', currentUser.Id);
            }

            // make sure the list of entries gets populated
            // we need user info to filter so in callback 
            helper.loadEntries(component, helper);

            // show work time tab by default
            helper.showFieldsForTab(component, helper, 'WorkTime');

            // listen for information from any button click on SF page layouts
            // passing from app component is too slow :(
            var magicURLmatches = window.location.href.match(/\?(Project__c|Package__c)=(.+)&c__tab=(.+)(&c__subtab=(.+))?/);

            console.log(magicURLmatches, '✨');

            if(magicURLmatches){

                var littleObjectMap = {
                        'Project__c': 'projectValue',
                        'Package__c': 'packageValue'
                    },
                    object = magicURLmatches[1],
                    id = magicURLmatches[2],
                    // i couldnt find the one regex to rule them all :(
                    subtab = decodeURIComponent(magicURLmatches[3].split('=')[1]).replace('+', ' ');

                component.set('v.' + littleObjectMap[object], id);

                if(subtab !== 'undefined') {
                    component.find('ServiceType__c').set('v.value', subtab);
                    helper.showFieldsForTab(component, helper, subtab);
                }

            }

        });

        $A.enqueueAction(action);

    },

    // handle time type tab
    toggleTimeType: function(component, event, helper){

        // sometimes this function is called with moment is not properly loaded yet
        if(moment !== undefined){
            var selectedTab = event.detail.selectedTab.get('v.id');
            helper.resetForm(component, helper);
            component.find('ServiceType__c').set('v.value', selectedTab);
            helper.showFieldsForTab(component, helper, selectedTab);
        }

    },

    onAbsenceDurationChange: function(component, event, helper){
        helper.parseAbsenceDuration(component);
    },

    // calculate time difference when time fields are changing
    onTimeFieldChange: function(component, event, helper) {
        helper.calculateTimeDifference(component, helper);
    },

    // make sure the duration field is properly formatted
    onDurationFieldChange: function(component, event, helper) {

        var durationComponent = component.find('DurationHhMm__c'),
            duration = durationComponent.get('v.value');

        if(!duration) return;

        var durationWithColon = duration.replace(/\.|;|\s|,/g, ':'),
            durationParts = durationWithColon.split(':');

        // sometimes people enter in a duration without a colon because they think they're cool
        // like this > 😎
        if(durationParts.length == 1 && durationParts[0].length > 3){
            var durationWithoutColon = durationParts[0],
                durationWithoutColonLength = durationParts[0].length;
            // maybe its like a hundred hours or something and then we just want most of the
            // numbers on the left side of the colon as hours and then the last two as minutes on the right side
            durationParts[0] = durationWithoutColon.substring(0, durationWithoutColonLength - 2);
            durationParts[1] = durationWithoutColon.substring(durationWithoutColonLength - 2, durationWithoutColonLength);
        }

        if(durationParts.length < 2){
            durationParts.push('00');
        }
        else {

            if(durationParts[0].length === 0){
                durationParts[0] = '0';
            }

            if(durationParts[1].length === 0){
                durationParts[1] = '00';
            }

            if(durationParts[1].length === 1){
                durationParts[1] = durationParts[1] + '0';
            }

        }

        durationComponent.set('v.value', durationParts.join(':'));

    },

    // handle lookup value changes for the interconnectivity between them
    onLookupValueChange: function(component, event, helper){

        var lookupType = event.getParam('lookupType'),
            valueObject = event.getParam('valueObject');

        // user lookup changed
        if(lookupType === 'User'){
            // lets load new entries
            helper.loadEntries(component, helper);
        }

        // bubbling up!
        if(valueObject){

            // if lookup is package
            if((lookupType === 'Work Package' || lookupType === 'Travel Package')){
                component.set('v.customerValue', valueObject.ProjectName__r.ProjectPartner__r.Id);
                component.set('v.customerValueLabel', valueObject.ProjectName__r.ProjectPartner__r.Name);
                component.set('v.projectValue', valueObject.ProjectName__r.Id);
                component.set('v.projectValueLabel', valueObject.ProjectName__r.ProjectNr__c + ' - ' + valueObject.ProjectName__r.Name);
            }

            // if lookup is internal package (on the absence tab)
            if(lookupType === 'Internal Package'){
                component.set('v.absenceProjectValue', valueObject.ProjectName__r.Id);
                component.set('v.absenceProjectValueLabel', valueObject.ProjectName__r.ProjectNr__c + ' - ' + valueObject.ProjectName__r.Name);
            }

            // if lookup is project
            if(lookupType === 'Project'){
                component.set('v.customerValue', valueObject.ProjectPartner__r.Id);
                component.set('v.customerValueLabel', valueObject.ProjectPartner__r.Name);
            }

        }
        // we don't have a value object = the user deselected a lookup
        else {

            if(lookupType === 'Account' || lookupType === 'Project') {
                component.set('v.packageValue', null);
                component.set('v.packageValueLabel', null);
            }

            if(lookupType === 'Account') {
                component.set('v.projectValue', null);
                component.set('v.projectValueLabel', null);
            }

            // for the absence tab
            if(lookupType === 'Internal Project'){
                component.set('v.absencePackageValue', null);
                component.set('v.absencePackageValueLabel', null);
            }

        }

    },

    onDateRangeSelect: function(component, event, helper){
        helper.loadEntries(component, helper);
    },

    onTodayButtonClick: function(component, event, helper){

        var today = moment().format('YYYY-MM-DD');

        component.find('entriesDateRangeStart').set('v.value', today);
        component.find('entriesDateRangeEnd').set('v.value', today);

        helper.loadEntries(component, helper);

    },
    buttonClicked: function(component, event, helper) {
        component.set('v.data', event.getParam('data'));
        $A.enqueueAction(event.getParam('action'));
    },
    onCloneButtonClick: function(component, event, helper) {

        var entryToBeCloned = JSON.parse(JSON.stringify(component.get('v.data')));


        // empty dates
        entryToBeCloned.DurationHhMm__c = null;

        // and empty ID
        entryToBeCloned.Id = null;

        helper.populateFormWithObject(component, helper, entryToBeCloned);

    },
    onEditButtonClick: function(component, event, helper) {

        var entryToBeEdited = component.get('v.data');
        helper.populateFormWithObject(component, helper, entryToBeEdited);

    },

    onDateFieldChange: function(component, event, helper){
        let untilValue = component.find('DateUntil__c').get('v.value');
        let fromValue = component.find('DateFrom__c').get('v.value');
        if(!untilValue || untilValue < fromValue){
            component.find('DateUntil__c').set('v.value', fromValue);
            return;
        }    
    },

    // the big save time entry method
    save: function(component, event, helper){

        // clear any existing errors
        helper.clearErrors(component);

        // fields to loop through to send to apex
        var fieldsToSave = helper.getFormFieldsForCurrentTab(component),
            timeEntry = {},
            fieldsNotFilledOut = [],
            dontValidateTheseFields = ['Id', 'StartHhMm__c', 'EndHhMm__c'];

        // loop through fields to save
        for (var i = fieldsToSave.length - 1; i >= 0; i--) {

            // get value + label
            var fieldComponent = component.find(fieldsToSave[i]),
                // values are good for saving entries
                value = fieldComponent.get('v.value'),
                // so we can error message about them if we have to
                label = fieldComponent.get('v.label'),
                // i couldnt find a way to add a data-name attribute on the fields :(
                name = fieldsToSave[i].replace(/Absence|Travel|Work/gi, '');

            // if empty, add to the field empty list
            if((value === null || value === '') && dontValidateTheseFields.indexOf(fieldsToSave[i]) < 0){
                fieldsNotFilledOut.push(label);
            }

            // add to time entry object
            timeEntry[name] = value;

        }

        // put the error on the screen
        if(fieldsNotFilledOut.length > 0){
            helper.addError(component, $A.get('$Label.c.SkyPleasefilloutthesefieldscorrectly')  + fieldsNotFilledOut.join(', '));
        }

        var timeEntries = [];

        // continue if no errors
        if(component.get('v.errors').length == 0){

            // dont confuse salesforce
            timeEntry.sobjectType = 'Time__c';

            // assuming we're saving a single entry
            var requestAction = 'c.saveTimeEntry';

           // JC If saving absence entry and Date is > 2025-12-31
            if (timeEntry.ServiceType__c === 'AbsenceTime') {
                // Read string value assembled earlier
                var dateUntilValAbs = timeEntry.DateUntil__c;

                if (dateUntilValAbs) {
                    // Parse as Date and compare to max (2025-12-31)
                    var selectedAbs = new Date(dateUntilValAbs);
                    var maxAbs = new Date('2025-12-31');

                    // Try to get the UI component for field-level error display
                    // Ensure this aura:id matches the Absence "Date Until" input in the component markup
                    var dateUntilFieldCmp = component.find('AbsenceDateUntil__c');

                    if (selectedAbs > maxAbs) {
                        // add a banner error
                        helper.addError(component, 'Please log all absences after 2025-12-31 in Personio.');
                        // set field-level error if we have the component
                        if (dateUntilFieldCmp && dateUntilFieldCmp.set) {
                            dateUntilFieldCmp.set('v.errors', [{ message: 'Please log all absences after 2025-12-31 in Personio.' }]);
                        }
                    } else {
                        // clear any previous field error
                        if (dateUntilFieldCmp && dateUntilFieldCmp.set) {
                            dateUntilFieldCmp.set('v.errors', null);
                        }
                    }
                }
            }

            // if we're saving an absence entry
            // we need to check if we need to create multiple entries
            if(timeEntry.ServiceType__c === 'AbsenceTime' || timeEntry.ServiceType__c === 'WorkTime'){

                // cloning into a new object
                var entryTemplate = JSON.parse(JSON.stringify(timeEntry));

                // sf doesnt want this
                delete entryTemplate['ServiceType__c'];

                // going where no trigger has gone before
                if(timeEntry.DateUntil__c !== timeEntry.DateFrom__c){

                    // getting how many days between the days
                    var amountOfDays = moment(timeEntry.DateUntil__c).diff(timeEntry.DateFrom__c, 'days');

                    for (var i = 0; i <= amountOfDays; i++) {

                        // cloning new entry
                        var oneSingleEntry = JSON.parse(JSON.stringify(entryTemplate)),
                            // setting current date
                            currentDate = moment(entryTemplate.DateFrom__c).add(i, 'days'),
                            formattedCurrentDate = currentDate.format('YYYY-MM-DD');

                        oneSingleEntry.DateFrom__c = formattedCurrentDate;
                        oneSingleEntry.DateUntil__c = formattedCurrentDate;

                        if(currentDate.isoWeekday() !== 6 && currentDate.isoWeekday() !== 7) {
                            timeEntries.push(oneSingleEntry);
                        }

                    }

                }
                else {
                    // only one absence entry, just add this one :D
                    timeEntries.push(entryTemplate);
                }

            }
            else {

                delete timeEntry['ServiceType__c'];

                timeEntry.DateUntil__c = timeEntry.DateFrom__c;

                // no absence multiple entries jazz, just save this one
                timeEntries.push(timeEntry);

            }
            var request = component.get('c.saveTimeEntries');
            request.setParams({
                'timeEntries': timeEntries
            });

            request.setCallback(this, function(response) {

                // clear any errors
                helper.clearErrors(component);

                // handle errors
                if(response.getState() === 'ERROR'){

                    var error = response.getError();
                    if(error[0] !== undefined && error[0].pageErrors !== undefined){
                        helper.addError(component, error[0].pageErrors[0].message);
                    }
                    else {
                        helper.addError(component, $A.get('$Label.c.SkySomethingwentwrongandwewerenotable'));
                    }

                }
                else {

                    var currentTab = component.find('ServiceType__c').get('v.value');

                    // on success, load the entries
                    // if absence time entry was created, then change the date span to be the entry date span
                    if(currentTab === 'AbsenceTime' || currentTab === 'WorkTime') {
                        component.find('entriesDateRangeStart').set('v.value', timeEntry.DateFrom__c);
                        component.find('entriesDateRangeEnd').set('v.value', timeEntry.DateUntil__c);
                    }

                    helper.loadEntries(component, helper);

                    helper.resetForm(component, helper);
                    helper.showFieldsForTab(component, helper, currentTab);


                }

                // scroll to top
                window.scrollTo(0, 0);

                $A.util.addClass(component.find('spinner'), 'hidden');

            });
            $A.util.removeClass(component.find('spinner'), 'hidden');
            $A.enqueueAction(request);

        }

    },

    delete: function(component, event, helper){

        if(confirm($A.get('$Label.c.SkyAreyousureyouwanttodeletethistimeentry'))){

            var request = component.get('c.deleteTimeEntry'),
                entryToBeDeleted = component.get('v.data');
                // entryToBeDeleted = JSON.parse(event.currentTarget.parentNode.parentNode.parentNode.getAttribute('data-entry'));

            entryToBeDeleted.sobjectType = 'Time__c';

            request.setParams({ 'timeEntry': entryToBeDeleted });

            request.setCallback(this, function(response) {
                helper.loadEntries(component, helper);
                $A.util.addClass(component.find('spinner'), 'hidden');
            });

            $A.util.removeClass(component.find('spinner'), 'hidden');
            $A.enqueueAction(request);

        }

    }
})