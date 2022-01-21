/***
* Name: model1
* Author: Azem Henri
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model magasin

/* Insert your model definition here */

global {
    int nb_preys_init <- 1;
    int width <- 70;
    int height <- 70;
    rgb couleur_mur <- #black;
    rgb couleur_entree -> #green;
    rgb couleur_sortie -> #red;
    rgb couleur_route -> #white;
    rgb couleur_rayon -> #yellow;
    rgb couleur_emplacement -> rgb(150, 150, 150);
    
    float distance_infection <- 1.8 #m; // Distance d'infection
    int contamination <- 0; // Total de personne contaminé dans le magasin
    int total_personne <- 0; // Total de personne déjà entré dans le magasin
    int total_magasin <- 0; // Total de personne dans le magasin en temps réel
    int max_personne <- 50; // Nombre maximal de personne dans le magasin
    int max_total_personne <- 500; // Nombre maximal de personne qui doivent entrer dans le magasin
    int malade_init <- 0; // Nombre de malade entré dans le magain
    int saine_init <- 0; // Nombre de personne saine entré dans le magain
    bool distanciation <- true; // Activer la distanciation
    bool masque <- true; // Activer le port de masque
    float distance_personne <- 4.0 #m; // Distance de distanciation
    float proba_infection init: 0.02;
    float proba_infection_masque init: 0.0005;
    list<route> chemin;
    graph path_route;
    
    ///////////
    bool pause <- false;
    
    file my_csv_file <- csv_file("../includes/map_2.csv",",");
    
    rgb color <- distanciation ? (masque ? #green : #orange) : (masque ? #blue : #black);
    string mode_experience <- distanciation ? (masque ? "+Distanciation +Masque" : "+Distanciation -Masque") : (masque ? "-Distanciation +Masque" : "-Distanciation -Masque");
    
    init {
    	matrix data <- matrix(my_csv_file);
    	ask route {
            grid_value <- float(data[grid_x,grid_y]);
        	color <- (grid_value = 0) ? couleur_route : ((grid_value = 1) ? couleur_mur : ((grid_value = 2) ? couleur_entree : ((grid_value = 4) ? couleur_rayon : ((grid_value = 3) ? couleur_sortie : couleur_emplacement))));
        }
    	
    	create personne number: nb_preys_init ;
    	chemin <- (agents of_generic_species route) where (each.color = couleur_route);
    	path_route <- grid_cells_to_graph(chemin);
    }
    
    reflex entree when: flip(0.25) and ((total_magasin < max_personne) and (total_personne < max_total_personne)) {
    	create species(personne) number: rnd(3) {
		}
    }
    
    reflex fin_simulation {
    	list<personne> p <- (agents of_generic_species personne);
    	if p = nil or length(p) = 0 {
    		do pause;
    	}
	}
	
	reflex when: pause = true {
		do pause;
	}
	
	reflex save_data when: every(1#cycle){
		save [cycle, first(contamination)] to:"../results/promotion_all_yes.csv" type: "csv" rewrite: false; 
		
		//write("proba_distance="+proba_distance);
	}
}

species personne skills:[moving] {
    float size <- 0.65 ;  
    rgb color_malade <- #red;
    rgb color_non_malade <- #blue;
    route target <- one_of(route where (each.color = couleur_emplacement)) ;
    bool deplacement <- true;
    bool est_malade;
    bool port_masque;
    float proba_distance init: 0.0 max: 5.0 min: 0.0;
    int temps_arret <- rnd(15, 25);
    int verif_sortie <- width + height;
    float speed <- 1.0 + rnd(2.0);
        
    init { 
        location <- one_of(route where (each.color = couleur_entree)).location;
        
        // Initialisation de la maladie
        if (flip(0.1)){
        	est_malade <- true;
        	malade_init <- malade_init + 1;
        } else {
        	est_malade <- false;
        	saine_init <- saine_init + 1;
        }
        
        //initialisation du masque
        if flip(0.25) {
        	port_masque <- true;
        } else {
        	port_masque <- false;
        }
        
        total_personne <- total_personne + 1;
        total_magasin <- total_magasin + 1;
    }
    
    list<route> get_position(float distance) {
    	list<route> cellules <- agents of_generic_species route overlapping(circle(size+distance, location));
    	return cellules;
    }
    
    action change_target {
        if (flip(0.30)){ // On sort du magasin
    		target <- one_of(route where (each.color = couleur_sortie));
    	} else { // Pour aller vers un autre rayon
    		target <- one_of(route where (each.color = couleur_emplacement));
    	}
    }
    
    reflex die when: target != nil and target.color = couleur_sortie {
    	list<personne> liste_personne <- agents_overlapping(target) of_generic_species personne;
	    if (liste_personne index_of self != -1) {
	    	total_magasin <- total_magasin -1;
        	do die;
	    }
    }
        
    reflex basic_move when: deplacement{
    	
    	bool deuxieme_cas <- true;
    	point old_position <- location;
    	
    	if distanciation and flip(1){
    		// On désactive le deuxième cas
    		deuxieme_cas <- false;
    		
    		// On vérifie si en se déplaçant on respectera la distentiatiation
    		list<personne> liste_personne <- agents_overlapping(circle(size+distance_personne, destination)) of_generic_species personne where (each != self);
    		
    		if length(liste_personne) = 0 { // si la distanciation sera respectée
				do goto target: target on: path_route speed: speed;
			} else {
				if flip(0.1) { // On ne bouge pas pour respecter la distanciation
					deuxieme_cas <- false;
				} else {
					deuxieme_cas <- true;
				}
			}
    	}
    	
    	if deuxieme_cas {
    		
    		// On vérifie si en se déplaçant on ne se déplace pas sur quelqu'un
    		list<personne> liste_personne <- agents_overlapping(circle(size+0.5, destination)) of_generic_species personne where (each != self);
    		
    		if length(liste_personne) = 0 { // si on ne se déplace pas sur quelqu'un
				do goto target: target on: path_route speed: speed;
			} else { //On change de destination
				// On cherche la case dans la quelle se trouve la prochaine destination
				route r <- (agents of_generic_species route overlapping(destination))[0];
				location <- r.neighbors[0].location;
				//do change_target;
			}
    	}
    }
    
    reflex dans_rayon when: deplacement{
	    // Si on est arrivé à destination dans le magasin (Dans un rayon)
	    list<personne> liste_personne <- agents_overlapping(target) of_generic_species personne where(each = self);
	    
	    if (liste_personne index_of self != -1) { // Si on est dans le rayon
	    	deplacement <- false;
	    }
	    
	    verif_sortie <- verif_sortie - 1;
	    
	    if verif_sortie <= 0 { // Si on reste sur place
	    	target <- one_of(route where (each.color = couleur_sortie));
	    }
    }
    
    reflex rester_dans_rayon when: !deplacement {
    	temps_arret <- temps_arret - 1; // Pour ne pas rester indéfiniment dans le rayon
    }
    
    reflex quitter_rayon when: deplacement = false  and temps_arret <= 0{
    	
	    temps_arret <- rnd(15, 25);
	    verif_sortie <- width + height;
    	
    	do change_target;
    	deplacement <- true;
    	
    }
    
    reflex contamination when: est_malade {
    	ask (agents of_generic_species personne) at_distance distance_infection where (each.est_malade = false){
    		float d <- self.location distance_to myself.location;
    		proba_distance <- (1 /(log(abs(d*10)+0.1) + 2.0)) * 10;
    		
    		if masque {
	    		if myself.port_masque {
	    			if flip(proba_infection_masque * proba_distance) and !self.est_malade {
		    			est_malade <- true;
		    			contamination <- contamination + 1;
	    			}
	    		} else {
	    			if flip(proba_infection * proba_distance) and !self.est_malade {
		    			est_malade <- true;
		    			contamination <- contamination + 1;
	    			}
	    		}
	    	} else {
	    		if flip(proba_infection * proba_distance) and !self.est_malade {
	    			est_malade <- true;
	    			contamination <- contamination + 1;
    			}
	    	}
    	}
    }

    aspect base {
    	draw circle(size) color: est_malade?color_malade:color_non_malade ;
    }
}

grid route width: width height: height neighbors: 4 {
    rgb color <- rgb(255, 255, 255);
    list<route> neighbors2 <- (self neighbors_at 1) where (length(agents_overlapping(each) of_generic_species personne) = 0 and each.color = couleur_emplacement);
}

experiment COSIT1 type: gui {
    parameter "Init-person: " var: nb_preys_init min: 1 max: 100 category: "Person-Parameters" ;
    parameter "Distance Infection" var: distance_infection category: 'Person-Parameters';// min:1.0 max:5.0;
    parameter "Max person inside" var: max_personne category: 'Person-Parameters' min:1 max:20;
    parameter "Max people" var: max_total_personne category: 'Person-Parameters' min:20 max:1000;
    parameter "Distance-person" var: distanciation category: 'Barrier-meseaures';
    parameter "Face-Mask" var: masque category: 'Barrier-meseaures';
    parameter "Distanciation" var: distance_personne category: 'Person-Parameters' ;//min:1.0 max:5.0;
    parameter "fichier magasin" var: my_csv_file category: 'Env-Parameters';
    parameter "width magasin" var: width category: 'Env-Parameters';
    parameter "height magasin" var: height category: 'Env-Parameters';
    
    output {
    	monitor "Patien0(People sick initialy)" value: malade_init;
    	monitor "Healthy people initialy" value: saine_init;
    	monitor "Number of contamination" value: contamination;
    	monitor "Total NUmber of Visitors" value: total_personne;
    	monitor "Current number in the environnment" value: total_magasin;
    	
		display Chart background: #white {
			chart "Evolution du nombre de malade avec le temps" type: series {
				data "numbre de contamination" value: contamination color: #blue;
			}
		}
    	
	    display main_display {
	        grid route lines: #white ;
	        species personne aspect: base ;
	    }
    }
}

/*experiment COSIT2 type: gui {
    //parameter "Initial number of person: " var: nb_preys_init min: 1 max: 100 category: "Personne" ;
    //parameter "Distance infection" var: distance_infection category: 'Personne' min:1.0 max:5.0;
    //parameter "Max personnes dans le magasin" var: max_personne category: 'Magasin' min:50 max:500;
    //parameter "Total Max personnes" var: max_total_personne category: 'Magasin' min:100 max:1000;
    //parameter "Distanciation dans le magasin" var: distanciation category: 'Magasin';
    //parameter "Distance personne" var: distance_personne category: 'Personne' min:1.0 max:5.0;
	
	permanent {
		display Comparison background: #white {
			chart "Evolution du nombre de malade avec le temps" type: series {
				loop s over: simulations {
					data s.mode_experience value: s.contamination color: s.color marker: false style: line thickness: 1 ;
				}
			}
		}
	}
	
	init {
		seed <- 1.0;
		create magasin_model with: [distanciation::true, masque::false];
		create magasin_model with: [distanciation::false, masque::true];
		create magasin_model with: [distanciation::true, masque::true];
	}
    
    output {
    	layout #split editors: false consoles: false toolbars: true tabs: false tray: false;
    	
	    display main_display {
	        grid route lines: #white ;
	        species personne aspect: base ;
	    }
    }
}*/