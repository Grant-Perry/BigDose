import Foundation

enum BigDoseInfoTopic: String, Identifiable, Sendable {
    case uvIndex
    case riskUsed
    case med
    case minToMED
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

    var id: String { rawValue }

    var title: String {
        switch self {
        case .uvIndex:
            "UV Index"
        case .riskUsed:
            "Risk Used"
        case .med:
            "MED - Risk"
        case .minToMED:
            "Min to MED"
        case .medUsed:
            "MED Used (Risk)"
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
            **What it does:** Shows how much of your personal **MED** a sample exposure would use — based on your **skin type**, **UV** and about **12 minutes** of sun.

            **How to use:** **Lower is safer.** Past about **75%**, conditions are getting risky. During a live sun session, watch **MED Used (Risk)** climb in real time instead.

            **Tip:** Open the **MED** info panel for the full burn-threshold explainer.
            """
        case .med:
            """
            **What it is:** **MED (Risk)** — *minimal erythema dose* — is BigDose's estimate of how much **UV exposure** would start to **redden your skin**, based on your **Fitzpatrick skin type** in **Dose DNA**.

            **How BigDose uses it:** During a sun session we count down to MED, show **MED (Risk) Used %** and warn at **50%** (turn over), **75%** (wrap up soon) and **90%** (stop or cover up).

            **What it is not:** A **medical measurement** or a guarantee you will or won't burn. Treat it as **conservative wellness guidance**.
            """
        case .minToMED:
            """
            **What it does:** Counts down the estimated **minutes until MED (risk)** at the current **UV**, **cloud** and **sunscreen** settings.

            **How to use:** Plan to **turn over**, **seek shade** or **end the session** before this hits zero. BigDose also alerts you earlier — at **75%** and **90%** of MED.

            **Watch for:** When **UV is low**, this number can look very long — that does not mean unlimited safe exposure.
            """
        case .medUsed:
            """
            **What it does:** Shows how much of your estimated **MED** this session has used so far — based on **elapsed time**, **UV**, **skin type** and exposure settings.

            **How to use:** Under **50%** is comfortable headroom. Past **75%**, BigDose recommends **wrapping up**. Past **90%**, the timer **pauses** and asks you to **stop or cover up**.

            **Tip:** Pair this with **Min to MED (Risk)** — one shows progress, the other shows time remaining.
            """
        case .sessionGoal:
            """
            **What it does:** Shows how close this sun session is to your **daily IU goal** — the ring and **% of goal** fill as estimated vitamin D accumulates.

            **How to use:** You can **change the goal** during the session. At **100%**, BigDose can **end the session automatically**. This tracks **IU for today**, not your **ng/mL** blood goal on Progress.

            **Good to know:** Goal progress and **MED Used (Risk)** measure different things — vitamin D gained vs. burn risk consumed.
            """
        case .skinType:
            """
            **What it does:** Your **Fitzpatrick skin type** from **Dose DNA** — how quickly your skin tends to **burn** in sun.

            **How to use:** **Tap** your profile photo or open **Profile → Dose DNA** to change it. Skin type drives **time-to-IU** and **MED** calculations.

            **Tip:** Pick the type that matches your **sunburn history**, not your tan goals.
            """
        case .goal:
            """
            **What it does:** Your target **blood vitamin D level** in **ng/mL** (nanograms per milliliter).

            **How to use:** Set it during onboarding or in **Dose DNA**. **Progress** tracks blood-level estimates against this target. **Home** tracks a separate **daily IU goal** for today's sun, supplements and food.

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
            **What it does:** Sets how long this **sun session** will run before BigDose ends it — unless you reach your **IU goal** or hit a **MED safety stop** first.

            **How to use:** Use the slider or tap **To goal** or **Safe max**. BigDose **caps** planned time at **Safe max** so you cannot schedule past your burn-risk limit for today's **UV**, **skin type** and **exposure** settings.

            **Good to know:** Shorter planned time is fine if you only need a few minutes of D. Longer is not safer — **Safe max** is the ceiling.
            """
        case .toReachGoal:
            """
            **What it does:** Estimates how many minutes at current **UV**, **exposed skin** and **cloud** settings it would take to reach your **daily IU goal** from this session alone.

            **How to use:** Compare this with **Safe max**. If **To reach goal** is shorter, tap **To goal (~X min)** on the slider. If your goal would take longer than **Safe max**, plan for multiple shorter sessions instead of one long one.

            **Good to know:** This tracks **IU intake for today**, not your **ng/mL** blood goal on Progress.
            """
        case .safeMax:
            """
            **What it is:** The longest **planned session** BigDose allows at current conditions — set at about **90%** of your estimated **MED (burn risk)** for your **skin type**, **UV**, **clouds** and **sunscreen** settings.

            **How to use:** Treat this as a **hard ceiling**, not a target. Tap **Safe max (~X min)** when you want the full safe window. BigDose still alerts earlier at **50%**, **75%** and **90%** of MED during the session.

            **What it is not:** A guarantee you will or won't burn. Use **Your Limits Today** for turn-over and exit milestones.
            """
        case .estimatedBloodLevel:
            """
            **What it does:** A **modeled blood vitamin D level** in **ng/mL**, anchored to your latest **lab or baseline** and adjusted by recent intake.

            **How to use:** This is different from the **IU %** on Home, which only tracks **today's sun, supplement and food IU** against your daily IU target. **Progress** estimates whether your blood level is moving toward your **ng/mL goal** over the last **7 days**.

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
        }
    }
}
