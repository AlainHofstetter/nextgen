({

    init : function(component, event, helper) {

        moment.locale($A.get('$Locale.language'));

        // defaults
        component.set('v.errors', []);
        component.set('v.totalsRow', []);

        // set the page title
        document.title = $A.get("$Label.c.SkyProjectBilling");

        // listen for a project id so we point them to the billing tab
        // again, because passing from app component is too slow
        var projectId = null,
            magicURLmatches = window.location.href.match(/\?c__projectId=(.+)&c__tab=(.+)/);

        if(magicURLmatches.length === 3) {
            component.set('v.projectId', magicURLmatches[1]);
        }

        /*
            Fixing headers and stuff
        */

        var lastFixed = false,
            scrollTop = 322,
            standardLeftOffset = 30;


        if(window.location.href.indexOf('skywalk--') > 0) scrollTop = scrollTop + 43;

        window.onscroll = function(){

            var fixedHeaderOptions = {
                fixed: false,
                offsetLeft: 0
            };

            if(window.scrollY > scrollTop) fixedHeaderOptions.fixed = true;

            if(lastFixed !== fixedHeaderOptions.fixed){
                fixedHeaderOptions.fixed = fixedHeaderOptions.fixed;
                lastFixed = fixedHeaderOptions.fixed;
            }

            if(fixedHeaderOptions.fixed && window.scrollX > 0){
                fixedHeaderOptions.offsetLeft = 'left: ' + (standardLeftOffset - window.scrollX) + 'px;';
            }

            component.set('v.fixedHeaderOptions', fixedHeaderOptions);

        };

        // loading initial data
        helper.loadData(component, helper, true);

    },

    onModalEditOpenClick: function(component, event, helper){
        var field = event.getSource().getLocalId().replace('buttonFor', '');
        component.find('modalFor' + field).set('v.open', true);
    },

    onInvoiceProgressFocus: function(component, event, helper){
        var value = helper.giveMeANumberOrGiveMeZero(event.getSource().get('v.value'));
        if(value === 0) event.getSource().set('v.value', '');
    },

    onInvoiceInProgressUpdated: function(component, event, helper){
        // just wait till the user calm down.
        // you know, life is too stressful if you keep pressing it ¯\_(ツ)_/¯
        clearTimeout(helper.typingTimeout);

        helper.typingTimeout = setTimeout(function() {
            helper.calculateColumns(component, helper);
        }, 666); // 👿
    },

    // when we have an empty string, show a pretty zero
    onInvoiceInProgressBlurred: function(component, event, helper){
        var value = helper.giveMeANumberOrGiveMeZero(event.getSource().get('v.value'));
        if(value === 0) event.getSource().set('v.value', value);
    },

    onLoadPackagesClick: function(component, event, helper) {
        helper.loadData(component, helper, true);
    },

    onDateRangeBlurred: function(component, event, helper){

        var data = component.get('v.data');

        if(data !== null){
            component.set('v.keepUserEnteredDateRange', true);
        }

    },

    dataButtonWasPressed: function(component, event, helper){
        var params = event.getParams();
        
        if(params.name == 'showModalForBillingPositionText' || params.name == 'closeModalForBillingPositionText'){

            var index = params.data,
                data = component.get('v.data'),
                packageToUpdate = data.packages[index];

            if(params.name == 'showModalForBillingPositionText'){
                packageToUpdate.showModalForBillingPositionText = true;
            }

            if(params.name == 'closeModalForBillingPositionText'){
                packageToUpdate.showModalForBillingPositionText = false;
                if(packageToUpdate.packageBillingPositionText) packageToUpdate.formattedPackageBillingPositionText = packageToUpdate.packageBillingPositionText.replace(/<(?:.|\n)*?>/gm, '');
            }

            component.set('v.data', data);

        }

    },

    onPreviewInvoiceClick: function(component, event, helper){

        var data = component.get('v.data'),
            packagesForPreview = [];

        for (var i = 0; i < data.packages.length; i++) {
            var p = data.packages[i];
            if(p.showPosition) packagesForPreview.push(p);
        }

        component.set('v.packagesForPreview', packagesForPreview);
        component.set('v.showInvoicePreview', true);

    },

    onInvoicePreviewDoneClick: function(component, event, helper){
        component.set('v.showInvoicePreview', false);
    },

    onUpdateInvoiceClick: function(component, event, helper){
        helper.saveInvoice(component, helper);
    },

    // because disabled checkboxes look a bit faded
    dontMakeThisCheckboxActuallyWork: function(component, event, helper){
        event.getSource().set('v.value', !event.getSource().get('v.value'));
    }

})