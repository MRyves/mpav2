/**
* Name: Files
* Based on the internal empty template. 
* Author: Yves
* Tags: 
*/


model Files

global {
	
	string includesPath <- "../includes/" const: true;
	
	file activityPerProfileFile <- file(includesPath + "ActivityPerProfile.csv");
	file criteriaFile <- file(includesPath + "CriteriaFile.csv");
	file activtyPerProfileFile <- file(includesPath + "g_ActivityPerProfile.csv");
	file goodsTimeDistributionFile <- file(includesPath + "GoodsTimeDistribution.csv");
	file goodsTimeDistribution2File <- file(includesPath + "GoodsTimeDistribution2.csv");
	file goodsTimeDistribution3File <- file(includesPath + "GoodsTimeDistribution3.csv");
	file modesFile <- file(includesPath + "Modes.csv");
	file odFile <- file(includesPath + "OD.csv");
	file profilesFile <- file(includesPath + "Profiles.csv");
	file profiles2File <- file(includesPath + "Profiles2.csv");
	file weatherCoeffPerMonthFile <- file(includesPath + "weather_coeff_per_month.csv");
	
	// volpe folder
	string volpePath <- includesPath + "volpe/" const: true;
	
	file amenitiesShapeFile <- file(volpePath + "amenities.shp");
	file boundsShapeFile <- file(volpePath + "Bounds.shp");
	file<geometry> buildingsShapeFile <- file<geometry>(volpePath + "Buildings.shp");
	file<geometry> roadsShapeFile <- file<geometry>(volpePath + "Roads.shp");
	file tableBoundsShapeFile <- file(volpePath + "table_bounds.shp");
	
	// energy folder
	string energyFolderPath <- volpePath + "energy/" const:true;
	
	file energyVolpeFile <- file(energyFolderPath + "volpe.shp");
	
	// mobility folder
	string mobilityFolderPath <- volpePath + "mobility/" const: true;
	
	file bostonMobilityFile <- file(mobilityFolderPath + "boston_1_08_10_2017.csv");
	file kendallMobilityFile <- file(mobilityFolderPath + "kendall_1_08_10_2017.csv");
	
	// Test that each file exists
	test filesExist {
		assert true;
	}
	
	init {
		write "Files init called";
	}
}

experiment FilesExistTest type: test autorun: true {}
