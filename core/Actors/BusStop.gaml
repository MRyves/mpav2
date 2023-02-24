/**
* Name: BusStop
* Based on the internal empty template. 
* Author: Yves
* Tags: 
*/


model BusStop

import "Human.gaml"

species BusStop {
	list<Human> waitingPeople;
	
	aspect default {
		draw hexagon(20) color: empty(waitingPeople) ? #white : #red border: #white depth:1;
	}
}

