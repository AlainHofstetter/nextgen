({

	init: function(component, event, helper){
		console.log('init');

		component.set('v.rows', ['thiese', 'are', 'rows']);

		dragula([document.getElementById('theTable')]).on('drop', function(){
			console.log('drop it like its hot', arguments);
		});

	},

	specialClickFunction: function(component, event, helper) {
		console.log('click', arguments, event.getName());
	}, 

	onMouseDown: function(component, event, helper){
		console.log('mouse down', arguments, event.target, event.getName());
	}

})