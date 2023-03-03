/**
* Name: Parameters
* Based on the internal empty template. 
* Author: Yves
*/
model MPAV2

/**
 * This model defines all the parameters of the simulation.
 * Parameters should only be defined here as it would lead to messy code otherwise.
 */
global {
	bool updatePollution <- false parameter: "Pollution:" category: "Simulation";
	bool updateDensity <- false parameter: "Density:" category: "Simulation";
	bool weatherImpact <- true parameter: "Weather impact:" category: "Simulation";
	float minsPerStep <- 5.0 parameter: "Minutes per step:" category: "Simulation" min: 0.001 max: 100.000;
	int peopleCount <- 1000 parameter: "People count:" category: "Input" min: 1 max: 100000;
	int busStopCount <- 6 parameter: "Bus stop count:" category: "Input" min: 1 max: 20;
	string mpavType <- "MPAV" among: ["Truck", "MPAV", "PEV"] parameter: "Type of MPAV:" category: "MPAV";
	int mpavCount <- 3 parameter: "Number of MPAVs" category: "MPAV" min: 0 max: 100;
}

