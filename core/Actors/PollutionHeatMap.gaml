/**
* Name: PollutionHeatMap
* Based on the internal empty template. 
* Author: Yves
* Tags: 
*/
model PollutionHeatMap

import "../Parameters.gaml"
grid PollutionHeatMap height: 50 width: 50 {
	int pollutionLevel <- 0;
	int density <- 0;
	rgb pollutionColor <- rgb(pollutionLevel * 10, 0, 0) update: rgb(pollutionLevel * 10, 0, 0);
	rgb densityColor <- rgb(255 - density * 50, 255 - density * 50, 255 - density * 50) update: rgb(255 - density * 50, 255 - density * 50, 255 - density * 50);

	aspect density {
		if updateDensity {
			draw shape color: densityColor at: {location.x + current_date.hour * world.shape.width, location.y};
		}

	}

	aspect pollution {
		if updatePollution {
			draw shape color: pollutionColor;
		}

	}

	reflex raz when: every(1 #day) {
		pollutionLevel <- 0;
	}

}

