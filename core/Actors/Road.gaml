/**
* Name: MPAV2
* Based on the internal empty template. 
* Author: Yves
* Tags: 
*/
model Road

import "../Shared.gaml"

global {
	map<Road, float> congestionMap;

	init {
		write "Road#Global init called";
	}

	/**
	 * Function computes all the graphs for each mobility mode.
	 */
	action computeMobilityGraph {
		write "Calculating mobility graph";
		loop mode over: colorPerMobility.keys {
			graphPerMobility[mode] <- as_edge_graph(Road where (mode in each.mobilityAllowed)) use_cache false;
		}

	}

}

species Road {
	list<string> mobilityAllowed;
	float capacity;
	float maxSpeed <- 30 #km / #h;
	float currentConcentration;
	float speedCoeff <- 1.0 update: shape.perimeter / max([0.01, exp(-currentConcentration / capacity)]);

	init {
		write "Road#Species init called";
		congestionMap[self] <- shape.perimeter;
	}

	reflex update_road_weights {
		congestionMap[self] <- speedCoeff;
	}

	/**
	 * This user command can be called at the time of running the simulation.
	 */
	user_command to_pedestrian_road {
		mobilityAllowed <- ["walking", "bike"];
		ask world {
			do computeMobilityGraph;
		}

	}

	aspect default {
		draw shape color: rgb(125, 125, 125);
	}

	aspect mobility {
		string maxMobility <- mobilityAllowed with_max_of (widthPerMobility[each]);
		draw shape width: widthPerMobility[maxMobility] color: colorPerMobility[maxMobility];
	}

}

