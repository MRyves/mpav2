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

	init {
		write "Shared init called";
		do characteristicFileImport;
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

}



