({

    /*
        Gets all fields in a flat array
    */
    getAllFormFields: function(component){

        var allFields = [],
            formFieldsByTab = component.get('v.formFields');

        if(formFieldsByTab) {

            for (var i = Object.keys(formFieldsByTab).length - 1; i >= 0; i--) {
                var tabFields = formFieldsByTab[Object.keys(formFieldsByTab)[i]];
                for (var x = tabFields.length - 1; x >= 0; x--) {
                    if(allFields.indexOf(tabFields[x]) == -1){
                        allFields.push(tabFields[x]);
                    }
                }
            }
            
        }

        return allFields;

    },

    getFormFieldsForCurrentTab: function(component){
        console.log(component.find('ExpenseType__c').get('v.value'), 'type?');
        console.log(component.get('v.formFields'), 'fields?');
        return this.copy(component.get('v.formFields')[component.find('ExpenseType__c').get('v.value')]);
    },

    /*
        Resets form!
    */
    resetForm: function(component, helper){

        console.log('reset form!');

        // clear all fields
        var formFields = helper.getAllFormFields(component),
            localCurrency = component.get('v.localCurrency');

        for (var i = formFields.length - 1; i >= 0; i--) {

            // leave timetracker as is
            if(formFields[i] !== 'Expensetracker__c' && formFields[i] !== 'ExpenseType__c'){

                if(formFields[i] !== undefined){

                    // setTimeout(function(){
                        var resetValue = null;
                        if(formFields[i] === 'LocalCurrency__c'){
                            resetValue = localCurrency;
                        }
                        if(formFields[i] === 'CreditCardResponsibleCompany__c'){
                            // also reset valuelabel
                            component.find(formFields[i]).set('v.valueLabel', resetValue);
                        }
                        // console.log(formFields[i], '??');
                        component.find(formFields[i]).set('v.value', resetValue);
                        if(formFields[i] === 'PaymentType__c'){
                            // toggle credit card field
                            helper.toggleCreditCardField(component);
                        }
                    // }, 20);

                }

            }

        }

    },

    /*
        Populates form with object
        used for edit and clone functions
    */
    populateFormWithObject: function(component, helper, object){

        console.log('pop with obj', object);

        helper.resetForm(component, helper);

        // will not properly reset all fields if not in a settimeout
        // not pretty, but only solution found so far
        // let lightning catch up with all the looping through
        // components and take a breather before moving on
        setTimeout(function(){

            var tab = object.ExpenseType__c,
                formFields = component.get('v.formFields')[tab];

            console.log('populating form for tab', tab);

            // manually set the lookup value labels
            component.find('ProjectPartner__c').set('v.value', object.ProjectName__r.ProjectPartner__r.Id);
            component.find('ProjectPartner__c').set('v.valueLabel', object.ProjectName__r.ProjectPartner__r.Name);
            component.find('ProjectName__c').set('v.valueLabel', object.ProjectName__r.Name);
            component.find('Package__c').set('v.valueLabel', object.Package__r.Name);
            if(tab === 'Car Travel') component.find('Car__c').set('v.valueLabel', object.Car__r.Name);
            component.find('Expensetracker__c').set('v.valueLabel', object.Expensetracker__r.Name);
            if(object.CreditCardResponsibleCompany__r) component.find('CreditCardResponsibleCompany__c').set('v.valueLabel', object.CreditCardResponsibleCompany__r.Name);


            // clone fields into form
            for (var i = formFields.length - 1; i >= 0; i--) {
                console.log('copy ', formFields[i], 'with val', object[formFields[i]]);
                component.find(formFields[i]).set('v.value', object[formFields[i]]);
            }

            // manually switch to api names for picklists
            console.log('SETTING picklists')
            component.find('PaymentType__c').set('v.value', helper.getPicklistAPIName(component.get('v.paymentTypes'), object['PaymentType__c']));
            component.find('ExpenseSubType__c').set('v.value', helper.getPicklistAPIName(component.get('v.expenseSubtypes'), object['ExpenseSubType__c']));
            // PaymentType__c
            // ExpenseSubType__c
            // // <aura:attribute name="paymentTypes" type="Array" />
            // // <aura:attribute name="expenseSubtypes" type="Array" />

            helper.showFieldsForTab(component, helper, tab);

        }, 0);

    },

    /*
        Show the fields for a specific tab
    */
    showFieldsForTab: function(component, helper, tab){

        console.log('showing fields for tab', tab);

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
            var c = component.find('parent' + allFormFields[x]);
            if (c) {
                $A.util.addClass(c, 'hidden');
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

        console.log('done');

    },

    /*
        Toggles credit card field
    */
    toggleCreditCardField: function(component){
        setTimeout(function(){
            if(component.find('PaymentType__c').get('v.value') === 'CompanyCreditCard'
            || component.find('PaymentType__c').get('v.value') === 'UnternehmenKreditkarte'){
                $A.util.removeClass(component.find('CreditCardResponsibleCompany__c'), 'hidden');
            } else {
                $A.util.addClass(component.find('CreditCardResponsibleCompany__c'), 'hidden');
            }
        }, 50);
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
            var differenceInMinutes = parsedEndTime.diff(parsedStartTime, 'minutes'),
                // format the difference in 3:42 format
                formattedDifferenceInHours = Math.floor(differenceInMinutes / 60),
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

        var action = component.get('c.getExpenseEntries'),
            onlyShowPaidPrivately = component.find('onlyShowPaidPrivately').get('v.value'),
            dateRangeStart = component.find('entriesDateRangeStart').get('v.value'),
            dateRangeEnd = component.find('entriesDateRangeEnd').get('v.value'),
            currentUser = component.get('v.currentUser'),
            filterByUser = component.find('Expensetracker__c').get('v.value');
            //currencyTypes = component.get('c.getCurrencyTypeWithRates');


        console.log('onlyShowPaidPrivately ===>', onlyShowPaidPrivately);

        if(!filterByUser){
            if (currentUser)
            	filterByUser = currentUser.InternalContactID__c;
        }

        action.setParams({
            'dateRangeStart': moment(dateRangeStart, ['DD.MM.YYYY', 'YYYY-MM-DD']).format('YYYY-MM-DD'),
            'dateRangeEnd': moment(dateRangeEnd, ['DD.MM.YYYY', 'YYYY-MM-DD']).format('YYYY-MM-DD'),
            'filterByUser': filterByUser,
            'onlyShowPaidPrivately': onlyShowPaidPrivately
        });
        var euroRates = 0.00,
            usdRates = 0.00,
            currencyTypes = component.get('v.currencyTypeWithRates'),
            currencyTypesList = currencyTypes.length;
        console.log('currencyTypes', currencyTypes);

        for (var i=0; i < currencyTypesList; i++){
            if(currencyTypes[i].label.IsoCode == 'EUR'){
                euroRates = currencyTypes[i].label.ConversionRate;              
            }
            if(currencyTypes[i].label.IsoCode == 'USD'){
                usdRates = currencyTypes[i].label.ConversionRate;
            }
        }

        action.setCallback(this, function(response){

            var results = response.getReturnValue(),
                CHFsubtotalExpenses = 0,
                EURsubtotalExpenses = 0,
                USDsubtotalExpenses = 0,
                totalExpenses = 0;

            console.log('results', results);

            if(results){
                
                for (var i = results.length - 1; i >= 0; i--) {
                    /* results[i].displayDate = moment(results[i].ExpenseDate__c).format('D.MM.YYYY'); */
                    results[i].displayGross = helper.formatAsCurrency(results[i].ExpenseGross__c);
                    console.log('curr', results[i].displayGross);
                    results[i].stringified = JSON.stringify(results[i]);
                    
                    //EPU14
                    if(results[i].LocalCurrency__c == 'CHF'){
                        CHFsubtotalExpenses = CHFsubtotalExpenses + parseFloat(results[i].ExpenseGross__c);
                    }else if(results[i].LocalCurrency__c == 'EUR'){
                        EURsubtotalExpenses = EURsubtotalExpenses + parseFloat(results[i].ExpenseGross__c);
                    }else{
                        USDsubtotalExpenses = USDsubtotalExpenses + parseFloat(results[i].ExpenseGross__c);
                    }

                }

                totalExpenses = CHFsubtotalExpenses + (EURsubtotalExpenses*euroRates) + (USDsubtotalExpenses*usdRates);

                if(results.length === 0) {
                    $A.util.removeClass(component.find('noEntriesError'), 'hidden');
                }
                else {
                    $A.util.addClass(component.find('noEntriesError'), 'hidden');
                }

                component.set('v.dateRangeTitle', moment(dateRangeStart, ['DD.MM.YYYY', 'YYYY-MM-DD']).format('dddd, D.MM.YYYY') + ' - ' + moment(dateRangeEnd, ['DD.MM.YYYY', 'YYYY-MM-DD']).format('dddd, D.MM.YYYY'));

                // calculating total duration
                component.set('v.dateRangeCHFSubtotalExpenses', helper.formatAsCurrency(CHFsubtotalExpenses));
                component.set('v.dateRangeEURSubtotalExpenses', helper.formatAsCurrency(EURsubtotalExpenses));
                component.set('v.dateRangeUSDSubtotalExpenses', helper.formatAsCurrency(USDsubtotalExpenses));
                //component.set('v.dateRangeTotalExpenses', helper.formatAsCurrency(totalExpenses));
                component.set('v.dateRangeTotalExpenses', totalExpenses);
            }
            else {
                $A.util.removeClass(component.find('noEntriesError'), 'hidden');
            }

            console.log('setting entries', results);

            component.set('v.entries', results);

        });

        $A.enqueueAction(action);

    },

    /*
        Save entires
    */
    saveEntries: function(component, helper, entries) {

        console.log('expenseEntry', entries);

        // build the request
        var request = component.get('c.saveExpenseEntries');
        request.setParams({
            'expenseEntries': entries
        });
        request.setCallback(this, function(response) {

            console.log(response.state, 'state');
            console.log(response.getState(), 'get state');
            console.log(response.getReturnValue(), 'response');

            // clear any errors
            helper.clearErrors(component);

            // handle errors
            if(response.getState() == 'ERROR'){

                console.log('ERROR', response);

                var error = response.getError();
                if(error[0] !== undefined){

                    // display error messages
                    if(error[0].message !== undefined){
                        helper.addError(component, error[0].message);
                    }

                    // display page errors
                    if(error[0].pageErrors !== undefined && error[0].pageErrors.length > 0){
                        helper.addError(component, error[0].pageErrors[0].message);
                    }

                    // display any field errors
                    if(error[0].fieldErrors !== undefined){
                        var fieldErrors = error[0].fieldErrors;

                        for(var fieldError in fieldErrors){
                            if(fieldErrors.hasOwnProperty(fieldError)){
                                helper.addError(component, fieldErrors[fieldError][0].message);
                            }
                        }

                    }

                }
                else {
                    helper.addError(component, $A.get('$Label.c.SkySomethingwentwrongandwewerenotable'));
                }

            }
            else {
                // on success, load the entries
                helper.loadEntries(component, helper);
                var currentTab = component.find('ExpenseType__c').get('v.value');
                helper.resetForm(component, helper);
                helper.showFieldsForTab(component, helper, currentTab);
            }

            // scroll to top
            window.scrollTo(0, 0);

            $A.util.addClass(component.find('spinner'), 'hidden');

        });

        $A.util.removeClass(component.find('spinner'), 'hidden');
        $A.enqueueAction(request);

    },

    formatAsCurrency: function(number){

        number = number.toString();

        // make sure decimals are formatted correctly
        if(number.indexOf('.') > 0){

            var splittedNumber = number.split('.');

            // add 0 if we only have 1 decimal number
            if(splittedNumber[1].length === 1){
                splittedNumber[1] = splittedNumber[1] + '0';
            }

            // cut off if we have more then 2 decimal numbers
            if(splittedNumber[1].length > 2){
                splittedNumber[1] = splittedNumber[1].slice(0, 2);
            }

            number = splittedNumber.join('.');

        } else {
            number = number + '.00';
        }

        return number.replace(/(\d)(?=(\d{3})+(?!\d))/g, "$1'");

    },

    copy: function(obj) {
      return JSON.parse(JSON.stringify(obj)); // trick to copy the defaul JSON and don't override the default :)
    },

    getPicklistAPIName: function(picklist, value) {

        var apiName = picklist.filter(function(entry){
            if(entry.label == value) return entry;
        })[0].value;
        return apiName;

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