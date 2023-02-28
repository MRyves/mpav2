/**
* Name: Functions
* Based on the internal empty template. 
* Author: Yves
* Tags: 
*/


model Functions

import "Constants.gaml"

global {
	
	/**
	 * This function compares two locations with each other with given precision.
	 */
	bool equalLocation(point location1, point location2, int precision <- 12) {
		point l1 <- location1 with_precision precision;
		point l2 <- location2 with_precision precision;
		
		return l1 = l2;
	}
	
	string getWeatherCondition {
		write "Test";
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

