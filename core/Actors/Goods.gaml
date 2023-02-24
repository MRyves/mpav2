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
		if type = "foods" {
			origin <- one_of(Building where (each.category = "Restaurant"));
			location <- any_location_in(origin);
		} else {
			origin <- one_of(Building where (each.usage = "Hub"));
			location <- any_location_in(origin);
		}

		mpavWaitingGoods << self;
		time_stamp <- time;
	}

	//	reflex disapear when: location = objective.location {
	//		do die;
	//	}
	action timer_stop {
		goodsTripTimeTotal << time - time_stamp;
		time_stamp <- time;
	}

	aspect default {
		if (type = "foods") {
			draw triangle(size * 1.2) color: #yellow;
		} else {
			draw triangle(size * 1.2) color: #aqua;
		}

	}

}
