
global = @
global.app = null
global.recentry_changed = 0

loaded_file = ( e ) ->
   read = e.target.result
   document.rewrite.data.value = read.substring ( read.indexOf( ',' ) + 1 )

clicked_tab = ( ) ->
   if not $( this ).hasClass 'selected'

      selected = $( '#tabs div.tab.selected' ).removeClass 'selected'
      $( "#" + selected.get( 0 ).dataset.panel ).hide( )

      $( this ).addClass 'selected'
      $( "#" + this.dataset.panel ).show( )

dragenter = ( ) ->
   $( this ).css backgroundColor: '#96B9F9';
   false

dragleave = ( ) ->
   $( this ).css backgroundColor: '#CCC'
   false

drop = ( e ) ->
   if e.originalEvent.dataTransfer.files.length isnt 0

      file = e.originalEvent.dataTransfer.files[ 0 ]
      if file.type.length isnt 0
         mime_type = file.type.split '/'
         document.rewrite.mime_header.value = mime_type[ 0 ]
         document.rewrite.mime_body.value = mime_type[ 1 ]
      else
         document.rewrite.mime_header.value = 'text'
         document.rewrite.mime_body.value = 'plain'

      $( 'input[ type = "radio" ][ name = "type" ]' ).val [ 'binary' ]

      reader = new FileReader
      reader.onloadend = loaded_file
      reader.readAsDataURL file

   $( this ).css backgroundColor: '#CCC'
   return false

clicked_rewrite_list_item = ( ) ->
   if $( this ).hasClass 'selected'
      $( this ).removeClass 'selected'
      $( this.nextSibling ).slideUp 150
   else
      if ( selected = $( this.parentNode ).children( 'div.item.selected' ) ).length isnt 0
         selected.removeClass 'selected'
         $( selected.get( 0 ).nextSibling ).slideUp 150
      $( this ).addClass 'selected'
      $( this.nextSibling ).slideDown 150

clicked_rewrite_amend = ( ) ->
   if ( rewrite = global.app.config.get_rewrite parseInt( this.parentNode.dataset.rewrite ) ) is null
      alert "データを取得できません。ページを再読み込みすると解決する場合があります"
      return

   $( '#status-message' ).hide( )
   $( '#edit h2' ).text '既存の設定を編集中'
   document.rewrite.id.value = rewrite.id
   document.rewrite.title.value = rewrite.title
   document.rewrite.url.value = rewrite.url
   document.rewrite.url_is_regex.checked = rewrite.url_is_regex
   document.rewrite.mime_header.value = rewrite.mime_header
   document.rewrite.mime_body.value = rewrite.mime_body
   $( 'input[ type = "radio" ][ name = "type" ]' ).val [ if rewrite.base64 then 'binary' else 'text' ]
   document.rewrite.data.value = rewrite.data

clicked_rewrite_remove = ( ) ->
   if confirm( "本当に削除しますか？" )
      operation = this.parentNode
      global.app.config.remove parseInt( operation.dataset.rewrite ), ( success, rewrite ) ->
         if success
            $( operation.previousSibling ).remove( )
            $( operation ).remove( )
            clear_form( ) if rewrite.id is parseInt( document.rewrite.id.value )
            send_changed_message( )
         else
            alert( "削除に失敗しました" );

clicked_save = ( ) ->

   return if not validation_form( )

   disable_form( )
   set_status_message 'waiting', '保存中...'

   id          = document.rewrite.id.value
   title       = document.rewrite.title.value
   url         = document.rewrite.url.value
   url_is_regex= document.rewrite.url_is_regex.checked
   mime_header = document.rewrite.mime_header.value
   mime_body   = document.rewrite.mime_body.value
   base64      = $( 'input[ type = "radio" ][ name = "type" ]:checked' ).val( ) is 'binary'
   data        = document.rewrite.data.value

   if id.length is 0
      global.app.config.add title, url, url_is_regex, mime_header, mime_body, base64, data, ( success, rewrite ) ->
         enable_form( )
         if success
            set_status_message 'success', '保存が完了しました'
            add_rewrite_list rewrite
            clear_form( )
            send_changed_message( )
         else
            set_status_message 'failed', '保存に失敗しました'
   else
      global.app.config.override id, title, url, url_is_regex, mime_header, mime_body, base64, data, ( success, rewrite ) ->
         enable_form( )
         if success
            set_status_message 'success', '書き換え設定を上書きしました'
            $( "#rewrite-#{rewrite.id}" ).text rewrite.title
            clear_form( )
            send_changed_message( )
         else
            set_status_message 'failed', '上書きに失敗しました'

# 他のタブでオプションページが開かれている可能性があるため、データの更新時はこの関数を呼び出してデータの更新を知らせる
send_changed_message = ( ) ->
   global.recentry_changed = ( new Date ).getTime( )
   chrome.extension.sendMessage changed: global.recentry_changed

add_rewrite_list = ( rewrite ) ->
   title       = $ "<div id=\"rewrite-#{rewrite.id}\" class=\"item\">#{rewrite.title}</div>"
   operation   = $ "<div class=\"operation\" data-rewrite=\"#{rewrite.id}\"></div>"
   operation.append '<span data-operation="amend">修正</span>'
   operation.append '<span data-operation="remove">削除</span>'

   $( '#rewrite-list' ).append title
   $( '#rewrite-list' ).append operation

   title.click clicked_rewrite_list_item
   operation.children( 'span[ data-operation = "remove" ]' ).click clicked_rewrite_remove
   operation.children( 'span[ data-operation = "amend" ]' ).click clicked_rewrite_amend

set_status_message = ( class_name, message, show ) ->
   $( 'span#status-message' ).removeClass( 'waiting success failed' ).addClass( class_name ).text message
   if not show? or show is true then $( 'span#status-message' ).show( )

validation_form = ( ) ->

   if document.rewrite.title.value.length is 0
      set_status_message 'failed', 'タイトルを入力してください'
      return false

   if document.rewrite.url.value.length is 0
      set_status_message 'failed', '対象URLを入力してください'
      return false

   valid_mime = /^[a-zA-Z0-9\.\-]+$/
   if not document.rewrite.mime_header.value.match valid_mime or not document.rewrite.mime_body.value.match
      set_status_message 'failed', 'MIMEタイプは英数字とピリオド,ハイフンで入力してください'
      return false

   true

get_form_element = ( ) ->
   [
      $( document.rewrite.title ),
      $( document.rewrite.url ),
      $( document.rewrite.url_is_regex ),
      $( document.rewrite.mime_header ),
      $( document.rewrite.mime_body ),
      $( 'input[ type = "radio" ][ name = "type" ]' ),
      $( document.rewrite.data ),
      $( document.rewrite.cancel ),
      $( document.rewrite.save )
   ]

disable_form = ( ) -> element.attr 'disabled', 'disabled' for element in get_form_element( )
enable_form = ( ) -> element.removeAttr 'disabled' for element in get_form_element( )

clear_form = ( ) ->
   $( '#edit h2' ).text '新規作成'
   document.rewrite.id.value = ''
   document.rewrite.title.value = ''
   document.rewrite.url.value = ''
   document.rewrite.url_is_regex.checked = false
   document.rewrite.mime_header.value = ''
   document.rewrite.mime_body.value = ''
   $( 'input[ type = "radio" ][ name = "type" ]' ).val [ 'text' ]
   document.rewrite.data.value = ''

ready = ( ) ->

   # データ更新のメッセージを受け取った場合、内容をチェックし必要ならリロードする
   chrome.extension.onMessage.addListener ( message ) ->
      location.reload( ) if message.changed? and parseInt( message.changed ) isnt global.recentry_changed

   if global.app.setup_failed
      $( '#foreground-view h3' ).text '拡張機能のセットアップに失敗しました。ブラウザを再起動すると解決する場合があります。'
   else
      $( '#foreground-view' ).hide( )
      for rewrite in global.app.config.get_rewrites( )
         add_rewrite_list rewrite

$ ( ) ->
   $( '#tabs div.tab' ).click clicked_tab

   $( '#file-drop-area' ).bind 'dragover', ( ) -> false
   $( '#file-drop-area' ).bind 'dragenter', dragenter
   $( '#file-drop-area' ).bind 'dragleave', dragleave
   $( '#file-drop-area' ).bind 'drop', drop

   $( document.rewrite.cancel ).click clear_form
   $( document.rewrite.save ).click clicked_save

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
               ready
         , 100






      



