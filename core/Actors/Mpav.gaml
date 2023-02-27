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
	geometry shape;
	// mpav type
	string type;
	
	list<Goods> goodsInMpav;
	list<Human> peopleInMpav;
	Building target <- nil;
	float timeStamp;

	int maxPeopleCount;
	int maxGoodsCount;

	reflex new_target when: target = nil {
		list<Building> target_list <- [];
		loop g over: goodsInMpav collect each.target {
			target_list << g;
		}

		loop g over: mpavWaitingGoods collect each.origin {
			if length(goodsInMpav) >= maxGoodsCount {
				break;
			}

			target_list << g;
		}

		loop p over: peopleInMpav collect each.currentObjective.target {
			target_list << p;
		}

		loop p over: mpavWaitingPeople collect each.closestBuilding {
			if length(peopleInMpav) >= maxPeopleCount {
				break;
			}

			target_list << p;
		}

		target <- target_list with_min_of (each distance_to (self));
		do startWorking;
	}

	reflex move when: target != nil {
		do goto target: target.location on: graphPerMobility["car"] speed: speed;
		if (length(goodsInMpav) + length(peopleInMpav)) > 0 {
			if maxPeopleCount = 0 {
				transportTypeDistance["truck"] <- transportTypeDistance["truck"] + speed / step;
			} else {
				transportTypeDistance["mpav"] <- transportTypeDistance["mpav"] + speed / step;
			}

		}

		if (location = target.location) {
			do startWaiting;
			loop g over: goodsInMpav where ((each.target = target)) {
				remove g from: goodsInMpav;
				ask g {
					do timer_stop;
					do die;
				}

			}

			loop g over: mpavWaitingGoods where ((each.origin = target)) {
				remove g from: mpavWaitingGoods;
				add g to: goodsInMpav;
				if length(goodsInMpav) >= maxGoodsCount {
					break;
				}

			}

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

			target <- nil;
		}

	}

	reflex carry {
		shape <- rectangle(45, 30);
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

