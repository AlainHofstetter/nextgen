({
    formatAsCurrency: function(number){

        number = number.toString();

        // make sure decimals are formatted correctly
        if(number.indexOf('.') > 0){

            var splittedNumber = number.split('.');

            // add 0 if we only have 1 decimal number
            if(splittedNumber[1].length === 1){
                splittedNumber[1] = splittedNumber[1] + '0';
            }

            // cut off if we have more then 2 decimal numbers
            if(splittedNumber[1].length > 2){
                splittedNumber[1] = splittedNumber[1].slice(0, 2);
            }

            number = splittedNumber.join('.');

        } else {
            number = number + '.00';
        }

        return number.replace(/(\d)(?=(\d{3})+(?!\d))/g, "$1'");

    }
})