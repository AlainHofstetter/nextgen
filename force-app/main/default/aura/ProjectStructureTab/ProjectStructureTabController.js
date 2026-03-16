({

    init : function(component, event, helper) {

        console.log('init');

        // defaults
        component.set('v.errors', []);

        /*
            Fixing headers and stuff
        */
        var lastFixed = false;
        window.onscroll = function(){

            var fixed = false;
            if(window.scrollY > 288) fixed = true;

            if(lastFixed !== fixed){
                console.log('setting fixed', fixed);
                component.set('v.fixedHeader', fixed);
                lastFixed = fixed;
            }

        };

        // set the page title
        document.title = "Project Structure";

        var action = component.get('c.getPicklists');

        action.setCallback(this, function(response){

            var response = response.getReturnValue();

            console.log('response', response);

            component.set('v.picklistValues', response);

            $A.util.addClass(component.find('spinner'), 'hidden');

        });

        $A.enqueueAction(action);

        // again, because passing from app component is too slow
        var projectId = null,
            magicURLmatches = window.location.href.match(/\?c__projectId=(.+)&c__tab=(.+)/);

        if(magicURLmatches.length === 3) {
            component.set('v.projectId', magicURLmatches[1]);
        }

        // loading initial data
        helper.loadData(component, helper);

    },

    onSaveButtonClick: function(component, event, helper){
        helper.save(component, helper);
    },

    onBudgetBlurred: function(component, event, helper){

        // when we have an empty string, show a pretty zero
        var value = helper.giveMeANumberOrGiveMeZero(event.getSource().get('v.value'));
        if(value === 0) event.getSource().set('v.value', value);

        // loop through packages
        var data = helper.copy(component.get('v.data'));

        // set totals
        helper.setGroupTotals(component, data, helper);

    },

    dataButtonWasPressed: function(component, event, helper){

        console.log('dataButtonWasPressed');

        var data = event.getParam('data'),
            name = event.getParam('name');

        if(name === 'deletePackage'){
            if(confirm( $A.get('$Label.c.SkyAreyousureyouwanttodeletethispackage') )){
                helper.save(component, helper, function(){
                    helper.delete(component, helper, data);
                });
            }
        }

    },

    // because disabled checkboxes look a bit faded
    dontMakeThisCheckboxActuallyWork: function(component, event, helper){
        event.getSource().set('v.value', !event.getSource().get('v.value'));
    }

})