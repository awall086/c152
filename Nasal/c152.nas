##########################################
# ALS Beacon and strobe Light
##########################################

aircraft.light.new("/sim/model/c152/lighting/beacon", [0.050, 1.5]);
aircraft.light.new("/sim/model/c152/lighting/strobe", [0.045, 1.985]);

aircraft.data.add(
    "/controls/flight/flaps",
);

##########################################
# Autostart
##########################################

var autostart = func (msg=1) {
    if (getprop("/engines/engine/running")) {
        if (msg)
            gui.popupTip("Engine already running", 5);
        return;
    }

    # Filling fuel tanks
	setprop("/controls/fuel/fuel-on", 1);

    # Setting levers radios and switches for startup
    setprop("/controls/switches/magnetos", 3);
    setprop("/controls/engines/engine/throttle", 0.10);
    setprop("/controls/engines/engine/mixture", 0.95);
    setprop("/controls/flight/elevator-trim", 0.0);
    setprop("/controls/switches/master-bat", 1);
    setprop("/controls/switches/master-alt", 1);
	setprop("/controls/engines/engine/primer", 3);

	setprop("/instrumentation/comm[0]/volume", 0.50);
	setprop("/instrumentation/comm[0]/power-btn", 1);
	setprop("/instrumentation/comm[1]/volume", 0.50);
	setprop("/instrumentation/comm[1]/power-btn", 1);
	setprop("/instrumentation/dme/power", 1);

    # Setting lights
    setprop("/controls/lighting/nav-lights-switch", 1);
    setprop("/controls/lighting/strobe-switch", 1);
    setprop("/controls/lighting/beacon-switch", 1);

    # Setting flaps to 0
    setprop("/controls/flight/flaps", 0.0);

    # All set, starting engine
    setprop("/controls/switches/starter", 1);
    setprop("/engines/engine/auto-start", 1);

    var engine_running_check_delay = 5.0;
    settimer(func {
        if (!getprop("/engines/engine/running")) {
            gui.popupTip("The autostart failed to start the engine. You must lean the mixture and start the engine manually.", 5);
        }
        setprop("/controls/switches/starter", 0);
        setprop("/engines/engine/auto-start", 0);
    }, engine_running_check_delay);

};

var reset_system = func {
    if (getprop("/fdm/jsbsim/running")) {
        c152.autostart(0);
    }
};

var update_pax = func {
    var state = 0;
    state = bits.switch(state, 0, getprop("pax/pilot/present"));
    state = bits.switch(state, 1, getprop("pax/co-pilot/present"));
    setprop("/payload/pax-state", state);
};

############################################
# Static objects: Place
############################################

var StaticModel = {
    new: func (name, file) {
        var m = {
            parents: [StaticModel],
            model: nil,
            model_file: file,
			object_name: name
        };

        setlistener("/sim/" ~ name ~ "/enable", func (node) {
            if (node.getBoolValue()) {
                m.add();
            }
            else {
                m.remove();
            }
        });

        return m;
    },

    add: func {
        var manager = props.globals.getNode("/models", 1);
        var i = 0;
        for (; 1; i += 1) {
            if (manager.getChild("model", i, 0) == nil) {
                break;
            }
        }
        var position = geo.aircraft_position().set_alt(getprop("/position/ground-elev-m"));
        me.model = geo.put_model(me.model_file, position, getprop("/orientation/heading-deg"));
    },

    remove: func {
        if (me.model != nil) {
            me.model.remove();
            me.model = nil;
        }
    }
};

StaticModel.new("coneR", "Aircraft/c152/Models/Exterior/safety-cone/safety-cone_R.xml");
StaticModel.new("coneL", "Aircraft/c152/Models/Exterior/safety-cone/safety-cone_L.xml");
StaticModel.new("gpu", "Aircraft/c152/Models/Exterior/external-power/external-power.xml");

# external electrical disconnect when groundspeed higher than 0.1ktn (replace later with distance less than 0.01...)
var ad_timer = maketimer(0.1, func {
    groundspeed = getprop("/velocities/groundspeed-kt") or 0;
    if (groundspeed > 0.1) {
        setprop("/controls/electric/external-power", "false");
    }
});
ad_timer.start();

#following ground equipement stuff placing was only possible by the help of the work by: Melchior Franz, Anders Gidenstam, Detelf Faber, onox. Thanks!
#wheel chocks======================================================

var chocks001_model = {
       index:   0,
       add:   func {
  var manager = props.globals.getNode("/models", 1);
                var i = 0;
                for (; 1; i += 1)
                   if (manager.getChild("model", i, 0) == nil)
                      break;

		var chocks001 = geo.aircraft_position().set_alt(
				props.globals.getNode("/position/ground-elev-m").getValue());

		geo.put_model("Aircraft/c152/Models/Exterior/chocks/NWchocks.ac", chocks001,
				props.globals.getNode("/orientation/heading-deg").getValue());
					 me.index = i;
          },

       remove:   func {
                #print("chocks001_model.remove");
             props.globals.getNode("/models", 1).removeChild("model", me.index);
          },
};

var init_common = func {
	setlistener("/sim/chocks001/enable", func(n) {
		if (n.getValue()) {
				chocks001_model.add();
		} else  {
			chocks001_model.remove();
		}
	});
}
settimer(init_common,0);

var chocks002_model = {
       index:   0,
       add:   func {
  var manager = props.globals.getNode("/models", 1);
                var i = 0;
                for (; 1; i += 1)
                   if (manager.getChild("model", i, 0) == nil)
                      break;

		var chocks002 = geo.aircraft_position().set_alt(
				props.globals.getNode("/position/ground-elev-m").getValue());

		geo.put_model("Aircraft/c152/Models/Exterior/chocks/LWchocks.ac", chocks002,
				props.globals.getNode("/orientation/heading-deg").getValue());
					 me.index = i;
          },

       remove:   func {
                #print("chocks002_model.remove");
             props.globals.getNode("/models", 1).removeChild("model", me.index);
          },
};

var init_common = func {
	setlistener("/sim/chocks002/enable", func(n) {
		if (n.getValue()) {
				chocks002_model.add();
		} else  {
			chocks002_model.remove();
		}
	});
}
settimer(init_common,0);

var chocks003_model = {
       index:   0,
       add:   func {
  var manager = props.globals.getNode("/models", 1);
                var i = 0;
                for (; 1; i += 1)
                   if (manager.getChild("model", i, 0) == nil)
                      break;

		var chocks003 = geo.aircraft_position().set_alt(
				props.globals.getNode("/position/ground-elev-m").getValue());

		geo.put_model("Aircraft/c152/Models/Exterior/chocks/RWchocks.ac", chocks003,
				props.globals.getNode("/orientation/heading-deg").getValue());
					 me.index = i;
          },

       remove:   func {
                #print("chocks003_model.remove");
             props.globals.getNode("/models", 1).removeChild("model", me.index);
          },
};

var init_common = func {
	setlistener("/sim/chocks003/enable", func(n) {
		if (n.getValue()) {
				chocks003_model.add();
		} else  {
			chocks003_model.remove();
		}
	});
}
settimer(init_common,0);

#Transponder ident light
var ident_status = maketimer(10.0, func {
    setprop("/instrumentation/transponder/ident_status", 1);
});
ident_status.start();

var ident_light_timer = maketimer(0.1, func {
    var light_intensity = getprop("/instrumentation/transponder/ident_light");
    var light_status = getprop("/instrumentation/transponder/ident_light_status");
    var actual_ident = getprop("/instrumentation/transponder/ident_status");

    if ( (light_intensity < 1) and (light_status == 0) and (actual_ident == 1) ) {
       setprop("/instrumentation/transponder/ident_light", light_intensity + 0.1);
       if ( light_intensity > 0.89 ) {
           setprop("/instrumentation/transponder/ident_light_status", 1);
           setprop("/instrumentation/transponder/ident_light", 1);
       }
    }
    else {
       setprop("/instrumentation/transponder/ident_light", light_intensity - 0.1);
       if ( light_intensity < 0.11 ) {
           setprop("/instrumentation/transponder/ident_light_status", 0);
           setprop("/instrumentation/transponder/ident_light", 0);
           setprop("/instrumentation/transponder/ident_status", 0);
       }
    }
});
ident_light_timer.start();

# Mixture will be calculated using the primer during 5 seconds AFTER the pilot used the starter
# This prevents the engine to start just after releasing the starter: the propeller will be running
# thanks to the electric starter, but carburator has not yet enough mixture
var primerTimer = maketimer(5, func {
    setprop("/controls/engines/engine/use-primer", 0);
    # Reset the number of times the pilot used the primer only AFTER using the starter
    setprop("/controls/engines/engine/primer", 0);
    print("Primer reset to 0");
    primerTimer.stop();
});

##########################################
# Click Sounds
##########################################

var click = func (name, timeout=0.1, delay=0) {
    var sound_prop = "/sim/model/c152/sound/click-" ~ name;

    settimer(func {
        # Play the sound
        setprop(sound_prop, 1);

        # Reset the property after 0.2 seconds so that the sound can be
        # played again.
        settimer(func {
            setprop(sound_prop, 0);
        }, timeout);
    }, delay);
};

##########################################
# SetListerner must be at the end of this file
##########################################
var originalfreq  = getprop("/instrumentation/adf/frequencies/selected-khz");
setprop("/instrumentation/adf/frequencies/digit100-khz", ( originalfreq - math.mod(originalfreq, 100))/100);
setprop("/instrumentation/adf/frequencies/digit10-khz", (( originalfreq - (originalfreq - math.mod(originalfreq, 100)) - math.mod(originalfreq, 10))/10) );
setprop("/instrumentation/adf/frequencies/digit1-khz", ( math.mod(originalfreq, 10)) );

setlistener("/instrumentation/adf/frequencies/digit100-khz", func (node) {
    var digit100 = getprop("/instrumentation/adf/frequencies/digit100-khz");
    var actualfreq = getprop("/instrumentation/adf/frequencies/selected-khz");
    setprop("/instrumentation/adf/frequencies/selected-khz", (digit100 * 100) + math.mod(actualfreq, 100) );
});

setlistener("/instrumentation/adf/frequencies/digit10-khz", func (node) {
    var digit10 = getprop("/instrumentation/adf/frequencies/digit10-khz");
    var actualfreq = getprop("/instrumentation/adf/frequencies/selected-khz");
    setprop("/instrumentation/adf/frequencies/selected-khz", actualfreq - math.mod(actualfreq, 100)  + (digit10 * 10) + math.mod(actualfreq, 10) );
});


setlistener("/instrumentation/adf/frequencies/digit1-khz", func (node) {
    var digit1 = getprop("/instrumentation/adf/frequencies/digit1-khz");
    var actualfreq = getprop("/instrumentation/adf/frequencies/selected-khz");
    setprop("/instrumentation/adf/frequencies/selected-khz", actualfreq - math.mod(actualfreq, 10) + digit1);
});


setlistener("/instrumentation/adf/actual-mode", func (node) {
    if ( getprop("/instrumentation/adf/actual-mode") == 0 ) {
        setprop("/instrumentation/adf/mode", "bfo");
    } else {
    if ( getprop("/instrumentation/adf/actual-mode") == 1 ) {
        setprop("/instrumentation/adf/mode", "ant");
    } else {
    if ( getprop("/instrumentation/adf/actual-mode") == 2 ) {
        setprop("/instrumentation/adf/mode", "adf");
    }
    }
    }
});

setlistener("/pax/pilot/present", update_pax, 0, 0);
setlistener("/pax/co-pilot/present", update_pax, 0, 0);
update_pax();

    setlistener("/engines/engine/running", func (node) {
        var autostart = getprop("/engines/engine/auto-start");
        var cranking  = getprop("/engines/engine/cranking");
        if (autostart and cranking and node.getBoolValue()) {
            setprop("/controls/engines/engine/starter", 0);
            setprop("/engines/engine/auto-start", 0);
        }
    }, 0, 0);

