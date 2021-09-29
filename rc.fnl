;-*-Lisp-*-

;; Import some snazzy macros
(import-macros {: binds : btn} :macros)

;; If LuaRocks is installed, make sure that packages installed through it are
;; found (e.g. lgi). If LuaRocks is not installed, do nothing.
(pcall require :luarocks.loader)

;; Standard awesome library
(local awful (require :awful))
(local gears (require :gears))
(require :awful.autofocus)

;; Widget and layout library
(local wibox         (require :wibox))

;; Theme handling library
(local beautiful     (require :beautiful))

;; Notification library
(local naughty       (require :naughty))

;; Declarative object management
(local ruled         (require :ruled))
(local menubar       (require :menubar))
(local hotkeys_popup (require :awful.hotkeys_popup))

;; Enable hotkeys help widget for VIM and other apps
;; when client with a matching name is opened:
(require :awful.hotkeys_popup.keys)

;; {{{ Error handling
;; Check if awesome encountered an error during startup and fell back to
;; another config (This code will only ever execute for the fallback config)
(naughty.connect_signal "request::display_error"
  (fn [message during-startup?]
    (naughty.notification
      {:urgency :critical
       :title   (str "Oops, an error happened"
                     (if during-startup?
                       " during start-up!"
                       "!"))
       :message message})))
;; }}}

;; {{{ Variable definitions
;; Themes define colours, icons, font and wallpapers
(beautiful.init
  (.. (gears.filesystem.get_themes_dir) "default/theme.lua"))

;; This is used later as the default terminal and editor to run.
(local terminal   :wezterm)
(local editor     (or (os.getenv :EDITOR) :nano))
(local editor-cmd (string.format "%s -e %s" terminal editor))

;; Default modkey.
;; Usually, Mod4 is the key with a logo between Control and Alt.
;; If you do not like this or do not have such a key,
;; I suggest you to remap Mod4 to another key using xmodmap or other tools.
;; However, you can use another modifier like Mod1, but it may interact with others.
(local mod-key :Mod4)
;;}}}

;; {{{ Menu
;; Create a launcher widget and a main menu
(local myawesomemenu
  [["hotkeys"     (fn [] (hotkeys_popup.show_help nil (awful.screen.focused)))]
   ["manual"      (string.format "%s -e man awesome" terminal)]
   ["edit config" (string.format "%s %s" editor-cmd awesome.conffile)]
   ["restart"     awesome.restart]
   ["quit"        (fn [] (awesome.quit))]])

(local mymainmenu
  (awful.menu
    {:items [["awesome"       myawesomemenu beautiful.awesome_icon]
             ["open terminal" terminal]]}))

(local mylauncher
  (awful.widget.launcher
    {:image beautiful.awesome_icon
     :menu  mymainmenu}))

;; Menubar configuration
(set menubar.utils.terminal terminal) ;; Set the terminal for applications that require it
;; }}}

;; {{{ Tag
;; Table of layouts to cover with awful.layout.inc, order matters.
(tag.connect_signal
  "request::default_layouts"
  (fn [] (awful.layout.append_default_layouts
           [awful.layout.suit.floating
            awful.layout.suit.tile
            awful.layout.suit.tile.left
            awful.layout.suit.tile.bottom
            awful.layout.suit.tile.top
            awful.layout.suit.fair
            awful.layout.suit.fair.horizontal
            awful.layout.suit.spiral
            awful.layout.suit.spiral.dwindle
            awful.layout.suit.max
            awful.layout.suit.max.fullscreen
            awful.layout.suit.magnifier
            awful.layout.suit.corner.nw])))
;; }}}

;; {{{ Wibar
;; Keyboard map indicator and switcher
(local mykeyboardlayout (awful.widget.keyboardlayout))

;; Create a textclock widget
(local mytextclock wibox.widget.textclock)

(screen.connect_signal
  "request::wallpaper"
  (fn [s]
    ;; Wallpaper
    (when beautiful.wallpaper
      (local wallpaper beautiful.wallpaper)
      (gears.wallpaper.maximized
        ;; If wallpaper is a function, call it with the screen
        (if (= (type wallpaper) :function)
          (wallpaper s)
          wallpaper)
        s true))))

(screen.connect_signal "request::desktop_decoration"
  (fn [s]
    ;; Each screen has its own tag table.
    (awful.tag ["1" "2" "3" "4" "5" "6" "7" "8" "9"] s (. awful.layout.layouts 1))

    ;; Create a promptbox for each screen
    (set s.mypromptbox (awful.widget.prompt))

    ;; Create an imagebox widget which will contain an icon indicating which layout we're using.
    ;; We need one layoutbox per screen.
    (set s.mylayoutbox
         (awful.widget.layoutbox
          {:screen s
           :buttons [(btn 1 (fn [] (awful.layout.inc 1)))
                     (btn 3 (fn [] (awful.layout.inc -1)))
                     (btn 4 (fn [] (awful.layout.inc 1)))
                     (btn 5 (fn [] (awful.layout.inc -1)))]}))
    (set s.mytaglist
         (awful.widget.taglist
          {:screen  s
           :filter  awful.widget.taglist.filter.all
           :buttons [(btn           1 (fn [t] (t:view_only)))
                     (btn [mod-key] 1 (fn [t] (when client.focus
                                               (client.focus:move_to_tag t))))
                     (btn           3 awful.tag.viewtoggle)
                     (btn [mod-key] 3 (fn [t] (when client.focus
                                               (client.focus:toggle_tag t))))
                     (btn 4 (fn [t] (awful.tag.viewprev t.screen)))
                     (btn 5 (fn [t] (awful.tag.viewnext t.screen)))]}))
    (set s.mytasklist
         (awful.widget.tasklist
           {:screen  s
            :filter  awful.widget.tasklist.filter.currenttags
            :buttons [(btn 1 (fn [c] (c:activate
                                       {:context :tasklist
                                        :action  :toggle_minimization})))
                      (btn 3 (fn [] (awful.menu.client_list
                                      {:theme {:width 250}})))
                      (btn 4 (fn [] (awful.client.focus.byidx -1)))
                      (btn 5 (fn [] (awful.client.focus.byidx 1)))]}))

    ;; Create the wibox
    (set s.mywibox
         (awful.wibar
           {:position :top
            :screen   s
            :widget
            {:layout wibox.layout.align.horizontal
             1 {:layout wibox.layout.fixed.horizontal
                1 mylauncher
                2 s.mytaglist
                3 s.mypromptbox}
             2 s.mytasklist
             3 {:layout wibox.layout.fixed.horizontal
                1 mykeyboardlayout
                2 (wibox.widget.systray)
                3 mytextclock
                4 s.mylayoutbox}}}))))
;; }}} 

;; {{{ Mouse bindings
(awful.mouse.append_client_mousebindings
  [(btn 3 (fn [] (mymainmenu:toggle)))
   (btn 4 awful.tag.vievprev)
   (btn 5 awful.tag.viewnext)])
;; }}}

;; {{{ Key bindings
;; General Awesome keys
(binds
  [{:description "show help" :group :awesome
    :mods [mod-key] :key :s
    :action hotkeys_popup.show_help}
   {:description "show main menu" :group :awesome
    :mods [mod-key] :key :w
    :action (fn [] (mymainmenu:show))}
   {:description "reload awesome" :group :awesome
    :mods [mod-key :Control] :key :r
    :action awesome.restart}
   {:description "quit awesome" :group :awesome
    :mods [mod-key :Control] :key :q
    :action awesome.quit}
   {:description "lua execute prompt" :group :awesome
    :mods [mod-key] :key :x
    :action (fn []
              (awful.prompt.run 
                {:prompt "<b>Run Lua code:</b> "
                 :textbox (let [screen (awful.screen.focused)]
                            screen.mypromptbox.widget)
                 :exe_callback awful.util.eval
                 :history_path (.. (awful.util.get_cache_dir) "/history_eval")}))}
   {:description "open a terminal" :group :launcher
    :mods [mod-key] :key :Return
    :action (fn [] (awful.spawn terminal))}
   {:description "run a prompt" :group :launcher
    :mods [mod-key] :key :r
    :action (fn []
              (let [s (awful.screen.focused)]
                (s.mypromptbox:run)))}
   {:description "show the menubar" :group :launcher
    :mods [mod-key] :key :p
    :action menubar.show}])

;; Tags related keybindings
(binds
  [{:description "view preview" :group :tag
    :mods [mod-key] :key :Left
    :action awful.tag.viewprev}
   {:description "view next" :group :tag
    :mods [mod-key] :key :Right
    :action awful.tag.viewnext}
   {:description "go back" :group :tag
    :mods [mod-key] :key :Escape
    :action awful.tag.history.restore}])

;; Focus related keybindings
(binds
  [{:description "focus next by index" :group :client
    :mods [mod-key] :key :j
    :action (fn [] (awful.client.focus.byidx  1))}
   {:description "focus preview by index" :group :client
    :mods [mod-key] :key :k
    :action (fn [] (awful.client.focus.byidx -1))}
   {:description "go back" :group :client
    :mods [mod-key] :key :Tab
    :action (fn []
              (awful.client.focus.history.previous)
              (if client.focus
                (client.focus:raise)))}
   {:description "focus the next screen" :group :client
    :mods [mod-key :Control] :key :j
    :action (fn [] (awful.screen.focus_relative  1))}
   {:description "focus the previous screen" :group :client
    :mods [mod-key :Control] :key :k
    :action (fn [] (awful.screen.focus_relative -1))}
   {:description "restore minimized" :group :client
    :mods [mod-key] :key :n
    :action (fn []
              (local c (awful.client.restore))
              (when c (c:activate {:raise true :context :key.unminimize})))}])

;; Layout related keybindings
(binds
  [{:description "swap with next client by index" :group :client
     :mods [mod-key :Shift] :key :j
     :action (fn [] (awful.client.swap.byidx  1))}
   {:description "swap with previous client by index" :group :client
    :mods [mod-key :Shift] :key :k
    :action (fn [] (awful.client.swap.byidx -1))}
   {:description "jump to urgent client" :group :client
    :mods [mod-key] :key :u
    :action awful.client.urgent.jumpto}
   {:description "increase master width factor" :group :layout
    :mods [mod-key] :key :l
    :action (fn [] (awful.tag.incmwfact  0.05))}
   {:description "decrease master width factor" :group :layout
    :mods [mod-key] :key :h
    :action (fn [] (awful.tag.incmwfact -0.05))}
   {:description "increase the number of master clients" :group :layout
    :mods [mod-key :Shift] :key :h
    :action (fn [] (awful.tag.incnmaster  1 nil true))}
   {:description "decrease the number of master clients" :group :layout
    :mods [mod-key :Shift] :key :l
    :action (fn [] (awful.tag.incnmaster -1 nil true))}
   {:description "increase the number of columns" :group :layout
    :mods [mod-key :Control] :key :h
    :action (fn [] (awful.tag.incncol  1 nil true))}
   {:description "decrease the number of columns" :group :layout
    :mods [mod-key :Control] :key :l
    :action (fn [] (awful.tag.incncol -1 nil true))}
   {:description "select next" :group :layout
    :mods [mod-key] :key :space
    :action (fn [] (awful.layout.inc  1))}
   {:description "select previous" :group :layout
    :mods [mod-key :Shift] :key :space
    :action (fn [] (awful.layout.inc -1))}])

(binds
  [{:description "only view tag" :group :tag
    :mods [mod-key] :keygroup :numrow
    :action (fn [idx]
              (let [screen (awful.screen.focused)
                    tag (. screen.tags idx)]
                (when tag
                  (tag:view_only))))}
   {:description "toggle tag" :group :tag
    :mods [mod-key :Control] :keygroup :numrow
    :action (fn [idx]
              (let [screen (awful.screen.focused)
                    tag (. screen.tags idx)]
                (when tag
                  (awful.tag.viewtoggle tag))))}
   {:description "move focused client to tag" :group :tag
    :mods [mod-key :Shift] :keygroup :numrow
    :action (fn [idx]
              (when client.focus
                (local tag (. client.focus.screen.tags idx))
                (when tag
                     (client.focus:move_to_tag tag))))}
   {:description "toggle focus client on tag" :group :tag
    :mods [mod-key :Control :Shift] :keygroup :numrow
    :action (fn [idx]
              (when client.focus
                (local tag (. client.focus.screen.tags idx))
                (when tag
                     (client.focus:toggle_tag tag))))}
   {:description "select layout directly" :group :layout
    :mods [mod-key] :keygroup :numpad
    :action (fn [idx]
              (local tag (. (awful.screen.focused) selected_tag))
              (when tag
                (set tag.layout (or (. tag.layouts idx) tag.layout))))}])

(client.connect_signal
  "request::default_mousebindings"
  (fn []
    (awful.mouse.append_client_mousebindings 
      [(btn           1 (fn [c] (c:activate {:context :mouse_click})))
       (btn [mod-key] 1 (fn [c] (c:activate {:context :mouse_click :action :mouse_move})))
       (btn [mod-key] 3 (fn [c] (c:activate {:context :mouse_click :action :mouse_resize})))])))

(client.connect_signal
  "request::default_keybindings"
  (fn []
    (binds 
      [{:description "toggle fullscreen" :group :client
        :mods [mod-key] :key :f
        :action (fn [c]
                  (set c.fullscreen (not c.fullscreen))
                  (c:raise))}
       {:description "close" :group :client
        :mods [mod-key :Shift] :key :c
        :action (fn [c] (c:kill))}
       {:description "toggle floating" :group :client
        :mods [mod-key :Control] :key :Space
        :action awful.client.floating.toggle}
       {:description "move to master" :group :client
        :mods [mod-key :Control] :key :Return
        :action (fn [c] (c:swap (awful.client.getmaster)))}
       {:description "toggle keep on top" :group :client
        :mods [mod-key] :key :t
        :action (fn [c] (set c.ontop (not c.ontop)))}
       {:description "minimize" :group :client
        :mods [mod-key] :key :m
        :action (fn [c] 
                  ;; The client currently has the input focus, so it cannot be
                  ;;  minimized, since minimized clients can't have the focus.
                  (set c.minimized true))}
       {:description "(un)maximize" :group :client
        :mods [mod-key :Control] :key :m
        :action (fn [c]
                  (set c.maximized (not c.maximized))
                  (c:raise))}
       {:description "(un)maximize vertically" :group :client
        :mods [mod-key :Control] :key :m
        :action (fn [c]
                  (set c.maximized_vertical (not c.maximized_vertical))
                  (c:raise))}
       {:description "(un)maximize horizontally" :group :client
        :mods [mod-key :Shift] :key :m
        :action (fn [c]
                  (set c.maximized_horizontal (not c.maximized_horizontal))
                  (c:raise))}])))
;; }}}

;; {{{ Rules
;; Rules to apply to new clients.
(ruled.client.connect_signal "request::rules"
  (fn []
    ;; All clients will match this rule.
    (ruled.client.append_rule
      {:id         :global
       :rule       {}
       :properties 
       {:focus     awful.client.focus.filter
        :raise     true
        :screen    awful.screen.preferred
        :placement (+ awful.placement.no_overlap
                      awful.placement.no_offscreen)}})

    ;; Floating clients.
    (ruled.client.append_rule
      {:id         :floating
       :rule_any
       {:instance ["copyq" "pinentry"]
        :class    ["Arandr" "Blueman-manager" "Gpick" "Kruler" "Sxiv"
                   "Tor Browser" "Wpa_gui" "veromix" "xtightvncviewer"]
        ;; Note that the name property shown in xprop might be set slightly after creation of the client
        ;; and the name shown there might not match defined rules here.
        :name ["Event Tester"] ; - xev
        
        :role ["AlarmWindow"   ; - Thunderbird's calendar.
               "ConfigWindow"  ; - Thunderbird's about:config.
               "pop-up"]}})    ; - e.g. Google Chrome's (detached) Developer Tools.

    ;; Add titlebars to normal clients and dialogs
    (ruled.client.append_rule
      {:id         :titlebars
       :rule_any   {:type [:normal :dialog]}
       :properties {:titlebars_enabled true}})
   
    ;; Set Firefox to always map on the tag named "2" on screen 1.
    (ruled.client.append_rule
      {:rule       {:class :Firefox}
       :properties {:screen 1
                    :tag    :2}})))
;; }}}

;; {{{ Titlebars
;; Add a titlebar if titlebars_enabled is set to true in the rules.
(client.connect_signal "request::titlebars"
  (fn [c]
    ;; buttons for the titlebar
    (local buttons
      [(btn 1 (fn [] (c:activate {:context :titlebar
                                  :action  :mouse_move})))
       (btn 3 (fn [] (c:activate {:context :titlebar
                                  :action  :mouse_resize})))])
    (local titlebar (awful.titlebar c))
    (set titlebar.widget
         {1 ;; Left
            {1 (awful.titlebar.widget.iconwidget c)
             :buttons buttons
             :layout wibox.layout.fixed.horizontal}
          2 ;; Middle
            {1 {:align  :center
                :widget (awful.titlebar.widget.titlewidget c)}
             :buttons buttons
             :layout wibox.layout.flex.horizontal}
          3 ;; Right
            {1 (awful.titlebar.widget.floatingbutton  c)
             2 (awful.titlebar.widget.maximizedbutton c)
             3 (awful.titlebar.widget.stickybutton    c)
             4 (awful.titlebar.widget.ontopbutton     c)
             5 (awful.titlebar.widget.closebutton     c)
             :layout wibox.layout.fixed.horizontal}
             
          :layout wibox.layout.align.horizontal})))
;; }}}

;; {{{ Notifications
(ruled.notification.connect_signal "request::rules"
  (fn []
    ;; All notifications will match this rule.
    (ruled.notification.append_rule
      {:rule {}
       :properties {:screen awful.screen.preferred
                    :implicit_timeout 5}})))

(naughty.connect_signal "request::display"
  (fn [n] (naughty.layout.box {:notification n})))
;; }}}

;; Enable sloppy focus, so that focus follows mouse.
(client.connect_signal "mouse::enter"
  (fn [c] (c:activate {:context "mouse_enter" :raise true})))

