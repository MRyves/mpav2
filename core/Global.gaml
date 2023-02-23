/**
* Name: Global
* Based on the internal empty template. 
* Author: Yves
* Tags: 
*/
model MPAV2

import "Constants.gaml"
import "Files.gaml"
import "Parameters.gaml"
import "Shared.gaml"
import "Actors/Road.gaml"

global {
	
	geometry shape <- envelope(roadsShapeFile);
	
	init {
		write "Global init called";
		
		create Road from: roadsShapeFile {
			mobilityAllowed <-["walking","bike","car","bus"];
			capacity <- shape.perimeter / 10.0;
			congestionMap [self] <- shape.perimeter;
		}
	}
}
