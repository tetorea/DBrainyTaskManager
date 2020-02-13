module Utils;

import std.variant;

ulong dimensions( Variant v ){
	if( !v.hasValue ) return 0;

	ulong dimensions = 0;
	try{
		dimensions = v.length;
	}catch( Exception e ) return 1;

	return dimensions;
}

auto typeBase( Variant v ){
	switch( v.dimensions ){
		case 0 :
		case 1 : return v.type;
		default : return v[0].type;
	}
}
