/**
* Name: Bus
* Based on the internal empty template. 
* Author: Yves
* Tags: 
*/


model Bus

import "Human.gaml"

species Bus skills: [moving] {
	list<BusStop> stops; 
	map<BusStop,list<Human>> peopleAtStops;
	geometry shape;
	
 
	BusStop target;
	
	reflex new_target when: target = nil{
		BusStop firstStop <- first(stops);
		remove firstStop from: stops;
		add firstStop to: stops; 
		target <- firstStop;
	}
	
	reflex move when: target != nil{
		do goto target: target.location on: graphPerMobility["car"] speed:speedPerMobility["bus"];
		int nb_passengers <- peopleAtStops.values sum_of (length(each));
		if (nb_passengers > 0) {
				transportTypeDistance["bus"] <- transportTypeDistance["bus"] + speed/step;
				transportTypeDistance["bus_people"] <- transportTypeDistance["bus_people"] + speed/step * nb_passengers;
		} 
			
		if(location = target.location) {
			// release some people
			ask peopleAtStops[target] {
				location <- myself.target.location;
				busStatus <- 2;
			}
			peopleAtStops[target] <- [];
			
			// get some people
			loop p over: target.waitingPeople {
				BusStop b <- BusStop with_min_of(each distance_to(p.currentObjective.target.location));
				add p to: peopleAtStops[b] ;
			}
			target.waitingPeople <- [];						
			target <- nil;			
		}
	}

	reflex carry {
		shape <- rectangle(40,30);
		loop stop over: stops {
			ask peopleAtStops[stop] {
				location <- any_location_in(myself.shape);
			}
		}
	}
	
	aspect default {
		draw shape color: #darkcyan;
	}
}