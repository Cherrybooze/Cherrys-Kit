-- Account lists for the login screen.
-- Copy this file to Interface\loginxml\accounts.lua and edit the copy: loginxml reads
-- that one first, and installing an update never overwrites it.
-- It holds passwords, so never share it.
return {
  -- _defaultPassword = 'PASSWORD', -- for listed accounts that have no password below
  accounts = {
    -- ['ACCOUNT'] = {'PASSWORD', 'SECPASSWORD'}, -- password and secondary password
    -- ['ACCOUNT'] = 'PASSWORD', -- password only; secondary password from password.lua or typed in
  },
  [1] = {
    _title = 'List 1',
    -- {acc = 'ACCOUNT', srv_sel = 'SERVER'}, -- log in, server picked but not joined
    -- {acc = 'ACCOUNT', srv = 'SERVER', note = 'NOTE'}, -- log in to character select
    -- {acc = 'ACCOUNT', srv = 'SERVER', char = 'CHARACTER', note = 'NOTE'}, -- log in to the game
    -- {
    --   acc = 'ACCOUNT',
    --   srv_sel = 'SERVER',
    --   chars = {
    --     SERVER = {'CHARACTER/NOTE', 'CHARACTER/NOTE'}, -- the first one is preselected
    --   },
    --   note = 'NOTE',
    -- },
  },
  -- [2] = {_title = 'List 2'}, -- each page has 2 x account_columns lists
}
