/**
* Name: Global
* Author: Yves
*/
model MPAV2

import "Constants.gaml"
import "Files.gaml"
import "Functions.gaml"
import "Parameters.gaml"
import "Shared.gaml"
import "Actors/Road.gaml"
import "Actors/Building.gaml"
import "Actors/Human.gaml"
import "Actors/Bus.gaml"

global {
	geometry shape <- envelope(roadsShapeFile);
	float step <- minsPerStep #mn;
	// date starting_date <- date([2022, 5, 4, 7, 30]);
	date starting_date <- date([2022, 1, 1, 7, 59]);
	
	string weatherDescription <- "Loading...";	
	

	init {
		do initSharedValues;
		create Road from: roadsShapeFile with: [maxSpeed::float(read("maxSpeed"))] {
			mobilityAllowed <- [WALKING, BIKE, CAR, BUS];
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
			peopleToStops <- map<BusStop, list<Human>>(stops collect(each::[]));
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
					speed <- speedPerMobility[CAR];
					maxPeopleCount <- 0;
					maxGoodsCount <- 50;
				}

				match "MPAV" {
				// big AV
					speed <- speedPerMobility[BIKE];
					maxPeopleCount <- 4;
					maxGoodsCount <- 10;
				}

				match "PEV" {
				// small AV
					speed <- speedPerMobility[BIKE];
					maxPeopleCount <- 1;
					maxGoodsCount <- 3;
				}

			}

		}

	}


	 action generateGoods {
		create Goods number: goodsData[FOODS][current_date.hour] {
			type <- FOODS;
			target <- one_of(Building where (each.category != "Hub"));
			do initPosition;
		}
		create Goods number: goodsData[PACKAGES][current_date.hour] {
			type <- PACKAGES;
			target <- one_of(Building where (each.usage != "Restaurant"));
			do initPosition;
		}
	}
	
	reflex cyclic_generate_goods when: every(1#hour){
		do generateGoods;
	}
	
	reflex updateWeather when: every(1#day) {
		point meanAndStd <- weatherCoffPerMonth[current_date.month];
		currentWeather <- gauss(meanAndStd);
		weatherDescription <- getWeatherCondition(currentWeather);
	}
	

}

