# =============================== DEFINITIONS ===========================================

# set the update period

var UPDATE_PERIOD = 0.3;

# =============================== Hobbs meter =======================================

# this property is saved by aircraft.timer
var hobbsmeter_engine = aircraft.timer.new("/sim/time/hobbs/engine[0]", 60, 1);

var init_hobbs_meter = func(index, meter) {
    setlistener("/engines/engine[" ~ index ~ "]/running", func {
        if (getprop("/engines/engine[" ~ index ~ "]/running")) {
            meter.start();
            print("Hobbs system started");
        } else {
            meter.stop();
            print("Hobbs system stopped");
        }
    }, 1, 0);
};

init_hobbs_meter(0, hobbsmeter_engine);

var update_hobbs_meter = func {
    # in seconds
    var hobbs_engine = getprop("/sim/time/hobbs/engine[0]") or 0.0;

    var hobbs = 0;
	hobbs = hobbs_engine / 3600.0;

    setprop("/instrumentation/hobbs-meter/digits0", math.mod(int(hobbs * 10), 10));
    # rest of digits
    setprop("/instrumentation/hobbs-meter/digits1", math.mod(int(hobbs), 10));
    setprop("/instrumentation/hobbs-meter/digits2", math.mod(int(hobbs / 10), 10));
    setprop("/instrumentation/hobbs-meter/digits3", math.mod(int(hobbs / 100), 10));
    setprop("/instrumentation/hobbs-meter/digits4", math.mod(int(hobbs / 1000), 10));
};

setlistener("/sim/time/hobbs/engine[0]", update_hobbs_meter, 1, 0);

# ========== primer stuff ======================

# Toggles the state of the primer
var pumpPrimer = func {
    var push = getprop("/controls/engines/engine/primer-lever") or 0;

    if (push) {
        var pump = getprop("/controls/engines/engine/primer") or 0;
        setprop("/controls/engines/engine/primer", pump + 1);
        setprop("/controls/engines/engine/primer-lever", 0);
    }
    else {
        setprop("/controls/engines/engine/primer-lever", 1);
    }
};

# Primes the engine automatically. This function takes several seconds
var autoPrime = func {
    var p = getprop("/controls/engines/engine/primer") or 0;
    if (p < 3) {
        pumpPrimer();
        settimer(autoPrime, 1);
    }
};

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

# ====== Engine starting actions ======
var engine_starting = props.globals.initNode("/engines/engine/starting", 0, "BOOL");
setlistener("/engines/engine/running", func(ngn){
    if (ngn.getValue() and !getprop("/engines/engine[0]/coughing")) {
        engine_starting.setValue(1);
        var timer = maketimer(1, func(){
            engine_starting.setValue(0);
        });
        timer.singleShot = 1; # timer will only be run once
        timer.start();
    } else {
        engine_starting.setValue(0);
    }
},0,0);

setlistener("/engines/engine/starting", func(ngn){
    # Eye-candy: when engine starts, let the view shake a bit
    if (ngn.getValue() and getprop("/sim/current-view/internal")) {
        var curX = getprop("/sim/current-view/x-offset-m");
        var xtimer = maketimer(0.05, func(){
            interpolate("/sim/current-view/x-offset-m", curX-0.0015+rand()*0.003, 0.05);
        });
        xtimer.start();
        var curY = getprop("/sim/current-view/y-offset-m");
        var ytimer = maketimer(0.05, func(){
            interpolate("/sim/current-view/y-offset-m", curY-0.0015+rand()*0.003, 0.05);
        });
        ytimer.start();
        var stoptimer = maketimer(0.8, func(){
           xtimer.stop();
           ytimer.stop();
           interpolate("/sim/current-view/x-offset-m", curX, 0.1);
           interpolate("/sim/current-view/y-offset-m", curY, 0.1);
        });
        stoptimer.singleShot = 1;
        stoptimer.start();
    }
}, 0, 0);

# ========== Main loop ======================

var update = func {
	#this block should be moved out of nasal and into jsbsim or autopilot logic
    var leftTankUsable  = 0;
    var rightTankUsable = 0;
	var LeftTankSelected = 0;
	var RightTankSelected = 0;
	var TankSelected = getprop("/controls/fuel/fuel-on");
	if ( TankSelected == 1 ) {
		LeftTankSelected = 1;
		RightTankSelected = 1;
	}
    if ( LeftTankSelected and ( getprop("/consumables/fuel/tank[1]/level-gal_us") > 0 ) ) { leftTankUsable = 1; }
    if ( RightTankSelected and ( getprop("/consumables/fuel/tank[2]/level-gal_us") > 0 ) ) { rightTankUsable  = 1; }
    var outOfFuel = !(leftTankUsable or rightTankUsable);

    # We use the mixture to control the engines, so set the mixture
    var usePrimer = getprop("/controls/engines/engine/use-primer") or 0;

    var engine_running = getprop("/engines/engine/running");

    if (outOfFuel and (engine_running or usePrimer)) {
        print("Out of fuel!");
        gui.popupTip("Out of fuel!");
    }
    elsif (usePrimer and !engine_running and getprop("/engines/engine/oil-temperature-degf") <= 75) {
        # Mixture is controlled by start conditions
        var primer = getprop("/controls/engines/engine/primer");
        if (!getprop("/fdm/jsbsim/fcs/mixture-primer-cmd") and getprop("/controls/switches/starter") and getprop("/controls/switches/master-bat")) {
            if (primer < 3) {
                print("Use the primer!");
                gui.popupTip("Use the primer!");
            }
            elsif (primer > 6) {
                print("Flooded engine!");
                gui.popupTip("Flooded engine!");
            }
            else {
                print("Check the throttle!");
                gui.popupTip("Check the throttle!");
            }
        }
    }
    
};

setlistener("/controls/switches/starter", func {
    var v = getprop("/controls/switches/starter") or 0;
    if (v == 0) {
        print("Starter off");
        # notice the starter will be reset after 5 seconds
        primerTimer.restart(5);
    }
    else {
        print("Starter on");
        if(getprop("/controls/panel/glass"))
            setprop("/controls/engines/engine/use-primer", 0); 
        else
            setprop("/controls/engines/engine/use-primer", 1);
        if (primerTimer.isRunning) {
            primerTimer.stop();
        }
    }
}, 1, 0);

var engine_timer = maketimer(UPDATE_PERIOD, func { update(); });

setlistener("/sim/signals/fdm-initialized", func {
    engine_timer.start();
});
