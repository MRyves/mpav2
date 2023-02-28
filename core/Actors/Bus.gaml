/**
* Name: Bus
* Based on the internal empty template. 
* Author: Yves
* Tags: 
*/
model Bus

import "Human.gaml"
species Bus skills: [moving] {
	geometry shape <- rectangle(40, 30);
	// list of all the bus stops on the map
	list<BusStop> stops;
	// the next bus stop
	BusStop target;
	// key: bus stop, value: humans which have to go to the bus stop (the key)
	// one can consider that the values are all the humans currently on the bus
	map<BusStop, list<Human>> peopleToStops;

	reflex newTarget when: target = nil {
		BusStop firstStop <- first(stops);
		// move next stop to the end of the stops list
		remove firstStop from: stops;
		add firstStop to: stops;
		target <- firstStop;
	}

	reflex move when: target != nil {
		do goto target: target.location on: graphPerMobility[CAR] speed: speedPerMobility[BUS];
		int passengersCount <- peopleToStops.values sum_of (length(each));
		if (passengersCount > 0) {
			transportTypeDistance[BUS] <- transportTypeDistance[BUS] + speed / step;
			transportTypeDistance["bus_people"] <- transportTypeDistance["bus_people"] + speed / step * passengersCount;
		}

		if (world.equalLocation(location, target.location)) {
		// the bus has reached the current target (bus station)
			do releasePeople;
			do pickupPeople;
			target <- nil;
		}

	}

	/**
	 * Release the people at the bus stop which is closest to their objective location.
	 * Only release peopel if the location of the bus is equal to the location of the bus stop
	 */
	action releasePeople {
		ask peopleToStops[target] {
			location <- myself.target.location;
			publicTransportStatus <- WALKING_TARGET;
		}

		peopleToStops[target] <- [];
	}

	/**
	 * Pick up the people which are waiting at the current bus stop.
	 */
	action pickupPeople {
		loop p over: target.waitingPeople {
			BusStop b <- BusStop with_min_of (each distance_to (p.currentObjective.target.location));
			add p to: peopleToStops[b];
		}

		target.waitingPeople <- [];
	}

	/**
	 * Update the location of the people inside the bus
	 */
	reflex carry {
		loop stop over: stops {
			ask peopleToStops[stop] {
				location <- any_location_in(myself.shape);
			}

		}

	}

	aspect default {
		draw shape color: #darkcyan;
	}

}