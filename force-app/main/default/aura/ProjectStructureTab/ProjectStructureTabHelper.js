({
    loadData : function(component, helper) {

        console.log('loadign data');

        // clear any existing errors
        helper.clearErrors(component);

        $A.util.removeClass(component.find('spinner'), 'hidden');

        var action = component.get('c.get');

        action.setParams({
            projectId: component.get('v.projectId'),
        });

        action.setCallback(this, function(response){

            var response = response.getReturnValue();

            console.log('resp', response);

            if(response.length === 0){
                helper.addError(component, $A.get('$Label.c.SkyThisprojecthasincompletedataPleaseverifyandrefreshthepage'));
                $A.util.addClass(component.find('spinner'), 'hidden');
                return;
            }

            var data = {
                    packages: helper.copy(response),
                    project: helper.copy(response[0].ProjectName__r)
                },
                picklistValues = component.get('v.picklistValues');

            console.log('PickListValues', picklistValues);

            // lightning bug work arounds! :D
            for (var i = 0; i < data.packages.length; i++) {
                // lightning bug where nested objects dont get binding or something weird like that
                if(data.packages[i].Segment__r) data.packages[i].SegmentName = data.packages[i].Segment__r.Name;

                // assign picklist values because of reasons. lighting is not full javascript
                data.packages[i].subTypePicklistValues = picklistValues.PackageSubType__c[data.packages[i].RecordType.Name];
                data.packages[i].packageStatusPicklistValues = picklistValues.PackageStatus__c[data.packages[i].RecordType.Name];
            }

            console.log('data', data);

            helper.setGroupTotals(component, data, helper);

            $A.util.addClass(component.find('spinner'), 'hidden');

        });

        $A.enqueueAction(action);

    },

    setGroupTotals: function(component, data, helper){

        //console.log('before data', data);
        for (var i = data.packages.length - 1; i >= 0; i--) {

            var pck = data.packages[i];

            // if the package is a group lets sum
            if(pck.PackageType__c === 'Group'){

                console.log('summing', pck.Name);

                // starting calculation from 0
                pck.BudgetAssign__c = 0;

                for (var x = data.packages.length - 1; x >= 0; x--) {

                    var childPackage = data.packages[x];

                    // checking if childpackage
                    if(pck.Id === childPackage.PackageSuperior__c){

                        // set amount based on package type
                        var amount = 0;

                        if (childPackage.PackageType__c === 'Time')
                            amount = helper.giveMeANumberOrGiveMeZero(childPackage.BudgetAssignTotalTime__c);

                        if (childPackage.PackageType__c === 'Expense')
                            amount = helper.giveMeANumberOrGiveMeZero(childPackage.BudgetAssignTotalExpense__c);

                        if (childPackage.PackageType__c === 'SupplierCosts')
                            amount = helper.giveMeANumberOrGiveMeZero(childPackage.BudgetAssignTotalSupplierCosts__c);

                        // grouping amount assign
                        pck.BudgetAssign__c = helper.giveMeANumberOrGiveMeZero(pck.BudgetAssign__c) + amount;

                    }
                }

                pck.formattedBudgetAssign__c = helper.formatAsCurrency(pck.BudgetAssign__c);

            }
        };

        component.set('v.data', data);

    },

    save: function(component, helper, callback){

        // clear any existing errors
        helper.clearErrors(component);

        $A.util.removeClass(component.find('spinner'), 'hidden');

        var data = component.get('v.data'),
            action = component.get('c.save');

        action.setParams({
            packages: data.packages
        });

        console.log('sending data', {
            packages: data.packages
        });

        action.setCallback(this, function(response){

            console.log('c.save data', response);

            if(response.getState() === 'ERROR'){

                var error = response.getError();
                if(error[0] !== undefined){

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
                    helper.addError(component, 'Something went wrong and we were not able to save the invoice.');
                }

            }
            else {

                if(callback !== undefined) {
                    callback();
                } else {
                    helper.loadData(component, helper);
                }

                component.set('v.showSuccessMessage', true);

            }

        });

        $A.enqueueAction(action);

    },

    delete: function(component, helper, pck){

        console.log('i would like to delete', pck);

        // clear any existing errors
        helper.clearErrors(component);

        $A.util.removeClass(component.find('spinner'), 'hidden');

        var data = component.get('v.data'),
            action = component.get('c.del'),
            params = {
                packages: [pck]
            };

        // deleting the package's children because wow we're terrible people
        if(pck.RecordType.Name === 'Group'){
            for (var i = 0; i < data.packages.length; i++) {
                if(data.packages[i].PackageSuperior__c === pck.Id){
                    params.packages.push(data.packages[i]);
                }
            }
        }

        action.setParams(params);

        console.log('c.del request', params);

        action.setCallback(this, function(response){

            console.log('c.del data', response);

            if(response.getState() === 'ERROR'){

                var error = response.getError();
                if(error[0] !== undefined){

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
                    helper.addError(component, 'Something went wrong and we were not able to save the invoice.');
                }

            }
            else {
                helper.loadData(component, helper);
                component.set('v.showSuccessMessage', true);
            }

        });

        $A.enqueueAction(action);

    },

    // trying to catch all possible input errors and handling it cleanly
    giveMeANumberOrGiveMeZero: function(theNumberInQuestion){

        if(theNumberInQuestion === undefined
            || theNumberInQuestion === NaN
            || theNumberInQuestion === null
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