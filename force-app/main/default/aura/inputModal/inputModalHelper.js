({
	formatValue: function(component, helper) {
		var value = component.get('v.value');
		console.log('formatting', value);
		if(value) component.set('v.formattedValue', value.replace(/<(?:.|\n)*?>/gm, ''));
	}
})