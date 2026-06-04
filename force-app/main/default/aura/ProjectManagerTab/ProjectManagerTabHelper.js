({
    listCosts: function(component, helper) {

        helper.clearErrors(component);

        var fields = ['projectId', 'packageId', 'showTime', 'dateFrom', 'dateTo', 'showExpense', 'showSupplierCosts', 'showValidatedInvoicedCosts'],
            params = {},
            fieldsNotFilledOut = [];

        for (var i = fields.length - 1; i >= 0; i--) {

            var fieldName = fields[i],
                fieldLabel = component.find(fields[i]).get('v.label'),
                fieldValue = component.find(fields[i]).get('v.value');

            if((fieldName !== 'packageId' && fieldName !== 'dateFrom' && fieldName !== 'dateTo')
                && (fieldValue === undefined
                    || fieldValue === null
                    || fieldValue === '')){
                fieldsNotFilledOut.push(fieldLabel);
            }
            else {
                params[fieldName] = fieldValue;
            }

        }

            if(params['dateFrom'] !== undefined
                && params['dateTo'] !== undefined
                && moment(params['dateTo']).isBefore(params['dateFrom'])){
                helper.addError(component, 'Date (Until) cannot be earlier than Date (From).');
                return;
            }

            if(fieldsNotFilledOut.length > 0){
                helper.addError(component, 'Please fill out these fields correctly: ' + fieldsNotFilledOut.join(', '));
            }
            else {

                component.set('v.resultsLoaded', false);

                component.set('v.timeRows', []);
                component.set('v.expenseRows', []);
                component.set('v.supplierCostsRows', []);

                var action = component.get('c.get');

                console.log('params', params);

                action.setParams({'params': JSON.stringify(params)});
                action.setCallback(this, function(response){

                    var results = helper.copy(response.getReturnValue());

                    console.log(results);

                    if(results === null){
                        helper.addError(component, $A.get('$Label.c.SkySomethingwentwrongandwewerenotabletoloadthecosts') );
                        return;
                    }

                    component.set('v.rawData', results);
                    component.set('v.resultsLoaded', true);

                    helper.listCachedData(component, helper);

                    $A.util.addClass(component.find('spinner'), 'hidden');

                });

                $A.enqueueAction(action);

            }

    },

    listCachedData: function(component, helper) {

        var data = component.get('v.rawData');

        var timeColumnNames = ['DateFrom__c', 'Package__r.Name', 'ServiceType__c', 'Timetracker__r.Name', 'Description__c', 'DurationHhMm__c', 'RateHour__c', 'ServiceTotalTime__c', 'OutOfScope__c', 'TimeValidatedProjectResponsible__c', 'Name'],
            expenseColumnNames = ['ExpenseDate__c', 'Package__r.Name', 'RecordType.Name', 'Expensetracker__r.Name', 'ExpenseSubType__c', 'ServiceExpenseNet__c', 'ExpenseValidatedProjectResponsible__c', 'Name'],
            supplierColumnNames = ['SupplierCostsDate__c', 'PackageName__r.Name', 'SupplierInvoice__r.BillerAccount__r.Name', 'SupplierInvoice__r.OrderReference__c', 'SupplierInvoicePositionText__c', 'SupplierCostsInvoicedPM__c', 'CostsSupplierCostsNet__c', 'Name'];

        component.set('v.timeRows', helper.turnDataIntoTableRows(component, helper, data.times, 'times', timeColumnNames));
        component.set('v.expenseRows', helper.turnDataIntoTableRows(component, helper, data.expenses, 'expenses', expenseColumnNames));
        component.set('v.supplierCostsRows', helper.turnDataIntoTableRows(component, helper, data.supplierCosts, 'supplierCosts', supplierColumnNames));

        component.set('v.timeTotalRow', helper.turnDataIntoTotalTableRow(helper, data.times, 'times', timeColumnNames, ['DurationHhMm__c', 'ServiceTotalTime__c']));
        component.set('v.expenseTotalRow', helper.turnDataIntoTotalTableRow(helper, data.expenses, 'expenses', expenseColumnNames, ['ServiceExpenseNet__c']));
        component.set('v.supplierCostsTotalRow', helper.turnDataIntoTotalTableRow(helper, data.supplierCosts, 'supplierCosts', supplierColumnNames, ['CostsSupplierCostsNet__c']));

    },

    turnDataIntoTotalTableRow: function(helper, data, type, columnNames, columnsToSum){

        // summing
        var totals = [];
        for (var i = 0; i < data.length; i++) {

            for (var x = 0; x < columnNames.length; x++) {

                var columnName = columnNames[x];

                if(totals[x] === undefined){
                    if(columnName === 'DurationHhMm__c'){
                        totals[x] = moment.duration('0:00');
                    } else {
                        totals[x] = '';
                    }
                }

                if(columnsToSum.indexOf(columnName) > -1){

                    if(columnName === 'DurationHhMm__c'){
                        totals[x].add(data[i][columnName]);
                    } else {

                        var addThisNumber = Number(data[i][columnName]);

                        if(!isNaN(addThisNumber)){

                            if(totals[x] === ''){
                                totals[x] = addThisNumber;
                            } else {
                                totals[x] = Number(totals[x]) + addThisNumber;
                            }
                            
                        }

                    }

                }

            }

        }

        // aaand formatting
        var formattedTotals = [];

        for (var i = 0; i < totals.length; i++) {

            if(typeof totals[i] === 'object'){

                var totalDurationInMinutes = helper.padNumber(totals[i].asMinutes() % 60, 2),
                    formattedTotalDuration = Math.floor(totals[i].asHours()) + ':' + totalDurationInMinutes;

                formattedTotals[i] = formattedTotalDuration;

            } else {
                formattedTotals[i] = helper.formatAsCurrency(totals[i]);
            }

        }

        console.log('formattedTotals', formattedTotals);

        // add another empty one to match the validation check column
        formattedTotals.push('');

        return formattedTotals;

    },

    turnDataIntoTableRows: function(component, helper, data, dataType, columnNames){

        /*
            ordering
        */
        var sortOptions = component.get('v.sortOptions');

        console.log('sorting with options', sortOptions);

        if(sortOptions !== null && sortOptions[dataType] !== undefined) {

            data.sort(function(aObject, bObject){

                var a = helper.getPropByString(aObject, sortOptions[dataType].field),
                    b = helper.getPropByString(bObject, sortOptions[dataType].field),
                    fieldType = typeof a;

                var sort = 0;

                // making exceptions
                if(sortOptions[dataType].field === 'DurationHhMm__c'){
                    a = moment.duration(a).asMinutes();
                    b = moment.duration(b).asMinutes();
                }

                if(a > b) sort = 1;
                if(a < b) sort = -1;

                if(!sortOptions[dataType].desc) {
                    sort = sort * -1;
                }

                return sort;

            });

        }

        /*
            making everything formatted and ready for the table
        */
        var rows = [];

        for (var i = 0; i < data.length; i++) {

            var columns = [];

            for (var x = 0; x < columnNames.length; x++) {

                var column = {
                    value: helper.getPropByString(data[i], columnNames[x]),
                    showCheck: false,
                    linksToSFpage: (columnNames[x] === 'Name'),
                    id: data[i].Id,
                    alignment: 'left'
                };

                if(columnNames[x] === 'ExpenseValidatedProjectResponsible__c'
                    || columnNames[x] === 'TimeValidatedProjectResponsible__c'
                    || columnNames[x] === 'OutOfScope__c'
                    || columnNames[x] === 'SupplierCostsInvoicedPM__c'){
                    column['showCheck'] = column.value;
                    column['value'] = '';
                }

                if(columnNames[x] === 'DurationHhMm__c'){
                    column['value'] = helper.formatAsTime(column.value);
                    column['alignment'] = 'right';
                }

                if(columnNames[x] === 'RateHour__c'
                    || columnNames[x] === 'ServiceTotalTime__c'
                    || columnNames[x] === 'ServiceExpenseNet__c'
                    || columnNames[x] === 'CostsSupplierCostsNet__c'){
                    column['value'] = helper.formatAsCurrency(column['value']);
                    column['alignment'] = 'right';
                }

                if(columnNames[x] === 'DateFrom__c'
                    || columnNames[x] === 'ExpenseDate__c'
                    || columnNames[x] === 'SupplierCostsDate__c'){
                    column['value'] = moment(column['value']).format('D.MM.YYYY');
                }

                columns.push(column);

            }

            columns.push({
                showCheckbox: true,
                toBeValidated: (dataType === 'supplierCosts') ? false : true,
                id: data[i].Id
            });

            rows.push(columns);

        }

        return rows;

    },

    validateSelectedCosts: function(component, helper){

        $A.util.removeClass(component.find('spinner'), 'hidden');

        var action = component.get('c.saveData');

        action.setParams({
            times: helper.getObjectListFromColumnData(component.get('v.timeRows'), 'Time__c'),
            expenses: helper.getObjectListFromColumnData(component.get('v.expenseRows'), 'Expense__c'),
            scList: helper.getObjectListFromColumnData(component.get('v.supplierCostsRows'), 'SupplierCosts__c')
        });

        action.setCallback(this, function(response){

            $A.util.addClass(component.find('spinner'), 'hidden');
            helper.clearErrors(component);

            console.log(response, 'resp');
            if(response.getState() !== 'ERROR'){
                component.set('v.showSuccessMessage', true);
                helper.listCosts(component, helper);
            }
            else {

                var error = response.getError();
                if(error[0] !== undefined && error[0].pageErrors !== undefined){
                    helper.addError(component, error[0].pageErrors[0].message);
                }
                else {
                    helper.addError(component, $A.get('$Label.c.SkySomethingwentwrongandwewerenotabletovalidatetheselectedcosts') );
                }

                window.scrollTo(0, 0);
            }


        });

        $A.enqueueAction(action);

    },

    getObjectListFromColumnData: function(rows, objectName){

        var list = [],
            fieldNamesByObject = {
                Time__c: 'TimeValidatedProjectResponsible__c',
                Expense__c: 'ExpenseValidatedProjectResponsible__c',
                SupplierCosts__c: 'SupplierCostsInvoicedPM__c'
            };

        for (var i = rows.length - 1; i >= 0; i--) {

            var lastColumn = rows[i][rows[i].length - 1],
                object = {
                    sobjectType: objectName,
                    Id: lastColumn.id
                };

            object[fieldNamesByObject[objectName]] = lastColumn.toBeValidated;

            list.push(object);

        }

        return list;

    },

    formatAsTime: function(number){
        if(number.indexOf('0') === 0 && number.indexOf(':') !== 1){
            number = number.slice(1, number.length);
        }
        return number;
    },

    formatAsCurrency: function(number){

        number = number.toString();

        if(number !== ''){

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

        }

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

    // needed to format duration correctly
    padNumber: function(n, width, z) {
        z = z || '0';
        n = n + '';
        return n.length >= width ? n : new Array(width - n.length + 1).join(z) + n;
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
    },

    copy: function(obj) {
        return JSON.parse(JSON.stringify(obj)); // trick to copy the defaul JSON and don't overried the default :)
    }

})