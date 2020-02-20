module Constraint;

import State;
import Utils;
import Ressources;

import std.variant;

// classe pour representer les pre-conditions et pre-requis
// La contrainte est générique, la classe doit être dérivée pour ecrire le corps des 2 fonctions, pour chaque contrainte spécifique
class Constraint {
    ulong id;
    string name = "";
    string expression = ""; // expression de la contrainte. A remplir soi-meme, ce sera juste pour debug! ex : "temperature < 40 AND camera = true"
    ulong[] idTestedStates; // la liste des ID des etats qui seront testés dans la fonction contrainteVerifiee

	this(
			ulong id = 0,
			string name = "",
			string expression = "",
			ulong[] idTestedStates = []
		 ){
			this.id = id;
			this.name = name;
			this.expression = expression;
			this.idTestedStates = idTestedStates;
	}

    // function pointer to initialize
    // arguments :
    // - the list of the system current states
    // - the list of states needing to be modified
    // output :
    // - true if some states need to be modified to satisfy the constraint
    bool function( const ref GenericState[] systemStates, ref GenericState[] statesNeedingModifications ) WaitingStates = null;
}


// examples of WaitingStates functions :

bool WaitingAtHomeState( ref GenericState[] systemStates, ref GenericState[] statesNeedingModifications )
{
	// return true if the state "At Home" is true
	foreach( ref GenericState s; systemStates ){
		if( s.name != State_AtHome ) continue;
		if( s.testValue!bool( Variant(true) ) ) return false;
		
		// state needs to be added to the waiting list, if not in already...

		foreach( ref GenericState snm; statesNeedingModifications ){
			if( snm.name == State_AtHome ) return true;
		}

		statesNeedingModifications ~= s;
		return true;
	}
	log.warn( State_AtHome ~" state is not in the system list!");
	return false;
}



