/**
* Name: Global
* Based on the internal empty template. 
* Author: Yves
* Tags: 
*/
model MPAV2

import "Constants.gaml"
import "Files.gaml"
import "Parameters.gaml"
import "Shared.gaml"
import "Actors/Road.gaml"
import "Actors/Building.gaml"
import "Actors/Human.gaml"
import "Actors/Bus.gaml"

global {
	geometry shape <- envelope(roadsShapeFile);
	float step <- stepsPerMin #mn;
	date starting_date <- date([2022, 5, 4, 7, 30]);

	init {
		write "Global init called";
		do initSharedValues;
		create Road from: roadsShapeFile {
			mobilityAllowed <- ["walking", "bike", "car", "bus"];
			capacity <- shape.perimeter / 10.0;
			congestionMap[self] <- shape.perimeter;
		}

		create Building from: buildingsShapeFile with: [usage::string(read("Usage")), scale::string(read("Scale")), category::string(read("Category"))] {
			if category = "stop" {
				create BusStop number: 1 {
					location <- myself.location;
				}

			}

		}

		do computeMobilityGraph;
		do generateGoods;
		
		create Bus number: 1 {
			stops <- list(BusStop);
			location <- first(stops).location;
			peopleAtStops <- map<BusStop, list<Human>>(stops collect(each::[]));
		}	
		
		create Human number: peopleCount {
			od <- proportionPerOdType.keys[rnd_choice(proportionPerOdType.values)];
			type <- proportionPerHumanType.keys[rnd_choice(proportionPerHumanType.values)];
			hasCar <- flip(carPerTypeProba[type]);
			hasBike <- flip(bikePerTypeProba[type]);
			if od = 'out2ks' {
				livingPlace <- one_of(Building where (each.usage = "SAT"));
			} else {
				livingPlace <- one_of(Building where (each.usage = "R"));
			}

			currentPlace <- livingPlace;
			location <- any_location_in(livingPlace);
			closestBusStop <- BusStop with_min_of (each distance_to (self));
			closestBuilding <- Building with_min_of (each distance_to (self));
			possibleMobilityModes <- evalPossibleMobilityModes();
			do createTripObjectives;
		}

		create Mpav number: mpavCount {
			target <- nil;
			timeStamp <- time;
			type <- mpavType;
			location <- one_of(Building where (each.usage = "Hub")).location;
			switch type {
				match "Truck" {
					speed <- speedPerMobility["car"];
					maxPeopleCount <- 0;
					maxGoodsCount <- 50;
				}

				match "MPAV" {
				// big AV
					speed <- speedPerMobility["bike"];
					maxPeopleCount <- 4;
					maxGoodsCount <- 10;
				}

				match "PEV" {
				// small AV
					speed <- speedPerMobility["bike"];
					maxPeopleCount <- 1;
					maxGoodsCount <- 3;
				}

			}

		}

	}

	/**
	 * Function has to be in global since it accesses Roads
	 */
	action computeMobilityGraph {
		write "Calculating mobility graph";
		loop mode over: colorPerMobility.keys {
			graphPerMobility[mode] <- as_edge_graph(Road where (mode in each.mobilityAllowed)) use_cache false;
		}

	}
	
	action generateGoods {
		create Goods number: goodsData["foods"][current_date.hour] {
			type <- "foods";
			target <- one_of(Building where (each.category != "Hub"));
			do initPosition;
		}
		create Goods number: goodsData["packages"][current_date.hour] {
			type <- "packages";
			target <- one_of(Building where (each.usage != "Restaurant"));
			do initPosition;
		}
	}
	
	reflex cyclic_generate_goods when: every(1#hour){
		do generateGoods;
	}
	
	reflex update_road_weights {
		ask Road {
			congestionMap[self] <- speedCoeff;
		}
	}

}

