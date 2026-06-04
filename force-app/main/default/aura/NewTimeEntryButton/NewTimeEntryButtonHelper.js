({
	redirect : function(object, id, tab, subtab) {

		console.log('redirecting with', object, id, subtab, tab);

		var url = '/lightning/n/SkywalkApp?' + object + '=' + id + '&c__tab=' + tab;

		if(subtab && subtab !== 'None' && subtab !== 'Expense') url = url + '&c__subtab=' + subtab;

		console.log('url', url);

	    window.location.replace(url);

	}
})