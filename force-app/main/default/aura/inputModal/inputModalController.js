({

	init: function(component, event, helper){
		console.log('init');
		helper.formatValue(component, helper);
	},

	closeModal: function(component, event, helper) {

		console.log('modal closed');

		// component.set('v.value', component.find('theFreakingRichTextField').get('v.value'));

		helper.formatValue(component, helper);
		component.set('v.open', false);

	},

	// manually updating the rich text field because its in beta
	// and such a cry baby and needs a lot of hand holding
	// and babysitting please someone help me im going crazy
	modalHasOpenedOrClosed: function(component, event, helper){
	// 	console.log('woa something is happenign');
	// 	if(component.get('v.open') === true){
	// 		console.log('open up the floodgates');
	// 		console.log('set value', component.get('v.value'));
	// 		component.find('theFreakingRichTextField').set('v.body', 'HELP!');
	// 	}
	}

})