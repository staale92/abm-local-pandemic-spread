;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; An Agent-Based Model of Local Pandemic Spread: Analysis of SARS-CoV-2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

globals [max-infected
max-immun                                                          ;duration of immunity
gdp                                                                ;GDP value
healed                                                             ;recovered people
total-cases                                                        ;count of total cases
current-positive                                                   ;count of current positives
deaths                                                             ;count of deaths
;tourism?                                                          ;it is activated with a switch.
                                                                      ;;If on: there is tourism in the country starting from the tick defined by the "openness-to-tourism" slider
tc1 tc2 tc3 tc4 tc5 tc6 tc7 tc8 tc9 tc10                           ;R0 construction: total cases at a given day
r01 r02 r03 r04 r05 r06 r07 r08 r09 r010                           ;R0 construction: using 10-day moving average
R0-calculation                                                     ;R0 calculation for the period
ma5                                                                ;R0 construction: 5-day moving average
ma10                                                               ;R0 construction: 10-day moving average
R0 Re Pc                                                           ;R0,Re, and Pc indexes
p-d f-m t-old p-d-old f-m-old pdfm                                 ;they record the changes to transmissibility rate: p-d for physical distance and f-m for face mask
count-lockdown                                                     ;it counts the lockdowns and reopenings timings
Italy1 Italy2 Italy3 Italy4 Italy5 Italy6                          ;lockdown phases for Italy
Germany1 Germany2 Germany3 Germany4 Germany5 Germany6              ;lockdown phases for Germany
Sweden1 Sweden2 Sweden3 Sweden4 Sweden5 Sweden6                    ;lockdown phases for Sweden
Brazil1 Brazil2 Brazil3 Brazil4 Brazil5 Brazil6                    ;lockdown phases for Brazil
h-saturation                                                       ;ICU hospital beds saturation
seniors                                                            ;over-65 persons (country-specific)
hospital-beds                                                      ;index of ICU beds for seriously ill patients in hospital (country-specific)
hospitalized-rate                                                  ;hospitalization rate (country-specific)
case-fatality-rate                                                 ;case fatality rate (country-specific)
recovery-index                                                     ;recovery index (country-specific)
home-isolation-rate                                                ;non-seriously ill patients (country-specific)
gdp-init                                                           ;initial GDP value
gdp-value                                                          ;GDP value (used for graph)
]

turtles-own[
  countim                                                          ;counts for how many days the agent is immune
  infected?
  immune?
  senior?                                                          ;senior (True or False)
  tourist?                                                         ;tourist (True or False)
  stay-time                                                        ;staying time in the considered country (counted for the tourists)
  incubation                                                       ;incubation period: it counts how long the virus incubation lasts
  maxincub                                                         ;maximum incubation period: for the elderly it is 3 days and for the young people it is 7 days
  infectivity                                                      ;infectivity during incubation
  time-immunity                                                    ;duration of immunity: if "hospitalized" = forever (1000 ticks); if "isolated at home" = 100 ticks.
                                                                      ;;Distinction between severe cases (that develop strong antibodies) and those who do not.
  count-immunity                                                   ;count of days of immunity
]

to setup
  clear-all
  setup-turtles
  setup-infected
  setup-parameters
  set max-infected (count turtles with [infected?])
  set max-immun duration-immunity
  reset-ticks
end

to setup-turtles
  create-turtles num-turtles [
    set color white
    set shape "person"
    set size 2
    set infected? false
    set immune? false
    set senior? false
    set tourist? false
    set countim 0                                                  ;resets the immunity count
    setxy random-pxcor random-pycor
  ]
end

to setup-infected
  ask n-of init-infected turtles [
   set color red
   set infected? true
  ]
end

to setup-parameters                                               ;it sets the parameters for the different countries
;ITALY                                        ;slider parameters: num-turtles 1000; init-infect 6; transmissibility 0.30; duration-immunity 100; speed 2.0; non-contagion-index 0.01; hospitalization 100
  if Italy [
    set seniors 230 set hospital-beds 13 set hospitalized-rate 1.5 set case-fatality-rate 0.8 set recovery-index 5.0
    set home-isolation-rate 5.0 set hospitalization 100 set transmissibility 0.30 set speed 2.0
  ]
  if Italy [set Italy1 39 set Italy2 51 set Italy3 95 set Italy4 109 set Italy5 128 set Italy6 156 set count-lockdown 0]

;GERMANY                                      ;slider parameters: num-turtles 1000; init-infect 6; transmissibility 0.30; duration-immunity 100; speed 2.0; non-contagion-index 0.01; hospitalization 60
  if Germany [
    set seniors 210 set hospital-beds 30 set hospitalized-rate 1.0 set case-fatality-rate 0.3 set recovery-index 6.0
    set home-isolation-rate 5.0 set hospitalization 60 set transmissibility 0.30 set speed 2.0
  ]
  if Germany [set Germany1 49 set Germany2 55 set Germany3 84 set Germany4 100 set Germany5 128 set Germany6 156 set count-lockdown 0]

;SWEDEN                                        ;slider parameters: num-turtles 1000; init-infect 6; transmissibility 0.30; duration-immunity 100; speed 2.0; non-contagion-index 0.01; hospitalization 100
  if Sweden [
    set seniors 200 set hospital-beds 20 set hospitalized-rate 1.5 set case-fatality-rate 0.4 set recovery-index 1.5
    set home-isolation-rate 4.7 set hospitalization 100 set transmissibility 0.30 set speed 2.0
  ]
  if Sweden [set Sweden1 47 set Sweden2 61 set Sweden3 103 set Sweden4 134 set count-lockdown 0]

;BRAZIL                                         ;slider parameters: num-turtles 1000; init-infect 6; transmissibility 0.30; duration-immunity 100; speed 2.0; non-contagion-index 0.01; hospitalization 100
  if Brazil [
    set seniors 90 set hospital-beds 9 set hospitalized-rate 1.3 set case-fatality-rate 0.3 set recovery-index 2.5
    set home-isolation-rate 6.0 set hospitalization 100 set transmissibility 0.30 set speed 2.0
  ]
  if Brazil [set Brazil1 21 set Brazil2 28 set Brazil3 51 set count-lockdown 0]

end

to go
  if ticks >= 365 [stop]                                                                      ;the simulation stops when tick = 365 (one year)
  if (count turtles with [color = red] + count turtles with [color = orange] +
    count turtles with [color = green]) >= 500 [stop]                                         ;contagion out of control!
  if ticks = 1 [ask n-of seniors turtles [set senior? true]]                                  ;a part of the population is elderly: this is regulated by the "seniors" variable
  infect-susceptibles                                                                         ;contagion phase
  recover-infected                                                                            ;some of the infected recover
  if count turtles with [color = blue or color = sky] >= 1
  [timeline]                                                                                  ;determines the stages of political decisions on lockdowns and reopenings
  move                                                                                        ;;;notice that the blue (hospitalized), the yellows (dead), and light blue (in home isolation) do not move

  total-gdp                                                                                   ;GDP calculation
  ;calculate-max-infected                                                                     ;;;;;;;;;;; unused variable (can be ignored) ;;;;;;;;;;
  if (total-cases > hospitalization) [
    ifelse hospital-capacity? and (count turtles with [color = blue] >= hospital-beds)
    [hospital-capacity] [hospital]]                                                           ;the model executes another routine (with an higher case fatality) when the max number of ICU beds is reached

  setup-tourist                                                                               ;tourist setup
  tourism                                                                                     ;tourist actions
  Rzero                                                                                       ;R0 and Re indexes calculation
  Herd-immunity                                                                               ;calculates level to be reached for herd immunity
  Immunity                                                                                    ;calculates immunity periods (different for blue and light blue)
  tick
end

to infect-susceptibles            ;**************** ATTENTION : depending on the selected country and its implemented measures, this step will vary ****************


 if Italy [
  if count-lockdown = (Italy1 - 1)                                                                                               ;settings for masks use and physical distance
   [set t-old transmissibility
   set p-d-old (transmissibility * 0.102)
   set p-d (transmissibility - (transmissibility * 0.102))
   set f-m-old (transmissibility * 0.143)
   set f-m (transmissibility - (transmissibility * 0.143))
   set pdfm (transmissibility - (transmissibility * 0.143 + transmissibility * 0.102))
  ]]

  if Italy [
  if count-lockdown = Italy1
      [if physical-distance [ifelse face-mask [set transmissibility pdfm][set transmissibility p-d]]]                             ;physical distance

  if count-lockdown = Italy1
    [if face-mask [ifelse physical-distance [set transmissibility pdfm][set transmissibility f-m]]]                               ;masks use
  ]

  if Germany [
  if count-lockdown = (Germany1 - 1)                                                                                              ;settings for masks use and physical distance
   [set t-old transmissibility
   set p-d-old (transmissibility * 0.102)
   set p-d (transmissibility - (transmissibility * 0.102))
   set f-m-old (transmissibility * 0.143)
   set f-m (transmissibility - (transmissibility * 0.143))
   set pdfm (transmissibility - (transmissibility * 0.143 + transmissibility * 0.102))
  ]]

  if Germany [
  if count-lockdown = Germany1
      [if physical-distance [ifelse face-mask [set transmissibility pdfm][set transmissibility p-d]]]                             ;physical distance

  if count-lockdown = Germany1
    [if face-mask [ifelse physical-distance [set transmissibility pdfm][set transmissibility f-m]]]                               ;masks use
  ]

  if Sweden [
  if count-lockdown = (Sweden1 - 1)                                                                                               ;settings for masks use and physical distance
   [set t-old transmissibility
   set p-d-old (transmissibility * (0.102))
   set p-d (transmissibility - (transmissibility * (0.102)))
   set f-m-old (transmissibility * (0.143 / 2))
   set f-m (transmissibility - (transmissibility * (0.143 / 2)))                                                                  ;the values are halved because there are no obligations, only advice
   set pdfm (transmissibility - (transmissibility * (0.143 / 2) + transmissibility * (0.102)))
  ]]

  if Sweden [
  if count-lockdown = Sweden2
      [if physical-distance [ifelse face-mask [set transmissibility pdfm][set transmissibility p-d]]]                              ;physical distance

  if count-lockdown = Sweden1
    [if face-mask [ifelse physical-distance [set transmissibility pdfm][set transmissibility f-m]]]                                ;masks use
  ]

  if Brazil [
  if count-lockdown = (Brazil1 - 1)                                                                                                ;settings for masks use and physical distance
  [set t-old transmissibility
   set p-d-old (transmissibility * (0.102 / 2))                                                                                    ;the values are halved because there are obligations only in some provinces
   set p-d (transmissibility - (transmissibility * (0.102 / 2)))
   set f-m-old (transmissibility * (0.143 / 2))
   set f-m (transmissibility - (transmissibility * (0.143 / 2)))                                                                   ;the values are halved because there are obligations only in some provinces
   set pdfm (transmissibility - (transmissibility * (0.143 / 2) + transmissibility * (0.102)))
  ]]

  if Brazil [
  if count-lockdown = Brazil3
      [if physical-distance [ifelse face-mask [set transmissibility pdfm][set transmissibility p-d]]]                              ;physical distance

  if count-lockdown = Brazil3
    [if face-mask [ifelse physical-distance [set transmissibility pdfm][set transmissibility f-m]]]                                ;masks use
  ]

  ask turtles with [color = white] [                                                                                               ;main contagion mechanism
    let infected-neighbors (count other turtles with [color = red or color = pink or color = sky or (color = orange and incubation >= 4)] in-radius 1)
    if (random-float 1 <  1 - (((1 - transmissibility) ^ infected-neighbors)) and not immune?)
      [set infected? true set color orange]]                                                                                       ;orange == virus in incubation

  ask turtles with [color = orange] [if incubation = 0 [if senior? = true [ifelse random-normal 3 1 < 3 [set maxincub 3] [set maxincub 5]]]]
  ask turtles with [color = orange] [if incubation = 0 [if senior? = false [ifelse random-normal 7 2 < 7 [set maxincub 5] [set maxincub 7]]]]
  ask turtles with [color = orange] [set incubation incubation + 1]
  ask turtles with [color = orange] [if incubation = maxincub [set color red set incubation 0]]

  ask turtles with [color = white] [                                                                                                ;contagion mechanism with incubation
    let infected-neighbors1 (count other turtles with [incubation = 1 and color = orange] in-radius 1)
    if (random-float 1 <  1 - (((1 - (transmissibility * 0.3)) ^ infected-neighbors1)) and not immune?)
      [set infected? true set color orange]]

  ask turtles with [color = white] [                                                                                                ;contagion mechanism with incubation
    let infected-neighbors2 (count other turtles with [incubation = 2 and color = orange] in-radius 1)
    if (random-float 1 <  1 - (((1 - (transmissibility * 0.4)) ^ infected-neighbors2)) and not immune?)
      [set infected? true set color orange]]

  ask turtles with [color = white] [                                                                                                ;contagion mechanism with incubation
    let infected-neighbors3 (count other turtles with [incubation = 3 and color = orange] in-radius 1)
    if (random-float 1 <  1 - (((1 - (transmissibility * 0.5)) ^ infected-neighbors3)) and not immune?)
      [set infected? true set color orange]]

  ask turtles with [color = orange] [                                                                                               ;definition of asymptomatics
    if (random-float 1 <  0.08 and not immune?)
      [set infected? true set color green]]

  ask turtles with [color = white or color = green] [                                                                               ;contagion mechanism with asymptomatics
    let infected-neighbors-asympt (count other turtles with [color = green] in-radius 1)
    if (random-float 1 <  1 - (((1 - (transmissibility * 0.1)) ^ infected-neighbors-asympt)) and not immune?)
      [set infected? true set color orange]]

  ask turtles with [color = orange or color = green] [
    let infected-neighbors-og (count other turtles with [color = red or color = pink or color = sky or (color = orange and incubation >= 4)] in-radius 1)
    if (random-float 1 <  1 - (((1 - (transmissibility)) ^ infected-neighbors-og)) and not immune?)
      [set infected? true set color red]]


  if hospital-capacity?[
    ifelse (count turtles with [color = blue] > hospital-beds) [set h-saturation 1]                                                  ;used for the graph about ICU hospital beds saturation
    [set h-saturation (count turtles with [color = blue] / (hospital-beds))]]

end

to timeline

; ITALY                              ;statistics: % over 65 on population = 22.6; ICU hospital beds = 2.6 each 1000; deaths/total cases =  14.55; healed/total cases = 76.89
  if Italy [

 set count-lockdown count-lockdown + 1
  if count-lockdown = Italy1 [set speed 1.7]               ;first lockdown: between municipalities (plus physical distancing and masks use)
  if count-lockdown = Italy2 [set speed 1.3]               ;second lockdown: all the non-essential activities
  if count-lockdown = Italy3 [set speed 1.5]               ;first reopenings
  if count-lockdown = Italy4 [set speed 1.7]               ;further reopenings
  if count-lockdown = Italy5 [set speed 2.0]               ;regions and EU reopening
  ;if count-lockdown = Italy6 [tourism]                    ;tourism reopening
  ]


; GERMANY                                 ;statistics: % over 65 on population = 21.4; ICU hospital beds = 6.0 each 1000; deaths/total cases = 4.67; healed/total cases = 91.15
if Germany [

 set count-lockdown count-lockdown + 1
  if count-lockdown = Germany1 [set speed 1.7]               ;first lockdown: schools, bar, restaurants, etc.
  if count-lockdown = Germany2 [set speed 1.3]               ;second lockdown: all the non-essential activities (plus physical distancing and masks use)
  if count-lockdown = Germany3 [set speed 1.5]               ;first reopenings
  if count-lockdown = Germany4 [set speed 1.7]               ;further reopenings
  if count-lockdown = Germany5 [set speed 2.0]               ;regions and EU reopening
  ;if count-lockdown = Germany6 [tourism]                    ;tourism reopening
  ]


; SWEDEN                                  ;statistics: % over 65 on population = 19.8; ICU hospital beds = 2.0 each 1000; deaths/total cases = 9.02; healed/total cases = 12.74
  if Sweden [

 set count-lockdown count-lockdown + 1
  if count-lockdown = Sweden1 [set speed 1.8]               ;first lockdown: schools
  if count-lockdown = Sweden2 [set speed 1.8]               ;physical distancing
  if count-lockdown = Sweden3 [set speed 1.6]               ;restrictions on travels
  if count-lockdown = Sweden4 [set speed 1.5]               ;further restrictions on travels
  ;if count-lockdown = Sweden5 [set speed 2.0]
  ;if count-lockdown = Sweden6 [tourism]                     ;tourism reopening
  ]

; BRAZIL                                  ;statistics: % over 65 on population = 8.6; ICU hospital beds = 1.1 each 1000; deaths/total cases = 4.65; healed/total cases = 49.81
  if Brazil [

 set count-lockdown count-lockdown + 1
  if count-lockdown = Brazil1 [set speed 1.8]               ;a district closes the non-essential activities
  if count-lockdown = Brazil2 [set speed 1.6]               ;another (more populous) district closes its non-essential activities
  if count-lockdown = Brazil3 [set speed 1.7]               ;some reopenings (but with physical distancing and masks use)
  ;if count-lockdown = Brazil4 [set speed 1.7]              ;further reopenings
  ;if count-lockdown = Brazil5 [set speed 2.0]              ;regions and EU reopening
  ;if count-lockdown = Brazil6 [tourism]                    ;tourism reopening
  ]

end

to hospital-capacity                                                                                                                    ;when all the hospital beds are occupied
  ask turtles with [color = red or color = pink]
  [if random-float 100 < hospitalized-rate [set color sky set immune? false set infected? true]]                                        ;defines the sick and not hospitalized people: light blue
  ask turtles with [color = sky]
  [if random-float 100 < (case-fatality-rate * 1.5) and senior? = false [set color yellow]]                                       ;defines the dead: yellow (without hospital the percentage increases)
  ask turtles with [color = sky]
  [if random-float 100 < (case-fatality-rate * 6 * 1.5) and senior? = true [set color yellow]]                                    ;defines the dead seniors: yellow (without hospital the percentage increases)
  ask turtles with [color = sky]                                                                                                        ;defines the recovered people: they become gray
  [if random-float 100 < (recovery-index / 1.5) and senior? = false [set color gray set healed healed + 1 set time-immunity max-immun]]      ;(with no hospital the percentage decreases)
  ask turtles with [color = sky]                                                                                                        ;defines the recovered seniors: they become gray
  [if random-float 100 < (recovery-index / 2.5) and senior? = true [set color gray set healed healed + 1 set time-immunity max-immun]]       ;(with a decreased percentage)

  ask turtles with [color = blue]
  [if random-float 100 < case-fatality-rate and senior? = false [set color yellow]]                                                         ;defines the dead: yellow
  ask turtles with [color = blue]
  [if random-float 100 < (case-fatality-rate * 6) and senior? = true [set color yellow]]                                                    ;defines the dead seniors: yellow
  ask turtles with [color = blue]                                                                                                       ;defines the recovered people: they become gray
  [if random-float 100 < recovery-index and senior? = false [set color gray set healed healed + 1 set time-immunity (max-immun * 10)]]       ;duration of immunity is forever
  ask turtles with [color = blue]                                                                                                       ;defines the recovered seniors: they become gray
  [if random-float 100 < (recovery-index / 2) and senior? = true [set color gray set healed healed + 1 set time-immunity (max-immun * 10)]]  ;duration of immunity is forever

end

to move
  ask turtles [if color = white and senior? = false [right random 360 forward speed]]
  ask turtles [if color = white and senior? = true [right random 360 forward (speed / 2)]]                                              ;the seniors move less
  ask turtles [if color = orange and senior? = false [right random 360 forward speed]]
  ask turtles [if color = orange and senior? = true [right random 360 forward (speed / 2)]]
  ask turtles [if color = red [right random 360 forward speed]]
  ask turtles [if color = red and senior? = true [right random 360 forward (speed / 2)]]
  ask turtles [if color = green [right random 360 forward speed]]
  ask turtles [if color = green and senior? = true [right random 360 forward (speed / 2)]]
  ask turtles [if color = gray [right random 360 forward speed]]
  ask turtles [if color = gray and senior? = true [right random 360 forward (speed / 2)]]
  set current-positive (count turtles with [color = red] + count turtles with [color = blue] + count turtles with [color = pink]        ;defines the "current-positive" variable
    + count turtles with [color = orange] + count turtles with [color = sky] + count turtles with [color = green])
  set deaths (count turtles with [color = yellow])                                                                                      ;defines the "deaths" variable
  set total-cases (current-positive + deaths + healed)                                                                                  ;defines the "total-cases" variable
end

to total-gdp                                                                                                                            ;GDP calculation
  if ticks = 2 [set gdp-init (gdp)]
  let gdpred (count turtles with [color = red and senior? = false])                                                                     ;GDP calculation for the workers with a speed defined by the slider
  let gdporange (count turtles with [color = orange and senior? = false])
  let gdpwhite (count turtles with [color = white and senior? = false])
  let gdpgray (count turtles with [color = gray and senior? = false])
  let gdpgreen (count turtles with [color = green and senior? = false])
  let gdp1 (gdpred + gdporange + gdpwhite + gdpgray + gdpgreen) * speed

  let gdpred1 (count turtles with [color = red and senior? = true])                                                                     ;GDP calculation for the seniors with less speed (1/2)
  let gdporange1 (count turtles with [color = orange and senior? = true])
  let gdpwhite1 (count turtles with [color = white and senior? = true])
  let gdpgray1 (count turtles with [color = gray and senior? = true])
  let gdpgreen1 (count turtles with [color = green and senior? = true])
  let gdp2 (gdpred1 + gdporange1 + gdpwhite1 + gdpgray1 + gdpgreen1) * (speed / 2)

  set gdp (gdp1 + gdp2)
  if ticks > 2 [set gdp-value (((gdp / gdp-init) - 1) * 100) / 2] set gdp-value (precision gdp-value 2)                           ;it is for monitoring %GDP and plot its graph
                                                                                           ; percentage increment normalized by the initial agents speed.

end

to recover-infected
  ask turtles with [color = red]
  [if random-float 1 < non-contagion-index
    [set infected? false
      ifelse remove-recovered?
      [set immune? true
        set color gray
        set healed healed + 1]
      [set color white]]]

end

to hospital

  ask turtles with [color = red or color = pink]
  [if random-float 100 < hospitalized-rate [set color blue set immune? false set infected? true]]                                        ;defines the hospitalized people: blue
  ask turtles with [color = blue]
  [if random-float 100 < case-fatality-rate and senior? = false [set color yellow]]                                                          ;defines the dead: yellow
  ask turtles with [color = blue]
  [if random-float 100 < (case-fatality-rate * 8) and senior? = true [set color yellow]]                                                     ;defines the dead seniors: yellow
  ask turtles with [color = blue]                                                                                                        ;defines the recovered people: they become gray
  [if random-float 100 < recovery-index and senior? = false [set color gray set healed healed + 1 set time-immunity (max-immun * 10)]]        ;immunity duration is forever
  ask turtles with [color = blue]                                                                                                        ;defines the recovered seniors: they become gray
  [if random-float 100 < (recovery-index / 2) and senior? = true [set color gray set healed healed + 1 set time-immunity (max-immun * 10)]]   ;immunity duration is forever


  ask turtles with [color = red or color = pink]
  [if random-float 100 < home-isolation-rate [set color sky set immune? false set infected? true]]                                       ;defines people in home isolation: light blue
  ask turtles with [color = sky]
  [if random-float 100 < (case-fatality-rate / 1.5) and senior? = false [set color yellow]]                                                  ;defines the dead: yellow
  ask turtles with [color = sky]                                                                                                         ;defines the recovered people: they become gray
  [if random-float 100 < (case-fatality-rate * 5.0) and senior? = true [set color yellow]]                                                   ;defines the dead seniors: yellow
  ask turtles with [color = sky]                                                                                                         ;defines the recovered people: they become gray
  [if random-float 100 < (recovery-index * 2) and senior? = false [set color gray set healed healed + 1 set time-immunity max-immun]]         ;immunity duration is defined by the slider value
  ask turtles with [color = sky]                                                                                                         ;defines the recovered seniors: they become gray
  [if random-float 100 < recovery-index and senior? = true [set color gray set healed healed + 1 set time-immunity max-immun]]                ;immunity duration is defined by the slider value


  ask turtles with [color = green]                                                                                                       ;puts asymptomatics in home isolation
  [if random-float 100 < (home-isolation-rate / 7) [set color sky set immune? false set infected? true]]                                 ;less probability to find them
end

to setup-tourist                                                                                                                         ;settings for the infected tourists
  if Italy [
  if tourism? [if count-lockdown >= Italy6 [if (count turtles with [tourist? = true] = 0)                                                ;reopening to tourism
  [create-turtles 2 [
    set color pink
    set shape "person"
    set size 2
    set infected? true
    set immune? false
    set senior? false
    set tourist? true
    set stay-time 0                                                                                                                      ;sets to 0 the staying time
    setxy random-pxcor random-pycor
  ]]]]]

  if Italy [
  if tourism? [if count-lockdown >= Italy6 [if (count turtles with [tourist? = true] = 1)                                                ;re-sets infected tourists to 2
  [create-turtles 1 [
    set color pink
    set shape "person"
    set size 2
    set infected? true
    set immune? false
    set senior? false
    set tourist? true
    set stay-time 0
    setxy random-pxcor random-pycor
  ]]]]]

  if Germany [
  if tourism? [if count-lockdown >= Germany6 [if (count turtles with [tourist? = true] = 0)                                                ;reopening to tourism
  [create-turtles 2 [
    set color pink
    set shape "person"
    set size 2
    set infected? true
    set immune? false
    set senior? false
    set tourist? true
    set stay-time 0                                                                                                                      ;sets to 0 the staying time
    setxy random-pxcor random-pycor
  ]]]]]

  if Germany [
  if tourism? [if count-lockdown >= Germany6 [if (count turtles with [tourist? = true] = 1)                                                ;re-sets infected tourists to 2
  [create-turtles 1 [
    set color pink
    set shape "person"
    set size 2
    set infected? true
    set immune? false
    set senior? false
    set tourist? true
    set stay-time 0
    setxy random-pxcor random-pycor
  ]]]]]

  if Sweden [
  if tourism? [if (count turtles with [tourist? = true] = 0)                                                ;no closure to tourism
  [create-turtles 1 [
    set color pink
    set shape "person"
    set size 2
    set infected? true
    set immune? false
    set senior? false
    set tourist? true
    set stay-time 0                                                                                                                      ;sets to 0 the staying time
    setxy random-pxcor random-pycor
  ]]]]

  if Brazil [
  if tourism? [if (count turtles with [tourist? = true] = 0)                                                ;no closure to tourism
  [create-turtles 1 [
    set color pink
    set shape "person"
    set size 2
    set infected? true
    set immune? false
    set senior? false
    set tourist? true
    set stay-time 0                                                                                                                      ;sets to 0 the staying time
    setxy random-pxcor random-pycor
  ]]]]


end

to tourism                                                                                                                               ;actions of the infected tourist
  ask turtles with [tourist? = true] [set stay-time stay-time + 1]
  ask turtles [if color = pink and tourist? = true [right random 360 forward (speed * 1)]]
  ask turtles with [tourist? = true] [if stay-time > 9 [die]]
end

to Rzero                                                                                                                                 ;R0 parameter construction
  if ticks = 1 or ticks = 11 or ticks = 21 or ticks = 31 or ticks = 41 or ticks = 51 or ticks = 61 or ticks = 71 or ticks = 81 or ticks = 91
  or ticks = 101 or ticks = 111 or ticks = 121 or ticks = 131 or ticks = 141 or ticks = 151 or ticks = 161 or ticks = 171 or ticks = 181 or ticks = 191
  or ticks = 201 or ticks = 211 or ticks = 221 or ticks = 231 or ticks = 241 or ticks = 251 or ticks = 261 or ticks = 271 or ticks = 281 or ticks = 291
  or ticks = 301 or ticks = 311 or ticks = 321 or ticks = 331 or ticks = 341 or ticks = 351 or ticks = 361 or ticks = 371
  [set ma5 ((tc1 + tc10 + tc9 + tc8 + tc7) / 5) set ma10 ((tc10 + tc9 + tc8 + tc7 + tc6 + tc5 + tc4 + tc3 + tc2 + tc1) / 10) set tc1 total-cases set r01 R0-calculation]

 if ticks = 2 or ticks = 12 or ticks = 22 or ticks = 32 or ticks = 42 or ticks = 52 or ticks = 62 or ticks = 72 or ticks = 82 or ticks = 92
  or ticks = 102 or ticks = 112 or ticks = 122 or ticks = 132 or ticks = 142 or ticks = 152 or ticks = 162 or ticks = 172 or ticks = 182 or ticks = 192
  or ticks = 202 or ticks = 212 or ticks = 222 or ticks = 232 or ticks = 242 or ticks = 252 or ticks = 262 or ticks = 272 or ticks = 282 or ticks = 292
  or ticks = 302 or ticks = 312 or ticks = 322 or ticks = 332 or ticks = 342 or ticks = 352 or ticks = 362 or ticks = 372
  [set ma5 ((tc2 + tc1 + tc10 + tc9 + tc8) / 5) set ma10 ((tc10 + tc9 + tc8 + tc7 + tc6 + tc5 + tc4 + tc3 + tc2 + tc1) / 10) set tc2 total-cases set r02 R0-calculation]

  if ticks = 3 or ticks = 13 or ticks = 23 or ticks = 33 or ticks = 43 or ticks = 53 or ticks = 63 or ticks = 73 or ticks = 83 or ticks = 93
  or ticks = 103 or ticks = 113 or ticks = 123 or ticks = 133 or ticks = 143 or ticks = 153 or ticks = 163 or ticks = 173 or ticks = 183 or ticks = 193
  or ticks = 203 or ticks = 213 or ticks = 223 or ticks = 233 or ticks = 243 or ticks = 253 or ticks = 263 or ticks = 273 or ticks = 283 or ticks = 293
  or ticks = 303 or ticks = 313 or ticks = 323 or ticks = 333 or ticks = 343 or ticks = 353 or ticks = 363 or ticks = 373
  [set ma5 ((tc3 + tc2 + tc1 + tc10 + tc9) / 5) set ma10 ((tc10 + tc9 + tc8 + tc7 + tc6 + tc5 + tc4 + tc3 + tc2 + tc1) / 10) set tc3 total-cases set r03 R0-calculation]

  if ticks = 4 or ticks = 14 or ticks = 24 or ticks = 34 or ticks = 44 or ticks = 54 or ticks = 64 or ticks = 74 or ticks = 84 or ticks = 94
  or ticks = 104 or ticks = 114 or ticks = 124 or ticks = 134 or ticks = 144 or ticks = 154 or ticks = 164 or ticks = 174 or ticks = 184 or ticks = 194
  or ticks = 204 or ticks = 214 or ticks = 224 or ticks = 234 or ticks = 244 or ticks = 254 or ticks = 264 or ticks = 274 or ticks = 284 or ticks = 294
  or ticks = 304 or ticks = 314 or ticks = 324 or ticks = 334 or ticks = 344 or ticks = 354 or ticks = 364 or ticks = 374
  [set ma5 ((tc4 + tc3 + tc2 + tc1 + tc10) / 5) set ma10 ((tc10 + tc9 + tc8 + tc7 + tc6 + tc5 + tc4 + tc3 + tc2 + tc1) / 10) set tc4 total-cases set r04 R0-calculation]

  if ticks = 5 or ticks = 15 or ticks = 25 or ticks = 35 or ticks = 45 or ticks = 55 or ticks = 65 or ticks = 75 or ticks = 85 or ticks = 95
  or ticks = 105 or ticks = 115 or ticks = 125 or ticks = 135 or ticks = 145 or ticks = 155 or ticks = 165 or ticks = 175 or ticks = 185 or ticks = 195
  or ticks = 205 or ticks = 215 or ticks = 225 or ticks = 235 or ticks = 245 or ticks = 255 or ticks = 265 or ticks = 275 or ticks = 285 or ticks = 295
  or ticks = 305 or ticks = 315 or ticks = 325 or ticks = 335 or ticks = 345 or ticks = 355 or ticks = 365 or ticks = 375
  [set ma5 ((tc5 + tc4 + tc3 + tc2 + tc1) / 5) set ma10 ((tc10 + tc9 + tc8 + tc7 + tc6 + tc5 + tc4 + tc3 + tc2 + tc1) / 10) set tc5 total-cases set r05 R0-calculation]

  if ticks = 6 or ticks = 16 or ticks = 26 or ticks = 36 or ticks = 46 or ticks = 56 or ticks = 66 or ticks = 76 or ticks = 86 or ticks = 96
  or ticks = 106 or ticks = 116 or ticks = 126 or ticks = 136 or ticks = 146 or ticks = 156 or ticks = 166 or ticks = 176 or ticks = 186 or ticks = 196
  or ticks = 206 or ticks = 216 or ticks = 226 or ticks = 236 or ticks = 246 or ticks = 256 or ticks = 266 or ticks = 276 or ticks = 286 or ticks = 296
  or ticks = 306 or ticks = 316 or ticks = 326 or ticks = 336 or ticks = 346 or ticks = 356 or ticks = 366 or ticks = 376
  [set ma5 ((tc6 + tc5 + tc4 + tc3 + tc2) / 5) set ma10 ((tc10 + tc9 + tc8 + tc7 + tc6 + tc5 + tc4 + tc3 + tc2 + tc1) / 10) set tc6 total-cases set r06 R0-calculation]

  if ticks = 7 or ticks = 17 or ticks = 27 or ticks = 37 or ticks = 47 or ticks = 57 or ticks = 67 or ticks = 77 or ticks = 87 or ticks = 97
  or ticks = 107 or ticks = 117 or ticks = 127 or ticks = 137 or ticks = 147 or ticks = 157 or ticks = 167 or ticks = 177 or ticks = 187 or ticks = 197
  or ticks = 207 or ticks = 217 or ticks = 227 or ticks = 237 or ticks = 247 or ticks = 257 or ticks = 267 or ticks = 277 or ticks = 287 or ticks = 297
  or ticks = 307 or ticks = 317 or ticks = 327 or ticks = 337 or ticks = 347 or ticks = 357 or ticks = 367 or ticks = 377
  [set ma5 ((tc7 + tc6 + tc5 + tc4 + tc3) / 5) set ma10 ((tc10 + tc9 + tc8 + tc7 + tc6 + tc5 + tc4 + tc3 + tc2 + tc1) / 10) set tc7 total-cases set r07 R0-calculation]

  if ticks = 8 or ticks = 18 or ticks = 28 or ticks = 38 or ticks = 48 or ticks = 58 or ticks = 68 or ticks = 78 or ticks = 88 or ticks = 98
  or ticks = 108 or ticks = 118 or ticks = 128 or ticks = 138 or ticks = 148 or ticks = 158 or ticks = 168 or ticks = 178 or ticks = 188 or ticks = 198
  or ticks = 208 or ticks = 218 or ticks = 228 or ticks = 238 or ticks = 248 or ticks = 258 or ticks = 268 or ticks = 278 or ticks = 288 or ticks = 298
  or ticks = 308 or ticks = 318 or ticks = 328 or ticks = 338 or ticks = 348 or ticks = 358 or ticks = 368 or ticks = 378
  [set ma5 ((tc8 + tc7 + tc6 + tc5 + tc4) / 5) set ma10 ((tc10 + tc9 + tc8 + tc7 + tc6 + tc5 + tc4 + tc3 + tc2 + tc1) / 10) set tc8 total-cases set r08 R0-calculation]

  if ticks = 9 or ticks = 19 or ticks = 29 or ticks = 39 or ticks = 49 or ticks = 59 or ticks = 69 or ticks = 79 or ticks = 89 or ticks = 99
  or ticks = 109 or ticks = 119 or ticks = 129 or ticks = 139 or ticks = 149 or ticks = 159 or ticks = 169 or ticks = 179 or ticks = 189 or ticks = 199
  or ticks = 209 or ticks = 219 or ticks = 229 or ticks = 239 or ticks = 249 or ticks = 259 or ticks = 269 or ticks = 279 or ticks = 289 or ticks = 299
  or ticks = 309 or ticks = 319 or ticks = 329 or ticks = 339 or ticks = 349 or ticks = 359 or ticks = 369 or ticks = 379
  [set ma5 ((tc9 + tc8 + tc7 + tc6 + tc5) / 5) set ma10 ((tc10 + tc9 + tc8 + tc7 + tc6 + tc5 + tc4 + tc3 + tc2 + tc1) / 10) set tc9 total-cases set r09 R0-calculation]

  if ticks = 10 or ticks = 20 or ticks = 30 or ticks = 40 or ticks = 50 or ticks = 60 or ticks = 70 or ticks = 80 or ticks = 90 or ticks = 100
  or ticks = 110 or ticks = 120 or ticks = 130 or ticks = 140 or ticks = 150 or ticks = 160 or ticks = 170 or ticks = 180 or ticks = 190 or ticks = 200
  or ticks = 210 or ticks = 220 or ticks = 230 or ticks = 240 or ticks = 250 or ticks = 260 or ticks = 270 or ticks = 280 or ticks = 290 or ticks = 300
  or ticks = 310 or ticks = 320 or ticks = 330 or ticks = 340 or ticks = 350 or ticks = 360 or ticks = 370 or ticks = 380
  [set ma5 ((tc10 + tc9 + tc8 + tc7 + tc6) / 5) set ma10 ((tc10 + tc9 + tc8 + tc7 + tc6 + tc5 + tc4 + tc3 + tc2 + tc1) / 10) set tc10 total-cases set r010 R0-calculation]

  ifelse (ma5 - ma10) > 0 and (total-cases - ma5) > 0 [
    set R0-calculation (total-cases - ma5) / (ma5 - ma10) if R0-calculation > 5 [set R0-calculation 5]] [set R0-calculation 0]             ;5-day and 10-day moving average
  set R0 (((r01 + r02 + r03 + r04 + r05 + r06 + r07 + r08 + r09 + r010) / 10) * 0.8)
  set Re R0 * (count turtles with [color = white] / num-turtles)                                                                           ;Re parameter calculation (effective reproduction number)

end

to Herd-immunity

  if ticks > 1 [ifelse R0 != 0 [set Pc (1 - (1 / R0)) if Pc < 0 [set Pc 0]] [set Pc 0]]                                                    ;herd immunity threshold calculation

end

to Immunity

  ask turtles with [color = gray] [set countim countim + 1]
  ask turtles with [color = gray] [if countim = time-immunity [set color white set immune? false set countim 0]]                           ;differentiates the immunity duration
                                                                                                                                           ;if the agent has been in hospital, immune for the whole simulation
end

to calculate-max-infected                                                                                                                  ;;;;;;; unused variable (can be ignored) ;;;;;;;
  let x (count turtles with [infected?])
  if x > max-infected
  [set max-infected x]
end
@#$#@#$#@
GRAPHICS-WINDOW
382
1
1408
522
-1
-1
6.323
1
10
1
1
1
0
1
1
1
-80
80
-40
40
1
1
1
ticks
30.0

BUTTON
7
11
74
45
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
157
10
221
44
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
6
48
179
81
num-turtles
num-turtles
100
2000
1000.0
50
1
NIL
HORIZONTAL

SLIDER
6
85
179
118
init-infected
init-infected
1
20
6.0
1
1
NIL
HORIZONTAL

SLIDER
7
122
180
155
transmissibility
transmissibility
0
1
0.3
.01
1
NIL
HORIZONTAL

SLIDER
7
195
180
228
speed
speed
0
5
2.0
.1
1
NIL
HORIZONTAL

PLOT
13
531
393
836
evolution of contagion
time
rate
0.0
366.0
0.0
0.2
true
true
"" ""
PENS
"infected" 1.0 0 -2674135 true "" "plot (count turtles with [color = red]) / num-turtles"
"immune" 1.0 0 -7500403 true "" "plot (count turtles with [color = grey]) / num-turtles\n;plot (healed / num-turtles)"
"hospitalized" 1.0 0 -13345367 true "" "plot (count turtles with [color = blue] / num-turtles)"
"deaths" 1.0 0 -1184463 true "" "plot (count turtles with [color = yellow] / num-turtles)"
"in-isolation" 1.0 0 -13791810 true "" "plot (count turtles with [color = sky] / num-turtles)"

SLIDER
9
232
181
265
non-contagion-index
non-contagion-index
0
0.1
0.01
.005
1
NIL
HORIZONTAL

SWITCH
198
49
370
82
remove-recovered?
remove-recovered?
0
1
-1000

SLIDER
8
159
180
192
duration-immunity
duration-immunity
0
500
100.0
50
1
NIL
HORIZONTAL

BUTTON
298
10
369
43
one-go
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
193
281
281
326
healed
healed
17
1
11

MONITOR
197
379
282
424
deaths
count turtles with [color = yellow]
17
1
11

MONITOR
193
232
281
277
total-cases 
total-cases
17
1
11

MONITOR
287
233
374
278
current-positive
;count turtles with [color = red] + count turtles with [color = blue]\ncurrent-positive
17
1
11

MONITOR
288
331
375
376
hospitalized
count turtles with [color = blue]
17
1
11

PLOT
397
531
909
681
positive, hospitalized, in-isolation, asymptomatic
time
variables
0.0
366.0
0.0
10.0
true
true
"" ""
PENS
"hospitalized" 1.0 0 -13345367 true "" "plot (count turtles with [color = blue])"
"positive" 1.0 0 -2674135 true "" "plot (count turtles with [color = red] + \ncount turtles with [color = blue] + \ncount turtles with [color = sky] + \ncount turtles with [color = orange] + \ncount turtles with [color = green])"
"in-isolation" 1.0 0 -13791810 true "" "plot (count turtles with [color = sky])"
"asymptomatic" 1.0 0 -10899396 true "" "plot (count turtles with [color = green])"

PLOT
914
531
1214
681
healed and deaths
time
variables
0.0
366.0
0.0
10.0
true
true
"" ""
PENS
"healed" 1.0 0 -10899396 true "" "plot healed"
"deaths" 1.0 0 -1184463 true "" "plot (count turtles with [color = yellow])"
"elders-dead" 1.0 0 -5825686 true "" "plot (count turtles with [color = yellow and senior? = true])"

PLOT
1219
532
1406
682
healed rate
time
healed / cases
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if healed != 0 [if total-cases != 0 [\nplot healed / total-cases]]"

SLIDER
9
269
181
302
hospitalization
hospitalization
0
200
100.0
10
1
NIL
HORIZONTAL

MONITOR
288
380
376
425
elders-dead
count turtles with [color = yellow and senior? = true]
17
1
11

SWITCH
202
159
372
192
hospital-capacity?
hospital-capacity?
0
1
-1000

PLOT
1026
686
1214
836
hospitals saturation rate
time
rate
0.0
366.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ";plot (count turtles with [color = blue] / (hospital-beds))\nifelse hospital-capacity? [plot h-saturation]\n[plot (count turtles with [color = blue] / (hospital-beds))]"

SWITCH
202
195
372
228
tourism?
tourism?
0
1
-1000

PLOT
399
686
711
836
R0 and Re index
time
R0 and Re
0.0
366.0
0.0
1.0
true
true
"" ""
PENS
"R0" 1.0 0 -16777216 true "" ";if ticks < 30 [stop]\n;if ticks >= 400 [stop]\nplot R0"
"Re" 1.0 0 -2674135 true "" ";if ticks < 30 [stop]\n;if ticks >= 400 [stop]\nplot Re"

PLOT
717
686
1017
836
Herd Immunity rate
time
H.I.,  infected
0.0
366.0
0.0
1.0
true
true
"" ""
PENS
"Infected" 1.0 0 -16777216 true "" ";if ticks > 30\n;plot (total-cases / num-turtles)\nplot ((count turtles with [color = gray] + current-positive) / num-turtles)"
"H.I." 1.0 0 -2674135 true "" ";if ticks > 30\nplot Pc"

SWITCH
200
122
370
155
physical-distance
physical-distance
0
1
-1000

SWITCH
199
85
370
118
face-mask
face-mask
0
1
-1000

MONITOR
196
330
281
375
in-isolation
count turtles with [color = sky]
17
1
11

MONITOR
288
282
376
327
asymptomatic
count turtles with [color = green]
17
1
11

MONITOR
198
428
282
473
% deaths
count turtles with [color = yellow] * 100 / total-cases
3
1
11

MONITOR
289
429
378
474
% elders-dead
count turtles with [color = yellow and senior? = true] * 100 / count turtles with [color = yellow]
3
1
11

SWITCH
13
358
187
391
Italy
Italy
0
1
-1000

SWITCH
13
400
187
433
Germany
Germany
1
1
-1000

SWITCH
12
442
186
475
Sweden
Sweden
1
1
-1000

SWITCH
12
486
186
519
Brazil
Brazil
1
1
-1000

MONITOR
199
477
283
522
productivity
gdp-value
17
1
11

PLOT
1219
687
1406
837
productivity (%)
time
productivity
0.0
366.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if ticks > 20 [plot gdp-value]"

TEXTBOX
19
309
169
354
             Attention:\n  only one country can be \n               \"ON\"
12
0.0
0

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment-122" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="9999"/>
    <metric>ticks</metric>
    <enumeratedValueSet variable="num-turtles">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmissibility">
      <value value="0.1"/>
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recovery-rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-infected">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="turning-angle">
      <value value="10"/>
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="remove-recovered?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="HW7-1" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <steppedValueSet variable="num-turtles" first="50" step="50" last="500"/>
    <enumeratedValueSet variable="transmissibility">
      <value value="0.1"/>
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recovery-rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-infected">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="turning-angle">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="remove-recovered?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="HW7-2" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <steppedValueSet variable="num-turtles" first="50" step="50" last="500"/>
    <enumeratedValueSet variable="transmissibility">
      <value value="0.1"/>
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recovery-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-infected">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="turning-angle">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="remove-recovered?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-covid" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100000"/>
    <metric>max-infected-prop</metric>
    <metric>prop-uninfected</metric>
    <enumeratedValueSet variable="num-turtles">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmissibility">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recovery-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-infected">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="speed" first="0.25" step="0.25" last="10"/>
    <enumeratedValueSet variable="remove-recovered?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
