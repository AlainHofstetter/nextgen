({
    init : function(component, event, helper) {

        var recordId = component.get('v.recordId'),
            sObjectName = component.get('v.sObjectName');

        if(sObjectName === 'Package__c') {

            var get = component.get('c.getPackageInformation');

            get.setParams({
                packageId: component.get('v.recordId'),
            });

            get.setCallback(this, function(response) {

                var p = response.getReturnValue(),
                    subtab = p.PackageSubType__c;

                if(subtab === 'Manufaktur') subtab = 'WorkTime';

                helper.redirect(sObjectName, recordId, p.RecordType.Name.toLowerCase(), subtab);

            });

            $A.enqueueAction(get);

        }
        else {
            helper.redirect(sObjectName, recordId, 'time');
        }

    }
})