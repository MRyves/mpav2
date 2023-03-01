/**
* Name: Constants
* Author: Yves 
*/


model Constants

/**
 * This file defines all the constant values used in the simulation.
 * It may be imported to all the other files, as it does not import anything (no risk of circular-dependency).
 * All variables which are defined in this file should be considered as constants, thus never chaning values.
 */

global {
	// constant values used for the human mobility modes
	string MPAV <- "mpav" const: true;
	string WALKING <- "walking" const: true;
	string BUS <- "bus" const: true;
	string BIKE <- "bike" const: true;
	string CAR <- "car" const: true;
	string TRUCK <- "truck" const: true;
	
	// the two different types of goods
	string FOODS <- "foods" const: true;
	string PACKAGES <- "packages" const: true;
	
	// constant for transport status:
	// 0 = human is walking to the pick-up location (e.g. bus stop, building)
	// 1 = human arrived at pick-up location, waiting for pick up
	// 2 = transport (mpav / bus) arrived at stop closest to target, human walks from there
	int WALKING_PICK_UP <- 0 const: true;
	int WAITING_PICK_UP <- 1 const: true;
	int WALKING_TARGET <- 2 const: true;
	
	
	map<string,rgb> buildingColors <- [ "Hub"::rgb("#8A4B4B"), "Restaurant"::rgb("#536A8D"), "Night"::rgb("#4B493E"),"GP"::rgb("#4B493E"), "Cultural"::rgb("#4B493E"), "Shopping"::rgb("#4B493E"), "HS"::rgb("#4B493E"), "Uni"::rgb("#4B493E"), "O"::rgb("#4B493E"), "R"::rgb("#222222"), "Park"::rgb("#68805F"), "SAT"::rgb("#4B493E"), "stop"::rgb("#4B493E")] const: true;	
	map<string,rgb> peopleColors <- [ "High School Student"::rgb("#FFFFB2"), "College student"::rgb("#FECC5C"),"Young professional"::rgb("#FD8D3C"),  "Mid-career workers"::rgb("#F03B20"), "Executives"::rgb("#BD0026"), "Home maker"::rgb("#0B5038"), "Retirees"::rgb("#8CAB13")] const: true;
	list<string> mobilityList <- [WALKING, BIKE, CAR, BUS, MPAV, TRUCK] const: true;
	
}

