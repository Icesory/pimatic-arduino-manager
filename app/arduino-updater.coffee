tc = pimatic.tryCatch
linkAdded = no
$(document).on( "pagebeforecreate", (event) ->
  if linkAdded then return
  console.log("adding")
  li = $ """
    <li data-theme="f">
      <a
        href="\#arduino-updater-page"
        data-transition="slidefade"
        class="ui-btn ui-btn-f ui-btn-icon-right ui-icon-carat-r arduino-updater-plugin"
      >
        Arduino Updater
      </a>
    </li>
  """
  menu = $('#nav-panel ul li:last')
  console.log menu
  menu.before(li)
  linkAdded = yes
)

$(document).on("pagecreate", '#arduino-updater-page', tc (event) ->

  class ArduinoUpdaterViewModel

    @mapping = {
      registeredPlugins:
        $key: 'name'
        $itemOptions: {
          name: 'copy'
          board: 'copy'
          uploader: 'copy'
          port: 'copy'
          file: 'copy'
          updateRequired: 'observe'
          whiteListState: 'observe'
        }
    }

    constructor: ->
      @updateFromJs([])

      @updateListView = ko.computed( =>
        @registeredPlugins()
        pimatic.try -> $('#registered-plugins-list').listview('refresh')
      )

    updateFromJs: (data) ->
      console.log("updateFromJs")
      console.log(data)
      ko.mapper.fromJS({registeredPlugins: data}, ArduinoUpdaterViewModel.mapping, this)

    loadRegisteredPlugins: ->
      $.ajax({
        url: '/arduino-updater/registerd-plugins',
        type: 'GET',
        global: false
      }).done( (plugins) =>
        @updateFromJs(plugins)
      )

    onUpdateClicked: (plugin) =>
      $.ajax({
        url: "/arduino-updater/flash/#{plugin.name}",
        type: 'POST',
        global: true
      }).done(ajaxShowToast)
      .fail(ajaxAlertFail)

    onCheckboxChange: (plugin)=>
      console.log("Checkbox clicked")
      console.log(plugin)
      console.log("Whiteliststate: #{plugin.whiteListState()}")
      $.ajax({
        url: "/arduino-updater/whitelist/#{plugin.name}/#{plugin.whiteListState()}",
        type: 'POST',
        global: true
      }).done(ajaxShowToast)
      .fail(ajaxAlertFail)
      return true

  try
    pimatic.pages.arduinoUpdater = arduinoUpdaterPage = new ArduinoUpdaterViewModel()
    ko.applyBindings(arduinoUpdaterPage, $('#arduino-updater-page')[0])
  catch e
    TraceKit.report(e)
  return
)

$(document).on("pagebeforeshow", '#arduino-updater-page', tc (event) ->
  try
    arduinoUpdaterPage = pimatic.pages.arduinoUpdater
    arduinoUpdaterPage.loadRegisteredPlugins()
  catch e
    TraceKit.report(e)
)
