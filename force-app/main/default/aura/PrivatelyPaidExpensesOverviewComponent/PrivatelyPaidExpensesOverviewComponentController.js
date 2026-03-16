({
	init: function(component, event, helper) {

        var action = component.get('c.getExpenseEntries'),
            dateRangeStart = component.get('v.startDate'),
            dateRangeEnd = component.get('v.endDate'),
            filterByUser = component.get('v.userId');

        action.setParams({
            'dateRangeStart': moment(dateRangeStart, ['DD.MM.YYYY', 'YYYY-MM-DD']).format('YYYY-MM-DD'),
            'dateRangeEnd': moment(dateRangeEnd, ['DD.MM.YYYY', 'YYYY-MM-DD']).format('YYYY-MM-DD'),
            'filterByUser': filterByUser,
            'onlyShowPaidPrivately': true
        });


        action.setCallback(this, function(response){

            var results = response.getReturnValue(),
                totalExpenses = 0;

            if(results){
                
                for (var i = results.length - 1; i >= 0; i--) {
                    results[i].displayGross = helper.formatAsCurrency(results[i].ExpenseGross__c);
                    results[i].formattedExpenseDate = moment(results[i].ExpenseDate__c).format('DD.MM.YYYY');
                    results[i].stringified = JSON.stringify(results[i]);
                    totalExpenses = totalExpenses + parseFloat(results[i].ExpenseGross__c);
                }

                if(results.length === 0) {
                    $A.util.removeClass(component.find('noEntriesError'), 'hidden');
                }
                else {
                    $A.util.addClass(component.find('noEntriesError'), 'hidden');
                }

                // calculating total duration
                component.set('v.dateRangeTotalExpenses', helper.formatAsCurrency(totalExpenses));

                console.log('employee', results[0].Expensetracker__r);

                // employee name
                component.set('v.employee', results[0].Expensetracker__r);
                component.set('v.formattedStartDate', moment(dateRangeStart).format('DD.MM.YYYY'));
                component.set('v.formattedEndDate', moment(dateRangeEnd).format('DD.MM.YYYY'));

            }
            else {
                $A.util.removeClass(component.find('noEntriesError'), 'hidden');
            }

            console.log('setting entries', results);

            component.set('v.entries', results);

        });

        $A.enqueueAction(action);


	},
    
    // because disabled checkboxes look a bit faded
    dontMakeThisCheckboxActuallyWork: function(component, event, helper){
        event.getSource().set('v.value', !event.getSource().get('v.value'));
    }

})