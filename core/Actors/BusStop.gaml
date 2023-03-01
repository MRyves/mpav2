/**
* Name: BusStop
* Based on the internal empty template. 
* Author: Yves
* Tags: 
*/


model BusStop

import "Human.gaml"

/**
 * Agent representing a bus stop.
 * BusStop is a static agent, it never moves around.
 * All it does is to store a list of all the humans waiting at the bus stop.
 */

species BusStop {
	list<Human> waitingPeople;
	
	aspect default {
		draw hexagon(20) color: empty(waitingPeople) ? #white : #red border: #white depth:1;
	}
}

