/**
* Name: TripObjective
* Based on the internal empty template. 
* Author: Yves
* Tags: 
*/


model TripObjective

import "Building.gaml"

species TripObjective {
	string name;
	Building target;
	int startHour;
	int startMinute;
	
}
