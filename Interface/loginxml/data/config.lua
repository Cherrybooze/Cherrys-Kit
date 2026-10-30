-- Settings for Cherry's Loginxml. To change them, copy this file to
-- Interface\loginxml\config.lua and edit the copy: loginxml reads that one
-- first, and installing an update never overwrites it. Keep every line: an
-- on/off setting missing from the file you use counts as off.
return { --
  debug = false, -- true shows the DEBUG button and log
  channel = 1, --
  server_list_retry = 10, -- launcher logins: seconds before asking for the server list again, 0 = only by hand
  server_list_retry_max = 3, -- automatic retries before leaving it to the Retry button
  show_account_info = true, --

  account_single_click = false,--
  account_force_show = false,--
  account_use_slider = true, --
  account_use_list = true, --
  account_columns = 5,--
  account_page = 1,--

  server_single_click = false,--

  character_single_click = false,--
  character_login_single = true, --
  character_login_first = false, -- log in the first character in the list once after each account login
  character_nologin_ctrl = true, --
  character_sort = false, --
}
