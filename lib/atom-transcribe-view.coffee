{$, View} = require 'atom-space-pen-views'
FuzzyMatching = require 'fuzzy-matching'
path = require 'path'
fs = require 'fs'

module.exports =
class AtomTranscribeView extends View
  thisTrack: null
  markerLayer: null
  setPulsing: false
  hoveredTime: null
  timestampRegexp: /(\d{1,2}:){1,2}\d{1,2}(\.\d{1,})?/
  smallSkip: atom.config.get('atom-transcribe.smallSkip')
  bigSkip: atom.config.get('atom-transcribe.bigSkip')
  pauseSkip: atom.config.get('atom-transcribe.pauseSkip')
  timeStampFormat: atom.config.get('atom-transcribe.timeStampFormat')

  @content: ->
    @div class:'atom-transcribe', =>
      @div class: 'player', outlet: 'playercontainer'
      @div class:'audio-controls-container', =>
        @div class: 'block', id: 'progressblock', =>
          @progress class: 'inline-block', max: '0', value='0', id: 'audio-progressbar', outlet: 'progressbar'
          @div id: 'audio-ticker-box', =>
            @span class: 'inline-block', id:'audio-ticker', outlet:'ticker'
        @div class:'btn-group btn-group-sm', =>
          @button class:'btn icon icon-playback-rewind skip_big', click:'fastbackward'
          @button class:'btn icon icon-playback-rewind skip_small', click:'backward'
          @button class:'btn icon playback-button icon-playback-play', click:'togglePlayback'
          @button class:'btn icon icon-playback-fast-forward skip_small', click:'forward'
          @button class:'btn icon icon-playback-fast-forward skip_big', click:'fastforward'
          @button class:'btn icon icon-watch', click:'insertTimestamp'
          @span '', class:'btn icon icon-device-camera-video show-video', click: 'toggleVideo', outlet:"btnToggleVideo"
        @div class:'btn-group btn-group-sm pull-right', =>
          @tag 'label', =>
            @tag 'input', style:'display: none;', type:'file', multiple: false, accept:"audio/*, video/*", outlet:"musicFileSelectionInput"
            @span '', class:'btn icon icon-file-directory',
        @div class:'inline-block playing-now-container', =>
          @span 'No file selected.', class:'highlight', outlet:'nowPlayingTitle'
        @div class:'inline-block pull-right', id:'playback-rate', =>
          @span outlet: 'playbackRangeText', class: 'pull-right playback-text'
          @input class: 'input-range', type: 'range', max: '1.6', min:'0.5', value:'1.0', step:'0.01', outlet: 'playbackRangeInput'

  initialize: ->
    self = @
    @musicFileSelectionInput.on 'change', @filesBrowsed
    @playbackRangeInput.on 'change', @playbackRateSlider
    @playercontainer.on 'play', 'audio, video', ( ) =>
      $('.playback-button').removeClass('icon-playback-play').addClass('icon-playback-pause')
    @playercontainer.on 'pause', 'audio, video', ( ) =>
      $('.playback-button').removeClass('icon-playback-pause').addClass('icon-playback-play')
    @playercontainer.on 'ended', 'audio, video', @songEnded
    @progressbar.on 'click', @jumpToTimeByProgress
    @progressbar.on 'mousemove', @hoverTime
    @progressbar.on 'mouseout', ( ) => @hoveredTime = null

    view = atom.views.getView atom.workspace.getActiveTextEditor()
    view.ondblclick = => @jumpToTimeByMarker()

  show: ->
    @panel ?= atom.workspace.addBottomPanel(item:this)
    @guessTrack()
    @panel.show()

  toggle:->
    if @panel?.isVisible()
      if not @player?.paused
        @togglePlayback()
      @hide()
    else
      @show()
      @pulsing()
      @moveTicker()

  toggleVideo: ->
    $('.atom-transcribe video').toggleClass 'hide'
    $('.atom-transcribe .btn.show-video').toggleClass 'text-subtle'

  makeTime: ( t ) ->
    ms = (t % 1).toFixed(2).substring(2)
    t = Math.floor(t)
    s = String('00' + t % 60).slice(-2);
    m = Math.floor(t / 60)
    str = ""
    if m > 60
      h = String('00' + Math.floor(m / 60)).slice(-2)
      m = String('00' + m % 60).slice(-2);
      str = "#{h}:#{m}:#{s}.#{ms}"
    else
      m = String('00' + m).slice(-2);
      str = "#{m}:#{s}.#{ms}"
    return str

  makeTimestamp: ( t ) ->
    tt = t.split(':').reverse()
    flt = 0
    for num, i in tt
        flt += Math.pow(60,i) * parseFloat num
    return flt

  hoverTime: ( e ) =>
    if @thisTrack?
      @hoveredTime = @player.duration * e.offsetX / parseInt(@progressbar.css('width'), 10)
      @progressbar.attr('value', @hoveredTime)

  jumpToTimeByProgress: ( e ) =>
    if @thisTrack?
      @player.currentTime = @player.duration * e.offsetX / parseInt @progressbar.css('width'), 10

  jumpToTimeByMarker: (e) =>
    editor = atom.workspace.getActiveTextEditor()
    pos = editor.getCursorBufferPosition()
    matchbefore = false
    matchafter = false
    editor.scan  new RegExp(@timestampRegexp, 'g'), ( match ) =>
      if match.range.start.isLessThanOrEqual(pos)
        # include COLUMN
        matchbefore = match
      if match.range.end.isGreaterThanOrEqual(pos)
        matchafter = match
        match.stop()

    if not matchbefore or not matchafter
      atom.notifications.addWarning 'Cannot move to the clicked section.',  {detail: 'The clicked section is before the first or after the last found timestamp; this makes interpolation impossible, sorry.', dismissible: true}
      return
    if matchbefore == matchafter
      @player.currentTime = @makeTimestamp matchbefore.matchText
      return

    prevtime = @makeTimestamp matchbefore.matchText
    nexttime = @makeTimestamp matchafter.matchText

    buffer = editor.getBuffer()
    start = buffer.characterIndexForPosition matchbefore.range.end
    end = buffer.characterIndexForPosition matchafter.range.start
    offset = buffer.characterIndexForPosition pos

    totaloffset = (offset - start) / (end - start)
    ts = prevtime + totaloffset * (nexttime - prevtime)

    @player.currentTime = ts


  moveTicker: ->
    setInterval ( ) =>
      if @thisTrack?
        timeSpent = @player.currentTime
        totalTime = @player.duration
        @progressbar.attr('max', totalTime)
        if @hoveredTime?
          t = @hoveredTime
          @ticker.html('<i>('+@makeTime(t)+')</i> ' + @makeTime(timeSpent) + ' / ' + @makeTime(totalTime))
        else
          t = timeSpent
          @ticker.text(@makeTime(timeSpent) + ' / ' + @makeTime(totalTime))
        @progressbar.attr('value', t)
    , 200

  pulsing: ->
    if @setPulsing
      setInterval ( ) =>
        $(@).addClass('pulse')
        setTimeout ( ) =>
          $(@).removeClass('pulse')
        , 2000
      , 4000

  songEnded: ( e ) =>
    #console.log "Finished."

  skip: ( seconds )->
    delta = @player.currentTime + seconds
    if (delta < 0)
      @player.currentTime = 0
    else if (delta > @player.duration)
      @stopTrack
    else
      @player.currentTime += seconds

  forward: ->
    @skip @smallSkip

  fastforward: ->
    @skip @bigSkip

  backward: ->
    @skip -1 * @smallSkip

  fastbackward: ->
    @skip -1 * @bigSkip

  reduceSpeed: ->
    @changePlaybackRate parseFloat(@playbackRangeInput.prop('value')) - 0.05

  increaseSpeed: ->
    @changePlaybackRate parseFloat(@playbackRangeInput.prop('value')) + 0.05

  guessTrack: ->
    player = @player
    extensions = ['.mp3', '.ogg', '.wav']
    if not player or not player.src?
      return
    file = atom.workspace.getActiveTextEditor().buffer.file.path
    folder = path.dirname file
    filename = path.basename file
    fs.readdir folder, (err, files) =>
      files = files.filter (f) -> extensions.includes(path.extname(f))
      fm = new FuzzyMatching(files)
      res = fm.get(filename)
      if res.distance > 0.7
        guessedaudio = { name: res.value, path: path.join folder, res.value }
        console.log 'Guessing audio', guessedaudio
        @loadTrack(guessedaudio, true)

  loadTrack: (track, dontplay) ->
    type = track.type.replace /\/.*/ , ''
    @player = document.createElement type
    if type == 'video'
        @btnToggleVideo.show()
    else
        @btnToggleVideo.hide()
    @playercontainer[0].appendChild @player
    if track?
      @nowPlayingTitle.html (track.name)
      @thisTrack = track
      @changePlaybackRate 1.0
      @player.pause()
      @player.src = track.path
      @player.load()
      if dontplay? and not dontplay
        @player.play()
      @markTimestamps()

  stopTrack: ->
    player = @player
    if @thisTrack?
      @togglePlayback() if not player.paused
      @nowPlayingTitle.html ('Nothing to play')
      player.src = null

  playbackRateSlider: ( e ) =>
    @changePlaybackRate $(e.target)[0].value

  changePlaybackRate: ( pbrate ) ->
    if pbrate > @playbackRangeInput.prop('max')
        pbrate = @playbackRangeInput.prop('max')
    if pbrate < @playbackRangeInput.prop('min')
        pbrate = @playbackRangeInput.prop('min')
    pbrate = parseFloat pbrate
    @player.playbackRate = pbrate
    @playbackRangeInput.prop('value', pbrate.toFixed(2))
    @playbackRangeText.text('x'+pbrate.toFixed(2))

  filesBrowsed: ( e ) =>
    files = $(e.target)[0].files
    if files?
      if files.length == 1
        track = { name: files[0].name, path: files[0].path, type: files[0].type }
        @loadTrack track
      else if files.length > 1
        @nowPlayingTitle.html ('Please select only one track.')

  togglePlayback: ->
    player = @player
    if @thisTrack?
      if player.paused or player.currentTime == 0
        @skip(-1 * @pauseSkip)
        player.play()
        $('.playback-button').removeClass('icon-playback-play').addClass('icon-playback-pause')
      else
        player.pause()
        $('.playback-button').removeClass('icon-playback-pause').addClass('icon-playback-play')

  insertTimestamp: ->
    if @thisTrack? and editor = atom.workspace.getActiveTextEditor()
      ts = @makeTime @player.currentTime
      txt = @timeStampFormat.replace('%t', ts)
      editor.insertText(txt)
      @markTimestamps()

  markTimestamps: ->
    if @markerLayer?
      @markerLayer.destroy()
    editor = atom.workspace.getActiveTextEditor()
    @markerLayer = editor.addMarkerLayer()
    range =  [[0, 0], editor.getEofBufferPosition()]
    editor.scanInBufferRange new RegExp(@timestampRegexp, 'g'), range, (result) =>
    #console.log result
      m = @markerLayer.markBufferRange(result.range, {'invalidate':'inside'})

    editor.decorateMarkerLayer @markerLayer, {
      type: 'highlight',
      class: 'atom-transcribe-timestamp'
    }

  hide: ->
    @panel?.hide()
