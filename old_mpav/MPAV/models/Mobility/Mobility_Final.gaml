/**
* Name: MobilityFinal
* Based on the internal empty template. 
* Author: Jiajie
* Tags: 
*/


model MobilityFinal

global {
	
	//PARAMETERS
	bool updatePollution <-false parameter: "Pollution:" category: "Simulation";
	bool updateDensity <-false parameter: "Density:" category: "Simulation";
	bool weatherImpact <-true parameter: "Weather impact:" category: "Simulation";
		
	// Added!!!!!! ONLINE PARAMETERS
	bool drawInteraction <- false;
	int distance <- 20;
	int refresh <- 10;
	bool dynamicGrid <- true;
	bool dynamicPop <- false;
	int refreshPop <- 100;
	int traceTime <- 100;
	int desired_cycle <- 8650;
	int refreshrate  <- 180;
	// Added!!!!!!, interaction_graph
	graph<people, people> interaction_graph;	
		
	
	//ENVIRONMENT
	float step <- 5 #mn;
	//float step <- 0.03 #mn;
	date starting_date <-date([2022,5,4,7,30]);
	string case_study <- "volpe" ;
	
	//PARAMETERS
	int nb_people <- 1000;
//	int nb_goods <- 60;
	int nb_stop <- 6;
	int nb_mpav <- 3;
	int mpav_ppl_capacity <- 0;
	int mpav_good_capacity <- 0;
	
	// MPAV vars
	string all_mpav_type;
	list<goods> mpav_waiting_goods;
	list<people> mpav_waiting_people; 
	
	// trip time monitor
	list<float> people_trip_time_total <- [];
	int people_trip_count <- 0;
	list<float> goods_trip_time_total <- [];
	int goods_trip_count <- 0;
	float mpav_idle <- 0.0;
	float mpav_working <- 0.0;

	
	
    string cityGISFolder <- "./../../includes/Mobility/"+case_study;
	file<geometry> buildings_shapefile <- file<geometry>(cityGISFolder+"/Buildings.shp");
	file<geometry> roads_shapefile <- file<geometry>(cityGISFolder+"/Roads.shp");
	geometry shape <- envelope(roads_shapefile);
	
	// MOBILITY DATA
	list<string> mobility_list <- ["walking", "bike","car","bus","mpav","truck"];
	file activity_file <- file("./../../includes/Mobility/ActivityPerProfile.csv");
	file goods_file <- file("./../../includes/Mobility/GoodsTimeDistribution3.csv");
	file criteria_file <- file("./../../includes/Mobility/CriteriaFile.csv");
	file profile_file <- file("./../../includes/Mobility/Profiles.csv");
	file od_profile_file <- file("./../../includes/Mobility/OD.csv");
	file mode_file <- file("./../../includes/Mobility/Modes.csv");
	file weather_coeff <- file("./../../includes/Mobility/weather_coeff_per_month.csv");
	
	map<string,rgb> color_per_category <- [ "Hub"::rgb("#8A4B4B"), "Restaurant"::rgb("#536A8D"), "Night"::rgb("#4B493E"),"GP"::rgb("#4B493E"), "Cultural"::rgb("#4B493E"), "Shopping"::rgb("#4B493E"), "HS"::rgb("#4B493E"), "Uni"::rgb("#4B493E"), "O"::rgb("#4B493E"), "R"::rgb("#222222"), "Park"::rgb("#68805F"), "SAT"::rgb("#4B493E"), "stop"::rgb("#4B493E")];	
	map<string,rgb> color_per_type <- [ "High School Student"::rgb("#FFFFB2"), "College student"::rgb("#FECC5C"),"Young professional"::rgb("#FD8D3C"),  "Mid-career workers"::rgb("#F03B20"), "Executives"::rgb("#BD0026"), "Home maker"::rgb("#0B5038"), "Retirees"::rgb("#8CAB13")];
	
	map<string,map<string,int>> activity_data_;
	map<string,map<int,string>> activity_data;
	map<string,map<int,int>> goods_data;
	map<string, float> proportion_per_type;
	map<string, float> proportion_per_od;
	map<string, float> proba_bike_per_type;
	map<string, float> proba_car_per_type;	
	map<string,rgb> color_per_mobility;
	map<string,float> width_per_mobility ;
	map<string,float> speed_per_mobility;
	map<string,graph> graph_per_mobility;
	map<string,float> weather_coeff_per_mobility;
	map<string,list<float>> charact_per_mobility;
	map<road,float> congestion_map;  
	map<string,map<string,list<float>>> weights_map <- map([]);
	list<list<float>> weather_of_month;
		//Added!!!
	map<string,float> fixed_price_per_mobility;
	map<string,float> price_per_mobility;
	map<string,float> waiting_per_mobility;	
	map<string,float> difficulty_per_mobility;		
	map<string,float> emission_per_mobility;

	
	// INDICATOR
	map<string,int> transport_type_cumulative_usage <- map(mobility_list collect (each::0));
	//Added!!!
	map<string,int> transport_type_daily_usage <- map(mobility_list collect (each::0));
	map<string,int> transport_type_cumulative_emission <- map(mobility_list collect (each::0));	
	map<string,int> transport_type_total_cost <- map(mobility_list collect (each::0));	
	map<string,int> transport_type_total_waiting <- map(mobility_list collect (each::0));
	map<string,int> transport_type_total_difficulty <- map(mobility_list collect (each::0));	
	map<string,int> transport_type_total_distance <- map(mobility_list collect (each::0));
	map<string,int> transport_type_total_distance_people <- map(mobility_list collect (each::0));
	map<string,int> transport_type_total_distance_goods <- map(mobility_list collect (each::0));
	map<string,int> transport_type_usage <- map(mobility_list collect (each::0));
	map<string,float> transport_type_distance <- map(mobility_list collect (each::0.0)) + ["bus_people"::0.0];
	map<string, int> buildings_distribution <- map(color_per_category.keys collect (each::0));
	
//	float weather_of_day min: 0.0 max: 1.0;	
	float weather_of_day <- 0.5;	
	
	init {
		gama.pref_display_flat_charts <- true;
		do import_shapefiles;	
		do profils_data_import;
		do od_proportion_import;
		do activity_data_import;
		do goods_data_import;
		do criteria_file_import;
		do characteristic_file_import;
		do import_weather_data;
		do compute_graph;
		do init_bus_stop;


		create goods_warehouse number: 1 {
			place <- one_of(building where (each.usage = "Hub"));
		}
		
		
//		!!! Define MPAV!
		create mpav number: nb_mpav{
			current_target <- nil;
			time_stamp <- time;
			mpav_type <- all_mpav_type;
			location <- one_of(building where (each.usage = "Hub")).location;
			
//??		Delivery Truck! GAS!!
			if mpav_type = "Truck" {
				mpav_speed <- speed_per_mobility["car"];
				max_nb_people <- 0;
				max_nb_goods <- 50;
			} else
			
//			!! Big AV
			if mpav_type = "MPAV" {
				mpav_speed <- speed_per_mobility["bike"];
				max_nb_people <- 4;
				max_nb_goods <- 10;
			} else
			
//			!! Small AV
			if mpav_type = "PEV" {
				mpav_speed <- speed_per_mobility["bike"];
				max_nb_people <- 1;
				max_nb_goods <- 3;
			}
		}
		
		create bus number: 1 {
			stops <- list(bus_stop);
			location <- first(stops).location;
			stop_passengers <- map<bus_stop, list<people>>(stops collect(each::[]));
		}		
		
		create people number: nb_people {
			od <- proportion_per_od.keys[rnd_choice(proportion_per_od.values)];
			type <- proportion_per_type.keys[rnd_choice(proportion_per_type.values)];
			has_car <- flip(proba_car_per_type[type]);
			has_bike <- flip(proba_bike_per_type[type]);
			if od = 'out2ks' {
				living_place <- one_of(building where (each.usage = "SAT"));
			} else {
				living_place <- one_of(building where (each.usage = "R"));
			}
			current_place <- living_place;
			location <- any_location_in(living_place);
			closest_bus_stop <- bus_stop with_min_of(each distance_to(self));
			closest_building <- building with_min_of(each distance_to(self));
			do create_trip_objectives;
		}
		
		do generate_goods;
		//Editing	
		save "cycle,walking,bike,car,bus,average_speed,walk_distance,bike_distance,car_distance,bus_distance, bus_people_distance" to: "../results/mobility.csv";
	}
	
    reflex save_simu_attribute when: (cycle mod 100 = 0){
//    	save [cycle,transport_type_usage.values[0] ,transport_type_usage.values[1], transport_type_usage.values[2], transport_type_usage.values[3], mean (people collect (each.speed)), transport_type_distance.values[0],transport_type_distance.values[1],transport_type_distance.values[2],transport_type_distance.values[3],transport_type_distance.values[4]] rewrite:false to: "../results/mobility.csv" type:"csv";
	    // Reset value
	    transport_type_usage <- map(mobility_list collect (each::0));
	    transport_type_distance <- map(mobility_list collect (each::0.0)) + ["bus_people"::0.0];
	    // Added!!!! desired_cycle
	    if(cycle = desired_cycle){
	    	do pause;
	    }
	}
	
	action import_weather_data {
		matrix weather_matrix <- matrix(weather_coeff);
		loop i from: 0 to:  weather_matrix.rows - 1 {
			weather_of_month << [float(weather_matrix[1,i]), float(weather_matrix[2,i])];
		}
	}
	
	action profils_data_import {
		matrix profile_matrix <- matrix(profile_file);
		loop i from: 0 to:  profile_matrix.rows - 1 {
			string profil_type <- profile_matrix[0,i];
			if(profil_type != "") {
				proba_car_per_type[profil_type] <- float(profile_matrix[2,i]);
				proba_bike_per_type[profil_type] <- float(profile_matrix[3,i]);
				proportion_per_type[profil_type] <- float(profile_matrix[4,i]);
			}
		}
	}
	
	
	
	action init_bus_stop {
		loop b over: building where (each.category = "stop") {
			create bus_stop number: 1 {			
				location <- b.location;
			}
		}
	}
	
	action od_proportion_import {
		matrix od_profile_matrix <- matrix(od_profile_file);
		int total_amount <- 0;
		loop i from: 0 to:  od_profile_matrix.rows - 1 {
			string profil_type <- od_profile_matrix[0,i];
			if(profil_type != "") {
				total_amount <- total_amount + int(od_profile_matrix[1,i]);
			}
		}
		loop i from: 0 to:  od_profile_matrix.rows - 1 {
			string profil_type <- od_profile_matrix[0,i];
			if(profil_type != "") {
				proportion_per_od[profil_type] <- float(int(od_profile_matrix[1,i]) / total_amount);
			}
		}
	}
	
	action activity_data_import {
		matrix activity_matrix <- matrix (activity_file);
		loop i from: 1 to:  activity_matrix.rows - 1 {
			string people_type <- activity_matrix[0,i];
			map<int, string> activities;
			string current_activity <- "";
			loop j from: 1 to:  activity_matrix.columns - 1 {
				string act <- activity_matrix[j,i];

				if (act != current_activity) {
					activities[j] <-act;
					current_activity <- act;
				}
			}
			activity_data[people_type] <- activities;
		}
	}
	
	action goods_data_import {
		matrix goods_matrix <- matrix (goods_file);
		loop i from: 1 to:  goods_matrix.rows - 1 {
			string good_type <- goods_matrix[0,i];
			map<int, int> amount_dist;
			loop j from: 1 to:  goods_matrix.columns - 1 {
				int amount <- int(goods_matrix[j,i]);
				amount_dist[j-1] <- amount;
			}
			goods_data[good_type] <- amount_dist;
		}
	}
	
	action criteria_file_import {
		matrix criteria_matrix <- matrix (criteria_file);
		int nbCriteria <- criteria_matrix[1,0] as int;
		int nbTO <- criteria_matrix[1,1] as int ;
		int lignCategory <- 2;
		int lignCriteria <- 3;
		
		loop i from: 5 to:  criteria_matrix.rows - 1 {
			string people_type <- criteria_matrix[0,i];
			int index <- 1;
			map<string, list<float>> m_temp <- map([]);
			if(people_type != "") {
				list<float> l <- [];
				loop times: nbTO {
					list<float> l2 <- [];
					loop times: nbCriteria {
						add float(criteria_matrix[index,i]) to: l2;
						index <- index + 1;
					}
					string cat_name <-  criteria_matrix[index-nbTO,lignCategory];
					loop cat over: cat_name split_with "|" {
						add l2 at: cat to: m_temp;
					}
				}
				add m_temp at: people_type to: weights_map;
			}
		}
	}
	
	action characteristic_file_import {
		matrix mode_matrix <- matrix (mode_file);
		loop i from: 0 to:  mode_matrix.rows - 1 {
			string mobility_type <- mode_matrix[0,i];
			if(mobility_type != "") {
				list<float> vals <- [];
				loop j from: 1 to:  mode_matrix.columns - 2 {
					vals << float(mode_matrix[j,i]);	
				}
				charact_per_mobility[mobility_type] <- vals;
				color_per_mobility[mobility_type] <- rgb(mode_matrix[7,i]);
				width_per_mobility[mobility_type] <- float(mode_matrix[8,i]);
				speed_per_mobility[mobility_type] <- float(mode_matrix[9,i]);
				weather_coeff_per_mobility[mobility_type] <- float(mode_matrix[10,i]);
				
				//Added!!!!!
				fixed_price_per_mobility[mobility_type] <- float(mode_matrix[1,i]);
				price_per_mobility[mobility_type] <- float(mode_matrix[2,i]);
				waiting_per_mobility[mobility_type] <- float(mode_matrix[3,i]);
				difficulty_per_mobility[mobility_type] <- float(mode_matrix[6,i]);
				emission_per_mobility[mobility_type] <- float(mode_matrix[11,i]);

				
			}
		}
	}
		
	action import_shapefiles {
		create road from: roads_shapefile {
			mobility_allowed <-["walking","bike","car","bus"];
			capacity <- shape.perimeter / 10.0;
			congestion_map [self] <- shape.perimeter;
		}
		create building from: buildings_shapefile with: [usage::string(read ("Usage")),scale::string(read ("Scale")),category::string(read ("Category"))]{
			color <- color_per_category[category];
		}
	}
		
	action compute_graph {
		loop mobility_mode over: color_per_mobility.keys {
			graph_per_mobility[mobility_mode] <- as_edge_graph(road where (mobility_mode in each.mobility_allowed)) use_cache false;	
		}
	}
		
	reflex cyclic_generate_goods when: every(1#hour){
		do generate_goods;
	}
	
	action generate_goods {
		create goods number: goods_data["foods"][current_date.hour] {
			type <- "foods";
			objective <- one_of(building where (each.category != "Hub"));
			do init_pos;
		}
		create goods number: goods_data["packages"][current_date.hour] {
			type <- "packages";
			objective <- one_of(building where (each.usage != "Restaurant"));
			do init_pos;
		}
	}
	
	reflex update_road_weights {
		ask road {
			do update_speed_coeff;	
			congestion_map [self] <- speed_coeff;
		}
	}
	
	reflex update_buildings_distribution{
		buildings_distribution <- map(color_per_category.keys collect (each::0));
		ask building{
			buildings_distribution[usage] <- buildings_distribution[usage]+1;
		}
	}
	
//	reflex update_weather when: weatherImpact and every(#day){
//		list<float> weather_m <- weather_of_month[current_date.month - 1];
//		weather_of_day <- gauss(weather_m[0], weather_m[1]);
//	}		
	
		// Added, drawInteraction
	reflex updateGraph when: (drawInteraction = true) {
		interaction_graph <- graph<people, people>(people as_distance_graph (distance));
	}
}

species trip_objective{
	building place; 
	int starting_hour;
	int starting_minute;
}

species bus_stop {
	list<people> waiting_people;
	
	aspect c {
		draw hexagon(20) color: empty(waiting_people)?#white:#red border: #white depth:1;
	}
}

species goods_warehouse {
	building place;
	aspect c {
		draw place.shape color: rgb("#8A4B4B");
	}
}

species goods {
	string type;
	rgb color;
	float size<-10#m;
	// TODO[Yves]: rename to 'target'
	building objective;
	building origin;
	float time_stamp;
	
	action init_pos {
		if type = "foods" {
			origin <- one_of(building where (each.category = "Restaurant"));
			location <- any_location_in(origin);
		} else {
			origin <- one_of(building where (each.usage = "Hub"));
			location <- any_location_in(origin);
		}
		mpav_waiting_goods << self;
		time_stamp <- time;
	}

//	reflex disapear when: location = objective.location {
//		do die;
//	}
	
	action timer_stop {
		goods_trip_time_total << time - time_stamp;
		time_stamp <- time;
//		goods_trip_time_total <- goods_trip_time_total + time - time_stamp;
//		goods_trip_count <- goods_trip_count + 1;
	}
	
	aspect default { 
		if (type = "foods") {
			draw triangle(size*1.2) color: #yellow  ;
		} else {
			draw triangle(size*1.2) color: #aqua ;
		}
	}
}

species mpav skills: [moving]{
	geometry mpav_shape;
	list<goods> carried_goods;
	list<people> carried_people;
	building current_target <- nil;
	float time_stamp;
	
	// mpav type
	string mpav_type;
	float mpav_speed;
	int max_nb_people;
	int max_nb_goods;
	
	reflex new_target when: current_target = nil {
		list<building> target_list <- [];
		loop g over: carried_goods collect each.objective {
			target_list << g;
		}
		loop g over: mpav_waiting_goods collect each.origin {
			if length(carried_goods) >= max_nb_goods{
					break;
			}
			target_list << g;
		}
		loop p over: carried_people collect each.my_current_objective.place {
			target_list << p;
		}
		loop p over: mpav_waiting_people collect each.closest_building {
			if length(carried_people) >= max_nb_people{
					break;
			}
			target_list << p;
		}
		current_target <- target_list with_min_of(each distance_to(self));
		
		do turn_to_work_statue;
	}
	
	reflex r when: current_target != nil{
		do goto target: current_target.location on: graph_per_mobility["car"] speed:mpav_speed;
	
		if (length(carried_goods)+length(carried_people)) > 0 {
			if max_nb_people = 0 {
				transport_type_distance["truck"] <- transport_type_distance["truck"] + speed/step;
			} else {
				transport_type_distance["mpav"] <- transport_type_distance["mpav"] + speed/step;
			}
		}
		
		if(location = current_target.location) {
			do turn_to_idle_statue;
			
			loop g over: carried_goods where ((each.objective = current_target)) {
				remove g from: carried_goods;
				ask g {
					do timer_stop;
					do die;
				}
			}
			
			loop g over: mpav_waiting_goods where ((each.origin = current_target)){
				remove g from: mpav_waiting_goods;
				add g to: carried_goods; 
				if length(carried_goods) >= max_nb_goods{
					break;
				}
			}
			
			loop p over: carried_people where ((each.my_current_objective.place = current_target)) {
				remove p from: carried_people;
				ask p {
					location <- myself.current_target.location;
					mpav_status <- 2;
				}
			}
			
			loop p over: mpav_waiting_people where ((each.closest_building = current_target)){
				remove p from: mpav_waiting_people;
				add p to: carried_people; 
				if length(carried_people) >= max_nb_people{
					break;
				}
			}
			
			current_target <- nil;
		} 
	}
	
	reflex carry {
		mpav_shape <- rectangle(45,30);
		loop g over: carried_goods {
			ask g {
				location <- any_location_in(myself.mpav_shape);
			}
		}
		loop p over: carried_people {
			ask p {
				location <- any_location_in(myself.mpav_shape);
			}
		}
	}
	
	action turn_to_work_statue {
		mpav_idle <- mpav_idle + time - time_stamp;
		time_stamp <- time;
	}
	
	action turn_to_idle_statue {
		mpav_working <- mpav_working + time - time_stamp;
		time_stamp <- time;
	}
	
	aspect default {
		draw mpav_shape color: #green;
	}
}



// BUS!!
species bus skills: [moving] {
	list<bus_stop> stops; 
	map<bus_stop,list<people>> stop_passengers ;
	geometry bus_shape;
	
 
	bus_stop my_target;
	
	reflex new_target when: my_target = nil{
		bus_stop firstStop <- first(stops);
		remove firstStop from: stops;
		add firstStop to: stops; 
		my_target <- firstStop;
	}
	
	reflex r when: my_target != nil{
		do goto target: my_target.location on: graph_per_mobility["car"] speed:speed_per_mobility["bus"];
		int nb_passengers <- stop_passengers.values sum_of (length(each));
		if (nb_passengers > 0) {
				transport_type_distance["bus"] <- transport_type_distance["bus"] + speed/step;
				transport_type_distance["bus_people"] <- transport_type_distance["bus_people"] + speed/step * nb_passengers;
		} 
			
		if(location = my_target.location) {
			////////      release some people
			ask stop_passengers[my_target] {
				location <- myself.my_target.location;
				bus_status <- 2;
			}
			stop_passengers[my_target] <- [];
			
			/////////     get some people
			loop p over: my_target.waiting_people {
				bus_stop b <- bus_stop with_min_of(each distance_to(p.my_current_objective.place.location));
				add p to: stop_passengers[b] ;
			}
			my_target.waiting_people <- [];						
			my_target <- nil;			
		}
	}

	reflex carry {
		bus_shape <- rectangle(40,30);
		loop stop over: stops {
			ask stop_passengers[stop] {
				location <- any_location_in(myself.bus_shape);
			}
		}
	}
	
	aspect bu {
		draw bus_shape color: #darkcyan;
	}
}

grid gridHeatmaps height: 50 width: 50 {
	int pollution_level <- 0 ;
	int density<-0;
	rgb pollution_color <- rgb(pollution_level*10,0,0) update:rgb(pollution_level*10,0,0);
	rgb density_color <- rgb(255-density*50,255-density*50,255-density*50) update:rgb(255-density*50,255-density*50,255-density*50);
	
	aspect density{
		draw shape color:density_color at:{location.x+current_date.hour*world.shape.width,location.y};
	}
	
	aspect pollution{
		draw shape color:pollution_color;
	}
//	
//	reflex raz when: every(1#hour) {
//		pollution_level <- 0;
//	}
}

species people skills: [moving]{
	string od;
	string type;
	rgb color ;
	float size<-5#m;	
	building living_place;
	list<trip_objective> objectives;
	trip_objective my_current_objective;
	building current_place;
	string mobility_mode;
	list<string> possible_mobility_modes;
	bool has_car ;
	bool has_bike;

	bus_stop closest_bus_stop;	
	building closest_building;
	int bus_status <- 0;
	int mpav_status <- 0;
	
	float time_stamp;
	
	action create_trip_objectives {
		map<int, string> activities <- activity_data[type];
		loop t over: activities.keys {
			string act <- activities[t];
			if (act != "") {
				list<string> parse_act <- act split_with "|";
				string act_real <- one_of(parse_act);

				list<building> possible_bds;
				if (length(act_real) = 2) and (first(act_real) = "R") {
					if od = "out2ks" {
						possible_bds <- building where ((each.usage = "SAT"));
					} else {
						possible_bds <- building where ((each.usage = "R") and (each.scale = last(act_real)));
					}
				} 
				else if (length(act_real) = 2) and (first(act_real) = "O") {
					if od = "ks2out" {
						possible_bds <- building where ((each.usage = "SAT"));
					} else {
						possible_bds <- building where ((each.usage = "O") and (each.scale = last(act_real)));
					}
				} 
				else {
					possible_bds <- building where (each.category = act_real);
				}
				
				building act_build <- one_of(possible_bds);
				if (act_build= nil) {write "problem with act_real: " + act_real;}
				do create_activity(act_real,act_build,t);
			}
		}
	}
	
	action create_activity(string act_name, building act_place, int act_time) {
		create trip_objective {
			name <- act_name;
			place <- act_place;
			starting_hour <- act_time;
			starting_minute <- rnd(60);
			myself.objectives << self;
		}
	} 

	action choose_mobility_mode {
		list<list> cands <- mobility_mode_eval();
		map<string,list<float>> crits <-  weights_map[type];
		list<float> vals ;
		loop obj over:crits.keys {
			if (obj = my_current_objective.name) or
			 ((my_current_objective.name in ["RS", "RM", "RL"]) and (obj = "R"))or
			 ((my_current_objective.name in ["OS", "OM", "OL"]) and (obj = "O")){
				vals <- crits[obj];
				break;
			} 
		}
		list<map> criteria_WM;
		loop i from: 0 to: length(vals) - 1 {
			criteria_WM << ["name"::"crit"+i, "weight" :: vals[i]];
		}
		int choice <- weighted_means_DM(cands, criteria_WM);
		if (choice >= 0) {
			mobility_mode <- possible_mobility_modes [choice];
		} else {
			mobility_mode <- one_of(possible_mobility_modes);
		}
		transport_type_cumulative_usage[mobility_mode] <- transport_type_cumulative_usage[mobility_mode] + 1;
		transport_type_usage[mobility_mode] <-transport_type_usage[mobility_mode]+1;
		speed <- speed_per_mobility[mobility_mode];
		
		// Added!!!!!!!!!!!, calculate statistics
		
		transport_type_daily_usage[mobility_mode] <- transport_type_daily_usage[mobility_mode]*min(mod(current_date.hour+2,24),1) + 1;
		transport_type_daily_usage['walking'] <- transport_type_daily_usage['walking']*min(mod(current_date.hour+2,24),1) + 1;
		transport_type_daily_usage['bus'] <- transport_type_daily_usage['bus']*min(mod(current_date.hour+2,24),1) + 1;		
		// Added!!!!!!!!!!!, calculate statistics
		transport_type_cumulative_emission[mobility_mode] <- transport_type_cumulative_emission[mobility_mode] + emission_per_mobility[mobility_mode]*speed_per_mobility[mobility_mode];
		transport_type_total_cost[mobility_mode] <- transport_type_total_cost[mobility_mode] + fixed_price_per_mobility[mobility_mode] + price_per_mobility[mobility_mode] * speed_per_mobility[mobility_mode];
		transport_type_total_waiting[mobility_mode] <- transport_type_total_waiting[mobility_mode] + waiting_per_mobility[mobility_mode];
		transport_type_total_difficulty[mobility_mode] <- transport_type_total_difficulty[mobility_mode] + difficulty_per_mobility[mobility_mode];	
		transport_type_total_distance[mobility_mode] <- transport_type_total_distance[mobility_mode] + speed_per_mobility[mobility_mode];
		transport_type_total_distance_goods[mobility_mode] <- transport_type_total_distance['MPAV'] + speed_per_mobility['MPAV'];		
	}
	
	
	list<list> mobility_mode_eval {
		list<list> candidates;
		loop mode over: possible_mobility_modes {
			list<float> characteristic <- charact_per_mobility[mode];
			list<float> cand;
			float distance <-  0.0;
			using topology(graph_per_mobility[mode]){
				distance <-  distance_to (location,my_current_objective.place.location);
			}
			if (self.od != 'ks2ks') {
			cand << characteristic[0] + characteristic[1]*(distance);
			cand << characteristic[2] #mn +  distance / speed_per_mobility[mode];
			} else {
			cand << characteristic[0] + characteristic[1]*(distance + 10);
			cand << characteristic[2] #mn +  (distance + 10) / speed_per_mobility[mode];
			} 
//			cand << characteristic[0] + characteristic[1]*(distance + 30);
//			cand << characteristic[2] #mn +  distance / speed_per_mobility[mode];
			cand << characteristic[4];
			cand << characteristic[5] * (weatherImpact ?(1.0 + weather_of_day * weather_coeff_per_mobility[mode]  ) : 1.0);
			add cand to: candidates;
		}
		
		//normalisation
		list<float> max_values;
		loop i from: 0 to: length(candidates[0]) - 1 {
			max_values << max(candidates collect abs(float(each[i])));
		}
		loop cand over: candidates {
			loop i from: 0 to: length(cand) - 1 {
				if ( max_values[i] != 0.0) {cand[i] <- float(cand[i]) / max_values[i];}
				
			}
		}
		return candidates;
	}
	
	action updatePollutionMap{
		ask gridHeatmaps overlapping(current_path.shape) {
			pollution_level <- pollution_level + 1;
		}
	}		
	
	reflex updateDensityMap when: (every(#hour) and updateDensity=true){
		ask gridHeatmaps{
		  density<-length(people overlapping self);	
		}
	}
	
	reflex choose_objective when: my_current_objective = nil {
		do wander speed:0.01;
		my_current_objective <- objectives first_with ((each.starting_hour = current_date.hour) and (current_date.minute >= each.starting_minute) and (current_place != each.place) );
		if (my_current_objective != nil) {
			current_place <- nil;
			possible_mobility_modes <- ["walking"];
			if (has_car) {possible_mobility_modes << "car";}
			if (has_bike) {possible_mobility_modes << "bike";}
			possible_mobility_modes << "bus";	
			if all_mpav_type != "Truck" {
				possible_mobility_modes << "mpav";	
			}
//			possible_mobility_modes <- ["bus"];	
			do choose_mobility_mode;
			do timer_start;
		}
	}
	reflex move when: (my_current_objective != nil) and (mobility_mode != "bus") and (mobility_mode != "mpav"){
		transport_type_distance[mobility_mode] <- transport_type_distance[mobility_mode] + speed/step;
		
		if ((current_edge != nil) and (mobility_mode in ["car"])) {road(current_edge).current_concentration <- max([0,road(current_edge).current_concentration - 1]); }
		
		if (mobility_mode in ["car"]) {
			do goto target: my_current_objective.place.location on: graph_per_mobility[mobility_mode] move_weights: congestion_map speed:speed_per_mobility["car"];
		}else {
			do goto target: my_current_objective.place.location on: graph_per_mobility[mobility_mode] speed:speed_per_mobility[mobility_mode];
		}
		
		if (location = my_current_objective.place.location) {
			do timer_stop;
			if(mobility_mode = "car" and updatePollution = true) {do updatePollutionMap;}					
				current_place <- my_current_objective.place;
				location <- any_location_in(current_place);
				my_current_objective <- nil;	
				mobility_mode <- nil;
			} else {
				if ((current_edge != nil) and (mobility_mode in ["car"])) {road(current_edge).current_concentration <- road(current_edge).current_concentration + 1; }
			}
	}
	
	reflex move_bus when: (my_current_objective != nil) and (mobility_mode = "bus") {

//		bus_status=0 时从起始点走去公交车站 
		if (bus_status = 0){
			do goto target: closest_bus_stop.location on: graph_per_mobility["walking"]
			speed:speed_per_mobility["walking"];
			transport_type_distance["walking"] <- transport_type_distance["walking"] + speed/step;
			
//			bus_status=1 到公交站了，加入等候list
			if(location = closest_bus_stop.location) {
				add self to: closest_bus_stop.waiting_people;
				bus_status <- 1;
			}
			
//		bus_status=2 时从公交车站走去目的地
		} else if (bus_status = 2){
			do goto target: my_current_objective.place.location on: graph_per_mobility["walking"]
			speed:speed_per_mobility["walking"];		
			transport_type_distance["walking"] <- transport_type_distance["walking"] + speed/step;
			
//			到目的地了，重设参数
			if (location = my_current_objective.place.location) {
				do timer_stop;
				current_place <- my_current_objective.place;
				closest_bus_stop <- bus_stop with_min_of(each distance_to(self));						
				location <- any_location_in(current_place);
				my_current_objective <- nil;	
				mobility_mode <- nil;
				bus_status <- 0;
			}
		}
	}	
	
	reflex move_mpav when: (my_current_objective != nil) and (mobility_mode = "mpav")  {

		if (mpav_status = 0){
			do goto target: closest_building.location on: graph_per_mobility["walking"] speed:speed_per_mobility["walking"];
			transport_type_distance["walking"] <- transport_type_distance["walking"] + speed/step;
			
			if(location = closest_building.location) {
				add self to: mpav_waiting_people;
				mpav_status <- 1;
			}
		} else if (mpav_status = 2){
			do goto target: my_current_objective.place.location on: graph_per_mobility["walking"] speed:speed_per_mobility["walking"];		
			transport_type_distance["walking"] <- transport_type_distance["walking"] + speed/step;
			
			if (location = my_current_objective.place.location) {
				do timer_stop;
				current_place <- my_current_objective.place;
				closest_building <- building with_min_of(each distance_to(self));						
				location <- any_location_in(current_place);
				my_current_objective <- nil;	
				mobility_mode <- nil;
				bus_status <- 0;
			}
		}
	}	
	
	action timer_start {
		time_stamp <- time;
	}
	
	action timer_stop {
		people_trip_time_total << time - time_stamp;
		time_stamp <- time;
//		people_trip_time_total <- goods_trip_time_total + time - time_stamp;
//		people_trip_count <- goods_trip_count + 1;
	}
	
	aspect default {
		if (mobility_mode = nil) {
			draw circle(size) at: location + {0,0,(current_place != nil ?current_place.height : 0.0) + 4}  color: #grey ;
		} else {
			if (mobility_mode = "walking") {
				draw circle(size) color: #lightyellow  ;
			}else if (mobility_mode = "bike") {
				draw circle(size) color: #white ;
			} else if (mobility_mode = "car") {
				draw circle(size)  color: #red ;
			} else if (mobility_mode = "mpav") {
				draw circle(size)  color: #lime ;
			} else if (mobility_mode = "bus") {
				draw circle(size)  color: #cyan ;
			}
		}
	}
	
	aspect base{
	  draw circle(size) at: location + {0,0,(current_place != nil ?current_place.height : 0.0) + 4}  color: #grey ;
	}
	aspect layer {
		if(cycle mod refreshrate = 0){
			draw sphere(size) at: {location.x,location.y,cycle*2} color: #white ;
		}
	}
}




species road  {
	list<string> mobility_allowed;
	float capacity;
	float max_speed <- 30 #km/#h;
	float current_concentration;
	float speed_coeff <- 1.0;
	
	action update_speed_coeff {
		speed_coeff <- shape.perimeter / max([0.01,exp(-current_concentration/capacity)]);
	}
	
	aspect default {		
		draw shape color:rgb(125,125,125);
	}
	
	aspect mobility {
		string max_mobility <- mobility_allowed with_max_of (width_per_mobility[each]);
		draw shape width: width_per_mobility[max_mobility] color:color_per_mobility[max_mobility] ;
	}
	
	user_command to_pedestrian_road {
		mobility_allowed <- ["walking", "bike"];
		ask world {do compute_graph;}
	}
}




species building {
	string usage;
	string scale;
	string category;
	rgb color <- #grey;
	float height <- 0.0;//50.0 + rnd(50);
	aspect default {
		draw shape color: color ;
	}
	aspect depth {
		draw shape color: color  depth: height;
	}
}

species externalCities parent:building{
	string id;
	point real_location;
	point entry_location;
	list<float> people_distribution;
	list<float> building_distribution;
	list<building> external_buildings;
	
	aspect base{
		draw circle(100) color:#yellow at:real_location;
		draw circle(100) color:#red at:entry_location;
	}
}

experiment MobilityFinal type: gui {
	
	// ONLINE PARAMETERS
	parameter "Draw Interaction:"  var: drawInteraction category: "Interaction";
	parameter "Distance:" var:distance category: "Interaction" min: 1 max: 100;
	parameter "Total Cycle:" var:desired_cycle category: "Simulation" min: 1000 max: 10000;
	parameter "Refresh Rate:" var:refreshrate category: "Simulation" min: 1 max: 200;
	parameter "Steps per minute:" var:step category: "Simulation" min: 0.001 max: 10.000;
	
	// Input
	parameter 'people' var: nb_people category:'Input Parameter' min:1 max:100000;
//	parameter 'step' var: step category:'Input Parameter';
	parameter 'num of bus stops' var: nb_stop category:'Input Parameter';
	
	// MPAV Parameters
	parameter 'Type of MPAV' var: all_mpav_type among:["Truck", "MPAV", "PEV"] init: "MPAV" category:'MPAV Parameter';
	
	output {
		display map type: opengl draw_env: false background: #black refresh:every(1#cycle){
			// Map
			species gridHeatmaps aspect:pollution;
			//species pie;
			species building aspect:depth refresh: true;
			species road ;		
			
			species bus_stop aspect:c;
			species goods_warehouse aspect:c;
			
			species bus aspect:bu;
			species mpav aspect:default;
			
			species people aspect:default ;
			species goods aspect:default ;
			species externalCities aspect:base;
					
			// Clock			
			graphics "time" {
				draw string(current_date.hour) + "h" + string(current_date.minute) +"m" color: # white font: font("Helvetica", 25, #italic) at: {world.shape.width*0.9,world.shape.height*0.55};
			}
			
			// Added!!!!!!!!!_Draw Interaction
			graphics "interaction_graph" {
				if (interaction_graph != nil and (drawInteraction = true)) {
					loop eg over: interaction_graph.edges {
						people src <- interaction_graph source_of eg;
						people target <- interaction_graph target_of eg;
						geometry edge_geom <- geometry(eg);
						draw line(edge_geom.points) color: # white;
					}
				}
			}			
		/* 	
			// Legends
			overlay position: { 5, 5 } size: { 240 #px, 680 #px } background: # black transparency: 1.0 border: #black 
            {
            	
                rgb text_color<-#white;
                float y <- 30#px;
  				draw "Building Usage" at: { 40#px, y } color: text_color font: font("Helvetica", 20, #bold) perspective:false;
                y <- y + 30 #px;
                loop type over: color_per_category.keys
                {
                    draw square(10#px) at: { 20#px, y } color: color_per_category[type] border: #white;
                    draw type at: { 40#px, y + 4#px } color: text_color font: font("Helvetica", 16, #plain) perspective:false;
                    y <- y + 25#px;
                }
                 y <- y + 30 #px;     
                draw "People Type" at: { 40#px, y } color: text_color font: font("Helvetica", 20, #bold) perspective:false;
                y <- y + 30 #px;
                loop type over: color_per_type.keys
                {
                    draw square(10#px) at: { 20#px, y } color: color_per_type[type] border: #white;
                    draw type at: { 40#px, y + 4#px } color: text_color font: font("Helvetica", 16, #plain) perspective:false;
                    y <- y + 25#px;
                }
				y <- y + 30 #px;
                draw "Mobility Mode" at: { 40#px, 600#px } color: text_color font: font("Helvetica", 20, #bold) perspective:false;
                map<string,rgb> list_of_existing_mobility <- map<string,rgb>(["Walking"::#green,"Bike"::#yellow,"Car"::#red,"Bus"::#blue]);
                y <- y + 30 #px;
                
                loop i from: 0 to: length(list_of_existing_mobility) -1 {    
                  // draw circle(10#px) at: { 20#px, 600#px + (i+1)*25#px } color: list_of_existing_mobility.values[i]  border: #white;
                   draw list_of_existing_mobility.keys[i] at: { 40#px, 610#px + (i+1)*20#px } color: list_of_existing_mobility.values[i] font: font("Helvetica", 18, #plain) perspective:false; 			
		        }     
            }
            */
            // Charts
            chart "Cumulative Trip" background:#black type: pie style:ring size: {0.5,0.5} position: {world.shape.width*1.1,world.shape.height*0} color: #white axes: #yellow title_font: 'Helvetica' title_font_size: 12.0 
			tick_font: 'Monospaced' tick_font_size: 10 tick_font_style: 'bold' label_font: 'Arial' label_font_size: 32 label_font_style: 'bold' x_label: 'Nice Xlabel' y_label:'Nice Ylabel'
			{
				loop i from: 0 to: length(transport_type_cumulative_usage.keys)-1	{
				  data transport_type_cumulative_usage.keys[i] value: transport_type_cumulative_usage.values[i] color:color_per_mobility[transport_type_cumulative_usage.keys[i]];
				}
			}
			chart "People Distribution" background:#black  type: pie size: {0.5,0.5} position: {world.shape.width*1.1,world.shape.height*0.5} color: #white axes: #yellow title_font: 'Helvetica' title_font_size: 12.0 
			tick_font: 'Helvetica' tick_font_size: 10 tick_font_style: 'bold' label_font: 'Helvetica' label_font_size: 32 label_font_style: 'bold' x_label: 'Nice Xlabel' y_label:'Nice Ylabel'
			{
				loop i from: 0 to: length(proportion_per_type.keys)-1	{
				  data proportion_per_type.keys[i] value: proportion_per_type.values[i] color:color_per_type[proportion_per_type.keys[i]];
				}
			}
			chart "People OD Distribution" background:#black  type: pie size: {0.5,0.5} position: {world.shape.width*1.1,world.shape.height*1} color: #white axes: #yellow title_font: 'Helvetica' title_font_size: 12.0 
			tick_font: 'Helvetica' tick_font_size: 10 tick_font_style: 'bold' label_font: 'Helvetica' label_font_size: 32 label_font_style: 'bold' x_label: 'Nice Xlabel' y_label:'Nice Ylabel'
			{
				loop i from: 0 to: length(proportion_per_od.keys)-1	{
				  data proportion_per_od.keys[i] value: proportion_per_od.values[i] color:color_per_type[proportion_per_type.keys[i]];
				}
			}
		} 				

//	    display "Radar Chart" {
//	        chart "Efficiency Radar Map" type: histogram background: #white axes:#black { //position: {world.shape.width*0,world.shape.height*0} {
//	        data "Total Cost" value: sum(transport_type_total_cost.values) color: #red accumulate_values: false;
//	        data "Waiting Time" value: sum(transport_type_total_waiting.values) color: #blue accumulate_values: false;
//	        data "Difficulty" value: sum(transport_type_total_difficulty.values) color: #blue accumulate_values: false;
//	        data "Distance" value: sum(transport_type_total_distance.values) color: #blue accumulate_values: false;
//	        data "Total CO2 Emission" value: sum(transport_type_cumulative_emission.values)/1000 color: #blue accumulate_values: false;	        	        	        	        	        	        
//	        }
//	    }

			
		//Added!!!!!! Separate Display for Charts
		display Dashboard type:opengl
		{	/*
			chart "prod" axes:rgb(125,125,125) size:{0.5,0.5} type:histogram style:stack //white
			{
				data 'production' value:sum(building collect each.production) accumulate_values:true color:rgb(169,25,37) marker:false thickness:2.0; //red
				data 'consumption' value:-sum(building collect each.consumption)  accumulate_values:true color:rgb(71,168,243) marker:false thickness:2.0; //blue
			}
			*/
			
            chart "Cumulative Trip" background:#black type: pie style:ring size: {0.5,0.5} position: {world.shape.width*1,world.shape.height*0} color: #white axes: #yellow title_font: 'Helvetica' title_font_size: 12.0 
			tick_font: 'Monospaced' tick_font_size: 18 tick_font_style: 'bold' label_font: 'Arial' label_font_size: 32 label_font_style: 'bold' x_label: 'Nice Xlabel' y_label:'Nice Ylabel'
			{
				loop i from: 0 to: length(transport_type_cumulative_usage.keys)-1 {
				if (transport_type_cumulative_usage.keys[i] != 'truck') {
				  data transport_type_cumulative_usage.keys[i] value: transport_type_cumulative_usage.values[i] color:color_per_mobility[transport_type_cumulative_usage.keys[i]];
				}
				}
			}
			
			
			chart "People Distribution" background:#black  type: pie size: {0.5,0.5} position: {world.shape.width*1.5,world.shape.height*0.5} color: #white axes: #yellow title_font: 'Helvetica' title_font_size: 12.0 
			tick_font: 'Helvetica' tick_font_size: 10 tick_font_style: 'bold' label_font: 'Helvetica' label_font_size: 32 label_font_style: 'bold' x_label: 'Nice Xlabel' y_label:'Nice Ylabel'
			{
				loop i from: 0 to: length(proportion_per_type.keys)-1	{
				  data proportion_per_type.keys[i] value: proportion_per_type.values[i] color:color_per_type[proportion_per_type.keys[i]];
				}
			}			
			
			
			chart "Trip Total Usage by Time" background:#black axes:rgb(125,125,125) size:{0.5,0.5} position:{world.shape.width/2,0} color: #white title_font: 'Helvetica' title_font_size: 12.0 
			{
				loop i from: 0 to: length(transport_type_cumulative_usage.keys)-1	{
				  data transport_type_cumulative_usage.keys[i] value: transport_type_cumulative_usage.values[i] color:color_per_mobility[transport_type_cumulative_usage.keys[i]] marker:false thickness:2.0;
				}
			}
			
			chart "Trip Usage by Days" background:#black axes:rgb(125,125,125) size:{0.5,0.5} position:{world.shape.width/2,world.shape.height*0.5} color: #white title_font: 'Helvetica' title_font_size: 12.0 
			{
				loop i from: 0 to: length(transport_type_daily_usage.keys)-1	{
				  data transport_type_daily_usage.keys[i] value: transport_type_daily_usage.values[i] color:color_per_mobility[transport_type_daily_usage.keys[i]] marker:false thickness:2.0;
				}
			}			
			
			chart "Trip Usage Increment" background:#black axes:rgb(125,125,125) size:{0.5,0.5} position:{world.shape.width*1,world.shape.height*0.5} color: #white title_font: 'Helvetica' title_font_size: 12.0 
			{
				loop i from: 0 to: length(transport_type_cumulative_usage.keys)-1	{
					if i = 0 {
						data transport_type_cumulative_usage.keys[i] value: transport_type_cumulative_usage.values[i] color:color_per_mobility[transport_type_cumulative_usage.keys[i]] marker:false thickness:2.0;
					}
					
					else {
				  		data transport_type_cumulative_usage.keys[i] value: transport_type_cumulative_usage.values[i]-transport_type_cumulative_usage.values[i-1] color:color_per_mobility[transport_type_cumulative_usage.keys[i]] marker:false thickness:2.0;
					}
				}
			}
			
			chart "CO2 Culmulative Emission" background:#black axes:rgb(125,125,125) size:{0.5,0.5} position:{world.shape.width*1.5,0} color: #white title_font: 'Helvetica' title_font_size: 12.0 
			{
				loop i from: 0 to: length(transport_type_cumulative_emission.keys)-1	{
				  data transport_type_cumulative_emission.keys[i] value: transport_type_cumulative_emission.values[i] color:color_per_mobility[transport_type_cumulative_usage.keys[i]] marker:false thickness:2.0;
				}
			}			
			
			
			graphics "Current Time" {
				draw 'Current Time：' + string(current_date.hour) + "h" + string(current_date.minute) +"m" color: # black font: font("Helvetica", 25, #italic) at: {world.shape.width*0,world.shape.height*0.05};
			}			
			
			
			graphics "Current Weather" {
				if weather_of_day >=0 and weather_of_day < 0.25 {
					draw 'Current Weather：' + "Excellent"  color: # black font: font("Helvetica", 25, #italic) at: {world.shape.width*0,world.shape.height*0.1};
				}
				if weather_of_day >=0.25 and weather_of_day < 0.5 {
					draw 'Current Weather：' + "Good"  color: # black font: font("Helvetica", 25, #italic) at: {world.shape.width*0,world.shape.height*0.1};
				}				
				if weather_of_day >=0.5 and weather_of_day < 0.75 {
					draw 'Current Weather：' + "Not Good"  color: # black font: font("Helvetica", 25, #italic) at: {world.shape.width*0,world.shape.height*0.1};
				}
				if weather_of_day >=0.75 and weather_of_day <= 1 {
					draw 'Current Weather：' + "Really Bad"  color: # black font: font("Helvetica", 25, #italic) at: {world.shape.width*0,world.shape.height*0.1};
				}								
			}			
			
			/* 
			graphics "Indicators" {
				loop i from: 0 to: length(transport_type_cumulative_emission.keys)-1 {
				  draw "Emission" + string(transport_type_cumulative_emission.keys[i]) + ': ' + string(transport_type_cumulative_emission.values[i]) color: # black font: font("Helvetica", 12, #italic) at: {world.shape.width*0,world.shape.height*(0.3+0.03*i)};
				  }
				loop i from: 0 to: length(transport_type_total_cost.keys)-1	{
				  draw 'Cost:' + string(transport_type_total_cost.keys[i]) + ': ' + string(transport_type_total_cost.values[i]) color: # black font: font("Helvetica", 12, #italic) at: {world.shape.width*0,world.shape.height*(0.5+0.03*i)};
				  }
				loop i from: 0 to: length(transport_type_total_waiting.keys)-1	{
				  draw 'Waiting:' + string(transport_type_total_waiting.keys[i]) + ': ' + string(transport_type_total_waiting.values[i]) color: # black font: font("Helvetica", 12, #italic) at: {world.shape.width*0,world.shape.height*(0.7+0.03*i)};
				  }
				loop i from: 0 to: length(transport_type_total_difficulty.keys)-1 	{
				  draw 'Difficulty:' +string(transport_type_total_difficulty.keys[i]) + ': ' + string(transport_type_total_difficulty.values[i]) color: # black font: font("Helvetica", 12, #italic) at: {world.shape.width*0,world.shape.height*(0.9+0.03*i)};
				  }
				loop i from: 0 to: length(transport_type_total_distance.keys)-1	{
				  draw 'Distance:'+ string(transport_type_total_distance.keys[i]) + ': ' + string(transport_type_total_distance.values[i]) color: # black font: font("Helvetica", 12, #italic) at: {world.shape.width*0,world.shape.height*(1.1+0.03*i)};
				  }
			}
			
			
			graphics "Total Numbers" {
				  draw 'Total Emission: '+ string(sum(transport_type_cumulative_emission.values)) color:# black font: font("Helvetica", 12, #italic) at: {world.shape.width*0,world.shape.height*0.13} ;
				  draw 'Total Cost: '+ string(sum(transport_type_total_cost.values)) color:# black font: font("Helvetica", 12, #italic) at: {world.shape.width*0,world.shape.height*0.15} ;
				  draw 'Total Waiting: '+ string(sum(transport_type_total_waiting.values)) color:# black font: font("Helvetica", 12, #italic) at: {world.shape.width*0,world.shape.height*0.17} ;
				  draw 'Total Difficulty: '+ string(sum(transport_type_total_difficulty.values)) color:# black font: font("Helvetica", 12, #italic) at: {world.shape.width*0,world.shape.height*0.19} ;
				  draw 'Total Distance: '+ string(sum(transport_type_total_distance.values)) color:# black font: font("Helvetica", 12, #italic) at: {world.shape.width*0,world.shape.height*0.21} ;
				  }			
			*/
				  
			graphics "Evaluation Matrix" {
				  draw 'Total Emission: '+ string(sum(transport_type_cumulative_emission.values))        + 'Co2 eq kg'                                    color:# black font: font("Helvetica", 12, #italic) at: {world.shape.width*0,world.shape.height*0.15} ;
				  draw 'MPAV Usage(%) : '+ string(int(10000*mpav_working/(mpav_idle+mpav_working))/100) + '%' color:# black font: font("Helvetica", 12, #italic) at: {world.shape.width*0,world.shape.height*0.19} ;
				  draw 'Green Modes Usage(%): '+ string(int(10000*(1-transport_type_cumulative_usage['car']/sum(transport_type_cumulative_usage.values)))/100)          + '%'                               color:# black font: font("Helvetica", 12, #italic) at: {world.shape.width*0,world.shape.height*0.23} ;
				  draw 'Travel Time per Trip (min): '+ string(int(sum(people_trip_time_total)/length(people_trip_time_total)/60))    + 'min'                                color:# black font: font("Helvetica", 12, #italic) at: {world.shape.width*0,world.shape.height*0.27} ;
				  draw 'Delivery Time per Trip (min): '+ string(int(sum(goods_trip_time_total)/length(goods_trip_time_total)/60))  + 'min'                               color:# black font: font("Helvetica", 12, #italic) at: {world.shape.width*0,world.shape.height*0.31} ;
				  draw 'Travel Cost per Trip ($): '+ string(int(100*sum(transport_type_total_cost.values)/sum(transport_type_cumulative_usage.values))/100) + '$' color:# black font: font("Helvetica", 12, #italic) at: {world.shape.width*0,world.shape.height*0.35} ;
//				  draw 'Delivery Cost per Trip ($): '+ string ((transport_type_total_cost['MPAV']+transport_type_total_cost['Truck'])/(transport_type_cumulative_usage['MPAV']+transport_type_cumulative_usage['Truck'])) color:# black font: font("Helvetica", 12, #italic) at: {world.shape.width*0,world.shape.height*0.39} ;
				  draw 'Total Waiting time: '+ string(sum(transport_type_total_waiting.values))+ 'min' color:# black font: font("Helvetica", 12, #italic) at: {world.shape.width*0,world.shape.height*0.39} ;
				  
				  }	
		}			
		
//		Output to XML
		// for radar chart

		monitor "transport_type_cumulative_emission" value: transport_type_cumulative_emission;
		monitor "weather_of_day" value: weather_of_day;
		monitor "people" value: people;
		

	}
}




experiment name type: gui {

	
	// Define parameters here if necessary
	// parameter "My parameter" category: "My parameters" var: one_global_attribute;
	
	// Define attributes, actions, a init section and behaviors if necessary
	// init { }
	
	
	output {
	// Define inspectors, browsers and displays here
	
	// inspect one_or_several_agents;
	//
	// display "My display" { 
	//		species one_species;
	//		species another_species;
	// 		grid a_grid;
	// 		...
	// }

	}
}