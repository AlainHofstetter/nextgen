({

    loadData : function(component, helper, reloadAll) {

        // clear any existing errors
        helper.clearErrors(component);

        $A.util.removeClass(component.find('spinner'), 'hidden');

        let action = component.get('c.getProjectStructure');
        let project = {
            projectId: component.get('v.projectId'),
            dateFrom: component.find('DateFrom').get('v.value'),
            dateTo: component.find('DateUntil').get('v.value')
        }

        action.setParams(project);
        action.setCallback(this, function(response){

            var data = helper.copy(response.getReturnValue());

            console.info('[BillingTabHelper]::[loadData]::[data]\n', data);

            if(!data.project){
                helper.addError(component, $A.get('$Label.c.SkyThisprojecthasincompletedataPleaseverifyandrefreshthepage'));
                $A.util.addClass(component.find('spinner'), 'hidden');
                return;
            }
            // when there is no invoice available
            if(!data.invoice) {
                data.invoice = {
                    InvoiceTitle__c: data.project.DefaultInvoiceTitle__c,
                    InvoiceDescription__c: data.project.DefaultInvoiceDescription__c,
                };
            }

            if(component.get('v.keepUserEnteredDateRange') === true){                
                data.invoice.PeriodFrom__c = project.dateFrom;
                data.invoice.PeriodUntil__c = project.dateTo;
            }

            // in case of bad data
            if(!data.invoice.PeriodFrom__c) data.invoice.PeriodFrom__c = project.dateFrom;
            if(!data.invoice.PeriodUntil__c) data.invoice.PeriodUntil__c = project.dateTo;

            // set invoice and finance dates
            if(!data.invoice.InvoiceDate__c) data.invoice.InvoiceDate__c = moment().format('YYYY-MM-DD');
            if(!data.invoice.FinanceDate__c) data.invoice.FinanceDate__c = data.invoice.PeriodUntil__c;

            if(!data.invoice.PeriodFrom__c || !data.invoice.PeriodUntil__c) {
                data.packages = null;
            }

            // if no dates at all, set defaults
            if ((!project.dateFrom || !project.dateTo)
                && (!data.invoice.PeriodFrom__c && !data.invoice.PeriodUntil__c)){

                var lastMonth = moment().subtract(1, 'months'),
                    firstDayOfLastMonth = lastMonth.startOf('month').format('YYYY-MM-DD'),
                    lastDayOfLastMonth = lastMonth.endOf('month').format('YYYY-MM-DD');

                data.invoice.PeriodFrom__c = firstDayOfLastMonth;
                data.invoice.PeriodUntil__c = lastDayOfLastMonth;

            }

            // // because after spending too much time trying to make the component do this work i gave up
            if(data.invoice.InvoiceTitle__c) component.set('v.formattedInvoiceTitle', data.invoice.InvoiceTitle__c.replace(/<(?:.|\n)*?>/gm, ''));
            if(data.invoice.InvoiceDescription__c) component.set('v.formattedInvoiceDescription', data.invoice.InvoiceDescription__c.replace(/<(?:.|\n)*?>/gm, ''));

            component.set('v.data', data);
            
            if(data.packages) helper.calculateColumns(component, helper, true);
            
            $A.util.addClass(component.find('spinner'), 'hidden');

            // set total rows as backup rows
            if (reloadAll) component.set('v.totalFirstRows', component.get('v.totalsRow'));
        });

        $A.enqueueAction(action);

    },

    calculateColumns: function(component, helper, isFirstRun){
        let data = { ...component.get('v.data') };

        data = { ...this.calc(data, component, helper, isFirstRun) };
        // data = this.calc(data, component, helper, isFirstRun);

        component.set('v.data', data);
    },

    calc: function(data, component, helper, isFirstRun){

        var totalsRow = [],
            numberFields = ['budget', 'invoice', 'calculatedAvailableFunds', 'servicesTotal', 'servicesTotalDR', 'invoiceNoDraft', 'invoiceInProgress', 'allowanceTotal'];

        for (var i = data.packages.length - 1; i >= 0; i--) {

            var pck = data.packages[i],
                invoiceNoDraft = helper.giveMeANumberOrGiveMeZero(pck.invoiceNoDraft),
                invoiceInProgress = helper.giveMeANumberOrGiveMeZero(pck.invoiceInProgress);

            // if the package is a group, we need to summarize invoiceInProgress
            if(pck.pck.PackageType__c === 'Group'){

                // starting calculation from 0
                pck.invoiceInProgress = 0;

                for (var x = data.packages.length - 1; x >= 0; x--) {

                    var childPackage = data.packages[x];

                    // checking if childpackage
                    if(pck.pck.Id === childPackage.pck.PackageSuperior__c){

                        // grouping invoiceInProgress
                        pck.invoiceInProgress = helper.giveMeANumberOrGiveMeZero(pck.invoiceInProgress) + helper.giveMeANumberOrGiveMeZero(childPackage.invoiceInProgress);

                    }

                }

            }

            // C : Invoice Column (Column G + Column H)
            // Only calculate when we actually have a value for invoiceInProgress
            pck.invoice = invoiceNoDraft;
            if(pck.invoiceInProgress) pck.invoice = invoiceNoDraft + invoiceInProgress;

            // D: Available Funds Column (Column B - Column C)
            pck.calculatedAvailableFunds = pck.availableFunds - invoiceInProgress;

            /*
                (CR) Z3: allowance total
            */
            // default
            pck.allowanceTotal = '';

            // project management allowance
            if ((pck.pck.RecordType.Name == 'Time' || pck.pck.RecordType.Name == 'Zeit') && pck.pck.ProjectManagementAllowancePackage__c === true){
                // check all packages that qualify
                var totalFromQualifyingPackages = 0;
                
                for (var pi = 0; pi < data.packages.length; pi++) {
                    var packageToCheck = data.packages[pi];
                    if( (
                           (packageToCheck.pck.RecordType.Name == 'Time' || packageToCheck.pck.RecordType.Name == 'Zeit')
                        || ((packageToCheck.pck.RecordType.Name == 'Supplier Costs' || packageToCheck.pck.RecordType.Name == 'Drittkosten') && packageToCheck.pck.SupplierCostsGroup__c == false)
                        ) && packageToCheck.pck.ExcludeFromProjectMgmtAllowance__c == false){
                        totalFromQualifyingPackages = totalFromQualifyingPackages + helper.giveMeANumberOrGiveMeZero(packageToCheck.invoiceInProgress);
                    }
                }
                pck.allowanceTotal = totalFromQualifyingPackages * (helper.giveMeANumberOrGiveMeZero(data.project.ProjectManagementAllowancePercent__c) / 100);
            }

            // expense allowance
            if((pck.pck.RecordType.Name == 'Expense' || pck.pck.RecordType.Name == 'Spesen') &&  pck.pck.ExpenseAllowancePackage__c === true){

                var totalFromQualifyingPackages = 0;
                for (var pi = 0; pi < data.packages.length; pi++) {
                    var packageToCheck = data.packages[pi];

                    if( (
                       (packageToCheck.pck.RecordType.Name == 'Time' || packageToCheck.pck.RecordType.Name == 'Zeit')
                    || ((packageToCheck.pck.RecordType.Name == 'Supplier Costs' || packageToCheck.pck.RecordType.Name == 'Drittkosten') && packageToCheck.pck.SupplierCostsGroup__c == false)
                    ) && packageToCheck.pck.ExcludeFromExpenseAllowance__c == false){
                        totalFromQualifyingPackages = totalFromQualifyingPackages + helper.giveMeANumberOrGiveMeZero(packageToCheck.invoiceInProgress);
                    }

                }
                pck.allowanceTotal = totalFromQualifyingPackages * (helper.giveMeANumberOrGiveMeZero(data.project.ExpenseAllowancePercent__c) / 100);
            }

            // only calcuate when not group and after calculations done and only on second run
            if(pck.pck.PackageType__c !== 'Group'){

                for (var index = 0; index < numberFields.length; index++) {

                    var valueToAdd = helper.giveMeANumberOrGiveMeZero(helper.getPropByString(pck, numberFields[index]));

                    if(totalsRow[index] === undefined){
                        totalsRow.push(valueToAdd);
                    }
                    else {
                        totalsRow[index] = totalsRow[index] + valueToAdd;
                    }

                }

            }

            pck.showModalForBillingPositionText = false;

            if(isFirstRun){

                // Lightning bug workaround:
                // values dont update if the value is in a nested object
                // moving them to the front and having to move them around later for saving
                pck.showPosition = pck.pck.ShowPosition__c;
                pck.showPositionAmount = pck.pck.ShowPositionAmount__c;
                pck.showInvoiceText = pck.pck.ShowInvoiceText__c;

                if(data.invoice.InvoiceStatus__c == 'Draft'){
                    pck.packageBillingPositionText = pck.position.InvoicePositionText__c ? pck.position.InvoicePositionText__c : ' ';
                }
                else {
                    pck.packageBillingPositionText = pck.pck.PackageBillingPositionText__c ? pck.pck.PackageBillingPositionText__c : ' ';
                }

                /*
                console.log(package.PackageBillingPositionText__c, 'text before');
                if(package.PackageBillingPositionText__c) package.PackageBillingPositionText__c = package.PackageBillingPositionText__c.replace(/<(?:.|\n)*?>/gm, '');
                console.log(package.PackageBillingPositionText__c, 'text after');
                */

            }

        }

        // format as currency!
        // we want to keep our numbers clean, but also format currencies in the table.
        // so we're creating new formatted fields to display
        /* for (var i = data.packages.length - 1; i >= 0; i--) { */
        /*  */
        /*     var pck = data.packages[i]; */
        /*     pck.formatted = {}; */
        /*  */
        /*     for (var y = numberFields.length - 1; y >= 0; y--) { */
        /*         var numberToBeFormatted = numberFields[y]; */
        /*         pck.formatted[numberToBeFormatted] = helper.formatAsCurrency(helper.giveMeANumberOrGiveMeZero(pck[numberToBeFormatted])); */
        /*     } */
        /*  */
        /* } */

        // console.log('setting data');
        // component.set('v.data', data);

        // console.info('[BillingTabHelper]::Setting total rows', totalsRow);

        // format as currency before we save the total rows
        for (var i = totalsRow.length - 1; i >= 0; i--) {
            totalsRow[i] = helper.formatAsCurrency(totalsRow[i]);
        }
        component.set('v.totalsRow', totalsRow);

        // we need to calculate the data again to update all the groups
        // a little recursion hasn't hurt anybody
        /* if(!runningThroughAgainForGroups) { */
        /*     console.log('running again'); */
        /*     helper.calculateColumns(component, helper, true); */
        /* } else { */
        /*     console.log('were done now is it broken?'); */
        /* } */

        return data;

    },

    // trying to catch all possible input errors and handling it cleanly
    giveMeANumberOrGiveMeZero: function(theNumberInQuestion){

        if(theNumberInQuestion === undefined
            || theNumberInQuestion === NaN
            || theNumberInQuestion === ''
            || parseFloat(theNumberInQuestion) === NaN) {
            theNumberInQuestion = 0;
        }
        else {
            theNumberInQuestion = parseFloat(theNumberInQuestion);
        }

        return theNumberInQuestion;

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

        /* console.log('output', number.replace(/(\d)(?=(\d{3})+(?!\d))/g, "$1'")); */

        return number.replace(/(\d)(?=(\d{3})+(?!\d))/g, "$1'");

    },

    // http://stackoverflow.com/questions/6906108/in-javascript-how-can-i-dynamically-get-a-nested-property-of-an-object
    getPropByString: function(obj, propString) {

        var prop,
            props = propString.split('.');

        for (var i = 0, iLen = props.length - 1; i < iLen; i++) {
            prop = props[i];

            var candidate = obj[prop];
            if (candidate !== undefined) {
                obj = candidate;
            }
        }

        return obj[props[i]] !== undefined ? obj[props[i]] : '' ;
    },

    /*
    Error handling!
    */
    addError: function(component, errorMessage){
        console.log('-----BillingTabHelper.addError: ',errorMessage);
        var errors = component.get('v.errors');
        errors.push(errorMessage);
        component.set('v.errors', errors);
    },
    clearErrors: function(component){
        component.set('v.errors', []);
    },

    saveInvoice: function(component, helper){

        // clear any existing errors
        helper.clearErrors(component);

        $A.util.removeClass(component.find('spinner'), 'hidden');

        var data = helper.copy(component.get('v.data')),
            invoice = helper.copy(data.invoice),
            packages = [],
            positions = [];

        invoice.sobjectType = 'Invoice__c';
        invoice.ProjectName__c = data.project.Id;

        delete invoice.TermsOfPayment2__c;

        for (var i = data.packages.length - 1; i >= 0; i--) {

            var p = data.packages[i];

            packages.push({
                sobjectType: 'Package__c',
                Id: p.pck.Id,
                PackageSuperior__c: p.pck.PackageSuperior__c,
                ShowPosition__c: p.showPosition,
                ShowInvoiceText__c: p.showInvoiceText,
                ShowPositionAmount__c: p.showPositionAmount
            });

            var position = {
                sobjectType: 'InvoicePos__c',
                InvoicePositionAmount__c: p.invoiceInProgress,
                ShowPosition__c: p.showPosition,
                ShowInvoiceText__c: p.showInvoiceText,
                ShowPositionAmount__c: p.showPositionAmount,
                PackageName__c: p.pck.Id,
                PackageType__c: p.pck.PackageType__c,
                InvoicePositionSortNr__c: p.pck.PackageSortNr__c
            };

            if(data.invoice.InvoiceStatus__c === 'Draft'){
                position.InvoicePositionText__c = p.packageBillingPositionText;
            }
            else {
                position.PackageBillingPositionText__c = p.packageBillingPositionText;

                if (!position.InvoicePositionText__c) {
                    position.InvoicePositionText__c = p.packageBillingPositionText;
                }
            }

            if(p.position.Id) position.Id = p.position.Id;

            positions.push(position);

        }

        let action = component.get('c.save');
        let params = {
                draft: invoice,
                packages: packages,
                positions: positions
            };

        console.info('[BillingTabHelper]::[Save]::[params]\n', params);

        action.setParams(params);
        action.setCallback(this, function(response){

            console.info('[BillingTabHelper]::[Save]::[Response]--->', response.getState());

            if (response.getState() == 'ERROR'){
                component.set('v.showSuccessMessage', false);

                var error = response.getError();
                console.info('[BillingTabHelper]::[Save]::[Error Message]--->', error);
                console.info('[BillingTabHelper]::[Save]::[error 0]--->', error[0]);
                if (error[0] !== undefined){

                    console.info('[BillingTabHelper]::[Save]::[error.0.message]--->', error[0].message);

                    // display Exception errors
                    if (error[0].message !== undefined) {
                        let errMsg = error[0].message;
                        console.info('[BillingTabHelper]::[Save]::[errMsg]--->', errMsg);
                        helper.addError(component, errMsg);
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

                    // scroll to top
                    window.scrollTo(0, 0);

                    $A.util.addClass(component.find('spinner'), 'hidden');

                }
                else {
                    helper.addError(component, $A.get('$Label.c.SkySomethingwentwrongandwewerenotable') );
                }

                console.log('[BillingTabHelper]::[Save]::[v.errors]--->',component.get('v.errors'));
            }
            else {
                console.info('[BillingTabHelper]::[Save Success]::load...');
                $A.util.removeClass(component.find('spinner'), 'hidden');
                helper.reloadDataAfterSaving(component, helper, 30000);
            }
        });

        $A.enqueueAction(action);

    },


    reloadDataAfterSaving: function(component, helper, interval) {
        setTimeout(() => {
            helper.loadData(component, helper, false);
            if (interval > 0) helper.reloadDataAfterSaving(component, helper, interval - 15000);
            else {
                component.set('v.showSuccessMessage', true);
                console.info('[BillingTabHelper]::[Save Success]::load Done');
            }
        }, interval);
    },

    deepEqual: function(object1, object2, helper) {
        const keys1 = Object.keys(object1);
        const keys2 = Object.keys(object2);

        if (keys1.length !== keys2.length) {
            return false;
        }

        for (const key of keys1) {
            const val1 = object1[key];
            const val2 = object2[key];
            const areObjects = helper.isObject(val1) && helper.isObject(val2);
            if (
                areObjects && !helper.deepEqual(val1, val2, helper) ||
                !areObjects && val1 !== val2
            ) {
                return false;
            }
        }

        return true;
    },

    isObject: function(object) {
        return object != null && typeof object === 'object';
    },

    moveInArray: function(array, old_index, new_index) {
        if (new_index >= array.length) {
            var k = new_index - array.length;
            while ((k--) + 1) {
                array.push(undefined);
            }
        }
        array.splice(new_index, 0, array.splice(old_index, 1)[0]);
        return array; // for testing purposes
    },

    copy: function(obj) {
        return JSON.parse(JSON.stringify(obj)); // trick to copy the defaul JSON and don't overried the default :)
    },
    typingTimeout: null
});