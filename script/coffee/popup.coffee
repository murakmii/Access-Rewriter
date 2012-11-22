
global = @

clicked_status_button = ( ) ->
   if not $( this ).hasClass "selected"

      item = $ this.parentNode
      item.children( '.selected' ).removeClass "selected"

      id = parseInt this.parentNode.dataset.rewrite
      disabled = $( this ).text( ) is 'OFF'

      $( '#foreground-view h3' ).text '変更しています'
      $( '#foreground-view' ).fadeIn 200, ( ) =>
         global.app.config.disabled id, disabled, ( success, rewrite ) =>
            item.children( if rewrite.disabled then ".off" else ".on" ).addClass "selected"
            $( '#foreground-view' ).fadeOut 200

changed_disabled_all = ( ) ->
   $( '#foreground-view h3' ).text '変更しています'
   $( '#foreground-view' ).fadeIn 200, ( ) ->
      global.app.config.set_disabled_all document.disabled_all.checkbox.checked, ( ) ->
         disabled_all = @disabled_all( )
         document.disabled_all.checkbox.checked = disabled_all

         hidden_element = if disabled_all then "#rewrites" else "#disabled-all-message"
         shown_element  = if disabled_all then "#disabled-all-message" else "#rewrites"

         $( hidden_element ).hide( )
         $( shown_element ).show( )
         $( '#foreground-view' ).fadeOut 200

add_rewrite_item = ( rewrite ) ->
   item = $ "<div class=\"rewrite\" data-rewrite=\"#{rewrite.id}\"></div>"
   item.append "<div class=\"name\">#{rewrite.title}</div>"

   on_button = $ '<div class="button on">ON</div>'
   off_button = $ '<div class="button off">OFF</div>'
   ( if rewrite.disabled then off_button else on_button ).addClass "selected"
   item.append on_button, off_button

   $( '#rewrites' ).append item
   on_button.click clicked_status_button
   off_button.click clicked_status_button

ready = ( ) ->

   if global.app.setup_failed
      $( '#foreground-view h3' ).text '拡張機能のセットアップに失敗しました'
   else
      $( '#foreground-view' ).hide( )
      if ( rewrites = global.app.config.get_rewrites( ) ).length isnt 0

         for rewrite in global.app.config.get_rewrites( )
            add_rewrite_item rewrite

         disabled_all = global.app.config.disabled_all( )
         document.disabled_all.checkbox.checked = disabled_all
         if disabled_all
            $( '#rewrites' ).hide( )
            $( '#disabled-all-message' ).show( )

         $( document.disabled_all.checkbox ).change changed_disabled_all

      else 
         $( 'form' ).hide( )
         $( '#container' ).append '<p>設定されている書き換え設定はありません<br />オプションページより設定を作成できます</p>'

$ ( ) ->

   chrome.runtime.getBackgroundPage ( bkg ) ->
      global.app = bkg.app
      if global.app.is_ready
         ready( )
      else
         $( '#foreground-view h3' ).text '拡張機能をロードしています'
         $( '#foreground-view' ).show( )
         timer = setInterval ( ) ->
            if global.app.is_ready
               clearInterval timer
               ready( )
         , 100