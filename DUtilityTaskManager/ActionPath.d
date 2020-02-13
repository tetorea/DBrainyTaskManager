module ActionPath;

import Action;
import State;

import std.datetime.stopwatch : benchmark, StopWatch, AutoStart;
import core.time : Duration;

// une suite d'action effectuee pour passer d'un ensemble d'etats à un autre ensemble d'etats
class ActionPath{
	ulong id;
	string name = "";
	string description = "";
	ulong priority = 100;			// used to favor some actions instead of others if all are available

	// statistics on time
	StopWatch stopWatch;					// started when the actionPath begins, used to measure actionPath time...
	long minExecTime = 0;
	long meanExecTime = 0;
	long maxExecTime = 0;
	double execTimeTotal = 0;

	long maxExecutionTimeBeforeAbort = 0;	// actionPath est interrompue si depasse ce temps

	// For statistical purposes, managed by the system. ...will set them as private sometimes...
	ulong nbCalled = 0;				// how many times the actionPath has been called
	ulong nbFailed = 0;				// how many times the actionPath has been aborted before successful completion
	ulong nbOfCallToIgnore = 0;		// number of calls to this actionPath that will be ignored. If the actionPath has been called a number of times unsuccessfully, we can set this value so that the actionPath will be ignored the next times it could be used.
	bool activated = true;			// actionPath can be deactivated if it's never successful

	GenericState[] startStates;		// les etats de depart
	GenericState[] endStates;		// les etats obtenus apres les actions
	GenericAction[] actionList;		// liste des actions effectuees, dans l'ordre!
}