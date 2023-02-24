/**
* Name: Shared
* Based on the internal empty template. 
* Author: Yves
* Tags: 
*/
model Shared

import "Files.gaml"

/* Insert your model definition here */
global {
	map<string, list<float>> charactPerMobility;
	map<string, float> speedPerMobility;
	map<string, float> weatherCoeffPerMobility;
	map<string, float> fixedPricePerMobility;
	map<string, float> pricePerMobility;
	map<string, float> waitingPerMobility;
	map<string, float> difficultyPerMobility;
	map<string, float> emissionPerMobility;
	map<string, float> widthPerMobility;
	map<string, rgb> colorPerMobility;
	map<string, map<int, string>> activityData;
	map<string, graph> graphPerMobility;
	// key: humanType, value: map[key: activity, value: probability of activiy]
	map<string, map<string, list<float>>> humanActivityProb <- map([]);
	map<string, float> proportionPerOdType;
	map<string, float> proportionPerHumanType;
	map<string, float> bikePerTypeProba;
	map<string, float> carPerTypeProba;
	map<string,map<int,int>> goodsData;
	

	init {
	}

	action initSharedValues {
		write "Shared init called";
		do characteristicFileImport;
		do activityDataImport;
		do criteriaFileImport;
		do odTypeProportionImport;
		do profilesDataImport;
		do goodsDataImport;
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
		matrix goods_matrix <- matrix (goodsTimeDistribution3File);
		loop i from: 1 to:  goods_matrix.rows - 1 {
			string good_type <- goods_matrix[0,i];
			map<int, int> amount_dist;
			loop j from: 1 to:  goods_matrix.columns - 1 {
				int amount <- int(goods_matrix[j,i]);
				amount_dist[j-1] <- amount;
			}
			goodsData[good_type] <- amount_dist;
		}
	}

}



