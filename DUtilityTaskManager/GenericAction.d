module Action;

import State;
import Constraint;

import std.datetime.stopwatch : benchmark, StopWatch, AutoStart;
import core.time : Duration;
import std.conv;
import std.variant;


class GenericAction {
	// action identification
	ulong id;
	string code = "";
	string description = "";
	ulong priority = 100;			// used to favor some actions instead of others if all are available

	// For statistical purposes, managed by the system. ...will set them as private sometimes...
	ulong nbCalled = 0;				// how many times the action has been called
	ulong nbFailed = 0;				// how many times the action has been aborted before successful completion
	ulong nbOfCallToIgnore = 0;		// number of calls to this action that will be ignored. If the action has been called a number of times unsuccessfully, we can set this value so that the action will be ignore the next times it could be used.
	bool activated = true;			// action can be deactivated if it's never successful

	// statistics on time
	StopWatch stopWatch;					// started when the action begins, used to measure action time...
	long minExecTime = 0;
	long meanExecTime = 0;
	long maxExecTime = 0;
	double execTimeTotal = 0;

	// Parametres à remplir a l'initialisation de l'action
	Constraint preConditions;		// contraintes à résoudre avant d'activer l'action. Ces contraintes dépendent d'états dont le système a une influence sur les valeurs
	Constraint preRequisites;		// contraintes à résoudre avant d'activer l'action. Ces contraintes dépendent d'états sur lesquels on n'a pas d'influence. On doit juste attendre...
	int[] ressources;				// liste de tous les éléments qui sont utilisés pendant cette action. 2 actions ne peuvent pas etre executees en meme temps si elles utilisent la meme ressource!
	Variant[] optimalParameters;	// les parametres a passer éventuellement dans l'action, le programme devra essayer plusieurs valeurs pour chaque parametre afin de trouver une bonne solution!
	GenericState[] results;			// liste des états modifiés par cette action

	long maxWaitingTimeForPreConditions = 0;	// temps d'attente max pour que les preconditions soient remplies
	long maxWaitingTimeForPreRequisites = 0;	// temps d'attente max pour que les pre requis soient remplis
	long maxExecutionTimeBeforeAbort = 0;	// action est interrompue si depasse ce temps

	GenericState*[] statesPossiblyCausingErrors;	// tableau de pointeurs vers les etats du systeme qui pourraient expliquer pourquoi l'action ne peut pas aboutir
	GenericState*[] systemStateList;				// tableau de pointeurs vers les etats du systeme qui nous interessent pour cette action
	GenericState[] systemStateInitialList;			// tableau de copies des etats du systeme qui nous interessent pour cette action, au moment ou l'action est lancee

	bool keepHistory = true;
	bool interrupted = false;		// flag mis a vrai si l'action doit etre / a ete interrompue (attenteMaxAction atteint, action prioritaire doit prendre le dessus...)

	string errorLog = "";


	this(   ulong id = 0, 
			string code = "", 
			string description = "", 
			uint priority = 0, 
			int[] ressources = []
			 ) 
    { 
		this.id = id;
		this.code = code;
		this.description = description;
		this.priority = priority;
		this.ressources = ressources;
	}


	//// FUNCTIONS THAT NEED TO BE INITIALIZED

	// gives an estimate of the states modifications based on a parameter value
	// return true if we have a result for the given parameter, false otherwise
	// probably difficult to evaluate... will see if this is useful sometimes...
	//
	// - paramIndex : index in the array parameters of the value we consider
	// - paramVal : value of the parameter we want to test
	// - indiceEtatRes : indices of the states which are influenced by the parameter, in the array systemStateList
	// - modifiedState : the states modified by the parameter
	bool function( ulong paramIndex, 
				   double paramVal, 
				   ulong[] indiceEtatRes, 
				   GenericState[] modifiedState ) 
		parametersInfluenceOnState = null;

	//bool parametersInfluenceOnState( ulong paramIndex, double paramVal, ulong[] indiceEtatRes, GenericState[] modifiedState ){ 
	//    return false; 
	//}

	// compute the utility of this action given the current system state
	bool function() computeUtility = null;

	//double computeUtility()
	//{
	//    return 0.0;
	//}


	// put the actions to do once, at the start of the action
	// if the action cannot be started, return false
	bool function() executionInit = null;
	//bool executionInit(){
	//    return true;
	//}

	// execute the action core commands 
	// If possible, the action is completed by executing this function several times
	// must return FALSE if the task is not finished
	// must return TRUE if the task has ended correctly
	bool function() executionTick = null;
	//bool executionTick()
	//{
	//    return false;
	//}

	//// ...FUNCTIONS THAT NEED TO BE INITIALIZED

	//// FONCTION POUVANT ETRE APPELEE
	bool abort()
	{
		interrupted = true;
		return true;
	}


	////////////////////////////////////////////////////// SYSTEM FUNCTIONS
	// to set private sometime...

	void actionFinished( bool goodEnding = true ){
		if( stopWatch.running && goodEnding ){
			Duration actionActivationTime = stopWatch.peek();
			stopWatch.stop();
			long actionActivationTimeMs = actionActivationTime.total!"msecs";

			// statistics...
			execTimeTotal += to!double(actionActivationTimeMs);
			meanExecTime = to!long( execTimeTotal / nbCalled );
			if( minExecTime == 0 || minExecTime > actionActivationTimeMs ) minExecTime = actionActivationTimeMs;
			if( maxExecTime == 0 || maxExecTime < actionActivationTimeMs ) maxExecTime = actionActivationTimeMs;
		}

		if( !goodEnding ){
			nbFailed++;
		}

		// sauvegarde de l'execution a la fin de l'action
		if( !keepHistory ) return;

		// sauvegarde le temps d'execution, le statut, ...
		// ...
	}


	// the system call this function when the conditions are met !!
	bool startExecution(){
		if( !activated ) return false;

		if( nbOfCallToIgnore > 0 ){
			nbOfCallToIgnore--;
			return false;
		}

		nbCalled++;
		stopWatch = StopWatch( AutoStart.yes );

		if( executionInit() ) return true;

		nbFailed++;
		actionFinished( false );
		return false;
	}

	// la fonction execution doit etre appelee regulierement par le systeme jusqu'à ce qu'elle renvoie false
	bool execution(){
		double temps = 0;
		long actionRunningTime = stopWatch.peek().total!"msecs";
		if( maxExecutionTimeBeforeAbort > 0 && actionRunningTime > maxExecutionTimeBeforeAbort ) interrupted = true;

		if( interrupted ){
			actionFinished( false );
			return false;
		}

		if( ! executionTick() ){
			// renvoie false si l'action n'est pas finie
			return true;
		}


		actionFinished( true );
		return false;	// action finie!
	}


	string save(){ return ""; }

	bool load( string actionJson ){ return true; }	// initialise les parametres de l'action en fonction de la chaine de caractere passee en entree


}



/*
Action:
- pré-conditions : liste d'états nécessaires avant de pouvoir réaliser l'action (ET, OU)
Ex: ( vitesse < 10 ET visage détecté dans les 10 dernières images ) OU etatRobot = SLEEP
- pré-requis : états nécessaires pour réaliser l'action mais ces états ne sont pas modifiables directement par le système ( température, heure, date ,...)
- temps d'attente max pré-requis (temps d'attente possible pour faire en sorte que les pré-conditions soient remplies
- paramètres de l'action
- temps d'action min (pour donner une indication du temps nécessaire pour tout le traitement, par exemple..)
- temps d'action moyen (pareil qu'au dessus)
- temps d'action max avant d'abandonner
- résultats : liste des états modifiés
- sauvegarde des exécutions précédentes de cette action avec le résultat obtenu en fonction du contexte (...pour statistiques + apprentissage par renforcement)
*/