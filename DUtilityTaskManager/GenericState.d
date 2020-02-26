module State;

import Ressources;
import Utils;

import std.conv;
import std.json;
import std.stdio : writeln;
import std.variant;
import core.stdc.stdint;

/++ 
The variable inside a State can have different meaning, noted as Dimension : <BR>
  - VALUE : a single variable. For example: temperature, distance to a goal, speed, number of detected faces, camera ready, ...<BR>
  - INTERVAL : 2 variables delimiting an interval. For example : limit moving distances, speed limits, ...<BR>
  - SET : a list of variables. For example : pose, 3D velocity, charging points position, ...<BR>
  - MAX/MIN : a single variable indicating a threshold. For example : max temperature, starting time, ...<BR>
+/
enum StateDimension { NULL, VALUE, INTERVAL, SET, MIN, MAX }

/++
The influence of the system on the state is noted as either :<BR>
  - FULL_CONTROL : the system controls the state. For example : position, camera state, ...<BR>
  - PARTIAL_CONTROL : partly influenced by the system. For example : distance between the robot and another dynamic object in the environment, ...<BR>
  - AUTONOMOUS : completely independant from our control. For example : outside temperature, date, ...<BR>
+/
enum StateControl { NULL, FULL_CONTROL, PARTIAL_CONTROL, AUTONOMOUS }

/++
A State can have a priority from 0 (low priority) to MAX_PRIORITY (state to satisfy)
+/
const uint MAX_PRIORITY = UINT32_MAX;

/++
the basic State class used to store the value(s) of a specific State
+/
class GenericState {
	ulong id;
	string code;
	string name;
	StateDimension dim;
	StateControl control;
	uint priority;							// un etat de priorite 1 doit etre atteint après un état de priorité plus élevé
    SystemRessources[] ressources;		// the ressources linked to this state

	Variant value;
	ulong valueLength;

	// -----------------------------------
	this(   Variant val,
			ulong id = 0, 
			string code = "", 
			string name = "", 
			StateDimension dim = StateDimension.NULL, 
			StateControl control = StateControl.NULL, 
			uint priority = 0, 
			SystemRessources[] ressources = [SystemRessources.NULL]
		) 
    { 
		this.value = val;
		this.id = id;
		this.code = code;
		this.name = name;
		this.dim = dim;
		this.control = control;
		this.priority = priority;
		this.ressources = ressources;
		valueLength = dimensions( val );
	}

	bool singleValue() pure nothrow @safe { return valueLength == 1; }
	bool multipleValue() pure nothrow @safe { return valueLength > 1; }

	bool testValue(T)( const Variant testValue ) {
		if( value.typeBase != testValue.typeBase ) { log.error( "GenericState.testValue ERR : value and testValue have different types"); return false; }

		switch( dim ){
			case StateDimension.NULL: return false;
			case StateDimension.VALUE: return value == testValue;

			case StateDimension.SET: 
				if( typeid(T) != value.typeBase ){ log.error( "GenericState.testValue ERR : value and T have different types"); return false; }
				foreach( v; value.get!(T[]) )
					if( v == testValue ) return true;
				return false;

			case StateDimension.INTERVAL: 
				if( value[0] > testValue || value[1] < testValue ) return false;
				return true;

			case StateDimension.MIN: return testValue > value;

			case StateDimension.MAX: return testValue < value;

			default: break;
		}
		return false;
	}


	// ----------------------------------------------

    bool setValue( Variant v ){ 
		if( v == null ) return false;
		value = v;
		valueLength = value.dimensions;
		return true; 
	}

	Variant getValue(){
		if( updateAutonomousValue !is null ) {
			if( !updateAutonomousValue() ) log.warn( "Error when updating the autonomous value : Value probably incorrect!" );
		}
		return value;
	}

	/++ Function pointer to retrieve the value of autonomous States <br>
	the function must be initialized by the user when the state is autonomous
	+/
	bool function() updateAutonomousValue = null;


	// -------------------------------------------
	// JSON functions to save and load the state 

	// T : base type (without [] if array)
	string save(T)(){ 
		if( typeid(T) != value.typeBase ){ 
			log.error( "GenericState.save ERR : value and T have different types"); 
			return "err";
		}
		if( valueLength < 1 ){ 
			log.error( "GenericState.save ERR : value not initialized"); 
			return "err";
		}

		JSONValue jv = [ "id": to!string(id) ];		// cannot read a ulong in json format so I have to use strings..

		try{
			jv.object["code"] = JSONValue( code );
			jv.object["name"] = JSONValue( name );
			jv.object["dim"] = JSONValue( dim );
			jv.object["control"] = JSONValue( control );
			jv.object["priority"] = JSONValue( priority );
			jv.object["ressources"] = JSONValue( ressources );
			if( valueLength > 1 ) 
				jv.object["value"] = JSONValue( value.get!(T[]) );
			else 
				jv.object["value"] = JSONValue( value.get!(T) );

		}catch( Exception e ){
			log.error( "GenericState.save ERR : "~ e.msg ); 
			return "";
		}


		return jv.toString; 
	}


	private T getJsonValue(T)( JSONValue j )
	{
		try{
			auto resstr = j.integer;
			writeln("value json : ", resstr );
			return resstr.to!T;
		}catch( Exception e ){
			//log.error("Exception : ", e.msg, " | not an integer?" );
		}
		try{
			auto resstr = j.uinteger;
			writeln("value json : ", resstr );
			return resstr.to!T;
		}catch( Exception e ){
			//log.error("Exception : ", e.msg, " | not an uinteger?" );
		}
		try{
			auto resstr = j.floating;
			writeln("value json : ", resstr );
			return resstr.to!T;
		}catch( Exception e ){
			//log.error("Exception : ", e.msg, " | not a float?" );
		}
		try{
			auto resstr = j.str;
			writeln("value json : ", resstr );
			return resstr.to!T;
		}catch( Exception e ){
			//log.error("Exception : ", e.msg, " | not a string?" );
		}
		// cannot do the same for .object and .array, compile error with : resstr.to!T

		log.warn("Warning : Value type not found, cannot be initialized" );

		return T();
	}


	// T : base type (without [] if array)
	bool load(T)( string jsonState ){ 
		immutable j = parseJSON( jsonState );

		string strId = ("id" in j).str;
		if( strId == null ) return false;
		id = to!ulong( strId );

		code = ("code" in j).str;
		if( code == null ) return false;

		name = ("name" in j).str;
		if( name == null ) return false;

		dim = cast(StateDimension) ("dim" in j).integer;
		control = cast(StateControl) ("control" in j).integer;
		priority = cast(uint) ("priority" in j).integer;

		auto ress = ("ressources" in j).array;
		ressources.length = ress.length;
		foreach( i, r; ress.dup ) ressources[i] = cast(SystemRessources) r.integer;

		// get the value, based on its dimension and type
		try{
			if( dim == StateDimension.INTERVAL || dim == StateDimension.SET ) {
				auto vbb = ("value" in j).array;
				T[] tvalue;
				tvalue.length = vbb.length;
				foreach( i, b; vbb.dup ) tvalue[i] = getJsonValue!T( b );
				setValue( Variant( tvalue ) );

			}else{
				setValue( Variant( getJsonValue!T( j["value"] ) ) );
			}
		}catch( Exception e ){
			log.error( "GenericState.load ERR : "~ e.msg ); 
			return false;
		}
		return true; 
	}


	/++
	Example of GenericState use
	+/ 
	unittest
	{
		// fonction appellee juste avant main() si les unit test ont ete activés a la compilation avec le switch -unittest
		writeln( "Test State LONG - VALUE ..." );
		GenericState etatBatterie = new GenericState( Variant(4522), 1, "ETAT_BATT", "etatBatterie", StateDimension.VALUE, StateControl.FULL_CONTROL, 5, [SystemRessources.NULL] );
		assert( etatBatterie.getValue == Variant(4522) );

		string strJson = etatBatterie.save!long();
		writeln("etatBatterie1 : ", strJson );

		GenericState etatBatterie2 = new GenericState( Variant(0) );
		etatBatterie2.load!long( strJson );
		strJson = etatBatterie2.save!long();
		writeln("etatBatterie2 : ", strJson );


		writeln( "Test State DOUBLE[] - SET ..." );
		GenericState etatLongueur = new GenericState( Variant([ 3.14, 8841.412, -41.7771 ]), 2, "ETAT_LONG", "etatLongueur", StateDimension.SET, StateControl.PARTIAL_CONTROL, 10, [SystemRessources.ARM] );
		strJson = etatLongueur.save!double();
		writeln("etatLongueur : ", strJson );

		GenericState etatLongueur2 = new GenericState( Variant(0) );
		etatLongueur2.load!double( strJson );
		strJson = etatLongueur2.save!double();
		writeln("etatLongueur2 : ", strJson );		
	}
}


