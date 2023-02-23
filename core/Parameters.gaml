/**
* Name: Parameters
* Based on the internal empty template. 
* Author: Yves
* Tags: 
*/


model MPAV2

global {
	bool updatePollution <- false parameter: "Pollution:" category: "Simulation";
	bool updateDensity <- false parameter: "Density:" category: "Simulation";
	bool weatherImpact <- true parameter: "Weather impact:" category: "Simulation";
	int desiredCycle <- 8650 parameter: "Desired Cycle:" category: "Simulation" min: 1000 max: 10000;
	int refreshRate <- 180 parameter: "Refresh Rate:" category "Simulation" min: 1 max: 200;
	float stepsPerMin <- 5.0 parameter: "Steps per minute:" category: "Simulation" min: 0.001 max: 10.000;

	bool drawInteraction <- false parameter: "Draw interactions:" category: "Interaction"; 
	int distance <- 20 parameter: "Distance: " category: "Interaction" min: 1 max: 100;
	
	int peopleCount <- 1000 parameter: "People count:" category: "Input" min: 1 max: 100000;
	int busStopCount <- 6 parameter: "Bus stop count:" category: "Input" min: 1 max: 20;

	string mpavType <- "MPAV" among: ["Truck", "MPAV", "PEV"] parameter: "Type of MPAV:" category: "MPAV";
	int mpavCount <- 3 parameter: "Number of MPAVs" category: "MPAV" min: 0 max: 100;
	int mpavPeopleCap <- 0 parameter: "MPAV people capacity" category: "MPAV" min: 0 max: 100;
	int mpavGoodCap <- 0 parameter: "MPAV goods capacity" category: "MPAV" min: 1 max: 100;	
}

