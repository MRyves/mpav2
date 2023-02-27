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

species Goods {
	string type;
	rgb color;
	float size <- 10 #m;
	Building target;
	Building origin;
	float time_stamp;

	action initPosition {
		switch type {
			match "foods" {
				origin <- one_of(Building where (each.category = "Restaurant"));
				location <- any_location_in(origin);
				color <- #yellow;
			}

			match "package" {
				origin <- one_of(Building where (each.usage = "Hub"));
				location <- any_location_in(origin);
				color <- #aqua;
			}

			default {
				error "Invalid goods type: " + type;
			}

		}

		mpavWaitingGoods << self;
		time_stamp <- time; // start timer
	}

	action timer_stop {
		goodsTripTimeTotal << time - time_stamp;
		time_stamp <- time;
	}

	aspect default {
		draw triangle(size * 1.2) color: color;
	}

}
