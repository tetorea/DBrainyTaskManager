module DUtilityTaskManager;

import std.conv;
import std.exception;
import std.json;
import std.stdio;
import std.variant;

import State;
import Ressources;


void main(string[] args) {
	float f = 3.5;
	string str = "dsfgsdgf";
	int[] iarr;

    writeln("type of f is ", typeid(f), "| is it float : ", (typeid(f) is typeid(float) ) );
    writeln("type of str is ", typeid(str), "| is it string : ", (typeid(str) is typeid(string) ) );
    writeln("type of iarr is ", typeid(iarr), "| is it array : ", (typeid(iarr) is typeid(int[]) ) );

	int b;
    writeln("b is null : ", b.stringof );


	// test State !!
	writeln( "Test State LONG - VALUE..." );
	GenericState etatBatterie = new GenericState( Variant(4522), 1, "etatBatterie", StateDimension.VALUE, StateControl.FULL_CONTROL, 5, [SystemRessources.CAMERA, SystemRessources.WHEEL] );
	string strJson = etatBatterie.save!int();
	writeln("etatBatterie1 : ", strJson );

	GenericState etatBatterie2 = new GenericState( Variant(0) );
	etatBatterie2.load!int( strJson );
	strJson = etatBatterie2.save!int();
	writeln("etatBatterie2 : ", strJson );


	// test State double[] !!
	GenericState etatLongueur = new GenericState( Variant([ 3.14, 8841.412, -41.7771 ]), 2, "etatLongueur", StateDimension.SET, StateControl.PARTIAL_CONTROL, 10, [SystemRessources.ARM] );

	strJson = etatLongueur.save!double();
	writeln("etatLongueur : ", strJson );

	GenericState etatLongueur2 = new GenericState( Variant(0) );
	etatLongueur2.load!double( strJson );
	strJson = etatLongueur2.save!double();
	writeln("etatLongueur2 : ", strJson );



	try{
		ulong idu = 71111888uL;
		JSONValue jv = [ "id": to!string(idu) ];
		jv.object["language"] = JSONValue( "C++" );
		jv.object["list"] = JSONValue( ["a","f","h"] );
		jv.object["listInt"] = JSONValue( [41,-177] );
		jv.object["flo"] = JSONValue( 3.144 );

		string js = jv.toString; //`{"language":"D","list":["a","b","c","D"],"rating":"3.5", "id":"142" }`;
		JSONValue j = parseJSON( js );

	} catch( Exception e ) {
	    writeln( e.msg ); // "error"
	    writeln( e.file ); // __FILE__
	    writeln( e.line ); // __LINE__ - 7
	}

    writeln("iarr is null : ", (iarr is null) );
	iarr = new int[4];
    writeln("iarr is null : ", (iarr is null) );

    writeln("Press enter...");
    readln();
}



/+

class Systeme{
ulong id;
string nom;

Etat[] listeEtats;						// tous les etats possibles du systeme
Action[] listeActions;					// toutes les actions possibles du systeme
Contrainte[] listeContraintes;			// toutes les contraintes possibles du systeme
RessourcesPhysiques[] listeRessources;	// les ressources du systeme

Etat[] etatsCourants;					// les etats actuels du systeme
Etat[] etatsVoulus;						// les etats a atteindre, chaque etat a une priorite : 1 -> but ultime, 2 -> but à faire avant 1, ...une tache de priorité élevée doit être faite avant les autres

// Etat[][] etatsVoulusProgrammes;		// prevoir des etats que l'on voudra atteindre a une certaine date/heure ?? dans ce cas, il faudra ajouter le timing voulu pour chaque ensemble


////////////////////////////////////////////
// Mecanismes pour la simulation
Etat[] etatsTmp;						// les etats utilises pendant la simulation
RessourcesPhysiques[] ressourcesTmp;	// l'etat des ressources pendant la simulation

Trajectoire[] trajectoiresPossibles;	// liste des trajectoires possibles pour atteindre un ensemble d'etats donné à partir de l'ensemble d'états courants
ulong trajectoireChoisie = -1;			// l'indice de la trajectoire choisie (= avec le plus grand score) dans les trajectoiresPossibles
double scoreTrajectoireChoisie = 0;		// meilleur score 


// on ne peut pas faire de graph simple car a partir d'un etat, une action est possible ou non suivant les autres etats!!
// on garde en memoire les suites d'actions calculées et la suite utilisee pour passer d'un ensemble d'etats à un autre ensemble!
// .. pour augmenter la vitesse de calcul apres coup
Trajectoire[] grandesActionsPassees;

void tick(){
// regulierement, le systeme :
//  - teste les actions en cours (finies? en attente? execution trop longue, il faut agreger? ...)
//  - regarde si des actions sont en attente d'etats specifiques et teste ces etats si oui
//  - 
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

class Coordinateur{
Systeme sysControle;		// le robot qu'on controle
Systeme sysExternes[];		// d'autres agents dynamiques similaires


}



+/

