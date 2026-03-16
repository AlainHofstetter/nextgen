({

    loadData : function(component, helper) {

        // clear any existing errors
        helper.clearErrors(component);

        $A.util.removeClass(component.find('spinner'), 'hidden');

        var action = component.get('c.get'),
            dateFrom = component.find('DateFrom').get('v.value'),
            dateTo = component.find('DateUntil').get('v.value');

        action.setParams({
            projectId: component.get('v.projectId'),
            dateFrom: dateFrom,
            dateTo: dateTo
        });

        action.setCallback(this, function(response){

            var data = helper.copy(response.getReturnValue());

            if(data === null || data.packages === null){
                helper.addError(component, $A.get('$Label.c.SkySomethingwentwrongwithretrievingthedata') );
                $A.util.addClass(component.find('spinner'), 'hidden');
                return;
            }

            if(!data.project){
                helper.addError(component, $A.get('$Label.c.SkyThisprojecthasincompletedataPleaseverifyandrefreshthepage') );
                $A.util.addClass(component.find('spinner'), 'hidden');
                return;
            }

            // when there is no invoice available
            if(!data.invoice) data.invoice = {};

            if(component.get('v.keepUserEnteredDateRange') === true){
                data.invoice.PeriodFrom__c = dateFrom;
                data.invoice.PeriodUntil__c = dateTo;
            }

            if(!data.invoice.PeriodFrom__c) data.invoice.PeriodFrom__c = dateFrom;
            if(!data.invoice.PeriodUntil__c) data.invoice.PeriodUntil__c = dateTo;

            if(!data.invoice.PeriodFrom__c || !data.invoice.PeriodUntil__c) {
                data.packages = null;
            }

            // if no dates at all, set defaults
            if((!dateFrom || !dateTo)
                && (!data.invoice.PeriodFrom__c && !data.invoice.PeriodUntil__c)){

                var lastMonth = moment().subtract(1, 'months'),
                    firstDayOfLastMonth = lastMonth.startOf('month').format('YYYY-MM-DD'),
                    lastDayOfLastMonth = lastMonth.endOf('month').format('YYYY-MM-DD');

                data.invoice.PeriodFrom__c = firstDayOfLastMonth;
                data.invoice.PeriodUntil__c = lastDayOfLastMonth;

            }

            // set invoice and finance dates
            if(!data.invoice.InvoiceDate__c) data.invoice.InvoiceDate__c = moment().format('YYYY-MM-DD');
            if(!data.invoice.FinanceDate__c) data.invoice.FinanceDate__c = data.invoice.PeriodUntil__c;

            /*
                restructure data for table

                INPUT:
                    - packages: [{}, {}, ..]
                    - leadingCC: [{}, {}, ..]
                    - receivingCC: [{}, {}, ..]

                OUTPUT:
                    - packages: [{pck: {}, ccs: []}, ..]
             */
            if(data.packages) {
                for (var i = 0; i < data.packages.length; i++) {

                    var pck = data.packages[i];
                    pck.costCentres = [];

                    // adding leading cost centre to the pck
                    var leadingCCPackage = data.leadingCC[i];
                    leadingCCPackage.isLeadingCC = true;
                    pck.costCentres.push(leadingCCPackage);

                    for (var ri = data.receivingCC.length - 1; ri >= 0; ri--) {
                        data.receivingCC[ri][i].isLeadingCC = false;
                        if(data.receivingCC[ri][i].position) data.receivingCC[ri][i].revenueNew = data.receivingCC[ri][i].position.ILVPositionAmount__c;
                        pck.costCentres.push(data.receivingCC[ri][i]);
                    }

                }

                /*
                we need to do this for the heading
                 */
                var costCentres = [];
                for (var i = 0; i < data.packages[0].costCentres.length; i++) {
                    var cc = data.packages[0].costCentres[i];
                    costCentres.push({
                        isLeadingCC: cc.isLeadingCC,
                        name: cc.name
                    });
                }

                component.set('v.costCentres', costCentres);
            }


            helper.calculateColumns(component, helper, data);

            $A.util.addClass(component.find('spinner'), 'hidden');
        });

        $A.enqueueAction(action);


    },

    calculateColumns: function(component, helper, data){

        if(data === undefined) data = helper.copy(component.get('v.data'));

        if (data.packages) {


            // do it
            data = helper.actuallyCalculateColumns(component, helper, data);

            // for groups
            data = helper.actuallyCalculateColumns(component, helper, data, true);

        }

        setTimeout(function() {

            if(data.totals){

                // format as currency before we save the total row
                for (var i = data.totals.length - 1; i >= 0; i--) {
                    // skip strings (they are percentages)
                    if(typeof data.totals[i] !== 'string') data.totals[i] = helper.formatAsCurrency(data.totals[i]);
                }

                // and add a little table break
                data.totals.splice(4, 0, 'table-break');

            }

            component.set('v.data', data);

        }, 1);

    },
    actuallyCalculateColumns: function(component, helper, data, runningThroughAgainForGroups){

        var totalsRow = [],
            numberFields = ['budget', 'services', 'invoice', 'billingRate', 'servicesDR', 'invoiceDR', 'billingDR'],
            ccNumberFields = ['services', 'revenue', 'revenueRate', 'servicesDR', 'revenueNew', 'revenueRateDR'];

        for (var i = data.packages.length - 1; i >= 0; i--) {

            var pck = data.packages[i];

            /*
                PACKAGE
                calculating billing rate (E4)
                billing rate = invoice total / services total
             */
            if(pck.services !== 0) pck.billingRate = Math.round((pck.invoice / pck.services) * 100);

            /*
                PACKAGE
                calculating billing rate date range (F3)
                billing rate DR = invoice DR total / services DR total
             */
            if(pck.servicesDR !== 0) pck.billingDR = Math.round((pck.invoiceDR / pck.servicesDR) * 100);

            /*
                LEADING COST CENTRE
                calculating REVENUE TOTAL w/o DRAFT
                revenueLeadingCC = pck.invoice - (revenue of every receiving CC)
                continuing calculating in the loop where leading = false
                    and then adding it after
             */
            var revenueLeadingCC = pck.invoice;

            /*
                LEADING COST CENTRE
                calculating REVENUE NEW
                revenueNewLeadingCC = pck.invoiceDR - (revenueNew of every receiving CC)
                continuing calculating in the loop where leading = false
                    and then adding it after
             */
            var revenueNewLeadingCC = pck.invoiceDR;

            // calculating stuff in the cost centres
            for (var cci = pck.costCentres.length - 1; cci >= 0; cci--) {

                var cc = pck.costCentres[cci],
                    intRevenueNew = (Math.ceil(helper.giveMeANumberOrGiveMeZero(cc.revenueNew)*20)/20);

                // setting the rounding off of cents back
                cc.revenueNew = intRevenueNew;

                // continuing calculating leading CC REVENUE TOTAL w/o DRAFT
                if(cc.isLeadingCC !== true) revenueLeadingCC = revenueLeadingCC - cc.revenue;

                // continuing calculating leading CC REVENUE NEW
                if(cc.isLeadingCC !== true) revenueNewLeadingCC = revenueNewLeadingCC - intRevenueNew;

                /*
                    calculating revenue rate (G3)
                    revenue rate = revenue / services
                 */
                if(cc.services !== 0) cc.revenueRate = Math.round((cc.revenue / cc.services) * 100);

                /*
                    calculating revenue rate DR (G3)
                    revenue rate = revenueNew / services DR
                 */
                if(cc.servicesDR !== 0) cc.revenueRateDR = Math.round((intRevenueNew / cc.servicesDR) * 100);

                /*
                    GROUP SUMS
                 */
                if(pck.pck.PackageType__c === 'Group'){

                    // starting sum with 0
                    cc.revenueNew = 0;

                    for (var x = data.packages.length - 1; x >= 0; x--) {

                        var childPackage = data.packages[x];

                        // checking if childpackage
                        if(pck.pck.Id === childPackage.pck.PackageSuperior__c){

                            var childCC = childPackage.costCentres[cci];

                            // grouping revenueNew
                            cc.revenueNew = cc.revenueNew + helper.giveMeANumberOrGiveMeZero(childCC.revenueNew);

                        }

                    }

                }

            }

            /*
                wrapping up a few leading CC calculations
             */
            // setting REVENUE TOTAL w/o DRAFT
            pck.costCentres[0].revenue = revenueLeadingCC;

            // setting REVENUE NEW
            pck.costCentres[0].revenueNew = revenueNewLeadingCC;

            // group sum again for leading cc
            if(pck.pck.PackageType__c === 'Group'){

                // starting sum with 0
                pck.costCentres[0].revenueNew = 0;

                for (var x = data.packages.length - 1; x >= 0; x--) {

                    var childPackage = data.packages[x];

                    // checking if childpackage
                    if(pck.pck.Id === childPackage.pck.PackageSuperior__c){

                        // summing revenueNew
                        pck.costCentres[0].revenueNew = pck.costCentres[0].revenueNew + helper.giveMeANumberOrGiveMeZero(childPackage.costCentres[0].revenueNew);

                    }

                }

            }

            // recalculating revenueRateDR
            if(pck.costCentres[0].servicesDR !== 0) pck.costCentres[0].revenueRateDR = Math.round((pck.costCentres[0].revenueNew / pck.costCentres[0].servicesDR) * 100);

            /*
                Totals row
                only calcuate when not group and after calculations done and only on second run
             */
            if(runningThroughAgainForGroups && pck.pck.PackageType__c !== 'Group'){

                var fieldIndex;
                for (fieldIndex = 0; fieldIndex < numberFields.length; fieldIndex++) {

                    var valueToAdd = helper.giveMeANumberOrGiveMeZero(helper.getPropByString(pck, numberFields[fieldIndex]));

                    if(numberFields[fieldIndex] === 'billingRate'
                    || numberFields[fieldIndex] === 'billingDR') {

                        // fingers crossing.
                        valueToAdd = 0;
                        if(totalsRow[fieldIndex - 2] !== 0) valueToAdd = Math.round((totalsRow[fieldIndex - 1] / totalsRow[fieldIndex - 2]) * 100);

                        valueToAdd = valueToAdd + '%';

                        totalsRow[fieldIndex] = valueToAdd;

                    }
                    else {
                        if(totalsRow[fieldIndex] === undefined){
                            totalsRow.push(valueToAdd);
                        }
                        else {
                            totalsRow[fieldIndex] = totalsRow[fieldIndex] + valueToAdd;
                        }
                    }

                }

                // going through the cost centres
                for (var ci = 0; ci < pck.costCentres.length; ci++) {

                    if(totalsRow[fieldIndex] === undefined){
                        totalsRow.push('table-break');
                    }

                    fieldIndex++;

                    var cc = pck.costCentres[ci],
                        ccIndex;

                    for (ccIndex = 0; ccIndex < ccNumberFields.length; ccIndex++) {

                        var valueToAdd = helper.giveMeANumberOrGiveMeZero(helper.getPropByString(cc, ccNumberFields[ccIndex])),
                            indexInTotalsRow = fieldIndex + ccIndex;


                        if(ccNumberFields[ccIndex] === 'billingRate'
                            || ccNumberFields[ccIndex] === 'revenueRate'
                            || ccNumberFields[ccIndex] === 'revenueRateDR') {

                            // fingers crossing.
                            valueToAdd = 0;
                            if(totalsRow[indexInTotalsRow - 2] !== 0) valueToAdd = Math.round((totalsRow[indexInTotalsRow - 1] / totalsRow[indexInTotalsRow - 2]) * 100);

                            valueToAdd = valueToAdd + '%';

                            totalsRow[indexInTotalsRow] = valueToAdd;

                        }
                        else {

                            if(totalsRow[indexInTotalsRow] === undefined){
                                totalsRow.push(valueToAdd);
                            }
                            else {
                                totalsRow[indexInTotalsRow] = totalsRow[indexInTotalsRow] + valueToAdd;
                            }

                        }

                    }

                    fieldIndex = fieldIndex + ccIndex;

                }

            }

        }

        // format as currency!
        // we want to keep our numbers clean, but also format currencies in the table.
        // so we're creating new formatted fields to display
        for (var i = data.packages.length - 1; i >= 0; i--) {

            var pck = data.packages[i];
            pck.formatted = {};

            for (var y = numberFields.length - 1; y >= 0; y--) {
                var numberToBeFormatted = numberFields[y];
                pck.formatted[numberToBeFormatted] = helper.formatAsCurrency(Math.ceil(helper.giveMeANumberOrGiveMeZero(pck[numberToBeFormatted])*20)/20);
            }

            for (var cci = pck.costCentres.length - 1; cci >= 0; cci--) {

                var cc = pck.costCentres[cci];
                cc.formatted = {};

                for (var ccy = ccNumberFields.length - 1; ccy >= 0; ccy--) {
                    var numberToBeFormatted = ccNumberFields[ccy];
                    cc.formatted[numberToBeFormatted] = helper.formatAsCurrency(Math.ceil(helper.giveMeANumberOrGiveMeZero(cc[numberToBeFormatted])*20)/20);
                }

            }

        }

        data.totals = totalsRow;

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

    saveInvoice: function(component, helper){

        // clear any existing errors
        helper.clearErrors(component);

        $A.util.removeClass(component.find('spinner'), 'hidden');

        var data = helper.copy(component.get('v.data')),
            invoice = helper.copy(data.invoice),
            positions = [];

        invoice.sobjectType = 'Invoice__c';
        invoice.RecordTypeId = component.get('v.ILVRecordTypeId');
        invoice.ProjectName__c = data.project.Id;

        delete invoice.TermsOfPayment2__c;

        for(var i = data.packages.length - 1; i >= 0; i--) {

            var p = data.packages[i];

            if(p.pck.PackageType__c === 'Time' || p.pck.PackageType__c === 'Group'){

                for(var ci = p.costCentres.length - 1; ci >= 0; ci--) {

                    var cc = p.costCentres[ci];

                    if(!cc.isLeadingCC) {

                        var position = {
                            sobjectType: 'ILVPos__c',
                            InvoiceName__c: invoice.Id,
                            PackageName__c: p.pck.Id,
                            ILVPositionAmount__c: cc.revenueNew,
                            CostCenterILVReceiver__c: cc.ccId,
                            ILVType__c : p.pck.PackageType__c
                            
                        };

                        if(cc.position && cc.position.Id) position.Id = cc.position.Id;

                        positions.push(position);

                    }

                }

            }

        }

        var action = component.get('c.startQueueableJob'),
            params = {
                draft: invoice,
                positions: positions
            };

        action.setParams(params);

        action.setCallback(this, function(response) {
            console.log('---ILVTabHelper.saveInvoice--- response: ',response);

            if (response.getState() === 'ERROR') {
                console.log('---ILVTabHelper.saveInvoice--- Handing error');
				this.handleErrors(component, helper, response);
            } else if (response.getReturnValue() != null) {
                $A.util.removeClass(component.find('spinner'), 'hidden');
            	this.checkIsJobFinished(component, helper, response.getReturnValue());
            } else {
	            helper.loadData(component, helper);
	            component.set('v.showSuccessMessage', true);
            }

        });

        $A.enqueueAction(action);
    },

	checkIsJobFinished: function(component, helper, jobId) {
		var checkAction = component.get('c.checkIsJobFinished');
		console.log('Check...');
		checkAction.setParams({
			jobId: jobId
		});
		checkAction.setCallback(this, function (response) {

			if (response.getState() === 'ERROR') {
                console.log('Errors', response);
				this.handleErrors(component, helper, response);
			} else {
				if (!response.getReturnValue()) {
                    $A.util.removeClass(component.find('spinner'), 'hidden');
					setTimeout(function () {
						helper.checkIsJobFinished(component, helper, jobId);
					}, 4500);
				} else {
					helper.loadData(component, helper);
					component.set('v.showSuccessMessage', true);
				}
			}
		});
		$A.enqueueAction(checkAction);
	},

	handleErrors: function(component, helper, response) {

		var error = response.getError();

        console.info('---ILVTabHelper.handleErrors--- response: ', response);
        console.info('---ILVTabHelper.handleErrors--- error: ', error[0]);
		if (error[0] !== undefined) {

            // display Exception errors
            if (error[0].message !== undefined) {
                let errMsg = error[0].message;
                console.info('[BillingTabHelper]::[Save]::[errMsg]--->', errMsg);
                helper.addError(component, errMsg);
            }

			// display page errors
			if (error[0].pageErrors !== undefined && error[0].pageErrors.length > 0) {
				helper.addError(component, error[0].pageErrors[0].message);
			}

			// display any field errors
			if (error[0].fieldErrors !== undefined) {
				var fieldErrors = error[0].fieldErrors;

				for (var fieldError in fieldErrors) {
					if (fieldErrors.hasOwnProperty(fieldError)) {
						helper.addError(component, fieldErrors[fieldError][0].message);
					}
				}
			}
			// display other errors
			if (error[0].message !== undefined && error[0].stackTrace !== undefined) {
				helper.addError(component, error[0].message + ': ' + error[0].stackTrace);
			}

			// scroll to top
			window.scrollTo(0, 0);

			$A.util.addClass(component.find('spinner'), 'hidden');

		}
		else {
			helper.addError(component, $A.get('$Label.c.SkySomethingwentwrongandwewerenotabletosavetheinvoice') );
		}
	},

    /*
        Error handling!
     */
    addError: function(component, errorMessage) {
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
});