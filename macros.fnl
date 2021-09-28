(fn map [func col]
  (let [out {}]
    (each [idx value (ipairs col)]
      (tset out idx (func value)))
    out))

{
 :btn (fn [arg1 arg2 arg3]
        (if (= arg3 nil)
          `(awful.button {} ,arg1 ,arg2)
          `(awful.button ,arg1 ,arg2 ,arg3)))

 :binds (fn [...]
          (let [binds ...]
            `(awful.keyboard.append_global_keybindings
               ,(map (fn
                      [bind]
                      `(awful.key
                         {:modifiers   ,bind.mods
                          :keygroup    ,bind.keygroup
                          :key         ,bind.key
                          :description ,bind.description
                          :group       ,bind.group
                          :on_press    ,bind.action}))
                  binds))))}
 
