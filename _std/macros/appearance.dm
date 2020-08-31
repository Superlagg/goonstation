//non-hairstyle body accessory bitflags
//corresponds to the color settings in user prefs
#define BODY_DETAIL_1	(1<<0)	//
#define BODY_DETAIL_2	(1<<1)	//
#define BODY_DETAIL_3	(1<<2)	//

#define HAS_HAIR_COLORED_HAIR			(1<<3)		// Hair (if any) is/are the color/s you/we (hopefully) set/assigned
#define HAS_HAIR_COLORED_DETAILS	(1<<5)	// Hair color is used to determine the color of certain non-hair things. Like horns or scales

#define BODY_DETAIL_OVERSUIT_1		(1<<7)		// Has a detail that goes over the suit, like a cute little enormous cow muzzle
#define BODY_DETAIL_OVERSUIT_IS_COLORFUL		(1<<8)		// The oversuit is colorful, otherwise don't color it. Defaults to first customization color

#define FIX_COLORS										(1<<9)	// Clamp customization RBG vals between 50 and 190, lizard-style
#define	HEAD_HAS_OWN_COLORS						(1<<10)	// our head has its own colors that would look weird if tinted
