/**
* Name: Shared
* Based on the internal empty template. 
* Author: Yves
*/
model Shared

import "Files.gaml"

/**
 * This model stores all the data which were read from the input files (see: Files.gaml) in memory and shares it with other models.
 * It is very important that this file does not import any other files other than "Files.gaml".
 * Otherwhise there would be a high risk of circular-dependency
 */
global {
/**
	 * The current weather in the simulation
	 */
	float currentWeather <- 0.5;

	/**
	 * Usage: used during mobility mode evaulation
	 */
	map<string, list<float>> charactPerMobility;
	/** key: mobility, value: speed in m/s */
	map<string, float> speedPerMobility;
	/** 
	 * Usage: if the weather is bad, humans pefer protected vehicles (car, bus etc...)
	 * key: mobility, value: weather coeff 
	 */
	map<string, float> weatherCoeffPerMobility;
	/** 
	 * Usage: calculate transport cost (see: Human.gaml)
	 * key: mobility, value: fix price in $
	 */
	map<string, float> fixedPricePerMobility;
	/** 
	 * Usage: calculate transport costs (see: Human.gaml)
	 * key: mobility, value: percentage price
	 */
	map<string, float> pricePerMobility;
	/** 
	 * Usage: calculate total waiting time per mobility (see: Human.gaml)
	 * key: mobility, value: fixed waiting time
	 */
	map<string, float> waitingPerMobility;
	/** 
	 * Usage: calculate total difficulty per mobility (see: Human.gaml)
	 * Yves note: I don't know what 'diffifulty' indicates here...
	 * key: mobility, value: some static float value
	 */
	map<string, float> difficultyPerMobility;
	/** 
	 * Usage: calculate total CO2 emissions (see: Human.gaml)
	 * key: mobility, value: factor value
	 */
	map<string, float> emissionPerMobility;
	/** 
	 * Usage: right now it is not really used, but it could be used
	 * to limit the allowed vehicles (mobility) per road.
	 * E.g.: a road could be to narrow for a truck
	 * key: mobilty, value: width in meters
	 */
	map<string, float> widthPerMobility;
	/** 
	 * Usage: right now it is not really used, but it could be used
	 * to display the roads in different colors, depending on the width of the road.
	 * See: Road.gaml > aspect mobility.
	 * key: mobility, value: color
 	 */
	map<string, rgb> colorPerMobility;
	/** 
	 * Usage: Stores the foundational data for all the activitys per type of human.
	 * Out of this map the activites for each human will be initialies. See: Human.gaml > createTripObjectives
	 * key: human type, value: map[
	 *		key: starting hour of the activity, value: 0..n activities (seperated by |)]
	 * 
	 */
	map<string, map<int, string>> activityData;
	/** Usage: stores the different graphs for each mobility. 
	* Right now the differenciation of each mobility type is not really used since all
	* roads allow all types of mobility. However, a map like this must be used once there are 
	* different types of roads (e.g.: pedestrian-roads, highways etc...).
	* key: mobility, value: graph
	* 
	*/
	map<string, graph> graphPerMobility;
	/** Usage: calculate the probability that a human would do a given activity (see: Human.gaml)
	* key: humanType, value: map[
	*		key: activity, value: probability of activiy]
	* 
	*/
	map<string, map<string, list<float>>> humanActivityProb <- map([]);
	/** Usage: proportion of different OD-Types of all the humans, used during human creation.
	* key: od type, value: proportion
	* 
	*/
	map<string, float> proportionPerOdType;
	/** 
	 * Usage: proportion of different human types, used during human creation.
	 * key: human type, value: propportion
	 * 
	 */
	map<string, float> proportionPerHumanType;
	/** 
	 * Usage: Used to decide wether a human has a bike or not. 
	 * Different types of humans have a different probability to own a bike. 
	 * Used during human creation. 
	 * key: human type, value: probability to own a bike
	 */
	map<string, float> bikePerTypeProba;
	/** Same as bikePerTypeProba, just for cars. */
	map<string, float> carPerTypeProba;
	/** 
	 * Usage: defines how many goods (either 'food' or 'packages') should generated.
	 * key: type of good (either 'food' or 'package'), value: map [
	 *		key: clock hour, value: amount which should be created
	 * 
	 */
	map<string, map<int, int>> goodsData;
	/** 
	 * Usage: randomly calculate the weather of the current day.
	 * key: month (1 to 12), value: {mean, std} of the weather coeff. 
	 */
	map<int, point> weatherCoffPerMonth;

	action initSharedValues {
		write "Shared init called. Reading data files...";
		do characteristicFileImport;
		do activityDataImport;
		do criteriaFileImport;
		do odTypeProportionImport;
		do profilesDataImport;
		do goodsDataImport;
		do weatherCoffPerMonthImport;
	}

	action characteristicFileImport {
		matrix modesMatrix <- matrix(modesFile);
		loop i from: 0 to: modesMatrix.rows - 1 {
			string mobilityType <- modesMatrix[0, i];
			if (mobilityType != "") {
				list<float> vals <- [];
				loop j from: 1 to: modesMatrix.columns - 2 {
					vals << float(modesMatrix[j, i]);
				}

				charactPerMobility[mobilityType] <- vals;
				colorPerMobility[mobilityType] <- rgb(modesMatrix[7, i]);
				widthPerMobility[mobilityType] <- float(modesMatrix[8, i]);
				speedPerMobility[mobilityType] <- float(modesMatrix[9, i]);
				weatherCoeffPerMobility[mobilityType] <- float(modesMatrix[10, i]);
				fixedPricePerMobility[mobilityType] <- float(modesMatrix[1, i]);
				pricePerMobility[mobilityType] <- float(modesMatrix[2, i]);
				waitingPerMobility[mobilityType] <- float(modesMatrix[3, i]);
				difficultyPerMobility[mobilityType] <- float(modesMatrix[6, i]);
				emissionPerMobility[mobilityType] <- float(modesMatrix[11, i]);
			}

		}

	}

	action activityDataImport {
		matrix activity_matrix <- matrix(activityPerProfileFile);
		loop i from: 1 to: activity_matrix.rows - 1 {
			string people_type <- activity_matrix[0, i];
			map<int, string> activities;
			string current_activity <- "";
			loop j from: 1 to: activity_matrix.columns - 1 {
				string act <- activity_matrix[j, i];
				if (act != current_activity) {
					activities[j] <- act;
					current_activity <- act;
				}

			}

			activityData[people_type] <- activities;
		}

		write activityData;
	}

	action criteriaFileImport {
		matrix criteria_matrix <- matrix(criteriaFile);
		int nbCriteria <- criteria_matrix[1, 0] as int;
		int nbTO <- criteria_matrix[1, 1] as int;
		int lignCategory <- 2;
		int lignCriteria <- 3;
		loop i from: 5 to: criteria_matrix.rows - 1 {
			string people_type <- criteria_matrix[0, i];
			int index <- 1;
			map<string, list<float>> m_temp <- map([]);
			if (people_type != "") {
				list<float> l <- [];
				loop times: nbTO {
					list<float> l2 <- [];
					loop times: nbCriteria {
						add float(criteria_matrix[index, i]) to: l2;
						index <- index + 1;
					}

					string cat_name <- criteria_matrix[index - nbTO, lignCategory];
					loop cat over: cat_name split_with "|" {
						add l2 at: cat to: m_temp;
					}

				}

				add m_temp at: people_type to: humanActivityProb;
			}

		}

	}

	action odTypeProportionImport {
		matrix od_profile_matrix <- matrix(odFile);
		int total_amount <- 0;
		loop i from: 0 to: od_profile_matrix.rows - 1 {
			string profil_type <- od_profile_matrix[0, i];
			if (profil_type != "") {
				total_amount <- total_amount + int(od_profile_matrix[1, i]);
			}

		}

		loop i from: 0 to: od_profile_matrix.rows - 1 {
			string profil_type <- od_profile_matrix[0, i];
			if (profil_type != "") {
				proportionPerOdType[profil_type] <- float(int(od_profile_matrix[1, i]) / total_amount);
			}

		}

	}

	action profilesDataImport {
		matrix profile_matrix <- matrix(profilesFile);
		loop i from: 0 to: profile_matrix.rows - 1 {
			string profil_type <- profile_matrix[0, i];
			if (profil_type != "") {
				carPerTypeProba[profil_type] <- float(profile_matrix[2, i]);
				bikePerTypeProba[profil_type] <- float(profile_matrix[3, i]);
				proportionPerHumanType[profil_type] <- float(profile_matrix[4, i]);
			}

		}

	}

	action goodsDataImport {
		matrix goods_matrix <- matrix(goodsTimeDistribution3File);
		loop i from: 1 to: goods_matrix.rows - 1 {
			string good_type <- goods_matrix[0, i];
			map<int, int> amount_dist;
			loop j from: 1 to: goods_matrix.columns - 1 {
				int amount <- int(goods_matrix[j, i]);
				amount_dist[j - 1] <- amount;
			}

			goodsData[good_type] <- amount_dist;
		}

	}

	action weatherCoffPerMonthImport {
		matrix weatherCoffMatrix <- matrix(weatherCoeffPerMonthFile);
		loop row from: 0 to: weatherCoffMatrix.rows - 1 {
			int month <- int(weatherCoffMatrix[0, row]);
			float mean <- float(weatherCoffMatrix[1, row]);
			float std <- float(weatherCoffMatrix[2, row]);
			weatherCoffPerMonth[month] <- point(mean, std);
		}

	}

}



