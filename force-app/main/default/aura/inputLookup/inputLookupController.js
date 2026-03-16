({

    init: function(component, event, helper) {

        // sometimes we directly init with values
        var value = component.get('v.value');
        if(value !== null && value !== undefined){
            helper.renderSelected(component);
        }

        Ps.initialize(component.find('scrollableFilterResultsDropdown').getElement());

    },

    filter: function(component, event, helper) {

        var keyCodes = {
                40: 'ARROW_DOWN',
                38: 'ARROW_UP',
                13: 'ENTER',
                8: 'BACKSPACE',
            },
            supportDownArrowBehaviour = component.get('v.supportDownArrowBehaviour'),
            currentValue = component.get('v.value'),
            // get results so we can update and check stuff
            results = helper.copy(component.get('v.results'));

        console.log('going', supportDownArrowBehaviour);

        // if the key pressed was one we support for keyboard controlled magic
        // except, if its down arrow with no results found, we want to request for an unfiltered list to show

        if(keyCodes[event.getParams().keyCode] !== undefined 
        && !(keyCodes[event.getParams().keyCode] === 'ARROW_DOWN' && results.length === 0)){

            console.log('doing keycode stuff');

            // the index keeps track what element we've selected
            var currentlySelectedIndex = component.get('v.keyboardResultCurrentlySelected');

            // if we pressed enter and we got an element selected
            if(keyCodes[event.getParams().keyCode] === 'ENTER'
            && currentlySelectedIndex > -1) {

                // select the item
                helper.select(component, helper, results[currentlySelectedIndex]);

                // reset stuff
                results[currentlySelectedIndex].selected = false;
                currentlySelectedIndex = -1;

            }

            if(keyCodes[event.getParams().keyCode] === 'BACKSPACE'
            && currentValue === null){
                $A.util.addClass(component.find('filterResultsDropdown'), 'hidden');
            }

            if(keyCodes[event.getParams().keyCode] === 'BACKSPACE'
            && currentValue !== null){

                helper.deselect(component, helper);

            }
            else {

                var directionIsGoingBack = false;

                // update index based on arrow keys
                if(keyCodes[event.getParams().keyCode] === 'ARROW_UP'
                && currentlySelectedIndex !== -1){
                    currentlySelectedIndex--;
                    directionIsGoingBack = true;
                }

                if(keyCodes[event.getParams().keyCode] === 'ARROW_DOWN'
                && currentlySelectedIndex !== (results.length - 1)){
                    currentlySelectedIndex++;
                }

                // with our new index, update results
                for (var i = 0; i < results.length; i++) {
                    if(i === currentlySelectedIndex){
                        results[i].selected = true;
                    }
                    else {
                        results[i].selected = false;
                    }
                }

            }

            // update the component
            component.set('v.keyboardResultCurrentlySelected', currentlySelectedIndex);
            component.set('v.results', results);

            // set scrolltop
            if(directionIsGoingBack || currentlySelectedIndex > 5) {
                var scrollTopIndex = currentlySelectedIndex - 5;
                component.find('scrollableFilterResultsDropdown').getElement().scrollTop = 34 * scrollTopIndex;
            }

        }
        else {

            var query = component.find('searchField').get('v.value');

            if((query.length > 0 && currentValue === null)
            || (keyCodes[event.getParams().keyCode] === 'ARROW_DOWN' && results.length === 0 && supportDownArrowBehaviour === true)){

                helper.searchLookup(component, helper);

                $A.util.removeClass(component.find('filterResultsDropdown'), 'hidden');
                Ps.update(component.find('scrollableFilterResultsDropdown').getElement());

                component.find('scrollableFilterResultsDropdown').getElement().scrollTop = 0;
                component.set('v.keyboardResultCurrentlySelected', -1);


            }
            else {
                // on clearing search field
                $A.util.addClass(component.find('filterResultsDropdown'), 'hidden');
            }
        }

    },
    buttonClicked: function(component, event, helper) {
        component.set('v.data', event.getParam('data'));
        $A.enqueueAction(event.getParam('action'));
    },
    onResultItemClick: function(component, event, helper){

        var valueObject = component.get('v.data');
        helper.select(component, helper, valueObject);

    },

    onDeselectClick: function(component, event, helper){
        helper.deselect(component, helper);
    },

    onInputClick: function(component, event, helper){

        var results = component.get('v.results');

        if(results.length > 0){
            $A.util.addClass(component.find('filterResultsDropdown'), 'hidden');
            component.set('v.results', []);
        }

    },
    onInputBlur: function(component, event, helper){
        $A.util.addClass(component.find('no-results-message'), 'hidden');
    },

    onValueChange: function(component, event, helper){

        if(event.getParam('value') !== null){

            // sometimes only the value is set,
            // but we need to populate more
            if(component.get('v.valueLabel') === undefined){
                component.find('searchField').set('v.value', event.getParam('value'));
                helper.searchLookup(component, helper);
            }

            helper.renderSelected(component);
        }
        else {
            component.set('v.valueLabel', null);
            helper.renderNotSelected(component);
            component.set('v.results', []);
        }

    }

})