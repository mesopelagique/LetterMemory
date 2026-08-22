/*
LetterMemory — a matching-pairs game where a pair is a LETTER and the PICTURE whose
name starts with it (like LetterDetective, but from memory). Flipped by Hero (cs.hero).

The flip is a matched-geometry move by hand: the back squishes to a zero-width sliver,
the face takes its place, and the face opens out — two chained tweens on one rectangle.
A pair is not two identical cards but a letter card and its picture card, sharing a pair
id in the deck; a turn matches when the two ids agree, so one letter meets one picture.

Language 🇫🇷 / 🇬🇧 changes each picture's name, hence its letter, so switching re-deals.

Layout comes from the form (the back_<n> boxes). Input is a transparent pick_<n> button
over each card. Store the instance in Form.game. Cells are 0-based internally.
*/

property transition : cs.hero.ElementTransition
property size : Integer:=4                 // 4x4
property cards : Integer                    // 16
property pairs : Integer                    // 8

property lang : Text:="fr"

// each item: {emoji; en; fr} — every first letter is a plain A–Z in both languages
property items : Collection:=[\
{emoji: "🍌"; en: "banana"; fr: "banane"}; \
{emoji: "🐶"; en: "dog"; fr: "chien"}; \
{emoji: "🐱"; en: "cat"; fr: "chat"}; \
{emoji: "🍎"; en: "apple"; fr: "pomme"}; \
{emoji: "🐟"; en: "fish"; fr: "poisson"}; \
{emoji: "🚗"; en: "car"; fr: "voiture"}; \
{emoji: "🌞"; en: "sun"; fr: "soleil"}; \
{emoji: "🌙"; en: "moon"; fr: "lune"}; \
{emoji: "🏠"; en: "house"; fr: "maison"}; \
{emoji: "🦊"; en: "fox"; fr: "renard"}; \
{emoji: "🐰"; en: "rabbit"; fr: "lapin"}; \
{emoji: "🌸"; en: "flower"; fr: "fleur"}; \
{emoji: "🐍"; en: "snake"; fr: "serpent"}; \
{emoji: "🍇"; en: "grapes"; fr: "raisin"}; \
{emoji: "🦁"; en: "lion"; fr: "lion"}; \
{emoji: "🐸"; en: "frog"; fr: "grenouille"}; \
{emoji: "🐮"; en: "cow"; fr: "vache"}; \
{emoji: "🐧"; en: "penguin"; fr: "pingouin"}; \
{emoji: "🐴"; en: "horse"; fr: "cheval"}; \
{emoji: "🔑"; en: "key"; fr: "clé"}; \
{emoji: "📖"; en: "book"; fr: "livre"}; \
{emoji: "🎩"; en: "hat"; fr: "chapeau"}; \
{emoji: "🐭"; en: "mouse"; fr: "souris"}; \
{emoji: "🐢"; en: "turtle"; fr: "tortue"}; \
{emoji: "🎸"; en: "guitar"; fr: "guitare"}; \
{emoji: "🍊"; en: "orange"; fr: "orange"}; \
{emoji: "🐷"; en: "pig"; fr: "cochon"}; \
{emoji: "🌵"; en: "cactus"; fr: "cactus"}]

property cardLeft : Collection
property cardTop : Collection
property cardSize : Real

property deck : Collection                  // [k] -> pair id 0..pairs-1
property revealed : Collection
property matched : Collection

property first : Integer
property busy : Boolean
property moves : Integer
property pairsFound : Integer
property over : Boolean
property _downCount : Integer

Class constructor($transition : cs.hero.ElementTransition)

	This.transition:=$transition
	This.cards:=This.size*This.size
	This.pairs:=This.cards/2

	This.cardLeft:=[]
	This.cardTop:=[]

	var $k : Integer
	For ($k; 0; This.cards-1)
		var $back:=cs.hero.ElementState.new("back_"+String($k+1))
		This.cardLeft.push($back.left)
		This.cardTop.push($back.top)
	End for
	This.cardSize:=cs.hero.ElementState.new("back_1").width

	This._highlightLang(1)
	This.reset()

	// === === === === === === === === === === === === === === === === === === === ===
	// Language: 1 = Français · 2 = English (new names → new letters → re-deal)
Function selectLang($i : Integer)

	If ($i=1)
		This.lang:="fr"
	Else
		This.lang:="en"
	End if
	This._highlightLang($i)
	This.reset()

	// === === === === === === === === === === === === === === === === === === === ===
Function reset()

	This.transition.stop()

	// deal `pairs` pictures with distinct starting letters, then a letter card and a
	// picture card for each — same pair id, different faces
	var $chosen : Collection:=This._deal(This.pairs)
	var $specs : Collection:=[]
	var $p : Integer
	For ($p; 0; This.pairs-1)
		var $it : Object:=$chosen[$p]
		$specs.push({pair: $p; text: This._first($it)})     // the letter card
		$specs.push({pair: $p; text: $it.emoji})            // the picture card
	End for
	$specs:=This._shuffle($specs)

	This.deck:=[]
	This.revealed:=[]
	This.matched:=[]

	var $k : Integer
	For ($k; 0; This.cards-1)
		This.deck.push($specs[$k].pair)
		This.revealed.push(False)
		This.matched.push(False)

		OBJECT SET TITLE(*; "face_"+String($k+1); $specs[$k].text)
		This._setBox("face_"+String($k+1); $k)
		This._setBox("back_"+String($k+1); $k)
		OBJECT SET VISIBLE(*; "face_"+String($k+1); False)
		OBJECT SET VISIBLE(*; "back_"+String($k+1); True)
	End for

	This.first:=-1
	This.busy:=False
	This.moves:=0
	This.pairsFound:=0
	This.over:=False
	This._downCount:=0

	OBJECT SET VISIBLE(*; "message"; False)
	This._updateHud()

	// === === === === === === === === === === === === === === === === === === === ===
Function pick($k : Integer)

	If (This.over) || (This.busy)
		return
	End if
	If (This.matched[$k]) || (This.revealed[$k])
		return
	End if

	This.busy:=True
	This._flipUp($k)

	// MARK:- [Flip — two tweens making a turn]
	// === === === === === === === === === === === === === === === === === === === ===
Function _flipUp($k : Integer)

	var $back : Text:="back_"+String($k+1)
	This.transition.animate($back)\
		.to(This._sliver($back))\
		.duration(110)\
		.easing("easeInQuad")\
		.then(Formula(Form.game._backHidden($1.target)))\
		.start()

	// === === === === === === === === === === === === === === === === === === === ===
Function _backHidden($back : Text)

	var $k : Integer:=Num(Substring($back; 6))-1
	var $face : Text:="face_"+String($k+1)

	OBJECT SET VISIBLE(*; $back; False)
	This._setSliver($face; $k)
	OBJECT SET VISIBLE(*; $face; True)

	This.transition.animate($face)\
		.to(This._fullBox($k))\
		.duration(110)\
		.easing("easeOutQuad")\
		.then(Formula(Form.game._revealed($1.target)))\
		.start()

	// === === === === === === === === === === === === === === === === === === === ===
Function _revealed($face : Text)

	var $k : Integer:=Num(Substring($face; 6))-1
	This.revealed[$k]:=True
	This._resolve($k)

	// === === === === === === === === === === === === === === === === === === === ===
Function _resolve($k : Integer)

	Case of
			//______________________________________________________
		: (This.first<0)
			This.first:=$k
			This.busy:=False

			//______________________________________________________
		Else
			This.moves:=This.moves+1
			var $a : Integer:=This.first
			This.first:=-1

			Case of
					//______________________________________________________
				: (This.deck[$a]=This.deck[$k])
					This.matched[$a]:=True
					This.matched[$k]:=True
					This.pairsFound:=This.pairsFound+1
					This._updateHud()
					If (This.pairsFound=This.pairs)
						This.over:=True
						This._say("Bravo !  "+String(This.moves)+" coups")
					End if
					This.busy:=False

					//______________________________________________________
				Else
					This._updateHud()
					This._downCount:=2
					This._flipDown($a)
					This._flipDown($k)
					//______________________________________________________
			End case
			//______________________________________________________
	End case

	// === === === === === === === === === === === === === === === === === === === ===
Function _flipDown($k : Integer)

	var $face : Text:="face_"+String($k+1)
	This.transition.animate($face)\
		.to(This._sliver($face))\
		.delay(800)\
		.duration(110)\
		.easing("easeInQuad")\
		.then(Formula(Form.game._faceHidden($1.target)))\
		.start()

	// === === === === === === === === === === === === === === === === === === === ===
Function _faceHidden($face : Text)

	var $k : Integer:=Num(Substring($face; 6))-1
	var $back : Text:="back_"+String($k+1)

	OBJECT SET VISIBLE(*; $face; False)
	This._setSliver($back; $k)
	OBJECT SET VISIBLE(*; $back; True)

	This.transition.animate($back)\
		.to(This._fullBox($k))\
		.duration(110)\
		.easing("easeOutQuad")\
		.then(Formula(Form.game._hidden($1.target)))\
		.start()

	// === === === === === === === === === === === === === === === === === === === ===
Function _hidden($back : Text)

	var $k : Integer:=Num(Substring($back; 6))-1
	This.revealed[$k]:=False
	This._downCount:=This._downCount-1
	If (This._downCount<=0)
		This.busy:=False
	End if

	// MARK:- [Deck helpers]
	// === === === === === === === === === === === === === === === === === === === ===
	// `$n` pictures with DISTINCT starting letters in the current language
Function _deal($n : Integer) : Collection

	var $src : Collection:=This._shuffle(This.items)
	var $used : Collection:=[]
	var $out : Collection:=[]
	var $it : Object
	For each ($it; $src)
		var $L : Text:=This._first($it)
		If (($used.indexOf($L)=-1) & ($out.length<$n))
			$used.push($L)
			$out.push($it)
		End if
	End for each
	return $out

	// --------------------------------------------------------------------------------
Function _word($item : Object) : Text

	return String($item[This.lang])

Function _first($item : Object) : Text

	return Uppercase(Substring(This._word($item); 1; 1))

	// --------------------------------------------------------------------------------
Function _shuffle($c : Collection) : Collection

	var $src : Collection:=$c.copy()
	var $out : Collection:=[]
	While ($src.length>0)
		var $k : Integer:=(Random % $src.length)
		$out.push($src[$k])
		$src.remove($k)
	End while
	return $out

	// MARK:- [Geometry helpers]
	// === === === === === === === === === === === === === === === === === === === ===
Function _sliver($name : Text) : Object

	var $st:=cs.hero.ElementState.new($name)
	return {left: ($st.left+$st.right)/2; width: 0}

Function _fullBox($k : Integer) : Object

	return {left: This.cardLeft[$k]; width: This.cardSize}

Function _setBox($name : Text; $k : Integer)

	OBJECT SET COORDINATES(*; $name; This.cardLeft[$k]; This.cardTop[$k]; \
		This.cardLeft[$k]+This.cardSize; This.cardTop[$k]+This.cardSize)

Function _setSliver($name : Text; $k : Integer)

	var $cx : Real:=This.cardLeft[$k]+(This.cardSize/2)
	OBJECT SET COORDINATES(*; $name; $cx; This.cardTop[$k]; $cx; This.cardTop[$k]+This.cardSize)

	// MARK:- [Display]
	// === === === === === === === === === === === === === === === === === === === ===
Function _updateHud()

	OBJECT SET TITLE(*; "moves"; "Coups : "+String(This.moves))
	OBJECT SET TITLE(*; "pairs"; "Paires : "+String(This.pairsFound)+" / "+String(This.pairs))

Function _say($message : Text)

	OBJECT SET TITLE(*; "message"; $message)
	OBJECT SET VISIBLE(*; "message"; True)

	// --------------------------------------------------------------------------------
Function _highlightLang($sel : Integer)

	var $i : Integer
	For ($i; 1; 2)
		If ($i=$sel)
			OBJECT SET RGB COLORS(*; "langPad_"+String($i); 0x00344054; 0x00344054)
			OBJECT SET RGB COLORS(*; "langLbl_"+String($i); 0x00FFFFFF; 0x00344054)
		Else
			OBJECT SET RGB COLORS(*; "langPad_"+String($i); 0x00E4E7EC; 0x00E4E7EC)
			OBJECT SET RGB COLORS(*; "langLbl_"+String($i); 0x00667085; 0x00E4E7EC)
		End if
	End for
