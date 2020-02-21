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
	GenericState[string] allPossibleStates;
	GenericAction[string] allPossibleActions;
	Constraint[string] allPossibleConstraints;

	// modified during the system life
	GenericState[string] actualStates;
	GenericState[string] goalStates;		// the states to reach, each goal has a priority : a state with a high priority must be reached before a lower priority
	SystemRessources[string] systemRessourcesUsed;

	// automatic regulation system!
	// Some specific goals can be set when some system state values are reached (temperature, battery-level, date, recognized face, ...)
	// It means the system must check these values regularly, interrupt current action, add the new goals with high priority in the goalStates, ...
	GenericState[] goalActivatedByStateValue;


	////////////////////////////////////////////
	// Mecanisms for simulation
	GenericState[string] tmpStates;			// = actualStates during the simulation
	SystemRessources[string] tmpRessources;	// = ressources used during the simulation

	ActionPath[] possiblePaths;		// list of possible ActionPath to reach a specific set of states based from the current set of states
	ulong chosenPath = -1;			// index og chosen Path in the array above (= with biggest score below)
	double chosenPathScore = 0;		// meilleur score 


	// on ne peut pas faire de graph simple car a partir d'un etat, une action est possible ou non suivant les autres etats!!
	// on garde en memoire les suites d'actions calculées et la suite utilisee pour passer d'un ensemble d'etats à un autre ensemble!
	// .. pour augmenter la vitesse de calcul apres coup
	ActionPath[] pathsComputedBefore;


	///////////////////////////////////////////////////////
	// Functions


	this(
		 ulong id,
		 string name = "",
		 string description = ""
		 ){
		this.id = id;
		this.name = name;
		this.description = description;
	}

	bool addPossibleState( GenericState gs ){
		if( gs.code in allPossibleStates ){
			log.warn("State Code "~ gs.code ~" already exists in the list! Replacing the old one..."); 
		}
		allPossibleStates[gs.code] = gs;
		return true;
	}

	bool addPossibleAction( GenericAction ga ){
		if( ga.code in allPossibleActions ){
			log.warn("Action Code "~ ga.code ~" already exists in the list! Replacing the old one..."); 
		}
		allPossibleActions[ga.code] = ga;
		return true;
	}

	bool addPossibleConstraint( Constraint con ){
		if( con.code in allPossibleConstraints ){
			log.warn("Constraint Code "~ con.code ~" already exists in the list! Replacing the old one..."); 
		}
		allPossibleConstraints[con.code] = con;
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

		// ... 

		return 0;
	};



	void tick(){
		// regulierement, le systeme :
		//  - teste les actions en cours (finies? en attente? execution trop longue, il faut agreger? ...)
		//  - regarde si des actions sont en attente d'etats specifiques et teste ces etats si oui
		//  - 
	}

///
	unittest{
		log = Log( stderrLogger, stdoutLogger(LogLevel.info), fileLogger("DUTM_log") );
		AutonomousSystem as( 1, "TESTSystem", "Description System" );

		// adding States
		GenericState gs1 = new GenericState( Variant(0.0), 1, "MOVED_DIST", "moved Distance", StateDimension.VALUE, StateControl.FULL_CONTROL, 5, [SystemRessources.NULL] );
		addPossibleState( gs1 );
		assert( allPossibleStates.length == 1 );
		
		addPossibleState( gs1 );	// id is the same, so shouldn't be added!
		assert( allPossibleStates.length == 1 );

		addPossibleState( new GenericState( Variant(0), 2, "FACE_RECO", "Face Recognized", StateDimension.VALUE, StateControl.FULL_CONTROL, 0, [SystemRessources.CAMERA] ) );
		assert( allPossibleStates.length == 2 );

		addPossibleState( new GenericState( Variant(true), 3, "AT_HOME", "At Home", StateDimension.VALUE, StateControl.FULL_CONTROL, 20, [SystemRessources.NULL] ) );
		assert( allPossibleStates.length == 3 );

		addPossibleState( new GenericState( Variant(100), 4, "BATT_LEVEL", "Battery Level", StateDimension.VALUE, StateControl.AUTONOMOUS, 5, [SystemRessources.NULL] ) );
		assert( allPossibleStates.length == 4 );

		addPossibleState( new GenericState( Variant(0L), 5, "SYS_EXEC_TIME", "System Executing Time", StateDimension.VALUE, StateControl.AUTONOMOUS, 5 ) );
		assert( allPossibleStates.length == 5 );


		// adding Constraints
		addPossibleConstraint( new Constraint( 1, "AT_CHARGE_PLACE", "At charging place", "Robot is connected to its charger", ["AT_HOME"] ) );
		assert( allPossibleConstraints.length == 1 );
		allPossibleConstraints[$-1].WaitingStates = WaitingBooleanState;

		addPossibleConstraint( new Constraint( 2, "BATTERY>50", "Battery > 50%", "Robot battery level is more than 50%", ["BATT_LEVEL"] ) );
		assert( allPossibleConstraints.length == 2 );
		auto lambdaFunction = ( ref string[] codeTestedStates, ref GenericState[string] sysStates, ref GenericState[string] statesNeedModif ) { 
			return true; 
		};
		allPossibleConstraints[$-1].WaitingStates = lambdaFunction;


		// adding Actions
		GenericAction ga1 = new GenericAction( 1, "MOVE", "Motion", "action to move the robot toward a given 2D location", 10 );

		addPossibleAction( ga1 );


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