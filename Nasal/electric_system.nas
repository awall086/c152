#Electrical System
var electricsystem=func{
    	var master_bat = getprop("/controls/switches/master-bat");
    	var master_alt = getprop("/controls/switches/master-alt");
	var battery_status = getprop("/systems/electrical/battery-status");
	var new_battery_status = battery_status;
	var external_volts = 0;

	# external power source connected
    if (getprop("/controls/electric/external-power"))
    {
        external_volts = 28;
    }
	
	var engine_rpm = getprop("/engines/engine/rpm");
	var ideal_rpm = 800;	
	var ideal_volts = 28;
	var ideal_amps = 60;
	var factor = engine_rpm/ideal_rpm;
	if (factor > 1.0) {
		factor = 1.0;
	}

 	var alternator_volts = ideal_volts * factor;
	var alternator_amps = ideal_amps * factor;
 
       if ( master_alt == 0 ){
 		var alternator_volts = 0;
		var alternator_amps = 0;
	}


    # determine power source
    	var bus_volts = 0.0;
	var battery_volts = (24.0 * battery_status)/100;
    	var power_source = nil;	


    if ( master_bat ) {
        bus_volts = battery_volts;        
	power_source = "battery";
#        gui.popupTip("Battery is power source!");
    }
    if ( master_alt and (alternator_volts > bus_volts) ) {
        bus_volts = alternator_volts;
        power_source = "alternator";
#        gui.popupTip("Alternator is power source!");
        #print("Alternator is power source!");
    }
    if ( external_volts > bus_volts ) {
        bus_volts = external_volts;
        power_source = "external";
#        gui.popupTip("external is power source!");
    }

    if ( power_source == "battery" ) {
		new_battery_status = battery_status - 0.001;
	}

    if ( power_source == "alternator" or power_source == "external") {
		new_battery_status = battery_status + 0.001;
		if ( new_battery_status > 100.0 ) {
			new_battery_status = 100.0;
		}
	}

    # Flaps
    if ( getprop("/controls/circuit-breakers/flaps") ) {
        setprop("/systems/electrical/outputs/flaps", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/flaps", 0.0);
    }

    # Comm-Nav
    if ( getprop("/controls/circuit-breakers/radio1") ) {
        setprop("/systems/electrical/outputs/comm[0]", bus_volts);
        setprop("/systems/electrical/outputs/nav", bus_volts);
        setprop("/systems/electrical/outputs/audio-panel", bus_volts);

    } else {
        setprop("/systems/electrical/outputs/comm[0]", 0.0);
        setprop("/systems/electrical/outputs/nav", 0.0);
        setprop("/systems/electrical/outputs/audio-panel", 0.0);
    }

    # Transponder
    if ( getprop("/controls/circuit-breakers/flaps") ) {
        setprop("/systems/electrical/outputs/transponder", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/transponder", 0.0);
    }
    
    # Pitot Heat Power
    if ( getprop("/controls/anti-ice/pitot-heat" ) ) {
        setprop("/systems/electrical/outputs/pitot-heat", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/pitot-heat", 0.0);
    }

    # Instrument Power: ignition, fuel, oil temperature
    if ( getprop("/controls/circuit-breakers/instr") ) {
        setprop("/systems/electrical/outputs/instr-ignition-switch", bus_volts);
        if ( bus_volts > 12 ) {
            # starter
            if ( getprop("controls/switches/starter") ) {
                setprop("systems/electrical/outputs/starter", bus_volts);
            } else {
                setprop("systems/electrical/outputs/starter", 0.0);
            }
        } else {
            setprop("systems/electrical/outputs/starter", 0.0);
        }
    } else {
        setprop("/systems/electrical/outputs/instr-ignition-switch", 0.0);
        setprop("/systems/electrical/outputs/starter", 0.0);
    }
    
    # Interior lights
    if ( getprop("/controls/circuit-breakers/instr_lt") ) {
        setprop("/systems/electrical/outputs/instrument-lights", bus_volts);
        setprop("/systems/electrical/outputs/cabin-lights", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/instrument-lights", 0.0);
        setprop("/systems/electrical/outputs/cabin-lights", 0.0);
    }    

    # Landing Light Power
    if ( getprop("/controls/circuit-breakers/landing_lt") ) {
        setprop("/systems/electrical/outputs/landing-light", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/landing-light", 0.0 );
    }    
        
    # Taxi Lights Power
    # Notice taxi lights also use landing lights breaker. It is not a bug.
    if ( getprop("/controls/circuit-breakers/landing_lt") ) {
        setprop("/systems/electrical/outputs/taxi-light", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/taxi-light", 0.0);
    }

    # Beacon and Pitot Heater Power
    if ( getprop("/controls/circuit-breakers/beacon_pitot") ) {
        setprop("/systems/electrical/outputs/beacon_pitot", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/beacon_pitot", 0.0);
    }
    
    # Nav Lights Power
    if ( getprop("/controls/circuit-breakers/nav_lt") ) {
        setprop("/systems/electrical/outputs/nav-lights", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/nav-lights", 0.0);
    }

    # Strobe Lights Power
    if ( getprop("/controls/circuit-breakers/strobe_lt") ) {
        setprop("/systems/electrical/outputs/strobe", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/strobe", 0.0);
    }

    # Turn Coordinator and directional gyro Power
    if ( getprop("/controls/circuit-breakers/turn-coordinator") ) {
        setprop("/systems/electrical/outputs/turn-coordinator", bus_volts);
        setprop("/systems/electrical/outputs/DG", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/turn-coordinator", 0.0);
        setprop("/systems/electrical/outputs/DG", 0.0);
    }

	setprop("/systems/electrical/suppliers/battery", battery_volts);
	setprop("/systems/electrical/suppliers/alternator", alternator_volts);
	setprop("/systems/electrical/amps", alternator_amps);
	setprop("/systems/electrical/volts", bus_volts);
	setprop("/systems/electrical/battery-status", new_battery_status);

	settimer(electricsystem, 0);
}

setlistener("sim/signals/fdm-initialized", electricsystem);



