class ChocAnimationEditor
  gval = eval

  constructor: (options) ->
    defaults =
      maxIterations: 1000
      maxAnimationFrames: 100

    @options = _.extend(defaults, options)
    @$ = options.$
    @state = 
      delay: null
      slider:
        value: 0
      playing: false
    @setupEditor()

  changeSliderValue: (newValue) ->
    @$( "#amount" ).text( "frame #{newValue}" ) 
    @state.slider.value = newValue

  changeSlider: (newValue) ->
    @changeSliderValue(newValue)
    @updateFrameView()

  setupEditor: () ->
    @interactiveValues = {
      onChange: (v) =>
        clearTimeout(@state.delay)
        @state.delay = setTimeout((() => @updateViews()), 1)
    }

    @codemirror = CodeMirror @$("#editor")[0], {
      value: @options.code
      mode:  "javascript"
      viewportMargin: Infinity
      tabMode: "spaces"
      interactiveNumbers: @interactiveValues
      }

    @codemirror.on "change", () =>
      clearTimeout(@state.delay)
      @state.delay = setTimeout((() => @updateViews()), 500)

    onSliderChange = (event, ui) =>
      if event.hasOwnProperty("originalEvent") # e.g. triggered by a user interaction, not programmatically below
        @changeSlider(ui.value)

    @slider = @$("#slider").slider {
      min: 0
      max: @options.maxAnimationFrames
      change: onSliderChange
      slide: onSliderChange
      }

    @$("#animation-controls").click () =>
      if @state.playing
        @onPause()
      else
        @onPlay()

  onPlay: () ->
    @$("#animation-controls").text("Pause")
    @state.playing = true
    @updateViews()
    @options.play()

  onPause: () ->
    @$("#animation-controls").text("Play")
    @state.playing = false
    @options.pause()
    @updateViews()

  onFrame: (frameCount, timeDelta) ->
    @changeSliderValue(frameCount)
    @slider.slider('value', frameCount)
    # console.log(frameCount)

  updateFrameView: () ->
    try
      code = @codemirror.getValue()
      if @options.animate?
        # below we run animate for every iteration to make sure we're at the
        # right place in code. However, we don't clear/update everytime because
        # it causes flashing. We only need to clear right before we draw the
        # frame we want to see
        appendSource = """
          for(var __i=0; __i<#{@state.slider.value}; __i++) {
            if(__i == #{@state.slider.value - 1}) {
              pad.clear();
              #{@options.animate}();
              pad.update();
            } else {
            #{@options.animate}();
            }
          }
        """

      @runCode(@codemirror.getValue() + appendSource, false)

      @$("#messages").text("")
    catch e
      console.log(e)
      console.log(e.stack)
      @$("#messages").text(e.toString())

  runCode: (code, isPreview=false) ->
    gval = eval

    localsIndex = if isPreview then 1 else 0

    window._choc_preview_locals = @options.locals
    localsStr = _.map( _.keys(@options.locals), \
                (name) -> 
                  "var #{name} = _choc_preview_locals.#{name}[#{localsIndex}]").join("; ")
    gval(localsStr + "\n" + code )

  updateViews: () ->
    @generatePreview()
    @updateFrameView()

  generatePreview: () ->
    @options.beforeGeneratePreview?()
    @runCode(@codemirror.getValue(), true)
    draw = gval(@options.animate)
    do (() -> draw()) for [1..@options.maxAnimationFrames]
    @options.afterGeneratePreview?()

  start: (frame=1) ->
    @changeSlider(frame)
    @updateViews()

root = exports ? this
root.choc.AnimationEditor = ChocAnimationEditor
