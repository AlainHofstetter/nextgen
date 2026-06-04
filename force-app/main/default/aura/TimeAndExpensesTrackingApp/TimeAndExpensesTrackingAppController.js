({

	init : function(component, event, helper) {

        // listen for a project id so we point them to the right tab
        var projectId = null,
            magicURLmatches = window.location.href.match(/\&c__tab=([a-zA-Z]+)/);

        if(magicURLmatches) {

            // demystifying
            var tab = magicURLmatches[1];

            if(tab === 'time'){
                console.log('open time');
                component.set('v.openTab', 'Time');
            }

            if(tab === 'expense'){
                console.log('open expense');
                component.set('v.openTab', 'Expense');
            }

            if(tab === 'billing'){
                console.log('open biling');
                component.set('v.showBillingTab', true);
                component.set('v.openTab', 'Billing');
            }

            if(tab === 'projectStructure'){
                console.log('open project structure');
                component.set('v.showProjectStructureTab', true);
                component.set('v.openTab', 'ProjectStructure');
            }

            if(tab === 'projectManager'){
                console.log('open ProjectManager');
                component.set('v.openTab', 'ProjectManager');
            }

            if(tab === 'ilv'){
                console.log('open ILV');
                component.set('v.showILVTab', true);
                component.set('v.openTab', 'ILV');
            }

        }

		// getting user info
		// so we can conditionally show HR + PM tabs
        var action = component.get('c.getInitialUserInfo');
        action.setCallback(this, function(response){

            var currentUser = response.getReturnValue();
            if(!currentUser) return;

            console.log('currentUser', currentUser);

            // move properties from the user object up
            for(var p in currentUser.User__r){
                if(p !== 'Id'){
                    currentUser[p] = currentUser.User__r[p];
                }
            }

            if(currentUser.IsProjectManager__c == true
            || currentUser.IsSuperUser__c == true
            || currentUser.IsManagingDirector__c == true
            || currentUser.IsFinanceManager__c == true){
            	component.set('v.showProjectManagerTab', true);
            }

            if(currentUser.IsHRManager__c == true
            || currentUser.IsFinanceManager__c == true){
            	component.set('v.showHumanResourcesTab', true);
            }

        });
        $A.enqueueAction(action);

	},

    onMovingAway: function(component, event, helper){
        var url = '' + window.location;
        window.location = url.replace(/\?(Package__c|Project__c)=(.+)&/g, '?');
    }

})