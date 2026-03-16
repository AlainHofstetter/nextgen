({
    listTime: function(component, helper) {

        var action = component.get('c.listTimeEntries'),
            params = {
                        'dateFrom': component.find('DateFrom').get('v.value'),
                        'dateUntil': component.find('DateUntil').get('v.value'),
                        'timetracker': component.find('Timetracker').get('v.value')
                    };


        if(params.dateFrom.length === 0
        || params.dateUntil.length === 0
        || params.timetracker === null){
            helper.addError(component, $A.get('$Label.c.SkyPleasemakesureallfieldsarefilledout') );
        }
        else {

            // if we have any?
            helper.clearErrors(component);

            action.setParams(params);
            action.setCallback(this, function(response){

                var results = response.getReturnValue();

                console.log('results', results);

                component.set('v.rawTimeEntries', results);

                // build up big object with summed time entries grouped by day by abacus
                var durationSumsByDayByAbacus = {},
                    durationSumsByDay = {};

                for (var i = results.length - 1; i >= 0; i--) {

                    var timeEntry = results[i];

                    if(!durationSumsByDayByAbacus.hasOwnProperty(timeEntry.AbacusTimeType__c)){
                        durationSumsByDayByAbacus[timeEntry.AbacusTimeType__c] = {};
                    }

                    if(!durationSumsByDayByAbacus[timeEntry.AbacusTimeType__c].hasOwnProperty(timeEntry.DateFrom__c)){
                        durationSumsByDayByAbacus[timeEntry.AbacusTimeType__c][timeEntry.DateFrom__c] = {
                            sum: parseFloat(timeEntry.DurationHhMmN__c).toFixed(2),
                            isWeekend: helper.isDateInWeekend(timeEntry.DateFrom__c)
                        };
                    }
                    else {
                        durationSumsByDayByAbacus[timeEntry.AbacusTimeType__c][timeEntry.DateFrom__c].sum = (parseFloat(durationSumsByDayByAbacus[timeEntry.AbacusTimeType__c][timeEntry.DateFrom__c].sum) + parseFloat(timeEntry.DurationHhMmN__c)).toFixed(2);
                    }

                    if(!durationSumsByDay.hasOwnProperty(timeEntry.DateFrom__c)){
                        durationSumsByDay[timeEntry.DateFrom__c] = {
                            sum: parseFloat(timeEntry.DurationHhMmN__c).toFixed(2),
                            isWeekend: helper.isDateInWeekend(timeEntry.DateFrom__c)
                        };
                    }
                    else {
                        durationSumsByDay[timeEntry.DateFrom__c].sum = (parseFloat(durationSumsByDay[timeEntry.DateFrom__c].sum) + parseFloat(timeEntry.DurationHhMmN__c)).toFixed(2);
                    }

                }

                // build up array with dates so we can build the table without gaps
                var daysInDuration = [],
                    totalDays = moment(params.dateUntil).diff(params.dateFrom, 'days'),
                    dateCursor = moment(params.dateFrom),
                    totalWeekDays = 0;

                for (var i = 0; i <= totalDays; i++) {
                    var currentFormattedDate = dateCursor.format('YYYY-MM-DD'),
                        isWeekend = helper.isDateInWeekend(currentFormattedDate);

                    if(!isWeekend) totalWeekDays++;

                    daysInDuration.push({
                        date: currentFormattedDate,
                        day: dateCursor.format('D'),
                        isWeekend: isWeekend,
                        dayName: dateCursor.format('ddd')
                    });
                    dateCursor.add(1, 'days');
                }

                /*
                    because lightning doesnt support looping over objects,
                    we now have to go and build the table within javascript first
                */
                var rows = [];
                for(var abacus in durationSumsByDayByAbacus){

                    var columns = [],
                        sumsByDays = durationSumsByDayByAbacus[abacus],
                        abacusTotal = 0;

                    columns.push({
                        value: abacus,
                        isWeekend: false
                    });

                    for (var i = 0; i < daysInDuration.length; i++) {
                        var d = daysInDuration[i],
                            value = '';

                        if(sumsByDays[d.date]){
                            value = sumsByDays[d.date].sum;
                            abacusTotal = (parseFloat(abacusTotal) + parseFloat(sumsByDays[d.date].sum)).toFixed(2);
                        }

                        columns.push({
                            value: helper.processAndFormatToTime(helper, value),
                            isWeekend: d.isWeekend
                        });

                    }

                    columns.push({
                        value: helper.processAndFormatToTime(helper, abacusTotal),
                        isWeekend: false
                    });

                    rows.push(columns);

                }

                // build up row for totals
                var totalRow = [],
                    theBigTotal = 0;

                for (var i = 0; i < daysInDuration.length; i++) {
                    var d = daysInDuration[i],
                        value = 0,
                        colourCode = '';

                    if(durationSumsByDay[d.date]){
                        value = durationSumsByDay[d.date].sum;
                        theBigTotal = (parseFloat(theBigTotal) + parseFloat(durationSumsByDay[d.date].sum)).toFixed(2);
                    }

                    if(!d.isWeekend){

                        if(value < 8){
                            colourCode = 'code-orange';
                        }

                        if(value < 5){
                            colourCode = 'code-red';
                        }

                    }

                    if(d.isWeekend && value === 0){
                        value = '';
                    }

                    totalRow.push({
                        value: helper.processAndFormatToTime(helper, value),
                        isWeekend: d.isWeekend,
                        colourCode: colourCode
                    });

                }

                totalRow.push({
                    value: helper.processAndFormatToTime(helper, theBigTotal),
                    isWeekend: false
                });

                var targetHours = totalWeekDays * 8,
                    hourDifference = (targetHours - theBigTotal) * -1;

                component.set('v.targetHours', helper.processAndFormatToTime(helper, targetHours));
                component.set('v.theBigTotal', helper.processAndFormatToTime(helper, theBigTotal));
                component.set('v.hourDifference', helper.processAndFormatToTime(helper, hourDifference));

                component.set('v.totalRow', totalRow);
                component.set('v.daysInDuration', daysInDuration);
                component.set('v.rows', rows);

                console.log('rows', rows);

            });

            $A.enqueueAction(action);

        }


    },

    formatAsTime: function(number){

        if(number !== undefined) {

            if(number === 0) {

                return '0:00';

            } else {

                number = number.toString();

                // remove any leading zero
                if(number.indexOf('0') === 0 && number.indexOf(':') !== 1){
                    number = number.slice(1, number.length);
                }

                // do things with decimals
                if(number.indexOf(':') > 0) {

                    var splittedNumber = number.split(':');

                    // add 0 if we only have 1 decimal number
                    if(splittedNumber[1].length === 1){
                        splittedNumber[1] = splittedNumber[1] + '0';
                    }

                    // cut off if we have more then 2 decimal numbers
                    if(splittedNumber[1].length > 2){
                        splittedNumber[1] = splittedNumber[1].slice(0, 2);
                    }

                    number = splittedNumber.join(':');

                }

            }

            return number;

        }

    },

    // because we have it as a number from SF
    // and we kinda of need that with all the calculation and stuff
    // this function is to make 1.75 > 1:45
    processAndFormatToTime: function(helper, time){

        if(time !== 0 && time !== undefined && time !== ''){

            // like they do in the sci fi movies
            var splitTime = time.toString().split('.'),
                processedMinutes
                    = (splitTime[1] != '00' && splitTime[1] !== undefined)
                    ? Math.round((60 / (100/parseFloat(splitTime[1], 10))))
                    : '00',
                gluedTogetherTime = splitTime[0] + ':' + helper.padNumber(processedMinutes, 2);

            return helper.formatAsTime(gluedTogetherTime);

        } else {
            if(time === 0){
                return helper.formatAsTime(time);
            } else {
                return time;
            }
        }

    },

    isDateInWeekend: function(date){
        console.log('weekend?', date, moment(date).format('d'), (moment(date).format('d') === 0 || moment(date).format('d') === 6));
        return (moment(date).format('d') == 0 || moment(date).format('d') == 6);
    },

    paginate: function(component, helper, direction){

        var contacts = component.get('v.contactsToPaginateThrough'),
            account = component.find('Account').get('v.value');

        // no account, no pagination, bro
        if(account === null) return ;

        if(contacts === null) {

            var request = component.get('c.loadContactsForAccount');
            request.setParams({
                filterById: account
            });

            // Add callback behavior for when response is received
            request.setCallback(this, function(response) {
                contacts = response.getReturnValue();
                component.set('v.contactsToPaginateThrough', contacts);
                helper.actuallyPaginate(component, helper, direction);
            });
            $A.enqueueAction(request);

        }
        else {
            helper.actuallyPaginate(component, helper, direction);
        }

    },

    // this is a seperate function because sometimes we need to wait for a callback to continue
    actuallyPaginate: function(component, helper, direction){

        var contacts = component.get('v.contactsToPaginateThrough'),
            index = component.get('v.paginationIndex'),
            max = contacts.length + 1;

        if(direction === 'forward'){
            index++;
            if(index === max) index = 1;
        }

        if(direction === 'backward'){
            index--;
            if(index === 0) index = contacts.length;
        }

        component.set('v.paginationIndex', index);

        var selectedContact = contacts[index - 1];

        component.find('Timetracker').set('v.value', selectedContact.Id);
        component.find('Timetracker').set('v.valueLabel', selectedContact.Name);

        helper.listTime(component, helper);

    },

    validateTime: function(component, helper){

        var timeEntries = component.get('v.rawTimeEntries');

        for (var i = timeEntries.length - 1; i >= 0; i--) {
            timeEntries[i].sobjectType = 'Time__c';
            timeEntries[i].TimeValidatedHumanResources__c = true;
        }

        $A.util.removeClass(component.find('spinner'), 'hidden');

        var action = component.get('c.saveData');

        action.setParams({
            times: timeEntries
        });

        action.setCallback(this, function(response){

            $A.util.addClass(component.find('spinner'), 'hidden');
            helper.clearErrors(component);

            console.log('response', response.getState());

            if(response.getState() !== 'ERROR'){
                component.set('v.showSuccessMessage', true);
            }
            else {

                var error = response.getError();

                if(error[0] !== undefined && error[0].pageErrors !== undefined){
                    helper.addError(component, error[0].pageErrors[0].message);
                }
                else {
                    helper.addError(component, $A.get('$Label.c.SkySomethingwentwrongandwewerenotabletovalidatethetimeentries') );
                }

                window.scrollTo(0, 0);
            }


        });

        $A.enqueueAction(action);

    },

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
    }
})