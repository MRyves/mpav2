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

global {

// INDICATOR
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
	string od;
	string type;
	rgb color;
	float size <- 5 #m;
	Building livingPlace;
	list<TripObjective> objectives;
	TripObjective currentObjective;
	Building currentPlace;
	string mobilityMode;
	list<string> possibleMobilityModes;
	bool hasCar;
	bool hasBike;
	BusStop closestBusStop;
	Building closestBuilding;
	int busStatus <- 0;
	int mpavStatus <- 0;
	float time_stamp;

	init {
		write "Calling Human#Init";
	}

	list<string> evalPossibleMobilityModes {
		list<string> modes <- ["walking", "bus"];
		if (hasCar) {
			modes << "car";
		}

		if (hasBike) {
			modes << "bike";
		}

		if mpavType != "Truck" {
			modes << "mpav";
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
				list<string> activities <- activitiesRawString split_with "|";
				string selectedActivity <- one_of(activities);
				Building activityBuilding <- selectRandomBuildingForActivty(od, selectedActivity);
				do createActivity(selectedActivity, activityBuilding, key);
			}

		}

	}

	Building selectRandomBuildingForActivty (string humanOD, string activity) {
		list<Building> possible_bds;
		if (length(activity) = 2) and (first(activity) = "R") {
			if humanOD = "out2ks" {
				possible_bds <- Building where ((each.usage = "SAT"));
			} else {
				possible_bds <- Building where ((each.usage = "R") and (each.scale = last(activity)));
			}

		} else if (length(activity) = 2) and (first(activity) = "O") {
			if humanOD = "ks2out" {
				possible_bds <- Building where ((each.usage = "SAT"));
			} else {
				possible_bds <- Building where ((each.usage = "O") and (each.scale = last(activity)));
			}

		} else {
			possible_bds <- Building where (each.category = activity);
		}

		Building activityBuilding <- one_of(possible_bds);
		if (activityBuilding = nil) {
			error "problem with act_real: " + activity;
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
	// TODO: create gridHeatMap
	//		ask gridHeatmaps overlapping(current_path.shape) {
	//			pollution_level <- pollution_level + 1;
	//		}
	}

	reflex updateDensityMap when: (every(#hour) and updateDensity = true) {
	//		ask gridHeatmaps{
	//		  density<-length(people overlapping self);	
	//		}
	}

	reflex chooseObjective when: currentObjective = nil {
		do wander speed: 0.01;
		currentObjective <- objectives first_with ((each.startHour = current_date.hour) and (current_date.minute >= each.startMinute) and (currentPlace != each.target));
		if (currentObjective != nil) {
			currentPlace <- nil;
			do chooseMobilityMode;
			do timer_start;
		}

	}

	action chooseMobilityMode {
		list<list> cands <- mobility_mode_eval();
		map<string, list<float>> crits <- humanActivityProb[type];
		list<float> vals;
		loop obj over: crits.keys {
			if (obj = currentObjective.name) or ((currentObjective.name in ["RS", "RM", "RL"]) and (obj = "R")) or ((currentObjective.name in ["OS", "OM", "OL"]) and (obj = "O")) {
				vals <- crits[obj];
				break;
			}

		}

		list<map> criteria_WM;
		loop i from: 0 to: length(vals) - 1 {
			criteria_WM << ["name"::"crit" + i, "weight"::vals[i]];
		}

		int choice <- weighted_means_DM(cands, criteria_WM);
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

	list<list> mobility_mode_eval {
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

	reflex move when: (currentObjective != nil) and (mobilityMode != "bus") and (mobilityMode != "mpav") {
		transportTypeDistance[mobilityMode] <- transportTypeDistance[mobilityMode] + speed / step;
		if ((current_edge != nil) and (mobilityMode = "car")) {
			Road(current_edge).currentConcentration <- max([0, Road(current_edge).currentConcentration - 1]);
		}

		if (mobilityMode = "car") {
			do goto target: currentObjective.target.location on: graphPerMobility[mobilityMode] move_weights: congestionMap speed: speedPerMobility["car"];
		} else {
			do goto target: currentObjective.target.location on: graphPerMobility[mobilityMode] speed: speedPerMobility[mobilityMode];
		}

		if (location = currentObjective.target.location) {
			do timer_stop;
			if (mobilityMode = "car" and updatePollution = true) {
				do updatePollutionMap;
			}

			currentPlace <- currentObjective.target;
			location <- any_location_in(currentPlace);
			currentObjective <- nil;
			mobilityMode <- nil;
		} else {
			if ((current_edge != nil) and (mobilityMode = "car")) {
				Road(current_edge).currentConcentration <- Road(current_edge).currentConcentration + 1;
			}

		}

	}

	reflex move_bus when: (currentObjective != nil) and (mobilityMode = "bus") {
	// bus_status=0 walk to bus station
		if (busStatus = 0) {
			do goto target: closestBusStop.location on: graphPerMobility["walking"] speed: speedPerMobility["walking"];
			transportTypeDistance["walking"] <- transportTypeDistance["walking"] + speed / step;

			// bus_status=1 add human to waiting list
			if (location = closestBusStop.location) {
				add self to: closestBusStop.waitingPeople;
				busStatus <- 1;
			}

			//		bus_status=2 arrived at bus stop closest to the object target, walk from there to target.
		} else if (busStatus = 2) {
			do goto target: currentObjective.target.location on: graphPerMobility["walking"] speed: speedPerMobility["walking"];
			transportTypeDistance["walking"] <- transportTypeDistance["walking"] + speed / step;

			//			target location reached, resetting params
			if (location = currentObjective.target.location) {
				do timer_stop;
				currentPlace <- currentObjective.target;
				closestBusStop <- BusStop with_min_of (each distance_to (self));
				location <- any_location_in(currentPlace);
				currentObjective <- nil;
				mobilityMode <- nil;
				busStatus <- 0;
			}

		}

	}

	reflex move_mpav when: (currentObjective != nil) and (mobilityMode = "mpav") {
		if (mpavStatus = 0) {
			do goto target: closestBuilding.location on: graphPerMobility["walking"] speed: speedPerMobility["walking"];
			transportTypeDistance["walking"] <- transportTypeDistance["walking"] + speed / step;
			if (location = closestBuilding.location) {
				add self to: mpavWaitingPeople;
				mpavStatus <- 1;
			}

		} else if (mpavStatus = 2) {
			do goto target: currentObjective.target.location on: graphPerMobility["walking"] speed: speedPerMobility["walking"];
			transportTypeDistance["walking"] <- transportTypeDistance["walking"] + speed / step;
			if (location = currentObjective.target.location) {
				do timer_stop;
				currentPlace <- currentObjective.target;
				closestBuilding <- Building with_min_of (each distance_to (self));
				location <- any_location_in(currentPlace);
				currentObjective <- nil;
				mobilityMode <- nil;
				busStatus <- 0;
				mpavStatus <- 0;
			}

		}

	}

	action timer_start {
		time_stamp <- time;
	}

	action timer_stop {
		peopleTripTimeTotal << time - time_stamp;
		time_stamp <- time;
	}

	aspect default {
		if (mobilityMode = nil) {
			draw circle(size) at: location + {0, 0, (currentPlace != nil ? currentPlace.height : 0.0) + 4} color: #grey;
		} else {
			rgb _color <- #grey;
			switch mobilityMode {
				match "walking" {
					_color <- #lightyellow;
				}

				match "bike" {
					_color <- #white;
				}

				match "car" {
					_color <- #red;
				}

				match "mpav" {
					_color <- #lime;
				}

				match "bus" {
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
