var $SIMDIV = "<div id='SIMDiv'><div style='text-align:right'><a href=\"#\" onclick='document.getElementById(\"SIMDiv\").style.display=\"none\"'><img src='~SIMURL~/img/images/close.png' width='36' height='36' border='0' alt='X' /></a></div><div id='SIMDivContent' style='border-radius:5px; border:1px solid #ccc; box-shadow: 0 0 5px #888; background-color:#fff; padding:10px; margin-top:-19px; margin-right:15px; font-family:Arial,Helvetica,sans-serif; font-size:75%;'>~CONTENT~</div></div>";
var simUrl;

$(function() {
	if (window.addEventListener) //DOM method for binding an event
		window.addEventListener('message', SIMReceiver, false);
	else if (window.attachEvent) //IE exclusive method for binding an event
		window.attachEvent('onmessage', SIMReceiver);
	else if (document.getElementById) //support older modern browsers
		window.onload = SIMReceiver;
});

function SIMReceiver(event) {
    if (simUrl.indexOf(event.origin) != -1) {
        if (event.data.substr(0, 14) == 'ShowSIMContent') {
            var $content = event.data.substr(event.data.indexOf("SIMContent=") + 11);
            showSimContent($content);
        }
        else if (event.data.substr(0, 12) == 'resizeIframe') {
			var $data = event.data.substr(event.data.indexOf('|')+1);
			var $sizes = $data.split('&');
			if($sizes.length == 2 && $sizes[0].substr(0,7)=="height=" && $sizes[1].substr(0,6)=="width=") {
				var $height = $sizes[0].replace("height=", "");
				var $width  = $sizes[1].replace("width=", "");
				resize360Frame($width, $height);
			}
        }
    }
}

function resize360Frame(width, height) {
    j$("#ContactFrame").attr("height", height+"px");
}

function showSimContent(content) {
    var $simDiv = j$("#SIMDiv");
    if ($simDiv.length > 0) {
        var $SIMDivContent = $simDiv.children("#SIMDivContent");
        $simDiv.css("display", "none");
        $SIMDivContent.html(content);
    } else {
        j$("body").append($SIMDIV.replace("~CONTENT~", content).replace("~SIMURL~", simUrl));
        $simDiv = j$("#SIMDiv");
    }
    $simDiv.center().fadeIn("slow");
}

jQuery.fn.center = function () {
    this.css("position", "absolute");
    this.css("top", (j$(window).height() - this.height()) / 2 + j$(window).scrollTop() + "px");
    this.css("left", (j$(window).width() - this.width()) / 2 + j$(window).scrollLeft() + "px");
    return this;
}