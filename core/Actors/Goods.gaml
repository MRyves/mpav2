/**
* Name: Goods
* Based on the internal empty template. 
* Author: Yves
* Tags: 
*/
model Goods

import "Building.gaml"
import "Mpav.gaml"

global {
	list<float> goodsTripTimeTotal <- [];
}

/**
 * Goods can either be of type 'food' or of type 'packages'.
 * Each good starts at the origin building and has to be transportet to the target building.
 * In the simulation the only mean of transportation for goods are the mpavs.
 * Once the good reaches the target building it will be removed from the experiment.
 */

species Goods {
	string type;
	rgb color;
	float size <- 10 #m;
	Building target;
	Building origin;
	float timeStamp;

	action initPosition {
		switch type {
			match FOODS {
				origin <- one_of(Building where (each.category = "Restaurant"));
				location <- any_location_in(origin);
				color <- #yellow;
			}

			match PACKAGES {
				origin <- one_of(Building where (each.usage = "Hub"));
				location <- any_location_in(origin);
				color <- #aqua;
			}

			default {
				error "Invalid goods type: " + type;
			}

		}

		mpavWaitingGoods << self;
		timeStamp <- time; // start timer
	}

	action stopTimer {
		goodsTripTimeTotal << time - timeStamp;
		timeStamp <- time;
	}

	aspect default {
		draw triangle(size * 1.2) color: color;
	}

}
