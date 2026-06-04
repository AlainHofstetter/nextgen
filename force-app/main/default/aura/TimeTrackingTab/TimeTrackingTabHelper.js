({

    /*
     * Gets all fields in a flat array
     */
    getAllFormFields: function(component){

        var allFields = [],
            formFieldsByTab = component.get('v.formFields');

        // dont crash when called early in the load
        if(formFieldsByTab === null) return [];

        for (var i = Object.keys(formFieldsByTab).length - 1; i >= 0; i--) {
            var tabFields = formFieldsByTab[Object.keys(formFieldsByTab)[i]];
            for (var x = tabFields.length - 1; x >= 0; x--) {
                if(allFields.indexOf(tabFields[x]) == -1){
                    allFields.push(tabFields[x]);
                }
            }
        }

        return allFields;

    },

    getFormFieldsForCurrentTab: function(component){
        return component.get('v.formFields')[component.find('ServiceType__c').get('v.value')];
    },

    /*
    Resets form!
    */
    resetForm: function(component, helper){

        // clear all fields
        var formFields = helper.getAllFormFields(component);

        for (var i = formFields.length - 1; i >= 0; i--) {

            // leave timetracker as is
            if(formFields[i] !== 'Timetracker__c' && formFields[i] !== 'ServiceType__c'){

                var resetValue = null;
                if(formFields[i] === 'OutOfScope__c'){
                    resetValue = false;
                }
                console.log()
                component.find(formFields[i]).set('v.value', resetValue);

            }

        }

        console.log(component.find('DateFrom__c'));
        component.find('DateFrom__c').set('v.value', moment().format('YYYY-MM-DD'));
        component.find('DateUntil__c').set('v.value', moment().format('YYYY-MM-DD'));

    },

    /*
    Populates form with object
    used for edit and clone functions
    */
    populateFormWithObject: function(component, helper, object){

        helper.resetForm(component, helper);

        // special service types
        // we delete service type before saving to SF so this should be okay
        if(object.ProjectName__r.ProjectSubType__c === 'Absence') object.ServiceType__c = 'AbsenceTime';
        if(object.ServiceType__c === 'Manufaktur') object.ServiceType__c = 'WorkTime';


        var tab = object.ServiceType__c,
            fieldTabName = tab.replace('Time', ''),
            formFields = component.get('v.formFields')[tab];

        // manually set the lookup value labels
        component.find('ProjectPartner__c').set('v.value', object.ProjectName__r.ProjectPartner__r.Id);
        component.find('ProjectPartner__c').set('v.valueLabel', object.ProjectName__r.ProjectPartner__r.Name);
        component.find('ProjectName__c').set('v.valueLabel', object.ProjectName__r.Name);
        component.find('AbsenceProjectName__c').set('v.valueLabel', object.ProjectName__r.Name);
        component.find(fieldTabName + 'Package__c').set('v.valueLabel', object.Package__r.Name);
        component.find('Timetracker__c').set('v.valueLabel', object.Timetracker__r.Name);

        // clone fields into form
        for (var i = formFields.length - 1; i >= 0; i--) {
            var fieldName = formFields[i].replace(/Absence|Travel|Work/gi, '');
            component.find(formFields[i]).set('v.value', object[fieldName]);
        }

        helper.showFieldsForTab(component, helper, tab);


    },

    /*
    Show the fields for a specific tab
    */
    showFieldsForTab: function(component, helper, tab){

        // get a whole bunch of vars we're going to need
        var allFormFields = helper.getAllFormFields(component),
            fields = component.get('v.formFields'),
            tabs = [],
            formFieldsByTab = [],
            tabComponent = component.find(tab);

        // sometimes fields arent intialised yet
        if(fields) {
            formFieldsByTab = fields[tab];
            tabs = Object.keys(fields);
        }

        // hide all the fields
        for (var x = allFormFields.length - 1; x >= 0; x--) {
            var co = component.find('parent' + allFormFields[x]);
            if (co) {
                $A.util.addClass(co, 'hidden');
            }
        }

        // show all fields in this tab
        for (var y = formFieldsByTab.length - 1; y >= 0; y--) {
            var c = component.find('parent' + formFieldsByTab[y]);
            if (c) {
                $A.util.removeClass(c, 'hidden');
            }
        }

        // make all tabs be inactive
        for (var i = 0; i < tabs.length; i++) {
            $A.util.removeClass(component.find(tabs[i]), 'slds-active');
        }

        // add active class for the one we love <3
        $A.util.addClass(tabComponent, 'slds-active');

    },

    /*
    Time difference calcuation
    */
    calculateTimeDifference: function(component, helper){

        // get times
        var rawStartTime = component.find('StartHhMm__c').get('v.value'),
            rawEndTime = component.find('EndHhMm__c').get('v.value'),
            // parse times into moment objects
            parsedStartTime = moment(rawStartTime, 'HH:mm'),
            parsedEndTime = moment(rawEndTime, 'HH:mm');

        // only continue if we have valid times entered
        if(parsedStartTime.isValid() && parsedEndTime.isValid()){

            // cacluate difference
            var differenceInMinutes = parsedEndTime.diff(parsedStartTime, 'minutes');

            // if the end time is past midnight, be more specific and add dates
            // actual dates dont really matter, we just need to tell momentjs the end time is later than start time
            if(differenceInMinutes < 0){

                // first get us some dates to work with
                var todaysDate = moment().format('YYYY-MM-DD'),
                    tomorrowsDate = moment().add(1, 'days').format('YYYY-MM-DD');

                // reparse the start and end time with dates
                parsedStartTime = moment(todaysDate + ' ' + rawStartTime, 'YYYY-MM-DD HH:mm');
                parsedEndTime = moment(tomorrowsDate + ' ' + rawEndTime, 'YYYY-MM-DD HH:mm');

                // recalcuate the difference
                differenceInMinutes = parsedEndTime.diff(parsedStartTime, 'minutes');

            }

            // format the difference in 3:42 format
            var formattedDifferenceInHours = Math.floor(differenceInMinutes / 60),
                formattedDifferenceInMinutes = helper.padNumber(differenceInMinutes % 60, 2),
                formattedDifference = formattedDifferenceInHours + ':' + formattedDifferenceInMinutes;

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

        var action = component.get('c.getTimeEntries'),
            dateRangeStart = component.find('entriesDateRangeStart').get('v.value'),
            dateRangeEnd = component.find('entriesDateRangeEnd').get('v.value'),
            currentUser = component.get('v.currentUser'),
            filterByUser = component.find('Timetracker__c').get('v.value');

        if(!filterByUser){
            filterByUser = currentUser.Id;
        }

        action.setParams({
            'dateRangeStart': moment(dateRangeStart, ['DD.MM.YYYY', 'YYYY-MM-DD']).format('YYYY-MM-DD'),
            'dateRangeEnd': moment(dateRangeEnd, ['DD.MM.YYYY', 'YYYY-MM-DD']).format('YYYY-MM-DD'),
            'filterByUser': filterByUser
        });

        action.setCallback(this, function(response){

            var results = response.getReturnValue(),
                totalDuration = moment.duration('0:00');

            if(results){
                for (var i = results.length - 1; i >= 0; i--) {
                    /* results[i].displayDate = moment(results[i].DateFrom__c).format('D.MM.YYYY'); */
                    results[i].stringified = JSON.stringify(results[i]);
                    totalDuration.add(results[i].DurationHhMm__c);
                }

                if(results.length === 0) {
                    $A.util.removeClass(component.find('noEntriesError'), 'hidden');
                }
                else {
                    $A.util.addClass(component.find('noEntriesError'), 'hidden');
                }

                component.set('v.dateRangeTitle', moment(dateRangeStart, ['DD.MM.YYYY', 'YYYY-MM-DD']).format('dddd, D.MM.YYYY') + ' - ' + moment(dateRangeEnd, ['DD.MM.YYYY', 'YYYY-MM-DD']).format('dddd, D.MM.YYYY'));

                // calculating total duration
                var totalDurationInMinutes = helper.padNumber(totalDuration.asMinutes() % 60, 2),
                    formattedTotalDuration = Math.floor(totalDuration.asHours()) + ':' + totalDurationInMinutes;

                component.set('v.dateRangeTotalTime', formattedTotalDuration);
            } else {
                $A.util.removeClass(component.find('noEntriesError'), 'hidden');
            }

            component.set('v.entries', results);

        });

        $A.enqueueAction(action);

    },

    parseAbsenceDuration: function(component){

        var absenceDurationComponent = component.find('AbsenceDurationHhMm__c'),
            currentValue = absenceDurationComponent.get('v.value'),
            parsedValue = moment(currentValue, 'HH:mm');

        // only continue if we have valid times entered
        if(parsedValue.isValid()){
            component.find('AbsenceDurationHhMm__c').set('v.value', parsedValue.format('H:mm'));
        }

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