
function $( sel )
{
	return document.querySelector( sel );
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
