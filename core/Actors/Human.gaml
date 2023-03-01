/**
* Name: Human
* Based on the internal empty template. 
* Author: Yves
* Tags: 
*/
model Human

import "../Constants.gaml"
import "../Parameters.gaml"
import "../Shared.gaml"
import "Building.gaml"
import "BusStop.gaml"
import "TripObjective.gaml"
import "Road.gaml"
import "Mpav.gaml"
import "PollutionHeatMap.gaml"

global {

// INDICATORs
	map<string, int> transportTypeCumulativeUsage <- map(mobilityList collect (each::0));
	map<string, int> transportTypeDailyUsage <- map(mobilityList collect (each::0));
	map<string, int> transportTypeCumulativeEmission <- map(mobilityList collect (each::0));
	map<string, int> transportTypeTotalCost <- map(mobilityList collect (each::0));
	map<string, int> transportTypeTotalWaiting <- map(mobilityList collect (each::0));
	map<string, int> transportTypeTotalDifficulty <- map(mobilityList collect (each::0));
	map<string, int> transportTypeTotalDistance <- map(mobilityList collect (each::0));
	map<string, int> transportTypeTotalDistance_people <- map(mobilityList collect (each::0));
	map<string, int> transportTypeTotalDistance_goods <- map(mobilityList collect (each::0));
	map<string, int> transportTypeUsage <- map(mobilityList collect (each::0));
	map<string, float> transportTypeDistance <- map(mobilityList collect (each::0.0)) + ["bus_people"::0.0];
	list<float> peopleTripTimeTotal <- [];
}

species Human skills: [moving] {

// static human values
	float size <- 5 #m;
	string od;
	string type;
	rgb color;
	Building livingPlace;
	list<TripObjective> objectives;
	list<string> possibleMobilityModes;
	bool hasCar;
	bool hasBike;

	// dynamic values:
	TripObjective currentObjective;
	Building currentPlace;
	string mobilityMode;
	BusStop closestBusStop;
	Building closestBuilding;
	int publicTransportStatus;
	float timeStamp;
	list<string> evalPossibleMobilityModes {
		list<string> modes <- [WALKING, BUS];
		if (hasCar) {
			modes << CAR;
		}

		if (hasBike) {
			modes << BIKE;
		}

		if mpavType != "Truck" {
			modes << MPAV;
		}

		return modes;
	}

	action createTripObjectives {
		if empty(activityData) or type = nil {
			error "ActivitData is empty";
		}

		map<int, string> activities <- activityData[type];
		loop key over: activities.keys {
			string activitiesRawString <- activities[key];
			if (activitiesRawString != "") {
				list<string> activitiesParsed <- activitiesRawString split_with "|";
				string selectedActivity <- one_of(activitiesParsed);
				Building activityBuilding <- selectRandomBuildingForActivty(od, selectedActivity);
				do createActivity(selectedActivity, activityBuilding, key);
			}

		}

	}

	Building selectRandomBuildingForActivty (string humanOD, string activity) {
		list<Building> possibleBuildings;
		if (length(activity) = 2) and (first(activity) = "R") {
			if humanOD = "out2ks" {
				possibleBuildings <- Building where ((each.usage = "SAT"));
			} else {
				possibleBuildings <- Building where ((each.usage = "R") and (each.scale = last(activity)));
			}

		} else if (length(activity) = 2) and (first(activity) = "O") {
			if humanOD = "ks2out" {
				possibleBuildings <- Building where ((each.usage = "SAT"));
			} else {
				possibleBuildings <- Building where ((each.usage = "O") and (each.scale = last(activity)));
			}

		} else {
			possibleBuildings <- Building where (each.category = activity);
		}

		Building activityBuilding <- one_of(possibleBuildings);
		if (activityBuilding = nil) {
			error "problem with activity: " + activity;
		}

		return activityBuilding;
	}

	action createActivity (string activityName, Building building, int hour) {
		create TripObjective {
			name <- activityName;
			target <- building;
			startHour <- hour;
			startMinute <- rnd(60);
			myself.objectives << self;
		}

	}

	action updatePollutionMap {
		ask PollutionHeatMap overlapping (current_path.shape) {
			pollutionLevel <- pollutionLevel + 1;
		}

	}

	reflex updateDensityMap when: (every(#hour) and updateDensity = true) {
		ask PollutionHeatMap {
			density <- length(Human overlapping self);
		}

	}

	reflex chooseObjective when: currentObjective = nil {
		do wander speed: 0.01;
		currentObjective <- objectives first_with ((each.startHour = current_date.hour) and (current_date.minute >= each.startMinute) and (currentPlace != each.target));
		if (currentObjective != nil) {
			currentPlace <- nil;
			do chooseMobilityMode;
			do startTimer;
		}

	}

	/**
	 * Note: I did not change anything in this method. To be honest, I don't really get how it evaluates the mobility modes.
	 * All I changed are the names of the variables, to be in line with other variable names.
	 */
	action chooseMobilityMode {
		list<list> candidates <- evalutateMobilityMode();
		map<string, list<float>> crits <- humanActivityProb[type];
		list<float> vals;
		loop obj over: crits.keys {
			if (obj = currentObjective.name) or ((currentObjective.name in ["RS", "RM", "RL"]) and (obj = "R")) or ((currentObjective.name in ["OS", "OM", "OL"]) and (obj = "O")) {
				vals <- crits[obj];
				break;
			}

		}

		list<map> criteriaWeightedMeans;
		loop i from: 0 to: length(vals) - 1 {
			criteriaWeightedMeans << ["name"::"crit" + i, "weight"::vals[i]];
		}

		int choice <- weighted_means_DM(candidates, criteriaWeightedMeans);
		if (choice >= 0) {
			mobilityMode <- possibleMobilityModes[choice];
		} else {
			mobilityMode <- one_of(possibleMobilityModes);
		}

		speed <- speedPerMobility[mobilityMode];
		// Update statistics:
		transportTypeCumulativeUsage[mobilityMode] <- transportTypeCumulativeUsage[mobilityMode] + 1;
		transportTypeUsage[mobilityMode] <- transportTypeUsage[mobilityMode] + 1;
		transportTypeDailyUsage[mobilityMode] <- transportTypeDailyUsage[mobilityMode] * min(mod(current_date.hour + 2, 24), 1) + 1;
		transportTypeDailyUsage['walking'] <- transportTypeDailyUsage['walking'] * min(mod(current_date.hour + 2, 24), 1) + 1;
		transportTypeDailyUsage['bus'] <- transportTypeDailyUsage['bus'] * min(mod(current_date.hour + 2, 24), 1) + 1;
		transportTypeCumulativeEmission[mobilityMode] <- transportTypeCumulativeEmission[mobilityMode] + emissionPerMobility[mobilityMode] * speedPerMobility[mobilityMode];
		transportTypeTotalCost[mobilityMode] <-
		transportTypeTotalCost[mobilityMode] + fixedPricePerMobility[mobilityMode] + pricePerMobility[mobilityMode] * speedPerMobility[mobilityMode];
		transportTypeTotalWaiting[mobilityMode] <- transportTypeTotalWaiting[mobilityMode] + waitingPerMobility[mobilityMode];
		transportTypeTotalDifficulty[mobilityMode] <- transportTypeTotalDifficulty[mobilityMode] + difficultyPerMobility[mobilityMode];
		transportTypeTotalDistance[mobilityMode] <- transportTypeTotalDistance[mobilityMode] + speedPerMobility[mobilityMode];
		transportTypeTotalDistance_goods[mobilityMode] <- transportTypeTotalDistance['MPAV'] + speedPerMobility['MPAV'];
	}

	/**
	 * Note: I did not change anything in this method. To be honest, I don't really get how it evaluates the mobility modes.
	 * All I changed are the names of the variables, to be in line with other variable names.
	 */
	list<list> evalutateMobilityMode {
		list<list> candidates;
		loop mode over: possibleMobilityModes {
			list<float> characteristic <- charactPerMobility[mode];
			list<float> cand;
			float mobDistance <- 0.0;
			using topology(graphPerMobility[mode]) {
				mobDistance <- distance_to(location, currentObjective.target.location);
			}

			if (self.od != 'ks2ks') {
				cand << characteristic[0] + characteristic[1] * (mobDistance);
				cand << characteristic[2] #mn + mobDistance / speedPerMobility[mode];
			} else {
				cand << characteristic[0] + characteristic[1] * (mobDistance + 10);
				cand << characteristic[2] #mn + (mobDistance + 10) / speedPerMobility[mode];
			}

			cand << characteristic[4];
			cand << characteristic[5] * (weatherImpact ? (1.0 + currentWeather * weatherCoeffPerMobility[mode]) : 1.0);
			add cand to: candidates;
		}

		//normalisation
		list<float> max_values;
		loop i from: 0 to: length(candidates[0]) - 1 {
			max_values << max(candidates collect abs(float(each[i])));
		}

		loop cand over: candidates {
			loop i from: 0 to: length(cand) - 1 {
				if (max_values[i] != 0.0) {
					cand[i] <- float(cand[i]) / max_values[i];
				}

			}

		}

		return candidates;
	}

	reflex move when: (currentObjective != nil) and (mobilityMode != BUS) and (mobilityMode != MPAV) {
		transportTypeDistance[mobilityMode] <- transportTypeDistance[mobilityMode] + speed / step;
		if ((current_edge != nil) and (mobilityMode = CAR)) {
			Road(current_edge).currentConcentration <- max([0, Road(current_edge).currentConcentration - 1]);
		}

		if (mobilityMode = CAR) {
			do goto target: currentObjective.target.location on: graphPerMobility[mobilityMode] move_weights: congestionMap speed: speedPerMobility[CAR];
		} else {
			do goto target: currentObjective.target.location on: graphPerMobility[mobilityMode] speed: speedPerMobility[mobilityMode];
		}

		if (world.equalLocation(location, currentObjective.target.location)) {
			do stopTimer;
			if (mobilityMode = CAR and updatePollution = true) {
				do updatePollutionMap;
			}

			currentPlace <- currentObjective.target;
			location <- any_location_in(currentPlace);
			currentObjective <- nil;
			mobilityMode <- nil;
		} else {
			if ((current_edge != nil) and (mobilityMode = CAR)) {
				Road(current_edge).currentConcentration <- Road(current_edge).currentConcentration + 1;
			}

		}

	}

	reflex move_bus when: (currentObjective != nil) and (mobilityMode = BUS) {
		if (publicTransportStatus = nil or publicTransportStatus = WALKING_PICK_UP) {
			publicTransportStatus <- WALKING_PICK_UP;
			do goto target: closestBusStop.location on: graphPerMobility[WALKING] speed: speedPerMobility[WALKING];
			transportTypeDistance[WALKING] <- transportTypeDistance[WALKING] + speed / step;
			if (location = closestBusStop.location) {
				add self to: closestBusStop.waitingPeople;
				publicTransportStatus <- WAITING_PICK_UP;
			}

		} else if (publicTransportStatus = WALKING_TARGET) {
			do goto target: currentObjective.target.location on: graphPerMobility[WALKING] speed: speedPerMobility[WALKING];
			transportTypeDistance[WALKING] <- transportTypeDistance[WALKING] + speed / step;
			if (world.equalLocation(location, currentObjective.target.location)) {
				do stopTimer;
				do handleTargetReached;
			}

		}

	}

	reflex move_mpav when: (currentObjective != nil) and (mobilityMode = MPAV) {
		if (publicTransportStatus = nil or publicTransportStatus = WALKING_PICK_UP) {
			publicTransportStatus <- WALKING_PICK_UP;
			do goto target: closestBuilding.location on: graphPerMobility[WALKING] speed: speedPerMobility[WALKING];
			transportTypeDistance[WALKING] <- transportTypeDistance[WALKING] + speed / step;
			if (location = closestBuilding.location) {
				add self to: mpavWaitingPeople;
				publicTransportStatus <- WAITING_PICK_UP;
			}

		} else if (publicTransportStatus = WALKING_TARGET) {
			do goto target: currentObjective.target.location on: graphPerMobility[WALKING] speed: speedPerMobility[WALKING];
			transportTypeDistance[WALKING] <- transportTypeDistance[WALKING] + speed / step;
			if (world.equalLocation(location, currentObjective.target.location)) {
				do stopTimer;
				do handleTargetReached;
			}

		}

	}

	/**
	 * Handles the case when the human has reached his target.
	 * Reset dynamic values, to initial values.
	 */
	action handleTargetReached {
		currentPlace <- currentObjective.target;
		closestBuilding <- Building with_min_of (each distance_to (self));
		location <- any_location_in(currentPlace);
		currentObjective <- nil;
		mobilityMode <- nil;
		publicTransportStatus <- nil;
	}

	action startTimer {
		timeStamp <- time;
	}

	action stopTimer {
		peopleTripTimeTotal << time - timeStamp;
		timeStamp <- time;
	}

	aspect default {
		if (mobilityMode = nil) {
			draw circle(size) at: location + {0, 0, (currentPlace != nil ? currentPlace.height : 0.0) + 4} color: #grey;
		} else {
			rgb _color <- #grey;
			switch mobilityMode {
				match WALKING {
					_color <- #lightyellow;
				}

				match BIKE {
					_color <- #white;
				}

				match CAR {
					_color <- #red;
				}

				match MPAV {
					_color <- #lime;
				}

				match BUS {
					_color <- #cyan;
				}

			}

			draw circle(size) color: _color;
		}

	}

	aspect base {
		draw circle(size) at: location + {0, 0, (currentPlace != nil ? currentPlace.height : 0.0) + 4} color: #grey;
	}

	aspect layer {
		if (desiredCycle mod refreshRate = 0) {
			draw sphere(size) at: {location.x, location.y, cycle * 2} color: #white;
		}

	}

}
