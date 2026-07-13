import Foundation

enum BigDoseInfoTopic: String, Identifiable, Sendable {
    case uvIndex
    case riskUsed
    case med
    case minToMED
    case minToRollOver
    case medUsed
    case sessionGoal
    case skinType
    case goal
    case peakUV
    case window
    case vitaminDWindowToday
    case dForDuration
    case dWindowOpen
    case estimatedIU
    case plannedTime
    case toReachGoal
    case safeMax
    case estimatedBloodLevel
    case bloodLevelGoalProgress
    case bloodLevelBand
    case last7DaysIntake
    case sunSafetyOverview
    case sessionSafetyAlerts
    case labResult25OHD
    case supplementBaseline
    case sunHabitOverview
    case typicalSkinExposure
    case usualSunscreen
    case casualOutdoorTime
    case incidentalDaylight
    case importedSun
    case dailyIUTarget

    var id: String { rawValue }

    var title: String {
        switch self {
        case .uvIndex:
            "UV Index"
        case .riskUsed:
            "Risk Used"
        case .med:
            "MED (burn risk)"
        case .minToMED:
            "Min to MED (burn risk)"
        case .minToRollOver:
            "Min to Roll-Over"
        case .medUsed:
            "MED (burn risk) Used"
        case .sessionGoal:
            "Session Goal"
        case .skinType:
            "Skin Type"
        case .goal:
            "Goal"
        case .peakUV:
            "Peak UV"
        case .window:
            "Window"
        case .vitaminDWindowToday:
            "Vitamin D Window Today"
        case .dForDuration:
            "D For"
        case .dWindowOpen:
            "D Window Open"
        case .estimatedIU:
            "Estimated IU"
        case .plannedTime:
            "Planned Time"
        case .toReachGoal:
            "To Reach Goal"
        case .safeMax:
            "Safe Max"
        case .estimatedBloodLevel:
            "Estimated Blood Level"
        case .bloodLevelGoalProgress:
            "Blood Level Goal"
        case .bloodLevelBand:
            "Level Band"
        case .last7DaysIntake:
            "Last 7 Days Intake"
        case .sunSafetyOverview:
            "Sun Safety - READ THIS!"
        case .sessionSafetyAlerts:
            "Session Safety Alerts"
        case .labResult25OHD:
            "25(OH)D Result"
        case .supplementBaseline:
            "Supplement Baseline"
        case .sunHabitOverview:
            "Sun Habit"
        case .typicalSkinExposure:
            "Typical Skin Exposure"
        case .usualSunscreen:
            "Usual Sunscreen"
        case .casualOutdoorTime:
            "Casual Outdoor Time"
        case .incidentalDaylight:
            "Incidental Sun"
        case .importedSun:
            "Imported Sun"
        case .dailyIUTarget:
            "Daily IU Target"
        }
    }

    var bodyText: String {
        switch self {
        case .uvIndex:
            """
            **What it does:** Shows the current **ultraviolet intensity** from Apple WeatherKit on a **0–11+** scale.

            **How to use:** Higher values mean **faster vitamin D** and **higher burn risk**. BigDose uses this live reading for session estimates and the weather card.

            **Watch for:** **UV 3–6** is often a productive range; **8+** deserves extra caution.
            """
        case .riskUsed:
            """
            **What it does:** Shows how much of your personal **MED (burn risk)** a sample exposure would use — based on your **skin type**, **UV** and about **12 minutes** of sun.

            **How to use:** **Lower is safer.** Past about **75%**, conditions are getting risky. During a live sun session, watch **MED (burn risk) Used** climb in real time instead.

            **Tip:** Open the **MED (burn risk)** info panel for the full burn-threshold explainer.
            """
        case .med:
            """
            **What it is:** **MED (burn risk)** — *minimal erythema dose* — is Science-based estimate of how much **UV exposure** would start to **redden your skin**, based on your **Fitzpatrick skin type** in **Dose DNA**.

            **How BigDose uses it:** During a sun session we count down to MED (burn risk), show **MED (burn risk) Used %** and warn to **turn over** at **halfway through your planned session** or **50% MED (burn risk)** — whichever comes first. **Nanny** adds **75%** (wrap up soon), the **95%** guidance alert and a **98%** reminder while you stay out.

            **What it is not:** A **medical measurement** or a guarantee you will or won't burn. BigDose warns — **only you stop the session**.
            """
        case .minToMED:
            """
            **What it does:** Counts down the estimated **minutes until MED (burn risk)** at the current **UV**, **cloud** and **sunscreen** settings.

            **How to use:** Plan to **turn over**, **seek shade** or **end the session** before this hits zero. **Nanny** alerts at **75%** (wrap up) and adds a **95%** guidance alert.

            **Watch for:** When **UV is low**, this number can look very long — that does not mean unlimited safe exposure.
            """
        case .minToRollOver:
            """
            **What it does:** Counts down until BigDose's **turn-over** milestone — **halfway through your planned session** or **50% of your estimated MED (burn risk)**, whichever comes first at the current **UV** and exposure settings.

            **How to use:** When this hits zero, **flip sides**, **rotate** or **change exposure** so one area of skin does not take all the UV. BigDose also sends a **Turn over** alert at that point.

            **Good to know:** On a short planned session, turn-over may arrive before **50% MED (burn risk) Used**. Even exposure helps you reach your vitamin D goal with less burn risk on any single spot.
            """
        case .medUsed:
            """
            **What it does:** Shows how much of your estimated **MED (burn risk)** this session has used so far — based on **elapsed time**, **UV**, **skin type** and exposure settings.

            **How to use:** Under **50%** is comfortable headroom. **Nanny** alerts at **75%** (wrap up), **95%** and **98%**. A stop-now warning always fires at **100%** — **only you stop it**. Exposure past **100%** counts toward **Sun risk today** on Home.

            **Tip:** Goal progress and **MED (burn risk) Used** measure different things — vitamin D gained vs. burn risk consumed.
            """
        case .sessionGoal:
            """
            **What it does:** Shows how close this sun session is to your **daily sun IU goal** — the ring and **% of goal** fill as estimated vitamin D from this session accumulates.

            **How to use:** Tap **Goal** during the session to open a slider and adjust your target IU without stopping. At **100%**, BigDose shows a **goal reached** alert — **only you stop the session**. Goals past burn guidance show a caution while **MED (burn risk) Used** keeps tracking separately. This tracks **sun IU for today**, not supplements, food or your **ng/mL** blood goal on Progress.

            **Good to know:** Goal progress and **MED (burn risk) Used** measure different things — vitamin D gained vs. burn risk consumed.
            """
        case .skinType:
            """
            **What it is:** The **Fitzpatrick scale** (**Types I–VI**) describes how skin responds to UV — especially how quickly it **burns** vs. tans.

            **How to use:** Pick the type that matches your **sunburn history**, not your tan goals. **Type I–II** burn easily. **Type III–IV** are moderate. **Type V–VI** rarely burn but still need vitamin D and still carry skin cancer risk.

            **How BigDose uses it:** Drives **MED (burn risk)**, **time-to-IU** and session safety milestones. Change anytime in **Profile → Dose DNA**.

            **Tip:** When unsure, choose the **more burn-prone** type — BigDose errs conservative.
            """
        case .goal:
            """
            **What it does:** Your target **blood vitamin D level** in **ng/mL** (nanograms per milliliter).

            **How to use:** Set it during onboarding or in **Dose DNA**. **Progress** tracks blood-level estimates against this target. **Home** tracks a separate **daily sun IU goal** — supplements and food are logged separately and do not fill the goal ring.

            **Good to know:** **ng/mL** and **IU** answer different questions — blood level vs. today's intake.
            """
        case .peakUV:
            """
            **What it does:** The **highest UV index** expected today at your location during **vitamin-D-active hours**.

            **How to use:** Compare this with the **Window** times below. Sessions near **peak UV** are usually the most **efficient for vitamin D** — and the most **burn-sensitive**.

            **Watch for:** High peak UV with a **short window** still means timing matters.
            """
        case .window:
            """
            **What it does:** The **start and end times** when the sun is high enough for meaningful **UVB vitamin D** production (about **30°** altitude and above).

            **How to use:** Aim for sun sessions **inside this range**. Outside the window, UVB is too weak for **efficient vitamin D** even on sunny days.

            **Tip:** The arc diagram above shows the same window visually across the day.
            """
        case .vitaminDWindowToday:
            """
            **What it does:** Today's **solar guidance card** — sun altitude, your **vitamin D window** and when conditions are best.

            **How to use:** Read the **arc** and **chips** below. **Tap Start Sun Session** when the window is **open** and **UV** looks right for you.

            **Good to know:** **Open now** beats **peak UV later** if you only have a few minutes outside.
            """
        case .dForDuration:
            """
            **What it does:** How long today's **vitamin D window lasts** — when the sun is high enough for meaningful **UVB** production.

            **How to use:** When the window is **open**, the smaller line shows time **remaining** today. Plan sessions **inside this span** for the best efficiency.

            **Watch for:** A long window does not mean you need to stay out the entire time.
            """
        case .dWindowOpen:
            """
            **What it does:** Tells you whether your **vitamin D window** is **open now** or when the **next one opens**.

            **How to use:** **D Window Open** means conditions are active now — a good time to **start a sun session**. **Up Next** means BigDose is counting down to the next opening.

            **Tip:** If it says **Tomorrow**, today's window may already have passed.
            """
        case .estimatedIU:
            """
            **What it does:** A **modeled vitamin D estimate** in **international units (IU)** — **not** a blood test result.

            **How to use:** BigDose calculates this from your **skin type**, **exposed skin**, **UV** and **session length**. **Outside the D window**, estimates are **scaled down** to reflect trace production.

            **What it is not:** A lab measurement. Treat it as **guidance**, not medical advice.
            """
        case .plannedTime:
            """
            **What it does:** Sets a **planned guide** for this sun session. BigDose **never auto-ends** — you stop when you are ready.

            **How to use:** Use the slider or tap **To goal** or **Safe max**. **Safe max** caps the plan at about **95%** of MED (burn risk) for today's **UV**, **skin type** and **exposure** settings. Turn-over alerts use this planned time — **halfway through your session** or **50% MED (burn risk)**, whichever comes first.

            **Good to know:** Shorter planned time is fine if you only need a few minutes of D. Longer is not safer — **Safe max** is the ceiling.
            """
        case .toReachGoal:
            """
            **What it does:** Estimates how many minutes at current **UV**, **exposed skin** and **cloud** settings it would take to reach your **daily sun IU goal** from this session alone.

            **How to use:** Compare this with **Safe max**. If **To reach goal** is shorter, tap **To goal (~X min)** on the slider. If your goal would take longer than **Safe max**, plan for multiple shorter sessions instead of one long one.

            **Good to know:** This tracks **sun IU for today**, not supplements, food or your **ng/mL** blood goal on Progress.
            """
        case .safeMax:
            """
            **What it is:** The longest **planned session** BigDose allows at current conditions — set at about **95%** of your estimated **MED (burn risk)** for your **skin type**, **UV**, **clouds** and **sunscreen** settings.

            **How to use:** Treat this as a **planning ceiling**, not a target. Tap **Safe max (~X min)** when you want the full guided window. Turn-over alerts fire at **halfway through your planned session** or **50% MED (burn risk)** — whichever comes first. **Nanny** adds **75%** wrap-up and the **95%** guidance alert.

            **What it is not:** A guarantee you will or won't burn. Use **Your Limits Today** for turn-over and exit milestones.
            """
        case .estimatedBloodLevel:
            """
            **What it does:** A **modeled blood vitamin D level** in **ng/mL**, anchored to your latest **lab or baseline** and adjusted by recent intake.

            **How to use:** This is different from the **IU %** on Home, which only tracks **today's sun IU** against your daily sun target. **Progress** estimates whether your blood level is moving toward your **ng/mL goal** over the last **7 days**.

            **Tip:** A fresh **lab result** in BigDose improves this estimate more than any single sun session.
            """
        case .bloodLevelGoalProgress:
            """
            **What it does:** Shows how close your **estimated blood level** is to your personal **ng/mL goal**.

            **How to use:** The **%** and arc fill use your **Progress estimate** divided by the **ng/mL target** in **Dose DNA**. **100%** means you are at or above that goal on paper — not that you should stop supplementing or sun.

            **Good to know:** This tracks **blood level**, not today's **IU intake** on Home.
            """
        case .bloodLevelBand:
            """
            **What it does:** A quick label for where your **estimated blood level** sits on Progress.

            **How to use:** **Low** means below **30 ng/mL**. **Prime** means **30 ng/mL or above**. These bands reflect your **blood-level estimate**, not sun or UV quality on Home.

            **Good to know:** A fresh **lab result** in BigDose sharpens the estimate more than any single week of logging.
            """
        case .last7DaysIntake:
            """
            **What it does:** Total **vitamin D intake** in **IU** from **sun sessions**, **supplements** and **food** logged over the **last 7 days**.

            **How to use:** Compare this to your **7-day intake target** — your **daily IU goal × 7**. Steady weeks near that target help your **blood-level estimate** trend the right way.

            **Good to know:** This is **intake**, not your **ng/mL** blood goal on the card above.
            """
        case .sunSafetyOverview:
            """
            **What it is:** **UVB** triggers **vitamin D production** in your skin. Sun exposure also **burns skin**, contributes to **photoaging** and raises **long-term skin cancer risk** with repeated overexposure.

            **How BigDose protects you:** We estimate your personal **MED (burn risk)** from **skin type**, **UV**, **clouds** and **sunscreen**. During live sun sessions we track **MED (burn risk) Used**, warn to **turn over** at **halfway through your planned session** or **50% MED (burn risk)** — whichever comes first — and stay vigilant about when to come out of the sun — **only you stop the session**.

            **Nanny:** In **Settings → Session Safety**, **Nanny** defaults **on** and adds **75%** wrap-up, the **95%** guidance alert and a **98%** reminder while you stay out. Turn it off anytime for **turn-over only** — over-limit tracking still applies past **100%**.

            **What it is not:** Medical-grade sun protection or a guarantee you will or won't burn. Use shade, clothing and sunscreen beyond what BigDose models.
            """
        case .sessionSafetyAlerts:
            """
            **What it does:** **Turn-over** at **halfway through your planned session** or **50% MED (burn risk)** — whichever comes first — plus **stop-now** alerts during live sun sessions and matching **background notifications** when the app is closed. **Nanny** adds **75%** wrap-up and **guidance-limit** alerts.

            **How to use:** Keep this **on** unless you are confident tracking burn risk yourself. BigDose uses your **skin type** and live **UV** to personalize every threshold.

            **Good to know:** Pair with **Nanny** in **Settings → Session Safety** for **75%** wrap-up, the **95%** guidance alert and a **98%** reminder. **Nanny** defaults **on** and can be turned off anytime.
            """
        case .labResult25OHD:
            """
            **What it is:** **25(OH)D** — *25-hydroxyvitamin D* — is the standard **blood test** for vitamin D status, usually reported in **ng/mL**.

            **How to use:** If you have a recent lab report, choose **Yes** and enter the number and date. On the printout look for **25(OH)D**, **Vitamin D, 25-Hydroxy** or **calcidiol**.

            **How BigDose uses it:** Anchors your **Progress** blood-level estimate. Without one, BigDose starts conservatively and labels estimates clearly until you add a result in **Profile → Lab Results**.

            **Good to know:** **ng/mL** is blood level — not the **IU** intake total on Home from sun, supplements and food.
            """
        case .supplementBaseline:
            """
            **What it does:** Your usual **daily vitamin D supplement** in **IU** — a default for quick logging on Home.

            **How to use:** Enter your typical dose (e.g. **1000 IU**). Use **0** if you do not supplement daily. One tap logs it from Dashboard when amounts match.

            **How BigDose uses it:** Sets your **daily sun IU target** on Home and optional **supplement reminders**. BigDose also calculates a **recommended total daily IU** from your age, weight, blood level goal and starting level — see **Daily IU Target** for the breakdown. You can still log one-off doses when amounts change.

            **Good to know:** This is **intake**, not your **25(OH)D** blood level on Progress.
            """
        case .dailyIUTarget:
            """
            **What it is:** BigDose's **recommended daily vitamin D intake** in **IU** — modeled from your **age**, **weight**, **blood level goal** and **starting level** (lab, baseline or conservative estimate).

            **How we calculate it:** Three pieces stack together, then we round to the nearest **100 IU** (minimum **400 IU**).
            ▸ **Maintenance** — **600 IU** under age 70, **800 IU** at 70+. Targeting **40 ng/mL or higher**? We use at least **1,500 IU**.
            ▸ **Level correction** — closes the gap from your starting level to goal over about **90 days** (**111 IU** per ng/mL gap per day).
            ▸ **Weight adjustment** — **+25 IU** per **10 kg** above **70 kg**.

            **How to use:** **Home** tracks **sun IU** against the **sun session target** — total recommended minus your default supplement (minimum **400 IU** from sun for tracking). Supplements and food log separately. Tap any **IU goal** badge for this explainer.

            **What it is not:** A prescription or lab result. Adjust with your clinician if you have deficiency, kidney disease or other conditions.
            """
        case .sunHabitOverview:
            """
            **What it is:** Your **everyday sun habits** — usual outfit coverage, whether you typically wear sunscreen and casual time outside.

            **How to use:** Answer for **life in general**, not for a single sun session today. Think typical warm-weather errands, walks and yard work.

            **Good to know:** These **prefill** the sun session planner. Each session still lets you change **coverage**, **sunscreen** and **time** before and during the session.
            """
        case .typicalSkinExposure:
            """
            **What it is:** How much skin is usually **uncovered by clothes** when you are outside — your default **walk-around outfit**.

            **How to use:** Set it once here or in **Dose DNA**. **Long sleeves and pants** mean less; **shorts and a tee** mean more.

            **Good to know:** This is a **general default**, not locked for every sun session. Adjust **Skin Coverage** in the planner or live session when today’s outfit is different.
            """
        case .usualSunscreen:
            """
            **What it is:** Whether you **usually** wear sunscreen when you are outside — a general habit, not a per-session log entry.

            **How to use:** Turn **on** if sunscreen is part of your normal routine. BigDose lengthens default time estimates because less UVB reaches your skin.

            **Good to know:** Sun sessions can still reflect **today’s** conditions. This toggle sets the **starting assumption**, not a rule for every tracked session.
            """
        case .casualOutdoorTime:
            """
            **What it is:** About how many minutes per week you are **casually outside** while dressed in your typical outfit — walks, errands, yard work or lunch outside.

            **How to use:** Estimate **unplanned** outdoor time. This is **not** the same as a **tracked sun session** in BigDose.

            **Good to know:** A **general background habit** for estimates and context — not something you set again at the start of each sun session.
            """
        case .incidentalDaylight:
            """
            **What it is:** **Incidental sun** from Apple Watch **Time in Daylight** — outdoor minutes BigDose converts to **~IU** with a **Holick estimate**.

            **How to use:** Sync **Apple Health** to import one **daily total** per day. BigDose subtracts minutes already credited from **tracked sessions** and **imported workouts** so the same outdoor time is not counted twice.

            **What it is not:** A lab result or measured vitamin D. Values use **assumed UV**, **lower exposed-skin defaults** and your **Dose DNA** skin type — treat as **guidance**.
            """
        case .importedSun:
            """
            **What it is:** **Imported sun** from **outdoor workouts** in Apple Health — walking, running, hiking, cycling and similar activities logged by apps like your workout tracker.

            **How BigDose uses it:** Each workout becomes a **Holick estimate** in **~IU** using workout **duration**, your **Dose DNA** skin type, **typical exposed skin** and **conservative assumed UV** — not the UV at that moment.

            **Good to know:** Indoor workouts and duplicates are skipped. Time already counted in **Incidental** or **Tracked** sessions is subtracted so the same outdoor minutes are not credited twice.

            **What it is not:** A measured vitamin D result. Sync **Apple Health** from **Profile → Manage Data** to review or refresh imports.
            """
        }
    }
}
