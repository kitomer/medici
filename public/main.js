
var queryinfo = {};

function $( sel )
{
	return document.querySelector( sel );
}

/*
 *		info: {
 *      "query" => "..."       # OPTIONAL!
 *      "mode" => "summary|detail|delete|delete-confirm|edit|save|..." # default mode
 *      "summary|detail|delete|delete-confirm|edit|save|..." => [ ids... ],  # optional, default is "view" all in the result set
 *      "page" => ... # page = -1 means all (but internal limit applies!)
 * 		}
 */
function query( info )
{
	var query = info.query || "";
	var page = parseInt(info.page) || -1; // -1 means all
	    page = ( page >= 0 ? page : -1 );
	var mode = info.mode || "view"; // default mode
	// modes for specific ids
	var summary = info.summary || "";
	var detail = info.detail || [];
	var delete_confirm = info.delete_confirm || [];
	var delete_do = info.delete_do || [];
	var edit = info.edit || [];
	var edit_save = info.edit_save || [];
	
	postdata = JSON.stringify({
		"query": query,
		"page": page,
		"mode": mode,
		"summary": summary,
		"detail": detail,
		"delete_confirm": delete_confirm,
		"delete_do": delete_do,
		"edit": edit,
		"edit_save": edit_save
	});
	
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.onreadystatechange =
		function() {
			if (this.readyState == 4 && this.status == 200) {
				var result = JSON.parse(this.responseText);
				// ...
				console.log(result);
			}
		};
	xmlhttp.open('POST', '/');
	console.log("sending ajax request");
	xmlhttp.send(postdata);
}

function toggleMenu()
{
	if( $('#left').style.display != 'none' ) {
		$('#left').style.display = 'none';
		$('#center').style.marginLeft = '0';
		$('#center').style.paddingLeft = '30pt';
	}
	else {
		$('#left').style.display = 'block';
		$('#center').style.marginLeft = '200pt';
		$('#center').style.paddingLeft = '20pt';
	}
}

function showCenter( n )
{
	$('.center-1').style.display = "none";
	$('.center-2').style.display = "none";
	switch( n ) {
		case 1: $('.center-1').style.display = "block"; break;
		case 2: $('.center-2').style.display = "block"; break;
	}
}
