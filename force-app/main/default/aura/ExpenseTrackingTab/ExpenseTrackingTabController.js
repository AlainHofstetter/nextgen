({
    /*
        In the beginning...
    */
    handleChangeCurrency: function (component, event) {
        // This will contain the string of the "value" attribute of the selected option
        var selectedOptionValue = event.getParam("value");
        component.set('v.localCurrency', selectedOptionValue);
    },
	init : function(component, event, helper) {

        moment.locale($A.get('$Locale.language'));

        console.log('init!');

        /*
            set form fields defaults
            we use this for tabbing around
        */
        var formFields = {
            'Receipt': ['Id', 'ExpenseType__c', 'Expensetracker__c', 'ExpenseDate__c', 'ExpenseSubType__c', 'BusinessReason__c', 'SupplierReceiverLocation__c', 'ListOfNames__c', 'ProjectPartner__c', 'ProjectName__c', 'Package__c', 'PaymentType__c', 'CreditCardResponsibleCompany__c', 'LocalCurrency__c', 'ExpenseGross__c'],
            'Car Travel': ['Id', 'ExpenseType__c', 'Expensetracker__c', 'ExpenseDate__c', 'Car__c', 'Distance__c', 'BusinessReason__c', 'ProjectPartner__c', 'ProjectName__c', 'Package__c', 'LocalCurrency__c']
        };

        component.set('v.formFields', formFields);

        // set default tab
        component.find('ExpenseType__c').set('v.value', 'Receipt');

        /*
            async load picklist values
        */
        // payment types
        var getPaymentTypes = component.get('c.getPaymentTypes');
        getPaymentTypes.setCallback(this, function(response){
            var list = [];
            var obj = response.getReturnValue();

            for (var key in obj) {
                if(obj.hasOwnProperty(key))
                    list.push({value: key, label: obj[key]});
            }
            console.log('paymentTypes', list);
            component.set('v.paymentTypes', list);
        });
        $A.enqueueAction(getPaymentTypes);

        // expense subtypes
        var getExpenseSubtypes = component.get('c.getExpenseSubtypes');
        getExpenseSubtypes.setCallback(this, function(response){
            var list = [];
            var obj = response.getReturnValue();

            for (var key in obj) {
                if(obj.hasOwnProperty(key))
                    list.push({value: key, label: obj[key]});
            }
            console.log('expenseSubTypes', list);
            component.set('v.expenseSubtypes', list);
        });
        $A.enqueueAction(getExpenseSubtypes);

        // currency rates EPU14
        var getCurrencyTypeWithRates = component.get('c.getCurrencyTypeWithRates');
        getCurrencyTypeWithRates.setCallback(this, function(response){
            var list = [];
            var obj = response.getReturnValue();

            for (var key in obj) {
                if(obj.hasOwnProperty(key))
                    list.push({value: key, label: obj[key]});
            }
            console.log('CurrencyTypeWithRates', list);
            component.set('v.currencyTypeWithRates', list);
        });
        $A.enqueueAction(getCurrencyTypeWithRates);

        /*
            default date range values
        */
        component.find('entriesDateRangeStart').set('v.value', moment().subtract(3, 'days').format('YYYY-MM-DD'));
        component.find('entriesDateRangeEnd').set('v.value', moment().add(1, 'days').format('YYYY-MM-DD'));
        component.find('entriesDateRangeTodayButton').set('v.label', moment().format('DD'));
        /*
            get initial user information
        */
        var getInitialUserInfo = component.get('c.getInitialUserInfo');
        getInitialUserInfo.setCallback(this, function(response){

            var currentUser = response.getReturnValue();

            // move properties from the user object up
            for(var p in currentUser.User__r){
                if(p !== 'Id'){
                    currentUser[p] = currentUser.User__r[p];
                }
            }

            console.log('currentUser', currentUser);

            // store for later use
            component.set('v.currentUser', currentUser);
            component.set('v.localCurrency', currentUser.LocalCurrency__c);
            //component.set('v.totalLocalCurrency', currentUser.LocalCurrency__c);
            component.set('v.totalLocalCurrency', 'CHF');

            helper.resetForm(component, helper);
            helper.showFieldsForTab(component, helper, 'Receipt');

            // if the user can track for others
            if(currentUser.CanTrackExpensesForOthers__c === true){
                // unhide the toggle
                $A.util.removeClass(component.find('Expensetracker__c'), 'hidden');
                component.find('Expensetracker__c').set('v.value', currentUser.InternalContactID__c);
                component.find('Expensetracker__c').set('v.valueLabel', currentUser.Name);
            }
            else {
                // else set the value to the current user's id
                component.find('Expensetracker__c').set('v.value', currentUser.InternalContactID__c);
            }

            // make sure the list of entries gets populated
            helper.loadEntries(component, helper);

            // listen for information from any button click on SF page layouts
            // passing from app component is too slow :(
            var magicURLmatches = window.location.href.match(/\?(Project__c|Package__c)=(.+)&tab=(.+)(&subtab=(.+))?/);

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
        $A.enqueueAction(getInitialUserInfo);

        /*
            get expense record type info
        */
        var getExpenseTypes = component.get('c.getExpenseRecordTypes');
        getExpenseTypes.setCallback(this, function(response){

            var rawRecordTypes = response.getReturnValue(),
                recordTypes = {};

            for (var i = 0; i < rawRecordTypes.length; i++) {
                recordTypes[rawRecordTypes[i].Name] = rawRecordTypes[i].Id;
            }

            // store for later use
            component.set('v.recordTypes', recordTypes);

        });
        $A.enqueueAction(getExpenseTypes);


    },

    // handle expense type tab
    toggleExpenseType: function(component, event, helper){
        var selectedTab = event.detail.selectedTab.get('v.id');
        component.find('ExpenseType__c').set('v.value', selectedTab);
        helper.showFieldsForTab(component, helper, selectedTab);
    },

    openPrivatelyPaidExpensesOverview: function(component, event, helper){

        var dateRangeStart = component.find('entriesDateRangeStart').get('v.value'),
            dateRangeEnd = component.find('entriesDateRangeEnd').get('v.value'),
            currentUser = component.get('v.currentUser'),
            filterByUser = component.find('Expensetracker__c').get('v.value'),
            grandTotalExpenses = component.get('v.dateRangeTotalExpenses'),
            localCurrency = component.get('v.localCurrency');


        if(!filterByUser && currentUser) filterByUser = currentUser.InternalContactID__c;

        window.open('/apex/PrivatelyPaidExpenses?userId=' + filterByUser + '&startDate=' + dateRangeStart + '&endDate=' + dateRangeEnd + '&localCurrency=' + localCurrency + '&grandTotalExpenses=' + grandTotalExpenses, '_blank');

    },

    // handle when payment type changes
    onPaymentTypeChange: function(component, event, helper) {
        helper.toggleCreditCardField(component);
    },

    onPrivatePaymentsOnlyClick: function(component, event, helper) {
        helper.loadEntries(component, helper);
        $A.util.toggleClass(component.find('PrintPrivatelyPaidButton'), 'hidden');
    },

    // handle lookup value changes for the interconnectivity between them
    onLookupValueChange: function(component, event, helper){

        var lookupType = event.getParam('lookupType'),
            valueObject = event.getParam('valueObject');

        // user lookup changed
        if(lookupType === 'User' && valueObject !== null){
            // lets load new entries
            helper.loadEntries(component, helper);
            console.log('changed user', valueObject);
            // set localcurrency
            component.set('v.localCurrency', valueObject.LocalCurrency__c); 
            helper.resetForm(component, helper);
        }

        // bubbling up!
        if(valueObject){

                // if lookup is project
            if(lookupType === 'Project' || lookupType === 'Expense Project'){
                component.set('v.customerValue', valueObject.ProjectPartner__r.Id);
                component.set('v.customerValueLabel', valueObject.ProjectPartner__r.Name);
            }

            // if lookup is package
            if(lookupType == 'Expense Package'){
                component.set('v.customerValue', valueObject.ProjectName__r.ProjectPartner__r.Id);
                component.set('v.customerValueLabel', valueObject.ProjectName__r.ProjectPartner__r.Name);
                component.set('v.projectValue', valueObject.ProjectName__r.Id);
                component.set('v.projectValueLabel', valueObject.ProjectName__r.ProjectNr__c + ' - ' + valueObject.ProjectName__r.Name);
            }

        }
        // we don't have a value object = the user deselected a lookup
        else {

            if(lookupType === 'Account' || lookupType === 'Project' || lookupType === 'Expense Project') {
                component.set('v.packageValue', null);
                component.set('v.packageValueLabel', null);
            }

            if(lookupType === 'Account') {
                component.set('v.projectValue', null);
                component.set('v.projectValueLabel', null);
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

        entryToBeCloned.Id = null;
        helper.populateFormWithObject(component, helper, entryToBeCloned);

    },

    onEditButtonClick: function(component, event, helper) {

        var entryToBeEdited = component.get('v.data');
        helper.populateFormWithObject(component, helper, entryToBeEdited);

    },

    onValidateButtonClick: function(component, event, helper){

        var entries = component.get('v.entries'),
            entriesToSave = [];

        for (var i = 0; i < entries.length; i++) {
            entriesToSave.push({
                Id: entries[i].Id,
                ExpenseValidatedFinance__c: true
            });
        }

        helper.saveEntries(component, helper, entriesToSave);

    },

    // the big save time entry method
    save: function(component, event, helper){

        // clear any existing errors
        helper.clearErrors(component);

        // fields to loop through to send to apex
        var fieldsToSave = helper.getFormFieldsForCurrentTab(component),
            expenseEntry = {},
            fieldsNotFilledOut = [];

        console.log('fieldsToSave', fieldsToSave);

        var creditCardIndex = fieldsToSave.indexOf('CreditCardResponsibleCompany__c');
        console.log('ptype', component.find('PaymentType__c').get('v.value'));
        if(creditCardIndex > -1 && component.find('PaymentType__c').get('v.value') !== 'CompanyCreditCard'){
            fieldsToSave.splice(creditCardIndex, 1);
        }

        // loop through fields to save
        for (var i = fieldsToSave.length - 1; i >= 0; i--) {

            // get value + label
            var fieldComponent = component.find(fieldsToSave[i]),
                value = fieldComponent.get('v.value'),
                label = fieldComponent.get('v.label');

            // if empty, add to the field empty list
            if((value === null || value === '') && fieldsToSave[i] !== 'Id'){
                fieldsNotFilledOut.push(label);
            }

            console.log(label, value);

            // add to time entry object
            expenseEntry[fieldsToSave[i]] = value;

        }

        // because there are triggers that will fail without knowing what record type is happening
        var recordTypes = component.get('v.recordTypes');
        console.log('RECORD TYPES', recordTypes, expenseEntry.ExpenseType__c);
        expenseEntry.RecordTypeId = recordTypes[expenseEntry.ExpenseType__c];

        // put the error on the screen
        if(fieldsNotFilledOut.length > 0){
            helper.addError(component, $A.get('$Label.c.SkyPleasefilloutthesefieldscorrectly') + fieldsNotFilledOut.join(', '));
        }

        // continue if no errors
        if(component.get('v.errors').length == 0){

            // dont confuse salesforce
            expenseEntry.sobjectType = 'Expense__c';
            console.log('expenseEntry ', expenseEntry);

            helper.saveEntries(component, helper, [expenseEntry]);

        }

    },

    delete: function(component, event, helper){

        if(confirm( $A.get('$Label.c.SkyAreyousureyouwanttodeletethisexpense') )){

            var request = component.get('c.deleteExpenseEntry'),
                entryToBeDeleted = component.get('v.data');
                // entryToBeDeleted = JSON.parse(event.currentTarget.parentNode.parentNode.parentNode.getAttribute('data-entry'));

            entryToBeDeleted.sobjectType = 'Expense__c';

            request.setParams({ 'expenseEntry': entryToBeDeleted });

            request.setCallback(this, function(response) {
                helper.loadEntries(component, helper);
                $A.util.addClass(component.find('spinner'), 'hidden');
            });

            $A.util.removeClass(component.find('spinner'), 'hidden');
            $A.enqueueAction(request);

        }

    }
})