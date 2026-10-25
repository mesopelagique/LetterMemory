// Each card flip is two chained tweens, played by the cs.hero engine

Case of

		//______________________________________________________
	: (Form event code=On Load)

		Form.transition:=cs.hero.ElementTransition.new()
		Form.game:=cs.LetterMemory.new(Form.transition)

		// Turn-based: the engine runs its own timer while a flip animates and
		// releases it when idle. On Timer only drives it — nothing to re-arm.

		//______________________________________________________
	: (Form event code=On Timer)

		Form.transition.onTimer()

		//______________________________________________________
	: (Form event code=On Clicked)

		var $name : Text:=FORM Event.objectName

		Case of

				//______________________________________________________
			: ($name="buttonReset")

				Form.game.reset()

				//______________________________________________________
			: (Position("pick_"; $name)=1)

				// pick_1 .. pick_16  ->  card 0 .. 15
				Form.game.pick(Num(Substring($name; 6))-1)

				//______________________________________________________
			: (Position("langBtn_"; $name)=1)

				Form.game.selectLang(Num(Substring($name; 9)))

				//______________________________________________________
			: (Position("modeBtn_"; $name)=1)

				Form.game.selectMode(Num(Substring($name; 9)))

				//______________________________________________________
		End case

		//______________________________________________________
	: (Form event code=On Unload)

		SET TIMER(0)

		//______________________________________________________
End case
