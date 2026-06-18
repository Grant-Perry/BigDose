   //
   //  Color+Ext.swift
   //  BigRoll
   //
   //  Created by Grant Perry on 4/3/23.
   //

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension Color {

   init(rgb: Int...) {
	  if rgb.count == 3 {
		 self.init(red: Double(rgb[0]) / 255.0, green: Double(rgb[1]) / 255.0, blue: Double(rgb[2]) / 255.0)
	  } else {
		 self.init(red: 1.0, green: 0.5, blue: 1.0)
	  }
   }

	  /// Toggle palette: `true` = cpMuted* (default), `false` = cp* (normal/brighter). Set to switch.
   enum Palette {
	  static var muted: Bool = true
   }

   static let gpDesignGold =  Color(#colorLiteral(red: 0.7998082638, green: 0.6508761048, blue: 0.3491310477, alpha: 1))


   static let gpProductionComplete = Color(#colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1))
   static let gpProductionOpen = Color(#colorLiteral(red: 0.3911147745, green: 0.8800172018, blue: 0.2343971767, alpha: 1))

	  /// Softer card borders — full status colors read too loud at 2pt stroke.
   static let gpProductionOpenBorder = gpProductionOpen.opacity(0.42)
   static let gpProductionCompleteBorder = gpProductionComplete.opacity(0.42)



   static let gpPastelMint = Color(#colorLiteral(red: 0.816, green: 1, blue: 0.647, alpha: 1))
   static let gpGreen = Color(#colorLiteral(red: 0.6198272109, green: 0.6509014368, blue: 0.4784618616, alpha: 1))
   static let gpMinty = Color(#colorLiteral(red: 0.5960784314, green: 1, blue: 0.5960784314, alpha: 1))
   static let gpFlatGreen = Color(#colorLiteral(red: 0.03852885208, green: 0.6235294342, blue: 0.3622174664, alpha: 1))
	  /// Soft teal for selected-plan glow — complements warm gold, reads well on dark
   static let gpActivePlanGlow = Color(#colorLiteral(red: 0.35, green: 0.65, blue: 0.62, alpha: 1))

   static let gpArmyGreen = Color(#colorLiteral(red: 0.4392156863, green: 0.4352941176, blue: 0.1803921569, alpha: 1))
   static let gpOrange = Color(#colorLiteral(red: 1, green: 0.6470588235, blue: 0, alpha: 1))
   static let gpPink = Color(#colorLiteral(red: 1, green: 0.4117647059, blue: 0.7058823529, alpha: 1))
   static let gpPurple = Color(#colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1))
   static let gpDkPurple = Color(#colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1))
   static let gpRed = Color(#colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1))


	  // Hilight colors
   static let gpHiGreen = Color(#colorLiteral(red: 0.3911147745, green: 0.8800172018, blue: 0.2343971767, alpha: 1))
   static let gpHiMinty = Color(#colorLiteral(red: 0.5960784314, green: 1, blue: 0.5960784314, alpha: 1))
   static let gpHiRedPink = Color(#colorLiteral(red: 1, green: 0.1857388616, blue: 0.3251032516, alpha: 1))
   static let gpHiOrange = Color(#colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1))
   static let gpHiMintYellow = Color(#colorLiteral(red: 0.816, green: 1, blue: 0.647, alpha: 1))
   static let gpHiYellow = Color(#colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1))
   static let gpHiBlue = Color(#colorLiteral(red: 0.4620226622, green: 0.8382837176, blue: 1, alpha: 1))
   static let gpHiLtBlue = Color(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1))
   static let gpHiDkBlue = Color(#colorLiteral(red: 0.1019607857, green: 0.2784313858, blue: 0.400000006, alpha: 1))
   static let gpHiPurple = Color(#colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1))
   static let gpHiCream = Color(#colorLiteral(red: 0.9450985789, green: 0.9490197301, blue: 0.8000027537, alpha: 1))
   static let gpHiFav = Color(#colorLiteral(red: 0.80610038, green: 0.9686274529, blue: 0.7690739287, alpha: 1))
   static let gpSideBarHi = Color(#colorLiteral(red: 0, green: 0.2927228212, blue: 0.9990779757, alpha: 1))
   static let gpSideBarLow = Color(#colorLiteral(red: 0.0008281979826, green: 0.5638359189, blue: 0.991630733, alpha: 1))




	  /// App-wide white for strokes and accents
   static let gpWhite = Color.white
   static let gpRedPitch = Color(#colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1))
   static let gpSelectedFav = Color(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1))
   static let gpRedPink = Color(#colorLiteral(red: 1, green: 0.1857388616, blue: 0.3251032516, alpha: 1))
   static let gpYellowD = Color(#colorLiteral(red: 0.7254902124, green: 0.4784313738, blue: 0.09803921729, alpha: 1))
   static let gpTan = Color(#colorLiteral(red: 0.4483810227, green: 0.3676018354, blue: 0.1985318112, alpha: 1))
   static let gpGold = Color(#colorLiteral(red: 0.6001003385, green: 0.4902321696, blue: 0.2627026737, alpha: 1))
   static let gpYellow = Color(#colorLiteral(red: 0.7166176741, green: 0.631458951, blue: 0.3852883836, alpha: 1))

	  /// Bright airport-style yellow for gate pills on dark cards.
   static let gpGatePill = Color(#colorLiteral(red: 1, green: 0.8235294118, blue: 0.09803921569, alpha: 1))
   static let gpDeltaPurple = Color(#colorLiteral(red: 0.5450980392, green: 0.1019607843, blue: 0.2901960784, alpha: 1))
   static let gpMaroon = Color(#colorLiteral(red: 0.4392156863, green: 0.1803921569, blue: 0.3137254902, alpha: 1))
   static let gpBlueDark = Color(#colorLiteral(red: 0.05882352963, green: 0.180392161, blue: 0.2470588237, alpha: 1))
   static let gpBlueDarkL = Color(#colorLiteral(red: 0.08346207272, green: 0.1920862778, blue: 0.2470588237, alpha: 1))
   static let gpBlueLight = Color(#colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1))
   static let gpBlue = Color(#colorLiteral(red: 0.4620226622, green: 0.8382837176, blue: 1, alpha: 1))
   static let gpLtBlue = Color(#colorLiteral(red: 0.7, green: 0.9, blue: 1, alpha: 1))

   static let gpDarkL = Color(#colorLiteral(red: 0.1378855407, green: 0.1486340761, blue: 0.1635932028, alpha: 1))
   static let gpDark1 = Color(#colorLiteral(red: 0.1378855407, green: 0.1486340761, blue: 0.1635932028, alpha: 1))
   static let gpDark2 = Color(#colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1))

   static let gpCalToday = Color(#colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1))
   static let gpPostBot = Color(#colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1))

   static let gpCurrentTop = Color(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1))
   static let gpCurrentBot = Color(#colorLiteral(red: 0.3128006691, green: 0.4008095726, blue: 0.6235075593, alpha: 1))

   static let gpScheduledTop = Color(#colorLiteral(red: 0.3156160096, green: 0.6235294342, blue: 0.5034397076, alpha: 1))
   static let gpScheduledBot = Color(#colorLiteral(red: 0.03852885208, green: 0.6235294342, blue: 0.3622174664, alpha: 1))

   static let gpFinalTop = Color(#colorLiteral(red: 0.4196078431, green: 0.2901960784, blue: 0.4745098039, alpha: 1))
   static let gpLivePlayHead = Color(#colorLiteral(red: 0.4196078431, green: 0.2901960784, blue: 0.4745098039, alpha: 1))

   static let gpDivider = Color(#colorLiteral(red: 0.768627451, green: 0.6078431373, blue: 0.8588235294, alpha: 1))


	  // MARK: cpMuted — Base palette (muted, warm, complementary to app)
	  // R Red
   static let cpMutedRed         = Color(#colorLiteral(red: 0.7998082638, green: 0.6508761048, blue: 0.3491310477, alpha: 1))   // cpMuted-Red
   static let cpMutedRedOrange   = Color(#colorLiteral(red: 0.7861937881, green: 0.487991035, blue: 0.3871542215, alpha: 1))   // cpMuted-Red-Orange
   static let cpMutedRedPink     = Color(#colorLiteral(red: 0.78, green: 0.52, blue: 0.50, alpha: 1))   // cpMuted-Red-Pink
   static let cpMutedCrimson     = Color(#colorLiteral(red: 0.68, green: 0.42, blue: 0.42, alpha: 1))   // cpMuted-Crimson
   static let cpMutedCoral       = Color(#colorLiteral(red: 0.82, green: 0.62, blue: 0.55, alpha: 1))   // cpMuted-Coral
																										// O Orange
   static let cpMutedOrange      = Color(#colorLiteral(red: 0.82, green: 0.58, blue: 0.42, alpha: 1))   // cpMuted-Orange
   static let cpMutedAmber       = Color(#colorLiteral(red: 0.88, green: 0.72, blue: 0.50, alpha: 1))   // cpMuted-Amber
   static let cpMutedPeach       = Color(#colorLiteral(red: 0.88, green: 0.72, blue: 0.62, alpha: 1))   // cpMuted-Peach
																										// Y Yellow
   static let cpMutedYellow      = Color(#colorLiteral(red: 0.88, green: 0.82, blue: 0.58, alpha: 1))   // cpMuted-Yellow
   static let cpMutedLime        = Color(#colorLiteral(red: 0.68, green: 0.75, blue: 0.55, alpha: 1))   // cpMuted-Lime
   static let cpMutedGold        = Color(#colorLiteral(red: 0.85, green: 0.75, blue: 0.55, alpha: 1))   // cpMuted-Gold
   static let cpMutedCream       = Color(#colorLiteral(red: 0.92, green: 0.90, blue: 0.78, alpha: 1))   // cpMuted-Cream
																										// G Green
   static let cpMutedYellowGreen = Color(#colorLiteral(red: 0.58, green: 0.68, blue: 0.48, alpha: 1))   // cpMuted-Yellow-Green
   static let cpMutedGreen       = Color(#colorLiteral(red: 0.48, green: 0.62, blue: 0.48, alpha: 1))   // cpMuted-Green
   static let cpMutedTeal        = Color(#colorLiteral(red: 0.45, green: 0.62, blue: 0.58, alpha: 1))   // cpMuted-Teal
																										// B Blue
   static let cpMutedCyan        = Color(#colorLiteral(red: 0.48, green: 0.68, blue: 0.72, alpha: 1))   // cpMuted-Cyan
   static let cpMutedSkyBlue     = Color(#colorLiteral(red: 0.48, green: 0.72, blue: 0.85, alpha: 1))   // cpMuted-Sky-Blue
   static let cpMutedBlue        = Color(#colorLiteral(red: 0.42, green: 0.58, blue: 0.75, alpha: 1))   // cpMuted-Blue
																										// I Indigo
   static let cpMutedIndigo      = Color(#colorLiteral(red: 0.48, green: 0.50, blue: 0.68, alpha: 1))   // cpMuted-Indigo
   static let cpMutedBlueViolet  = Color(#colorLiteral(red: 0.55, green: 0.48, blue: 0.70, alpha: 1))   // cpMuted-Blue-Violet
																										// V Violet
   static let cpMutedViolet      = Color(#colorLiteral(red: 0.62, green: 0.52, blue: 0.72, alpha: 1))   // cpMuted-Violet
   static let cpMutedPurple      = Color(#colorLiteral(red: 0.62, green: 0.55, blue: 0.72, alpha: 1))   // cpMuted-Purple
   static let cpMutedMagenta     = Color(#colorLiteral(red: 0.72, green: 0.55, blue: 0.62, alpha: 1))   // cpMuted-Magenta
   static let cpMutedPink        = Color(#colorLiteral(red: 0.78, green: 0.62, blue: 0.65, alpha: 1))   // cpMuted-Pink
   static let cpMutedRose        = Color(#colorLiteral(red: 0.78, green: 0.65, blue: 0.62, alpha: 1))   // cpMuted-Rose


	  // MARK: cp — Brighter palette (saturated)
	  // R Red
   static let cpRed         = Color(#colorLiteral(red: 0.898, green: 0.224, blue: 0.208, alpha: 1))   // cp-Red
   static let cpRedOrange   = Color(#colorLiteral(red: 1, green: 0.341, blue: 0.133, alpha: 1))    // cp-Red-Orange
   static let cpRedPink     = Color(#colorLiteral(red: 0.937, green: 0.325, blue: 0.314, alpha: 1)) // cp-Red-Pink
   static let cpCrimson     = Color(#colorLiteral(red: 0.827, green: 0.184, blue: 0.184, alpha: 1)) // cp-Crimson
   static let cpCoral       = Color(#colorLiteral(red: 1, green: 0.420, blue: 0.420, alpha: 1))     // cp-Coral
																									// O Orange
   static let cpOrange      = Color(#colorLiteral(red: 1, green: 0.596, blue: 0, alpha: 1))        // cp-Orange
   static let cpAmber       = Color(#colorLiteral(red: 1, green: 0.757, blue: 0.027, alpha: 1))    // cp-Amber
   static let cpPeach       = Color(#colorLiteral(red: 1, green: 0.671, blue: 0.569, alpha: 1))     // cp-Peach
																									// Y Yellow
   static let cpYellow      = Color(#colorLiteral(red: 1, green: 0.922, blue: 0.231, alpha: 1))    // cp-Yellow
   static let cpLime        = Color(#colorLiteral(red: 0.804, green: 0.863, blue: 0.224, alpha: 1)) // cp-Lime
   static let cpGold        = Color(#colorLiteral(red: 0.976, green: 0.851, blue: 0.549, alpha: 1))  // cp-Gold
   static let cpCream       = Color(#colorLiteral(red: 0.945, green: 0.949, blue: 0.800, alpha: 1))  // cp-Cream
																									 // G Green
   static let cpYellowGreen = Color(#colorLiteral(red: 0.545, green: 0.765, blue: 0.290, alpha: 1)) // cp-Yellow-Green
   static let cpGreen       = Color(#colorLiteral(red: 0.298, green: 0.686, blue: 0.314, alpha: 1))  // cp-Green
   static let cpTeal        = Color(#colorLiteral(red: 0, green: 0.588, blue: 0.533, alpha: 1))    // cp-Teal
																								   // B Blue
   static let cpCyan        = Color(#colorLiteral(red: 0, green: 0.737, blue: 0.831, alpha: 1))    // cp-Cyan
   static let cpSkyBlue     = Color(#colorLiteral(red: 0.462, green: 0.838, blue: 1, alpha: 1))    // cp-Sky-Blue (gpHiBlue)
   static let cpBlue        = Color(#colorLiteral(red: 0.129, green: 0.588, blue: 0.953, alpha: 1)) // cp-Blue
																									// I Indigo
   static let cpIndigo      = Color(#colorLiteral(red: 0.247, green: 0.318, blue: 0.710, alpha: 1))  // cp-Indigo
   static let cpBlueViolet  = Color(#colorLiteral(red: 0.404, green: 0.227, blue: 0.718, alpha: 1)) // cp-Blue-Violet
																									// V Violet
   static let cpViolet      = Color(#colorLiteral(red: 0.612, green: 0.153, blue: 0.690, alpha: 1)) // cp-Violet
   static let cpPurple      = Color(#colorLiteral(red: 0.556, green: 0.353, blue: 0.969, alpha: 1)) // cp-Purple
   static let cpMagenta     = Color(#colorLiteral(red: 0.914, green: 0.118, blue: 0.388, alpha: 1)) // cp-Magenta
   static let cpPink        = Color(#colorLiteral(red: 0.941, green: 0.384, blue: 0.573, alpha: 1)) // cp-Pink
   static let cpRose        = Color(#colorLiteral(red: 0.957, green: 0.561, blue: 0.694, alpha: 1)) // cp-Rose

	  /// Array of all 25 palette colors in ROYGBIV order — respects Color.Palette.muted
   static var colorPaletteArray: [Color] {
	  if Palette.muted {
		 return [
			cpMutedRed, cpMutedRedOrange, cpMutedRedPink, cpMutedCrimson, cpMutedCoral,
			cpMutedOrange, cpMutedAmber, cpMutedPeach,
			cpMutedYellow, cpMutedLime, cpMutedGold, cpMutedCream,
			cpMutedYellowGreen, cpMutedGreen, cpMutedTeal,
			cpMutedCyan, cpMutedSkyBlue, cpMutedBlue,
			cpMutedIndigo, cpMutedBlueViolet,
			cpMutedViolet, cpMutedPurple, cpMutedMagenta, cpMutedPink, cpMutedRose
		 ]
	  } else {
		 return [
			cpRed, cpRedOrange, cpRedPink, cpCrimson, cpCoral,
			cpOrange, cpAmber, cpPeach,
			cpYellow, cpLime, cpGold, cpCream,
			cpYellowGreen, cpGreen, cpTeal,
			cpCyan, cpSkyBlue, cpBlue,
			cpIndigo, cpBlueViolet,
			cpViolet, cpPurple, cpMagenta, cpPink, cpRose
		 ]
	  }
   }

	  /// Spine palette — complements Dashboard (dark, gold, brown, blue). Brighter than muted.
   static let gpSpineMutedPurple = Color(#colorLiteral(red: 0.65, green: 0.58, blue: 0.75, alpha: 1))
   static let gpSpineMutedTeal = Color(#colorLiteral(red: 0.55, green: 0.78, blue: 0.76, alpha: 1))
   static let gpSpineMutedBlue = Color(#colorLiteral(red: 0.52, green: 0.62, blue: 0.78, alpha: 1))
   static let gpSpineSage = Color(#colorLiteral(red: 0.58, green: 0.72, blue: 0.65, alpha: 1))
   static let gpSpineLavender = Color(#colorLiteral(red: 0.75, green: 0.68, blue: 0.85, alpha: 1))
   static let gpSpinePlum = Color(#colorLiteral(red: 0.62, green: 0.49, blue: 0.67, alpha: 1))
   static let gpSpineDustyRose = Color(#colorLiteral(red: 0.72, green: 0.58, blue: 0.62, alpha: 1))
   static let gpSpineDustyBlue = Color(#colorLiteral(red: 0.48, green: 0.62, blue: 0.72, alpha: 1))
   static let gpSpineAmber = Color(#colorLiteral(red: 0.92, green: 0.75, blue: 0.52, alpha: 1))
   static let gpSpineDkTeal = Color(#colorLiteral(red: 0.42, green: 0.68, blue: 0.62, alpha: 1))
   static let gpSpineWarmGold = Color(#colorLiteral(red: 0.85, green: 0.75, blue: 0.58, alpha: 1))
   static let gpSpineOlive = Color(#colorLiteral(red: 0.62, green: 0.65, blue: 0.48, alpha: 1))
   static let gpSpineSlate = Color(#colorLiteral(red: 0.58, green: 0.65, blue: 0.72, alpha: 1))
   static let gpSpineMutedCoral = Color(#colorLiteral(red: 0.78, green: 0.62, blue: 0.62, alpha: 1))
   static let gpSpineSoftMint = Color(#colorLiteral(red: 0.58, green: 0.72, blue: 0.68, alpha: 1))

   static let awayTeamColor = Color(#colorLiteral(red: 0.0, green: 0.404, blue: 0.439, alpha: 1)) // #006774
   static let homeTeamColor = Color(#colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1))

	  // MLB Team Colors

   static let nyyDark = Color(#colorLiteral(red: 0.047, green: 0.137, blue: 0.251, alpha: 1)) // #0C2340
   static let rockiesPrimary = Color(#colorLiteral(red: 0.345, green: 0.267, blue: 0.541, alpha: 1)) // #58448A
   static let padresDark = Color(#colorLiteral(red: 0.204, green: 0.157, blue: 0.086, alpha: 1)) // #342814
   static let marinersPrimary = Color(#colorLiteral(red: 0.0, green: 0.404, blue: 0.439, alpha: 1)) // #006774
   static let marinersDark = Color(#colorLiteral(red: 0.0, green: 0.176, blue: 0.192, alpha: 1)) // #002D31
   static let nyyPrimary = Color(#colorLiteral(red: 0.0, green: 0.188, blue: 0.529, alpha: 1)) // #003087

   static let marlinsPrimary = Color(#colorLiteral(red: 0.0, green: 0.729, blue: 0.831, alpha: 1)) // #00BAD4
   static let marlinsDark = Color(#colorLiteral(red: 0.0, green: 0.263, blue: 0.306, alpha: 1)) // #00434E


	  /// Calculate luminance using WCAG formula
   func luminance() -> Double {
#if os(macOS)
	  let platformColor = NSColor(self)
#else
	  let platformColor = UIColor(self)
#endif
	  var red: CGFloat = 0
	  var green: CGFloat = 0
	  var blue: CGFloat = 0

	  platformColor.getRed(&red, green: &green, blue: &blue, alpha: nil)

		 // Apply gamma correction according to WCAG
	  func adjustComponent(_ component: CGFloat) -> CGFloat {
		 return component <= 0.03928 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
	  }

	  let adjRed = adjustComponent(red)
	  let adjGreen = adjustComponent(green)
	  let adjBlue = adjustComponent(blue)

		 // WCAG luminance formula
	  return 0.2126 * Double(adjRed) + 0.7152 * Double(adjGreen) + 0.0722 * Double(adjBlue)
   }

	  /// Determine if color is light based on luminance
   func isLight() -> Bool {
	  return luminance() > 0.5
   }

	  /// Return appropriate contrasting text color (black or white)
   func adaptedTextColor() -> Color {
	  return isLight() ? Color.black : Color.white
   }

	  /// Calculate WCAG contrast ratio against another color
   func contrastRatio(against color: Color) -> Double {
	  let luminance1 = self.luminance()
	  let luminance2 = color.luminance()
	  let lighter = max(luminance1, luminance2)
	  let darker = min(luminance1, luminance2)
	  return (lighter + 0.05) / (darker + 0.05)
   }

   func interpolated(with color: Color, by factor: Double) -> Color {
	  let factor = max(0, min(1, factor)) // Clamp factor between 0 and 1

#if os(macOS)
		 // Catalog/dynamic colors crash getRed:green:blue:alpha:; convert to sRGB first
	  let nc1 = NSColor(self)
	  let nc2 = NSColor(color)
	  guard let c1 = nc1.usingColorSpace(.sRGB),
			let c2 = nc2.usingColorSpace(.sRGB) else {
		 return factor < 0.5 ? self : color
	  }
#else
	  let c1 = UIColor(self)
	  let c2 = UIColor(color)
#endif

	  var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
	  var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

	  c1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
	  c2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

	  let r = r1 + (r2 - r1) * factor
	  let g = g1 + (g2 - g1) * factor
	  let b = b1 + (b2 - b1) * factor
	  let a = a1 + (a2 - a1) * factor

	  return Color(.sRGB, red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
   }

	  // 🔥 DRY: Moved from DraftWarRoomApp.swift
	  /// Get RGB components of color for interpolation and manipulation
   var components: (red: Double, green: Double, blue: Double, alpha: Double) {
#if os(macOS)
	  let platformColor = NSColor(self)
#else
	  let platformColor = UIColor(self)
#endif
	  var red: CGFloat = 0
	  var green: CGFloat = 0
	  var blue: CGFloat = 0
	  var alpha: CGFloat = 0
	  platformColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
	  return (Double(red), Double(green), Double(blue), Double(alpha))
   }

	  /// Hex string for persistence (e.g. "#FF5733")
   var hexString: String {
	  let c = components
	  let r = Int(c.red * 255)
	  let g = Int(c.green * 255)
	  let b = Int(c.blue * 255)
	  return String(format: "#%02X%02X%02X", r, g, b)
   }

	  /// Create Color from hex string ("#RRGGBB" or "RRGGBB")
   init?(hex: String) {
	  var hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
	  if hex.hasPrefix("#") { hex.removeFirst() }
	  guard hex.count == 6, let rgb = Int(hex, radix: 16) else { return nil }
	  let r = Double((rgb >> 16) & 0xFF) / 255
	  let g = Double((rgb >> 8) & 0xFF) / 255
	  let b = Double(rgb & 0xFF) / 255
	  self.init(red: r, green: g, blue: b)
   }
}
