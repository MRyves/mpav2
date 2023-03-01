/**
* Name: Bus
* Based on the internal empty template. 
* Author: Yves
* Tags: 
*/
model Bus

import "Human.gaml"

/**
 * Agents represents a bus, which is moving around the bus stations all the time.
 * At the moment there is no concept of a time-scheduler implemented.
 * The bus starts driving at the beginning of the simulation and never stops.
 */

species Bus skills: [moving] {
	geometry shape <- rectangle(40, 30);
	/** 
	 * list of all the bus stops on the map
	 */
	list<BusStop> stops;
	/** the next bus stop */
	BusStop target;
	/**
	 * Usage: All the people in the bus, which have to descend on different bus stops.
	 * key: bus stop, value: humans which have to go out at that bus stop (the key)
	 */
	map<BusStop, list<Human>> peopleToStops;

	reflex newTarget when: target = nil {
		BusStop firstStop <- first(stops);
		// move next stop to the end of the stops list
		remove firstStop from: stops;
		add firstStop to: stops;
		target <- firstStop;
	}

	/**
	 * Drive to the next target.
	 * If targed reached, let the people descend and pick up the waiting humans at the current bus stop. 
	 */
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