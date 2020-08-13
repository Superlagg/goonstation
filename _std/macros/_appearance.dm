//head defines
#define HEAD_HUMAN 0
#define HEAD_MONKEY 1
#define HEAD_LIZARD 2
#define HEAD_COW 3
#define HEAD_WEREWOLF 4
#define HEAD_SKELETON 5	// skullception *shrug*
#define HEAD_SEAMONKEY 6
#define HEAD_CAT 7
#define HEAD_ROACH 8
#define HEAD_FROG 9
#define HEAD_SHELTER 10

//appearance bitflags cus im tired of tracking down a million different vars that rarely do what they should
#define IS_MUTANT								1	// Log shit if this is set but the mutantrace isnt. why does this even happen.

#define HAS_HUMAN_SKINTONE			2	// Skin tone determined through the usual route
#define HAS_SPECIAL_SKINTONE		4	// Skin tone defined some other way
#define HAS_NO_SKINTONE					8	// Please dont tint my mob it looks weird

// used in appearance holder
#define HAS_HUMAN_HAIR					16 // Hair sprites are roughly what you set in the prefs
#define HAS_SPECIAL_HAIR				32 // Hair sprites are there, but they're supposed to be different
#define HAS_NO_HAIR							64 // Please don't render hair on my lizards it looks too cute

#define HAS_HAIR_COLORED_HAIR			128	// Hair (if any) is/are the color/s you/we (hopefully) set/assigned
#define HAS_SPECIAL_COLORED_HAIR	256 // Hair color is determined some other way
#define HAS_HAIR_COLORED_DETAILS	512	// Hair color is used to determine the color of certain non-hair things. Like horns or scales
#define HAS_UNUSED_HAIR_COLOR		 1024 // Hair color isnt used for anything :/

#define HAS_HUMAN_EYES					2048 // We have normal human eyes of human color where human eyes tend to be
#define HAS_SPECIAL_EYES				4096 //	We have different eyes of different color probably somewhere else
#define HAS_NO_EYES							8192 // We have no eyes and yet must see (cus they're baked into the sprite or something)

#define HAS_HUMAN_HEAD					16384	// Head is roughly human-shaped with no additional features
#define HAS_SPECIAL_HEAD				32768	// Head is shaped differently, but otherwise just a head
#define HAS_VERY_SPECIAL_HEAD		65536	// Head has other head pieces overlayed on top, like horns or a lizard crest-thing
#define HAS_NO_HEAD							131072	// Don't show their head, its already baked into their icon override

#define BUILT_FROM_PIECES				262144	// Use humanlike body rendering process, otherwise use a static icon or something
#define HAS_EXTRA_DETAILS				524288	// Has something in their detail slot they want to show off, like lizard splotches
#define HAS_A_TAIL							1048576	// Has a tail, so give em an oversuit

//Hairstyle bitflags
//corresponds to the color settings in user prefs, so we can change which hair layer gets what color without actually changing the value
//
#define DETAIL_1_USES_PREF_COLOR_1		1			//
#define DETAIL_1_USES_PREF_COLOR_2		2 		//
#define DETAIL_1_USES_PREF_COLOR_3		4 		//

#define DETAIL_2_USES_PREF_COLOR_1		8 		//
#define DETAIL_2_USES_PREF_COLOR_2		16 		//
#define DETAIL_2_USES_PREF_COLOR_3		32		//

#define DETAIL_3_USES_PREF_COLOR_1		64		//
#define DETAIL_3_USES_PREF_COLOR_2		128		//
#define DETAIL_3_USES_PREF_COLOR_3		256		//

#define OVERSUIT_USES_PREF_COLOR_1		512		//
#define OVERSUIT_USES_PREF_COLOR_2		1024	//
#define OVERSUIT_USES_PREF_COLOR_3		2048	//

#define SKINTONE_USES_PREF_COLOR_1		4096	//
#define SKINTONE_USES_PREF_COLOR_2		8192	//
#define SKINTONE_USES_PREF_COLOR_3		16384	//
