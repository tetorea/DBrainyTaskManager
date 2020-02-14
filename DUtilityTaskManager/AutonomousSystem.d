module AutonomousSystem;

import Action;
import ActionPath;
import Constraint;
import Ressources;
import State;
import Utils;

class AutonomousSystem{
	ulong id;
	string name = "";
	string description = "";

	// Must be initialized at the initialization of the system
	GenericState[] allPossibleStates;
	GenericAction[] allPossibleActions;
	Constraint[] allPossibleConstraints;

	// modified during the system life
	GenericState[] actualStates;
	GenericState[] goalStates;		// the states to reach, each goal has a priority : a state with a high priority must be reached before a lower priority
	SystemRessources[] systemRessourcesUsed;

	// automatic regulation system!
	// Some specific goals can be set when some system state values are reached (temperature, battery-level, date, recognized face, ...)
	// It means the system must check these values regularly, interrupt current action, add the new goals with high priority in the goalStates, ...
	GenericState[] goalActivatedByStateValue;


	////////////////////////////////////////////
	// Mecanisms for simulation
	GenericState[] tmpStates;			// = actualStates during the simulation
	SystemRessources[] tmpRessources;	// = ressources used during the simulation

	ActionPath[] possiblePaths;		// list of possible ActionPath to reach a specific set of states based from the current set of states
	ulong chosenPath = -1;			// index og chosen Path in the array above (= with biggest score below)
	double chosenPathScore = 0;		// meilleur score 


	// on ne peut pas faire de graph simple car a partir d'un etat, une action est possible ou non suivant les autres etats!!
	// on garde en memoire les suites d'actions calculées et la suite utilisee pour passer d'un ensemble d'etats à un autre ensemble!
	// .. pour augmenter la vitesse de calcul apres coup
	ActionPath[] pathsComputedBefore;


	///////////////////////////////////////////////////////
	// Functions


	this(){
		
	};

	bool addPossibleState( GenericState gs ){
		if( allPossibleStates == null ) {
			allPossibleStates ~= gs;
			return true;
		}

		// test if the state ID is already used by another state in the list
		foreach( GenericState g; allPossibleStates ) 
			if( g.id == gs.id ) { 
				log.warn("State ID already exist in the list"); 
				return false; 
			}

		allPossibleStates ~= gs;
		return true;
	}


	int computePossiblePaths(){
		if( allPossibleStates.length < 1 ) {
			log.info("No State in the system !");
			return 0;
		}
		if( allPossibleActions.length < 1 ) {
			log.info("No Action in the system !");
			return 0;
		}
		if( allPossibleConstraints.length < 1 ) {
			log.info("No Constraint in the system !");
			return 0;
		}
		if( actualStates.length < 1 ) {
			log.info("No actual state in the system !");
			return 0;
		}
		if( goalStates.length < 1 ) {
			log.info("No Goals in the system !");
			return 0;
		}

		return 0;
	};



	void tick(){
		// regulierement, le systeme :
		//  - teste les actions en cours (finies? en attente? execution trop longue, il faut agreger? ...)
		//  - regarde si des actions sont en attente d'etats specifiques et teste ces etats si oui
		//  - 
	}


	unittest{
		log = Log(stderrLogger, stdoutLogger(LogLevel.info), fileLogger("DUTM_log"));
		AutonomousSystem as;
		as.id = 0;
		as.name = "TESTSystem";
		as.description = "Description System";

		GenericState gs1 = new GenericState( Variant(0), 1, "moved Distance", StateDimension.VALUE, StateControl.FULL_CONTROL, 5, [SystemRessources.NULL] );

		addPossibleState( gs1 );
		assert( allPossibleStates.length == 1 );

		//GenericState[] allPossibleStates;
		//GenericAction[] allPossibleActions;
		//Constraint[] allPossibleConstraints;
	}
}

/*
Fonctions pour 
- calculer la meilleure trajectoire pour passer de l'etat courant a l'etat voulu
- vérifier les trajectoires passées pour voir celles utiles
- calculer la suite des actions possibles afin d'arriver aux etats voulus
- certaines actions ont des parametres, il faudrait aussi varier les parametres pour voir si on se rapproche du but
- l'exploration se fait suivant un temps limite donné + ou - grand
- si une trajectoire finie n'est pas trouvée au bout du temps imparti, on peut déjà lancer les actions de départ, on continue de calculer la trajectoire au fur et à mesure

- choisir l'etat voulu (= se choisir un objectif!)
- les taches doivent pouvoir être interrompue par d'autres taches paralleles
- on peut mettre en standby des taches avec des taches types Interruption / surprise
- 
*/