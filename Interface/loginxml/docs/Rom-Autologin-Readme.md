# Rom Autologin
[English version below](#english-version)

## Features
- Fix für "Lade Serverliste", auch ohne das Hinterlegen von Accountdaten
- Speicherung des primären und des sekundären Passwortes und Login über "NoCheckVersion"
- Eingabe des sekundären Passwortes bei Login über Steam oder Gameforge Client
- Überarbeitete Serverauswahl
- Überarbeitete Charaktererstellung mit optionalem Namensgenerator
- Auswahl von "NoCheckVersion" Charakteren und Accounts, die eingeloggt werden sollen, über beschriftbare Listen
- Hinterlegen von Notizen zu Accounts
- Einloggen auf einen default Channel

## Installation
Dieses Addon kann nicht gleichzeitig mit anderen Autologin-Addons verwendet werden. Diese müssen daher entfernt werden.
Zum Installieren das .zip Archiv entpacken, und den Ordner "loginxml" in den Ordner (Installationsordner von Rom)/interface kopieren

## Einrichten für NoCheckVersion Accounts

### Eintragen der Login Daten
In der Datei *data/accounts.lua*
```
_defaultPassword = 'PASSWORD',
```
Angabe eines default primären Passwortes, das verwendet wird, sofern der Account nicht in der unten aufgeführten Accountliste vorkommt

```
['ACCOUNT'] = {'PASSWORD', 'SEKPASSWORD'}, 
```
Angabe eines Accountnamen mit primärem und sekundärem Passwort
```
['ACCOUNT'] = 'PASSWORD',
```
Nur das primäre Passwort, das sekundäre Passwort befindet sich in der password.lua oder wird von Hand eingegeben
 
### Einrichten der Account- oder Charakterauswahl
Folgende Optionen sind vorhanden:  
  ```
  [1] = { -- Liste 1
    _title = "test", -- Title der Liste, zum Beispiel "Lagerchars"
    {
      acc = 'ACCOUNT', -- Accountname
      srv_sel = 'SERVER', -- Vorausgewählter Server
      chars = {
        SERVER = {
          'CHARACTER/NOTE', -- preselect
          'CHARACTER/NOTE',
        }, --
      }, --
      note = 'NOTE',
    }, -- login account
    {acc = 'ACCOUNT', srv_sel = 'SERVER'}, -- Login bis zur Serverauswahl, Server wird ausgewählt aber muss noch bestätigt werden
    {acc = 'ACCOUNT', srv = 'SERVER', char = 'CHARACTER', note = 'NOTE'}, -- Login direkt ins Spiel
    {acc = 'ACCOUNT', srv = 'SERVER', note = 'NOTE'}, -- Login zur Charakterauswahl
  },
  [2] = nil, -- diese Liste wird nicht angezeigt
  ```
### Einrichten von Seiten
Auf jeder Seite befinden sich Anzahl 2 * **account_columns** Listen, die mit Accounts oder Charakteren gefüllt werden können. 

## Eintragen vom sekundären Passwort
In der Datei *data/password.lua*:  
Alle Einträge in Grossschrift ersetzen durch die richtigen Daten oder herauslöschen bzw. mit `--` Zeilenweise auskommentieren.

Wird für Gameforge Launcher Account und Steamaccounts benutzt. Für NoCheckVersion kann hier das sekundäre Passwort auch angegeben werden, allerdings wird das sekundäre Passwort in *data/accounts.lua* priorisiert.
```
return {
  _default = "DEFAULTSEKPASSWORD",
  SERVERNAME = {
    CHARNAME = 'SEKPASSWORD',
  },
  SERVERNAME = {
    CHARNAME = 'PRIMPASSWORD',
    ['CHARNAME'] = 'PRIMPASSWORD',
  },
}
```

## Einstellungen

Einstellung | Default | Beschreibung
------------ | ----- | -------------
**channel** | 1 | Channel, der in der Auswahl automatisch selektiert werden soll  
**show_account_info** | true | Blendet den Accountnamen oben rechts ein  
**account_single_click** | false | Mit einem Klick wird der Account eingeloggt, default ist Doppelklick  
**account_force_show** | false | Leere Accountlisten werden nicht angezeigt
**account_use_slider** | true | Man kann mehrere Seiten mit Accounts/Charakteren erstellen. Man kann zwischen diesen mit dem Slider wechseln  
**account_use_list** | true | Die Auswahl der Seiten soll über eine Liste stattfinden  
**account_columns** | 5 | Gibt an, wieviele Spalten an Accountlisten angezeigt werden soll  
**account_page** | 1 | Welcher Seite mit Accounts/Charakteren beim Starten zuerst angezeigt werden soll  
**server_single_click** | false | Mit einem Klick wird der Server ausgewählt, default ist Doppelklick  
**character_single_click** | false | Mit einem Klick wird der Charakter eingeloggt, default ist Doppelklick  
**character_login_single** | true | Wenn sich nur ein Charakter auf einem Account befindet, so soll dieser direkt eingeloggt werden  
**character_nologin_ctrl** | true | Wenn man einen Account einloggt, und man die Taste "Strg" beim Einloggen gedrückt halt, so stoppt der Loginvorgang in der Charakterauswahl, wenn **character_login_single** aktiv ist
**character_sort** | true | Die Charaktere werden nach Level sortiert. Wenn der Wert false ist, dann wird oben der älteste Charakter angezeigt

## English version

## Features
- Fixes the "Loading server list" without the need to add account data  
- Saves log in data for old Rom accounts that log in via "NoCheckVersion"  
- Enters the secondary password when using Steam or the Gameforge client to log in  
- Improved server selection  
- Improved character creation with optional name generator  
- Lists of "NoCheckVersion" accounts and characters to log in with optional notes  
- Log in onto a predefined channel  

## Installation guide
This addon cannot be used simultaneously with other log in addons. You have to remove them first.  
To install this addon you have to extract the .zip archive, and move the directory "loginxml" into (Path to Runes of Magic)/interface

## Set up NoCheckVersion accounts

### Add account data
Open file *data/accounts.lua*
```
_defaultPassword = 'PASSWORD',
```
Definition of a default primary password that is used if an account or character is defined in a list, but no primary password has been found in the `account {` section.

```
['ACCOUNT'] = {'PASSWORD', 'SEKPASSWORD'}, 
```
An account with primary and secondary password
```
['ACCOUNT'] = 'PASSWORD',
```
An account with primary password defined here, the secondary password is either definied in the *password.lua* or entered manually
 
### Set up of account and character lists
Options available are:  
  ```
  [1] = { -- List 1
    _title = "test", -- Title of the list
    {
      acc = 'ACCOUNT', -- account name
      srv_sel = 'SERVER', -- preselected server
      chars = {
        SERVER = {
          'CHARACTER/NOTE', -- preselected character
          'CHARACTER/NOTE',
        }, --
      }, --
      note = 'NOTE',
    }, -- login account
    {acc = 'ACCOUNT', srv_sel = 'SERVER'}, -- Log in to the server selection, server has to be confirmed to log in
    {acc = 'ACCOUNT', srv = 'SERVER', char = 'CHARACTER', note = 'NOTE'}, -- Log in of a character 
    {acc = 'ACCOUNT', srv = 'SERVER', note = 'NOTE'}, -- Log into the character selection
  },
  [2] = nil, -- this list will be invisible
  ```
### Set up of pages
2 times **account_columns** of lists can be added to each page.

## Setting of the secondary password
Open file *data/password.lua*:  
Replace all words written in capital letters with you data, delete unused entries or disable them line by line via `--`.

The secondary passwords defined here are used for Gameforge Client and Steam log ins. If you log in via NoCheckVersion you can also define your secondary password here, but the one defined in *data/accounts.lua* is priorised.

```
return {
  _default = "DEFAULTSEKPASSWORD",
  SERVERNAME = {
    CHARNAME = 'SEKPASSWORD',
  },
  SERVERNAME = {
    CHARNAME = 'PRIMPASSWORD',
    ['CHARNAME'] = 'PRIMPASSWORD',
  },
}
```

## Settings

Setting | Default | Description
------------ | ----- | -------------
**channel** | 1 | Channel that is preselected on log in  
**show_account_info** | true | Hides account name in the top right corner  
**account_single_click** | false | Logs in account with a single click, default is double click  
**account_force_show** | false | Empty list are hidden  
**account_use_slider** | true | Enables a slider to switch between pages  
**account_use_list** | true | Enables a list to switch between pages  
**account_columns** | 5 | Numbers of columns of lists  
**account_page** | 1 | Number of page to be displayed first  
**server_single_click** | false | Logs into the server selection with a single click, default is double click  
**character_single_click** | false | Logs into the character selection with a single click, default is double click  
**character_login_single** | true | Skips character selection if there is only one character on the server to select from  
**character_nologin_ctrl** | true | If an account is selected, and there is only one character to choose from, the log in stops in the character selection if "Ctrl" is pressed and **character_login_single** is active  
**character_sort** | true | Enables sorting of characters in the character selection by level. If disabled the characters aren't sorted, the oldest character is displayed at the top  
