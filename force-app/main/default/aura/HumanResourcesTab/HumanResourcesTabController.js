({
  init: function(component, event, helper){

        moment.locale($A.get('$Locale.language'));

    console.log('init!');

    var lastMonth = moment().subtract(1, 'months'),
        firstDayOfLastMonth = lastMonth.startOf('month').format('YYYY-MM-DD'),
        lastDayOfLastMonth = lastMonth.endOf('month').format('YYYY-MM-DD');

    component.find('DateFrom').set('v.value', firstDayOfLastMonth);
    component.find('DateUntil').set('v.value', lastDayOfLastMonth);

    component.set('v.errors', []);
    component.set('v.showSuccessMessage', false);
    component.set('v.paginationIndex', 0);

  },

  onListTimeClick: function(component, event, helper){
    helper.listTime(component, helper);
  },

  onNextClick: function(component, event, helper){
    helper.paginate(component, helper, 'forward');
  },

  onPreviousClick: function(component, event, helper){
    helper.paginate(component, helper, 'backward');
  },

  onValidateTimeClick: function(component, event, helper){
    helper.validateTime(component, helper);
  },

  onLookupValueChange: function(component, event, helper) {

    var lookupType = event.getParam('lookupType'),
      valueObject = event.getParam('valueObject');

    // bubbling up!
    if(valueObject){

      // if lookup is user
      if(lookupType === 'User'){
        component.find('Account').set('v.value', valueObject.Account.Id);
        component.find('Account').set('v.valueLabel', valueObject.Account.Name);
      }

    }
    // we don't have a value object = the user deselected a lookup
    else {

      if(lookupType === 'Internal Account') {
        component.find('Timetracker').set('v.value', null);
        component.find('Timetracker').set('v.valueLabel', null);

        component.set('v.contactsToPaginateThrough', null);
        component.set('v.paginationIndex', 0);
      }

    }

  }
})