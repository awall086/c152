##########################################
# Autostart
##########################################

var autostart = func (msg=1) {
    if (getprop("/engines/active-engine/running")) {
        if (msg)
            gui.popupTip("Engine already running", 5);
        return;
    }

    # Filling fuel tanks
    setprop("/consumables/fuel/tank[0]/selected", 1);
    setprop("/consumables/fuel/tank[1]/selected", 1);

    # Setting levers and switches for startup
    setprop("/controls/switches/magnetos", 3);
    setprop("/controls/engines/engine[0]/throttle", 0.2);
    setprop("/controls/engines/engine[0]/mixture", 0.95);
    setprop("/controls/flight/elevator-trim", 0.0);
    setprop("/controls/engines/engine[0]/master-bat", 1);
    setprop("/controls/engines/engine[0]/master-alt", 1);

    # Setting lights
    setprop("/controls/lighting/nav-lights", 1);
    setprop("/controls/lighting/strobe", 1);
    setprop("/controls/lighting/beacon", 1);

    # Setting flaps to 0
    setprop("/controls/flight/flaps", 0.0);

    # All set, starting engine
    setprop("/controls/switches/starter", 1);
    setprop("/engines/active-engine/auto-start", 1);

    var engine_running_check_delay = 5.0;
    settimer(func {
        if (!getprop("/engines/engine/running")) {
            gui.popupTip("The autostart failed to start the engine. You must lean the mixture and start the engine manually.", 5);
        }
        setprop("/controls/switches/starter", 0);
        setprop("/engines/active-engine/auto-start", 0);
    }, engine_running_check_delay);

};

var reset_system = func {
    if (getprop("/fdm/jsbsim/running")) {
        c172p.autostart(0);
    }
};

##########################################
# SetListerner must be at the end of this file
##########################################

    setlistener("/engines/active-engine/running", func (node) {
        var autostart = getprop("/engines/active-engine/auto-start");
        var cranking  = getprop("/engines/active-engine/cranking");
        if (autostart and cranking and node.getBoolValue()) {
            setprop("/controls/switches/starter", 0);
            setprop("/engines/active-engine/auto-start", 0);
        }
    }, 0, 0);

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