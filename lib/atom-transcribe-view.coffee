{$, View} = require 'atom-space-pen-views'
module.exports =
class AtomTranscribeView extends View
  thisTrack: null
  setPulsing: false
  smallSkip: atom.config.get('atom-transcribe.smallSkip')
  bigSkip: atom.config.get('atom-transcribe.bigSkip')
  pauseSkip: atom.config.get('atom-transcribe.pauseSkip')

  @content: ->
    @div class:'atom-transcribe', =>
      @div class:'audio-controls-container', =>
        @div class: 'block', id: 'progressblock', =>
          @progress class: 'inline-block', max: '0', value='0', id: 'audio-progressbar', outlet: 'progressbar'
          @span class: 'inline-block', id:'audio-ticker', outlet:'ticker'
        @div class:'btn-group btn-group-sm', =>
          @button class:'btn icon icon-playback-rewind skip_big', click:'fastbackward'
          @button class:'btn icon icon-playback-rewind skip_small', click:'backward'
          @button class:'btn icon playback-button icon-playback-play', click:'togglePlayback'
          @button class:'btn icon icon-playback-fast-forward skip_small', click:'forward'
          @button class:'btn icon icon-playback-fast-forward skip_big', click:'fastforward'
        @div class:'btn-group btn-group-sm pull-right', =>
          @tag 'label', =>
            @tag 'input', style:'display: none;', type:'file', multiple: false, accept:"audio/*", outlet:"musicFileSelectionInput"
            @span '', class:'btn icon icon-file-directory',
        @div class:'inline-block playing-now-container', =>
          @span 'No file selected.', class:'highlight', outlet:'nowPlayingTitle'
      @div class:'atom-transcribe-list-container'
      @tag 'audio', class:'audio-player', outlet:'audio_player', =>

  initialize: ->
    self = @
    @musicFileSelectionInput.on 'change', @filesBrowsed
    @audio_player.on 'play', ( ) =>
      $('.playback-button').removeClass('icon-playback-play').addClass('icon-playback-pause')
    @audio_player.on 'pause', ( ) =>
      $('.playback-button').removeClass('icon-playback-pause').addClass('icon-playback-play')
    @audio_player.on 'ended', @songEnded
    @progressbar.on 'click', @jumpToTime
    @progressbar.on 'mouseover', ( ) => $('#audio-progressbar').addClass('progresshover')
    @progressbar.on 'mousemove', @hoverTime
    @progressbar.on 'mouseout', ( ) => $('#audio-progressbar').removeClass('progresshover')

  show: ->
    @panel ?= atom.workspace.addBottomPanel(item:this)
    @panel.show()

  toggle:->
    if @panel?.isVisible()
      @hide()
    else
      @show()
      @pulsing()
      @moveTicker()

  makeTime: ( t ) =>
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

  hoverTime: ( e ) =>
    if @thisTrack?
      totalTime = @audio_player[0].duration
      newTime = totalTime * e.offsetX / parseInt(@progressbar.css('width'), 10)
      @progressbar.attr 'value', newTime
      @ticker.text(@makeTime(newTime) + ' / ' + @makeTime(totalTime))

  jumpToTime: ( e ) =>
    if @thisTrack?
      @audio_player[0].currentTime = @audio_player[0].duration * e.offsetX / parseInt @progressbar.css('width'), 10

  moveTicker: ->
    setInterval ( ) =>
      if @thisTrack?
        timeSpent = @audio_player[0].currentTime
        totalTime = @audio_player[0].duration
        if !@progressbar.hasClass('progresshover')
          @progressbar.attr('max', totalTime)
          @progressbar.attr('value', timeSpent)
          @ticker.text(@makeTime(timeSpent) + ' / ' + @makeTime(totalTime))
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
    console.log "Finished."

  skip: ( seconds )->
    delta = @audio_player[0].currentTime + seconds
    if (delta < 0)
      @audio_player[0].currentTime = 0
    else if (delta > @audio_player[0].duration)
      @stopTrack
    else
      @audio_player[0].currentTime += seconds

  forward: ->
    @skip @smallSkip

  fastforward: ->
    @skip @bigSkip

  backward: ->
    @skip -1 * @smallSkip

  fastbackward: ->
    @skip -1 * @bigSkip

  loadTrack: (track) ->
    player = @audio_player[0]
    if track?
      @nowPlayingTitle.html (track.name)
      @thisTrack = track
      player.pause()
      player.src = track.path
      player.load()
      player.play()

  stopTrack: ->
    player = @audio_player[0]
    if @thisTrack?
      @togglePlayback() if not player.paused
      @nowPlayingTitle.html ('Nothing to play')
      player.src = null

  filesBrowsed: ( e ) =>
    files = $(e.target)[0].files
    if files? and files.length == 1
      track = { name: files[0].name, path: files[0].path }
      @loadTrack track
    else
      @nowPlayingTitle.html ('Please select only one track.')

  togglePlayback: ->
    player = @audio_player[0]
    if @thisTrack?
      if player.paused or player.currentTime == 0
        @skip(-1 * @pauseSkip)
        player.play()
        $('.playback-button').removeClass('icon-playback-play').addClass('icon-playback-pause')
      else
        player.pause()
        $('.playback-button').removeClass('icon-playback-pause').addClass('icon-playback-play')

  hide: ->
    @panel?.hide()
