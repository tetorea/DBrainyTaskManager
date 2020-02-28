module Constraint;

import State;
import Utils;

import std.variant;

// classe pour representer les pre-conditions et pre-requis
// La contrainte est générique, la classe doit être dérivée pour ecrire le corps des 2 fonctions, pour chaque contrainte spécifique
class Constraint {
    ulong id;
    string code = "";
    string description = ""; // expression de la contrainte. A remplir soi-meme, ce sera juste pour debug! ex : "temperature < 40 AND camera = true"
    string[] codeTestedStates; // the list of codes corresponding to the States linked to the constraint = They will be tested in the function WaitingStates

	this(
			ulong id = 0,
			string code = "",
			string description = "",
			string[] codeTestedStates = []
		 ){
			this.id = id;
			this.code = code;
			this.description = description;
			this.codeTestedStates = codeTestedStates;
	}

    // function pointer to initialize
    // arguments :
    // - the list of the system current states
    // - the list of states needing to be modified
    // output :
    // - true if some states need to be modified to satisfy the constraint
    bool function( ref string[] codeTestedStates, 
				   ref GenericState[string] systemStates, 
				   ref GenericState[string] statesNeedingModifications ) 
		WaitingStates = null;
}


// examples of WaitingStates functions :

/// returns true if some elements are not in the good state
static bool WaitingBooleanState( ref string[] codeTestedStates, 
						  ref GenericState[string] systemStates, 
						  ref GenericState[string] statesNeedingModifications )
{
	ulong stateToWait = codeTestedStates.length;

	foreach( cts; codeTestedStates ){
		if( (cts in systemStates) is null ) {
			log.warn( "State "~ cts ~" is not in the system list of States!");
			return false;
		}
		if( systemStates[cts].testValue!bool( Variant(true) ) ) return false;

		statesNeedingModifications[cts] = systemStates[cts];
		if( --stateToWait == 0 ) return true;
	}

	return false;
}



