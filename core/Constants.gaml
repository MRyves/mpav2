/**
* Name: Constants
* Based on the internal empty template. 
* Author: Yves
* Tags: 
*/


model Constants

global {
	// constant values used for the human mobility modes
	string MPAV <- "mpav" const: true;
	string WALKING <- "walking" const: true;
	string BUS <- "bus" const: true;
	string BIKE <- "bike" const: true;
	string CAR <- "car" const: true;
	string TRUCK <- "truck" const: true;
	
	// constant for transport status:
	// 0 = human is walking to the pick-up location (e.g. bus stop, building)
	// 1 = human arrived at pick-up location, waiting for pick up
	// 2 = transport (mpav / bus) arrived at stop closest to target, human walks from there
	int WALKING_PICK_UP <- 0 const: true;
	int WAITING_PICK_UP <- 1 const: true;
	int WALKING_TARGET <- 2 const: true;
	
	
	map<string,rgb> buildingColors <- [ "Hub"::rgb("#8A4B4B"), "Restaurant"::rgb("#536A8D"), "Night"::rgb("#4B493E"),"GP"::rgb("#4B493E"), "Cultural"::rgb("#4B493E"), "Shopping"::rgb("#4B493E"), "HS"::rgb("#4B493E"), "Uni"::rgb("#4B493E"), "O"::rgb("#4B493E"), "R"::rgb("#222222"), "Park"::rgb("#68805F"), "SAT"::rgb("#4B493E"), "stop"::rgb("#4B493E")] const: true;	
	map<string,rgb> peopleColors <- [ "High School Student"::rgb("#FFFFB2"), "College student"::rgb("#FECC5C"),"Young professional"::rgb("#FD8D3C"),  "Mid-career workers"::rgb("#F03B20"), "Executives"::rgb("#BD0026"), "Home maker"::rgb("#0B5038"), "Retirees"::rgb("#8CAB13")] const: true;
	list<string> mobilityList <- ["walking", "bike","car","bus","mpav","truck"];
	
	// right now this value is constant,
	// maybe it will get dynamic in a future version
	float currentWeather <- 0.5;	
	
}

