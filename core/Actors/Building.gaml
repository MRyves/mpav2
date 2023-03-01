/**
* Name: Buildung
* Based on the internal empty template. 
* Author: PCYves3
* Tags: 
*/
model Buildung

import "../Constants.gaml"

/**
 * Defines a building in the simulation.
 * Buildings are static agents, they don't move or change over time.
 * They are simple shown on the map in different colors, depnding on the type of building.
 */
species Building {
	string usage;
	string scale;
	string category;
	rgb color <- #grey;
	float height <- 0.0;

	init {
		color <- buildingColors[category];
	}

	aspect default {
		draw shape color: color;
	}

	aspect depth {
		draw shape color: color depth: height;
	}

}

