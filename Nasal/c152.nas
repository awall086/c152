##Click sounds

var click = func (name, timeout = 0.1, delay=0) {
    var sound_prop = "/sim/model/c152/sound/click-"~name ;

    settimer(func  {
        #play the sound
        setprop(sound_prop, 1);
    
        #Reset property after 0.2 seconds so the sound can be played again

        settimer(func {
            setprop(sound_prop, 0);
        }, timeout);

    }, delay);
};