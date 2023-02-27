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
	float timeStamp;

	action initPosition {
		switch type {
			match "foods" {
				origin <- one_of(Building where (each.category = "Restaurant"));
				location <- any_location_in(origin);
				color <- #yellow;
			}

			match "packages" {
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
