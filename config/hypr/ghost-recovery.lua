-- A new lock client may take over after the previous one dies; `ghost lock` starts it.
hl.config({ misc = { allow_session_lock_restore = true } })
