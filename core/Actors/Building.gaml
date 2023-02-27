/**
* Name: Buildung
* Based on the internal empty template. 
* Author: PCYves3
* Tags: 
*/
model Buildung

import "../Constants.gaml"

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

