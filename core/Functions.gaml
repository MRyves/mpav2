/**
* Name: Functions
* Based on the internal empty template. 
* Author: Yves
*/
model Functions

import "Constants.gaml"

/**
 * This model provides shared functions which are called by multiple models.
 */
global {

/**
	 * This function compares two locations with each other with given precision.
	 * This is very useful as sometimes an object (e.g. MPAV) can not reach the target building exactly since the road-graph is not connected to this exact location.
	 * That edge-case can be fixed with this function, simply by comparing the two locations with less precision.
	 */
	bool equalLocation (point location1, point location2, int precision <- 12) {
		point l1 <- location1 with_precision precision;
		point l2 <- location2 with_precision precision;
		return l1 = l2;
	}

	/**
	 * Takes the currentWeather value and transforms it to a human understanable value.
	 * Used to show the current weather on the monitor.
	 */
	string getWeatherCondition (float currentWeather) {
		if currentWeather >= 0 and currentWeather < 0.25 {
			return "Excellent";
		}

		if currentWeather >= 0.25 and currentWeather < 0.5 {
			return "Good";
		}

		if currentWeather >= 0.5 and currentWeather < 0.75 {
			return "Not Good";
		}

		if currentWeather >= 0.75 and currentWeather <= 1 {
			return "Really Bad";
		}

	}

}

