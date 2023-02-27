/**
* Name: Mpav
* Based on the internal empty template. 
* Author: Yves
* Tags: 
*/
model Mpav

import "Human.gaml"
import "Goods.gaml"

global {
	float mpavIdle <- 0.0;
	float mpavWorking <- 0.0;
	list<Human> mpavWaitingPeople <- [];
	list<Goods> mpavWaitingGoods <- [];
}

species Mpav skills: [moving] {
	geometry shape <- rectangle(45, 30);
	string type;
	list<Goods> goodsInMpav;
	list<Human> peopleInMpav;
	Building target <- nil;
	float timeStamp;
	int maxPeopleCount;
	int maxGoodsCount;

	reflex new_target when: target = nil {
		target <- collectTargets() with_min_of (each distance_to (self));
		do startWorking;
	}

	/**
	 * Iterate through all the goods & people in the MPAV and collect their targets.
	 * Also iterate the targets of the goods & people waiting to be picked up.
	 * See the two lists defined in the global section
	 */
	list<Building> collectTargets {
		list<Building> targets <- [];
		loop g over: goodsInMpav collect each.target {
			targets << g;
		}

		loop g over: mpavWaitingGoods collect each.origin {
			if length(goodsInMpav) >= maxGoodsCount {
				break;
			}

			targets << g;
		}

		loop p over: peopleInMpav collect each.currentObjective.target {
			targets << p;
		}

		loop p over: mpavWaitingPeople collect each.closestBuilding {
			if length(peopleInMpav) >= maxPeopleCount {
				break;
			}

			targets << p;
		}

		return targets;
	}

	reflex move when: target != nil {
		do goto target: target.location on: graphPerMobility[CAR] speed: speed;
		if (length(goodsInMpav) + length(peopleInMpav)) > 0 {
			if maxPeopleCount = 0 {
				transportTypeDistance[TRUCK] <- transportTypeDistance[TRUCK] + speed / step;
			} else {
				transportTypeDistance[MPAV] <- transportTypeDistance[MPAV] + speed / step;
			}

		}

		if (location = target.location) {
			do startWaiting;
			do handleGoods;
			do handleHumans;
			target <- nil;
		}

	}

	/**
	 * When the MPAV reaches a target station.
	 * This method can be called to handle the goods transactions:
	 * 1. Removing the goods which reached their target destition
	 * 2. Adding the waiting goods of the current location to the MPAV
	 */
	action handleGoods {
	// remove goods which reached their target
		loop g over: goodsInMpav where ((each.target = target)) {
			remove g from: goodsInMpav;
			ask g {
				do timer_stop;
				do die;
			}

		}
		// add the goods waiting at current location
		// once the mpav is full, no more goods will be added
		loop g over: mpavWaitingGoods where ((each.origin = target)) {
			remove g from: mpavWaitingGoods;
			add g to: goodsInMpav;
			if length(goodsInMpav) >= maxGoodsCount {
				break;
			}

		}

	}

	/**
	 * Very similar to #handleGoods method, simply for humans
	 */
	action handleHumans {
		loop p over: peopleInMpav where ((each.currentObjective.target = target)) {
			remove p from: peopleInMpav;
			ask p {
				location <- myself.target.location;
				publicTransportStatus <- WALKING_TARGET;
			}

		}

		loop p over: mpavWaitingPeople where ((each.closestBuilding = target)) {
			remove p from: mpavWaitingPeople;
			add p to: peopleInMpav;
			if length(peopleInMpav) >= maxPeopleCount {
				break;
			}

		}

	}

	/**
	 * Simply update the location of the carried humans & goods
	 */
	reflex carry {
		loop g over: goodsInMpav {
			ask g {
				location <- any_location_in(myself.shape);
			}

		}

		loop p over: peopleInMpav {
			ask p {
				location <- any_location_in(myself.shape);
			}

		}

	}

	action startWorking {
		mpavIdle <- mpavIdle + time - timeStamp;
		timeStamp <- time;
	}

	action startWaiting {
		mpavWorking <- mpavWorking + time - timeStamp;
		timeStamp <- time;
	}

	aspect default {
		draw shape color: #green;
	}

}

