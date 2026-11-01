'use strict';
// The Macros and Addon settings tabs: what the game saved for each character, and the helper's backups of it.
// The bridge does all the reading and writing; every change it makes keeps a copy of the file it replaced.
const GBBackups = (() => {
  // Which addon a saved variable belongs to, for the kit's own addons.
  const KIT_ADDONS = [
    [/^RWA_/, 'RoM WeakAuras'], [/^KittyCombo_/, 'KittyCombo'], [/^CherrysBar_/, 'Cherry’s Bar'], [/^CherrysChat_/, 'Cherry’s Chat'],
    [/^CherrysGrid_/, 'Cherry’s Grid'], [/^CherrysKit_/, 'Cherry’s Kit hub'], [/^(CherrysQuests_|CherrysEMI_|PortraitHP_|TooltipIds_|pbInfo)/, 'Cherry’s Info'],
    [/^zBag/, 'zBag'], [/^ZShop_/, 'ZShop'], [/^UMMConfig$/, 'Ultimate Mail Mod'], [/^AAH_/, 'Advanced AuctionHouse'],
    [/^CherrysLoginxml_/, 'Cherry’s Loginxml'], [/^LogNextChar_/, 'LogNextChar'], [/^GlobalBank_/, 'Global Bank'],
  ];
  const addonOf = variable => (KIT_ADDONS.find(([pattern]) => pattern.test(variable)) || [null, ''])[1];
  const STATES = {same: 'Same as now', changed: 'Different', absent: 'Not in this copy', none: 'No copy yet'};
  const FROM_NAMES = {newest: 'the newest backup', earlier: 'the backup from about a day ago', before: 'the copy from before your last change'};

  function el(tag, properties = {}, ...children) {
    const node = Object.assign(document.createElement(tag), properties);
    node.append(...children.filter(child => child !== null && child !== undefined));
    return node;
  }
  function when(stamp) {
    if (!stamp) return 'none yet';
    const hours = (Date.now() - new Date(stamp.time).getTime()) / 3600000;
    const age = hours < 1 ? 'under an hour ago' : hours < 48 ? `${Math.round(hours)} h ago` : `${Math.round(hours / 24)} days ago`;
    return `${new Date(stamp.time).toLocaleString()} (${age})`;
  }
  const size = bytes => bytes < 1024 ? `${bytes} B` : `${Math.round(bytes / 1024).toLocaleString('en-US')} KB`;
  // The aura names of a saved RWA_DB, which are the keys one level inside its auras table.
  function auraNames(text) {
    const start = text.search(/^\t\["auras"\] = \{/m);
    if (start < 0) return [];
    const rest = text.slice(start);
    const end = rest.search(/^\t\},?\s*$/m);
    return [...(end < 0 ? rest : rest.slice(0, end)).matchAll(/^\t\t\["([^"\r\n]*)"\] = \{/gm)].map(match => match[1]);
  }

  function create(send, options) {
    const byId = id => document.getElementById(id);
    let overview = null;
    let loading = null;

    function say(id, text) { byId(id).textContent = text; }
    function complain(id, error) { say(id, String(error.message || error)); }

    async function load() {
      let json = '';
      let total = 0;
      do {
        const part = await send({type: 'backup-overview', offset: json.length});
        json += part.json;
        total = part.total;
      } while (json.length < total);
      overview = JSON.parse(json);
    }
    function refresh() {
      if (!loading) loading = load().finally(() => { loading = null; });
      return loading;
    }
    const allNames = () => overview ? [...overview.characters.map(character => character.name), ...overview.noMacros].sort((a, b) => a.localeCompare(b)) : [];
    function gameNote() { return overview?.gameRunning ? 'The game is open. The library still works, and Import in the macro window picks up your changes, but changing a character\u2019s own macros or putting files back waits until the game is closed.' : ''; }

    // The macro library: every macro any character has, and any written here, with groups
    const MAX_NAME = 32, MAX_TEXT = 767, SLOTS = 56, MAX_ROWS = 300, FAVOURITES = 'Favourites';
    const library = () => overview?.library || {groups: [], macros: []};
    const shownFilter = {groups: new Set(), noGroup: false};
    let holders = new Map();
    let selectedId = null;
    let character = null;
    let slot = 0;
    // The backup this character's macros are compared with, and what it holds
    let compare = null;

    const entryNamed = id => library().macros.find(entry => entry.id === id) || null;
    const macroTitle = macro => macro.name || macro.text.slice(0, 48) || '(empty)';
    function afterLoad() {
      holders = new Map();
      for (const who of overview.characters) {
        for (const macro of who.macros) {
          if (!macro.library) continue;
          if (!holders.has(macro.library)) holders.set(macro.library, []);
          holders.get(macro.library).push({name: who.name, slot: macro.slot, latest: macro.latest});
        }
      }
      if (character === null || !allNames().includes(character)) character = overview.characters[0]?.name ?? allNames()[0] ?? null;
      if (overview.libraryError) say('macro-status', overview.libraryError);
    }
    function who() { return overview?.characters.find(entry => entry.name === character) || (character ? {name: character, macros: []} : null); }
    function slotMacro(index) { return who()?.macros.find(macro => macro.slot === index) || null; }

    // Icons. A macro keeps a number. The bridge works out the game's own numbers from its files, and the higher ones come from Cherry's Info's lists.
    let iconInfo = null;
    const iconLists = new Map();
    const iconUrls = new Map();
    const iconsWanted = new Set();
    let iconsLoading = false;
    function askIconInfo() {
      if (!iconInfo) iconInfo = send({type: 'macro-icons'}).then(answer => ({categories: answer.categories || [], stock: answer.stock || []})).catch(() => ({categories: [], stock: []}));
      return iconInfo;
    }
    async function askIconList(code) {
      if (!iconLists.has(code)) iconLists.set(code, send({type: 'macro-icon-list', code}).then(answer => answer.paths || []).catch(() => []));
      return iconLists.get(code);
    }
    async function iconPath(number) {
      const info = await askIconInfo();
      if (number >= 1 && number <= info.stock.length) return info.stock[number - 1] || null;
      const text = String(number);
      if (text.length < 6 || !info.categories.some(category => category.code === text.slice(0, 5)) || Number(text.slice(0, 5)) >= 90000) return null;
      const list = await askIconList(text.slice(0, 5));
      const path = list[Number(text.slice(5)) - 1];
      return path ? 'Interface/' + path : null;
    }
    const cleanPath = path => path.replace(/\\+/g, '/').replace(/\.dds$/i, '');
    function showIconPicture(path, url) {
      iconUrls.set(path.toLowerCase(), url);
      for (const image of document.querySelectorAll('img[data-icon]')) {
        if (image.dataset.icon === path.toLowerCase()) { image.src = url; image.hidden = false; image.nextElementSibling.hidden = true; }
      }
    }
    async function loadWantedIcons() {
      if (iconsLoading) return;
      iconsLoading = true;
      try {
        while (iconsWanted.size) {
          const names = [...iconsWanted];
          iconsWanted.clear();
          await GBIcons.load(names, send, showIconPicture).catch(() => {});
        }
      } finally { iconsLoading = false; }
    }
    function pictureForPath(image, label, path) {
      if (!path) return;
      const clean = cleanPath(path);
      image.dataset.icon = clean.toLowerCase();
      const known = iconUrls.get(clean.toLowerCase());
      if (known) { image.src = known; image.hidden = false; label.hidden = true; return; }
      iconsWanted.add(clean);
      loadWantedIcons();
    }
    // A square with the macro's picture, or its number until the picture is known
    function iconNode(number) {
      const image = el('img', {alt: '', hidden: true});
      const label = el('span', {textContent: number > 0 ? String(number) : ''});
      const node = el('span', {className: 'macro-icon', title: number > 0 ? `Icon ${number}` : ''}, image, label);
      if (number > 0) iconPath(number).then(path => pictureForPath(image, label, path));
      return node;
    }

    // A library row
    function entryMatches(entry, words) {
      const within = `${entry.name}\n${entry.groups.join('\n')}\n${entry.text}`.toLowerCase();
      return words.every(word => within.includes(word));
    }
    function shownEntries() {
      const words = byId('macro-search').value.trim().toLowerCase().split(/\s+/).filter(Boolean);
      const showDeleted = byId('macro-deleted').checked;
      const onlySelected = byId('macro-selected').checked ? new Set(options.selectedNames()) : null;
      const list = library().macros.filter(entry => {
        if (Boolean(entry.deleted) !== showDeleted) return false;
        if (shownFilter.noGroup && entry.groups.length) return false;
        for (const group of shownFilter.groups) if (!entry.groups.includes(group)) return false;
        if (onlySelected && !(holders.get(entry.id) || []).some(holder => onlySelected.has(holder.name))) return false;
        return entryMatches(entry, words);
      });
      const nameOf = entry => (entry.name || '￿' + entry.text).toLowerCase();
      return list.sort((a, b) => Number(b.groups.includes(FAVOURITES)) - Number(a.groups.includes(FAVOURITES)) || nameOf(a).localeCompare(nameOf(b)));
    }
    function setEntry(entry) {
      const list = library().macros;
      const at = list.findIndex(other => other.id === entry.id);
      if (at < 0) list.push(entry); else list[at] = entry;
    }
    async function setEntryGroups(entry, groups) {
      const answer = await send({type: 'macro-groups', id: entry.id, groups});
      setEntry(answer.entry);
      library().groups = answer.groups;
      drawLibrary();
    }
    function chip(text, active, onclick, title = '') {
      return el('button', {type: 'button', className: 'macro-chip' + (active ? ' active' : ''), textContent: text, onclick, title, ariaPressed: String(!!active)});
    }
    function holdersText(entry) {
      const list = holders.get(entry.id) || [];
      if (!list.length) return 'On no character';
      return `On ${list.length} ${list.length === 1 ? 'character' : 'characters'}`;
    }
    function libraryRow(entry) {
      const open = entry.id === selectedId;
      const favourite = entry.groups.includes(FAVOURITES);
      const star = el('button', {type: 'button', className: 'macro-star' + (favourite ? ' active' : ''), textContent: favourite ? '★' : '☆', title: favourite ? 'In Favourites' : 'Add to Favourites', ariaPressed: String(favourite), onclick: event => {
        event.stopPropagation();
        setEntryGroups(entry, favourite ? entry.groups.filter(group => group !== FAVOURITES) : [FAVOURITES, ...entry.groups]).catch(error => complain('macro-status', error));
      }});
      const head = el('div', {className: 'macro-row-head'}, iconNode(entry.icon),
        el('span', {className: 'macro-row-name' + (entry.name ? '' : ' unnamed'), textContent: macroTitle(entry)}),
        el('span', {className: 'macro-row-groups'}, ...entry.groups.filter(group => group !== FAVOURITES).map(group => el('span', {className: 'macro-tag', textContent: group}))),
        el('span', {className: 'hint macro-row-count', textContent: holdersText(entry)}), star);
      const row = el('div', {className: 'macro-row' + (open ? ' open' : ''), draggable: true,
        ondragstart: event => event.dataTransfer.setData('text/plain', entry.id)}, head);
      head.onclick = () => { selectedId = open ? null : entry.id; drawLibrary(); drawWindow(); };
      if (open) row.append(entryDetails(entry));
      return row;
    }
    function entryDetails(entry) {
      const list = holders.get(entry.id) || [];
      const older = list.filter(holder => !holder.latest).length;
      const box = el('div', {className: 'macro-row-details'}, el('pre', {className: 'macro-text', textContent: entry.text}));
      if (list.length) box.append(el('p', {className: 'hint', textContent: list.slice(0, 40).map(holder => `${holder.name} (${holder.slot + 1})${holder.latest ? '' : ' older copy'}`).join(', ') + (list.length > 40 ? ` and ${list.length - 40} more` : '')}));
      if (older) box.append(el('p', {className: 'hint', textContent: `${older} ${older === 1 ? 'has' : 'have'} an older copy of this macro.`}));
      const actions = el('div', {className: 'bank-menu-buttons'},
        el('button', {type: 'button', textContent: 'Edit…', onclick: () => openEditor({entry})}),
        el('button', {type: 'button', textContent: 'Copy text', onclick: () => navigator.clipboard.writeText(entry.text).then(() => say('macro-status', 'Copied.'), error => complain('macro-status', error))}),
        el('button', {type: 'button', textContent: 'Put on selected characters', onclick: () => copyEntry(entry)}));
      actions.append(entry.deleted
        ? el('button', {type: 'button', textContent: 'Bring back', onclick: () => deleteEntry(entry, false)})
        : el('button', {type: 'button', textContent: 'Delete from the library', onclick: () => {
          if (window.confirm(`Delete "${macroTitle(entry)}" from the library? Characters keep their copies, and you can bring it back with Show deleted.`)) deleteEntry(entry, true);
        }}));
      box.append(actions);
      return box;
    }
    async function deleteEntry(entry, deleted) {
      try {
        const answer = await send({type: 'macro-delete', id: entry.id, deleted});
        setEntry(answer.entry);
        selectedId = null;
        drawLibrary();
        say('macro-status', deleted ? `Deleted "${macroTitle(entry)}" from the library.` : `Brought back "${macroTitle(entry)}".`);
      } catch (error) { complain('macro-status', error); }
    }
    async function copyEntry(entry) {
      const names = options.selectedNames();
      if (!names.length) { say('macro-status', 'Select the characters first: click them on any tab.'); return; }
      if (!window.confirm(`Put "${macroTitle(entry)}" in the first empty macro slot of ${names.length} ${names.length === 1 ? 'character' : 'characters'}? A copy of each file is kept first.`)) return;
      say('macro-status', 'Copying…');
      const full = [];
      try {
        // A message to the bridge is limited in size, so a long list goes in parts.
        for (let i = 0; i < names.length; i += 100) {
          const answer = await send({type: 'backup-macro-set', characters: names.slice(i, i + 100), slot: 0, firstFree: true, icon: entry.icon, name: entry.name, text: entry.text});
          full.push(...(answer.full || []));
        }
        await afterChange();
        const done = names.length - full.length;
        say('macro-status', `Put on ${done} ${done === 1 ? 'character' : 'characters'}. Log in to see it.` + (full.length ? ` No room or no macro file: ${full.join(', ')}.` : ''));
      } catch (error) { complain('macro-status', error); }
    }
    function drawLibrary() {
      if (!overview) return;
      const counts = new Map();
      let noGroup = 0, live = 0;
      for (const entry of library().macros) {
        if (entry.deleted) continue;
        live++;
        if (!entry.groups.length) noGroup++;
        for (const group of entry.groups) counts.set(group, (counts.get(group) || 0) + 1);
      }
      const filtering = shownFilter.groups.size > 0 || shownFilter.noGroup;
      byId('macro-group-chips').replaceChildren(
        chip(`All ${live}`, !filtering, () => { shownFilter.groups.clear(); shownFilter.noGroup = false; drawLibrary(); }),
        ...library().groups.map(group => chip(`${group} ${counts.get(group) || 0}`, shownFilter.groups.has(group), () => {
          if (!shownFilter.groups.delete(group)) shownFilter.groups.add(group);
          shownFilter.noGroup = false;
          drawLibrary();
        }, 'Click several to see macros in all of them')),
        chip(`No group ${noGroup}`, shownFilter.noGroup, () => { shownFilter.noGroup = !shownFilter.noGroup; shownFilter.groups.clear(); drawLibrary(); }));
      const list = shownEntries();
      byId('macro-rows').replaceChildren(...list.slice(0, MAX_ROWS).map(libraryRow),
        ...(list.length > MAX_ROWS ? [el('p', {className: 'hint', textContent: `And ${(list.length - MAX_ROWS).toLocaleString('en-US')} more. Narrow your search to see them.`})] : []),
        ...(!list.length ? [el('p', {className: 'hint', textContent: live ? 'No macro matches.' : 'No macros yet. Write one with New macro, or log a character out once it has some.'})] : []));
      say('macro-summary', `${live.toLocaleString('en-US')} macros in the library, from ${overview.characters.length.toLocaleString('en-US')} of your ${(overview.characters.length + overview.noMacros.length).toLocaleString('en-US')} characters. In game, press Import in the macro window (/emi) to use any of them. ${gameNote()}`);
    }

    // One character's macro window, as the game draws it: seven across, eight down.
    function drawWindow() {
      if (!overview) return;
      const pick = byId('macro-character');
      if (document.activeElement !== pick) pick.value = character || '';
      const names = allNames().filter(name => options.shows(name, false));
      byId('macro-character-list').replaceChildren(...names.map(name => el('option', {value: name})));
      const different = index => {
        if (!compare) return false;
        const mine = slotMacro(index);
        const theirs = compare.macros.find(macro => macro.slot === index);
        if (!mine && !theirs) return false;
        return !mine || !theirs || mine.name !== theirs.name || mine.text !== theirs.text || mine.icon !== theirs.icon;
      };
      const buttons = [];
      for (let index = 0; index < SLOTS; index++) {
        const macro = slotMacro(index);
        buttons.push(el('button', {type: 'button', className: 'macro-slot' + (index === slot ? ' selected' : '') + (different(index) ? ' different' : ''),
          title: macro ? macroTitle(macro) : `Macro ${index + 1}: empty`,
          ariaPressed: String(index === slot),
          onclick: () => { slot = index; drawWindow(); },
          ondblclick: () => { slot = index; openEditor({slot: index}); },
          ondragover: event => event.preventDefault(),
          ondrop: event => {
            event.preventDefault();
            const entry = entryNamed(event.dataTransfer.getData('text/plain'));
            if (entry) { slot = index; putEntry(entry, index); }
          }},
        ...(macro ? [iconNode(macro.icon), el('span', {className: 'macro-slot-name', textContent: macro.name})] : [])));
      }
      byId('macro-slots').replaceChildren(...buttons);
      const macro = slotMacro(slot);
      byId('macro-slot-edit').textContent = macro ? 'Edit…' : 'Create…';
      byId('macro-slot-edit').disabled = !character;
      byId('macro-slot-clear').disabled = !macro;
      const chosen = entryNamed(selectedId);
      byId('macro-slot-put').disabled = !chosen || !character;
      byId('macro-slot-put').textContent = chosen ? `Put "${macroTitle(chosen).slice(0, 24)}" here` : 'Pick a library macro to put here';
      const detail = byId('macro-slot-detail');
      detail.replaceChildren();
      if (macro) {
        detail.append(el('p', {className: 'macro-title', textContent: `${slot + 1}. ${macro.name || '(no name)'}`}), el('pre', {className: 'macro-text', textContent: macro.text}));
        const entry = entryNamed(macro.library);
        if (entry) detail.append(el('button', {type: 'button', className: 'link-button', textContent: entry.groups.length ? `In the library: ${entry.groups.join(', ')}` : 'In the library, no group yet', onclick: () => { selectedId = entry.id; drawLibrary(); drawWindow(); }}));
      } else {
        detail.append(el('p', {className: 'hint', textContent: `Macro ${slot + 1} is empty.`}));
      }
      drawCompare();
    }
    function drawCompare() {
      const person = who();
      const pick = byId('macro-compare');
      const stamp = person?.earlier, newest = person?.newest;
      pick.replaceChildren(el('option', {value: '', textContent: 'No backup'}),
        el('option', {value: 'newest', textContent: `Newest: ${when(newest)}`, disabled: !newest}),
        el('option', {value: 'earlier', textContent: `About a day ago: ${when(stamp)}`, disabled: !stamp}),
        el('option', {value: 'before', textContent: 'Before your last change', disabled: !person?.undo}));
      pick.value = compare ? compare.from : '';
      byId('macro-restore-all').hidden = !compare;
      if (!compare) return;
      const theirs = compare.macros.find(macro => macro.slot === slot);
      const mine = slotMacro(slot);
      const detail = byId('macro-slot-detail');
      if (theirs && mine && theirs.name === mine.name && theirs.text === mine.text && theirs.icon === mine.icon) {
        detail.append(el('p', {className: 'hint', textContent: 'The same in the backup.'}));
        return;
      }
      if (!theirs && !mine) return;
      detail.append(el('p', {className: 'macro-backup-label', textContent: theirs ? `In the backup: ${theirs.name || '(no name)'}, icon ${theirs.icon}` : 'This slot is empty in the backup.'}));
      if (theirs) detail.append(el('pre', {className: 'macro-text', textContent: theirs.text}));
      detail.append(el('button', {type: 'button', textContent: 'Put this one back', onclick: () => {
        const from = compare.from, index = slot;
        change('macro-status', {type: 'backup-restore-macros', character, slot: index, from}, () => `Put macro ${index + 1} of ${character} back from ${FROM_NAMES[from]}.`);
      }}));
    }
    function putEntry(entry, index) {
      if (slotMacro(index) && !window.confirm(`Replace macro ${index + 1} of ${character} with "${macroTitle(entry)}"? A copy of the file is kept first.`)) return;
      change('macro-status', {type: 'backup-macro-set', characters: [character], slot: index, icon: entry.icon, name: entry.name, text: entry.text}, () => `Put "${macroTitle(entry)}" in macro ${index + 1} of ${character}. Log in to see it.`);
    }

    // The edit window: an icon, a name, the text with its count, and the groups
    let editing = null;
    let editIcon = 1;
    let editGroups = [];
    function drawEditIcon() { byId('macro-edit-icon').replaceChildren(iconNode(editIcon)); }
    function drawEditCount() {
      const length = byId('macro-edit-text').value.length;
      say('macro-edit-count', `${length} of ${byId('macro-edit-text').maxLength} letters`);
    }
    function drawEditGroups() {
      const all = [...new Set([...library().groups, ...editGroups])];
      byId('macro-edit-groups').replaceChildren(...all.map(group => chip(group, editGroups.includes(group), () => {
        editGroups = editGroups.includes(group) ? editGroups.filter(other => other !== group) : [...editGroups, group];
        drawEditGroups();
      })));
    }
    function openEditor(what) {
      const macro = what.slot !== undefined ? slotMacro(what.slot) : what.entry || null;
      const entry = what.entry || (macro?.library ? entryNamed(macro.library) : null);
      editing = what;
      if (what.slot !== undefined) say('macro-edit-title', `Macro ${what.slot + 1} of ${character}`);
      else say('macro-edit-title', what.entry ? 'Macro in the library' : 'New macro in the library');
      byId('macro-edit-name').maxLength = Math.max(MAX_NAME, macro?.name.length || 0);
      byId('macro-edit-name').value = macro?.name || '';
      byId('macro-edit-text').maxLength = Math.max(MAX_TEXT, macro?.text.length || 0);
      byId('macro-edit-text').value = macro?.text || '';
      editIcon = macro && macro.icon > 0 ? macro.icon : 1;
      editGroups = [...(entry?.groups || [])];
      byId('macro-edit-new-group').value = '';
      const others = what.entry ? (holders.get(what.entry.id) || []) : [];
      byId('macro-edit-apply-row').hidden = !others.length;
      byId('macro-edit-apply').checked = false;
      say('macro-edit-apply-text', `Also change it on the ${others.length} ${others.length === 1 ? 'character that has' : 'characters that have'} it (close the game first)`);
      byId('macro-icon-picker').hidden = true;
      say('macro-edit-error', '');
      drawEditIcon();
      drawEditCount();
      drawEditGroups();
      byId('macro-dialog').showModal();
    }
    async function saveEditor() {
      const name = byId('macro-edit-name').value;
      const text = byId('macro-edit-text').value;
      if (new TextEncoder().encode(text).length > 1023) { say('macro-edit-error', 'That text is too long for the macro file.'); return; }
      if (new TextEncoder().encode(name).length > 255) { say('macro-edit-error', 'That name is too long for the macro file.'); return; }
      if (!name.trim() && !text.trim()) { say('macro-edit-error', 'Give the macro a name or some text.'); return; }
      const what = editing;
      say('macro-edit-error', 'Saving…');
      try {
        let done;
        if (what.slot !== undefined) {
          const old = slotMacro(what.slot);
          await send({type: 'backup-macro-set', characters: [character], slot: what.slot, icon: editIcon, name, text, follow: !!old});
          // The groups go with the library's copy of it, whichever way it got there
          await send({type: 'macro-save', id: old?.library || undefined, name, icon: editIcon, text, groups: editGroups});
          done = `Saved macro ${what.slot + 1} of ${character}. Log in to see it.`;
        } else {
          const answer = await send({type: 'macro-save', id: what.entry?.id, name, icon: editIcon, text, groups: editGroups, apply: byId('macro-edit-apply').checked});
          selectedId = answer.entry.id;
          done = `Saved "${macroTitle(answer.entry)}" in the library.` + (answer.changedCharacters ? ` Changed on ${answer.changedCharacters} ${answer.changedCharacters === 1 ? 'character' : 'characters'}.` : ' In game, press Import in the macro window to use it.');
        }
        byId('macro-dialog').close();
        await afterChange();
        say('macro-status', done);
      } catch (error) { complain('macro-edit-error', error); }
    }

    // The icon picker: one category at a time, like the game's
    const ICONS_PER_PAGE = 45;
    let pickerCategory = '', pickerPage = 0, pickerIcon = 1;
    async function pickerList() {
      if (!pickerCategory) {
        const info = await askIconInfo();
        return info.stock.map((path, i) => ({number: i + 1, path}));
      }
      const paths = await askIconList(pickerCategory);
      return paths.map((path, i) => ({number: Number(pickerCategory + (i + 1)), path: 'Interface/' + path}));
    }
    async function drawPicker() {
      const list = await pickerList();
      const pages = Math.max(1, Math.ceil(list.length / ICONS_PER_PAGE));
      pickerPage = Math.min(Math.max(0, pickerPage), pages - 1);
      say('macro-icon-page', `Page ${pickerPage + 1} of ${pages}`);
      byId('macro-icon-prev').disabled = pickerPage <= 0;
      byId('macro-icon-next').disabled = pickerPage >= pages - 1;
      byId('macro-icon-number').value = pickerIcon;
      const custom = Number(pickerCategory) >= 90000;
      say('macro-icon-note', !pickerCategory && !list.length ? 'The game’s icons couldn’t be read. Type the icon’s number below.' : '');
      byId('macro-icon-grid').replaceChildren(...list.slice(pickerPage * ICONS_PER_PAGE, (pickerPage + 1) * ICONS_PER_PAGE).map(({number, path}) => {
        const image = el('img', {alt: '', hidden: true});
        const label = el('span', {textContent: String(number)});
        if (!custom) pictureForPath(image, label, path);
        return el('button', {type: 'button', className: 'macro-icon-choice' + (number === pickerIcon ? ' selected' : ''), title: `${path} (icon ${number})`, onclick: () => { pickerIcon = number; drawPicker(); }},
          el('span', {className: 'macro-icon'}, image, label));
      }));
    }
    async function openPicker() {
      pickerIcon = editIcon;
      const info = await askIconInfo();
      const pick = byId('macro-icon-category');
      pick.replaceChildren(el('option', {value: '', textContent: 'Default Icons'}), ...info.categories.map(category => el('option', {value: category.code, textContent: category.name})));
      const text = String(editIcon);
      const code = text.length >= 6 && info.categories.some(category => category.code === text.slice(0, 5)) ? text.slice(0, 5) : '';
      pick.value = pickerCategory = code;
      pickerPage = Math.floor(((code ? Number(text.slice(5)) : editIcon) - 1) / ICONS_PER_PAGE);
      byId('macro-icon-picker').hidden = false;
      await drawPicker();
    }
    function stepCategory(step) {
      const pick = byId('macro-icon-category');
      pick.selectedIndex = (pick.selectedIndex + step + pick.options.length) % pick.options.length;
      pickerCategory = pick.value;
      pickerPage = 0;
      drawPicker();
    }

    // The group list
    function drawGroupEditor() {
      byId('macro-groups-list').replaceChildren(...library().groups.map((group, index) => el('li', {},
        el('span', {className: 'macro-group-name', textContent: group}),
        el('button', {type: 'button', textContent: '↑', title: 'Earlier', disabled: index === 0, onclick: () => editGroupList('earlier', group)}),
        el('button', {type: 'button', textContent: '↓', title: 'Later', disabled: index === library().groups.length - 1, onclick: () => editGroupList('later', group)}),
        el('button', {type: 'button', textContent: 'Rename…', onclick: () => {
          const to = window.prompt(`New name for ${group}`, group);
          if (to && to.trim() && to.trim() !== group) editGroupList('rename', group, to.trim());
        }}),
        el('button', {type: 'button', textContent: 'Remove', onclick: () => {
          if (window.confirm(`Remove the group ${group}? The macros in it stay in the library.`)) editGroupList('remove', group);
        }}))));
    }
    async function editGroupList(action, group, to) {
      try {
        const answer = await send({type: 'macro-group-list', action, group, to});
        library().groups = answer.groups;
        for (const {id, groups} of answer.macros || []) {
          const entry = entryNamed(id);
          if (entry) entry.groups = groups || [];
        }
        shownFilter.groups.clear();
        say('macro-groups-error', '');
        drawGroupEditor();
        drawLibrary();
      } catch (error) { complain('macro-groups-error', error); }
    }

    async function afterChange() {
      compare = null;
      await refresh();
      afterLoad();
      drawMacros();
      if (byId('settings-rows').childElementCount) await drawSettingsRows();
    }
    // A change, then a fresh read of what the files hold now.
    async function change(statusId, message, done) {
      say(statusId, 'Working…');
      try {
        const answer = await send(message);
        await afterChange();
        say(statusId, done(answer));
      } catch (error) { complain(statusId, error); }
    }
    function drawMacros() {
      drawLibrary();
      drawWindow();
    }
    function setCharacter(name) {
      if (!allNames().includes(name) || name === character) return;
      character = name;
      compare = null;
      slot = 0;
      drawWindow();
    }

    // Addon settings
    let settingsCharacter = '';
    function fillCharacterPick() {
      const pick = byId('settings-who');
      const chosen = pick.value;
      pick.replaceChildren(el('option', {value: '', textContent: 'Shared by all characters'}), ...allNames().map(name => el('option', {value: name, textContent: name})));
      pick.value = allNames().includes(chosen) ? chosen : '';
      settingsCharacter = pick.value;
    }
    const whoName = () => settingsCharacter || 'the shared file';
    async function drawSettingsRows() {
      const answer = await send(settingsCharacter ? {type: 'backup-settings', character: settingsCharacter} : {type: 'backup-settings'});
      const kitOnly = byId('settings-kit').checked;
      const rows = (answer.rows || []).filter(row => !kitOnly || addonOf(row.name));
      rows.sort((a, b) => addonOf(a.name).localeCompare(addonOf(b.name)) || a.name.localeCompare(b.name));
      const restoreButton = (row, from) => row[from] === 'changed' || row[from] === 'absent'
        ? el('button', {type: 'button', textContent: 'Put back', onclick: () => {
          if (window.confirm(`Replace ${row.name} in ${whoName()} with ${FROM_NAMES[from]}? A copy of the file is kept first.`)) {
            change('settings-status', {type: 'backup-restore-settings', character: settingsCharacter || undefined, variable: row.name, from}, () => `Put ${row.name} back from ${FROM_NAMES[from]}. Log in to see it.`);
          }
        }}) : null;
      byId('settings-rows').replaceChildren(...rows.map(row => el('tr', {},
        el('td', {textContent: addonOf(row.name) || 'Other addon'}),
        el('td', {}, el('button', {type: 'button', className: 'link-button', textContent: row.name, onclick: () => showValue(row.name, 'now')})),
        el('td', {textContent: size(row.size)}),
        ...['newest', 'earlier'].map(from => el('td', {className: 'settings-' + row[from]}, STATES[row[from]], ' ', restoreButton(row, from))))));
      say('settings-times', `Now: ${when(answer.now)}. Newest backup: ${when(answer.newest)}. About a day ago: ${when(answer.earlier)}.`);
      const small = answer.now && answer.earlier && answer.now.size * 2 < answer.earlier.size;
      say('settings-warning', small ? 'This file is less than half the size of the copy from about a day ago, so it may have been damaged. Look before the next log out.' : gameNote());
      for (const from of ['newest', 'earlier']) byId('settings-whole-' + from).disabled = !answer[from];
      byId('settings-whole-before').disabled = !answer.before;
    }
    async function showValue(variable, from) {
      say('settings-value-title', variable);
      byId('settings-value-box').hidden = false;
      byId('settings-value-box').dataset.variable = variable;
      byId('settings-value-from').value = from;
      say('settings-value', 'Reading…');
      say('settings-auras', '');
      try {
        const answer = await send({type: 'backup-value', character: settingsCharacter || undefined, variable, from});
        const text = answer.text ?? 'This copy doesn’t have it.';
        say('settings-value', text + (answer.more ? '\n… The rest is too long to show here.' : ''));
        const auras = variable === 'RWA_DB' ? auraNames(text) : [];
        if (auras.length) say('settings-auras', `${auras.length} auras: ${auras.join(', ')}`);
      } catch (error) { say('settings-value', String(error.message || error)); }
    }
    async function drawSettings() {
      say('settings-status', 'Reading…');
      try {
        if (!overview) await refresh();
        fillCharacterPick();
        await drawSettingsRows();
        say('settings-status', `Backups are in ${overview.folder}`);
      } catch (error) { complain('settings-status', error); }
    }
    function restoreWhole(from) {
      if (window.confirm(`Replace all of ${whoName()} with ${FROM_NAMES[from]}? A copy of the file is kept first.`)) {
        change('settings-status', {type: 'backup-restore-settings', character: settingsCharacter || undefined, from}, () => `Put ${whoName()} back from ${FROM_NAMES[from]}. Log in to see it.`);
      }
    }

    byId('macro-search').addEventListener('input', drawLibrary);
    byId('macro-selected').addEventListener('change', drawLibrary);
    byId('macro-deleted').addEventListener('change', drawLibrary);
    byId('macro-refresh').addEventListener('click', async () => {
      say('macro-status', 'Reading the save files\u2026');
      try { await afterChange(); say('macro-status', ''); } catch (error) { complain('macro-status', error); }
    });
    byId('macro-new').addEventListener('click', () => openEditor({}));
    byId('macro-character').addEventListener('change', () => setCharacter(byId('macro-character').value));
    byId('macro-compare').addEventListener('change', async () => {
      const from = byId('macro-compare').value;
      if (!from) { compare = null; drawWindow(); return; }
      try {
        const answer = await send({type: 'backup-macros', character, from});
        compare = {from, macros: answer.macros || [], time: answer.time};
        drawWindow();
      } catch (error) { complain('macro-status', error); }
    });
    byId('macro-restore-all').addEventListener('click', () => {
      if (!compare) return;
      const from = compare.from;
      if (window.confirm(`Replace all the macros of ${character} with ${FROM_NAMES[from]}? A copy of the file is kept first.`)) {
        change('macro-status', {type: 'backup-restore-macros', character, slot: -1, from}, () => `Put the macros of ${character} back from ${FROM_NAMES[from]}.`);
      }
    });
    byId('macro-slot-edit').addEventListener('click', () => openEditor({slot}));
    byId('macro-slot-clear').addEventListener('click', () => {
      const macro = slotMacro(slot);
      if (macro && window.confirm(`Delete macro ${slot + 1} (${macroTitle(macro)}) of ${character}? The library keeps its copy, and a copy of the file is kept first.`)) {
        change('macro-status', {type: 'backup-macro-set', characters: [character], slot, icon: -1, name: '', text: ''}, () => `Deleted macro ${slot + 1} of ${character}.`);
      }
    });
    byId('macro-slot-put').addEventListener('click', () => {
      const entry = entryNamed(selectedId);
      if (entry) putEntry(entry, slot);
    });
    byId('macro-edit-form').addEventListener('submit', event => {
      event.preventDefault();
      saveEditor();
    });
    byId('macro-edit-cancel').addEventListener('click', () => byId('macro-dialog').close());
    byId('macro-edit-text').addEventListener('input', drawEditCount);
    byId('macro-edit-icon').addEventListener('click', () => { openPicker().catch(error => complain('macro-edit-error', error)); });
    const addEditGroup = () => {
      const group = byId('macro-edit-new-group').value.trim();
      if (!group) return;
      if (!editGroups.includes(group)) editGroups = [...editGroups, group];
      byId('macro-edit-new-group').value = '';
      drawEditGroups();
    };
    byId('macro-edit-add-group').addEventListener('click', addEditGroup);
    byId('macro-edit-new-group').addEventListener('keydown', event => { if (event.key === 'Enter') { event.preventDefault(); addEditGroup(); } });
    byId('macro-icon-category').addEventListener('change', () => { pickerCategory = byId('macro-icon-category').value; pickerPage = 0; drawPicker(); });
    byId('macro-icon-left').addEventListener('click', () => stepCategory(-1));
    byId('macro-icon-right').addEventListener('click', () => stepCategory(1));
    byId('macro-icon-prev').addEventListener('click', () => { pickerPage--; drawPicker(); });
    byId('macro-icon-next').addEventListener('click', () => { pickerPage++; drawPicker(); });
    byId('macro-icon-grid').addEventListener('wheel', event => {
      event.preventDefault();
      pickerPage += event.deltaY > 0 ? 1 : -1;
      drawPicker();
    }, {passive: false});
    byId('macro-icon-number').addEventListener('change', () => {
      const number = Number(byId('macro-icon-number').value);
      if (Number.isInteger(number) && number > 0) { pickerIcon = number; drawPicker(); }
    });
    byId('macro-icon-ok').addEventListener('click', () => {
      editIcon = pickerIcon;
      byId('macro-icon-picker').hidden = true;
      drawEditIcon();
    });
    byId('macro-icon-cancel').addEventListener('click', () => { byId('macro-icon-picker').hidden = true; });
    byId('macro-groups-edit').addEventListener('click', () => {
      say('macro-groups-error', '');
      byId('macro-groups-new').value = '';
      drawGroupEditor();
      byId('macro-groups-dialog').showModal();
    });
    byId('macro-groups-close').addEventListener('click', () => byId('macro-groups-dialog').close());
    byId('macro-groups-form').addEventListener('submit', event => {
      event.preventDefault();
      const group = byId('macro-groups-new').value.trim();
      if (group) { byId('macro-groups-new').value = ''; editGroupList('add', group); }
    });
    byId('settings-who').addEventListener('change', () => {
      settingsCharacter = byId('settings-who').value;
      byId('settings-value-box').hidden = true;
      drawSettingsRows().catch(error => complain('settings-status', error));
    });
    byId('settings-kit').addEventListener('change', () => drawSettingsRows().catch(error => complain('settings-status', error)));
    byId('settings-value-from').addEventListener('change', () => showValue(byId('settings-value-box').dataset.variable, byId('settings-value-from').value));
    for (const from of ['newest', 'earlier', 'before']) byId('settings-whole-' + from).addEventListener('click', () => restoreWhole(from));

    let drawnMacros = false;
    return {
      auraNames,
      async showMacros() {
        if (drawnMacros) return;
        drawnMacros = true;
        say('macro-status', 'Reading the save files\u2026');
        try { await refresh(); afterLoad(); drawMacros(); say('macro-status', overview.libraryError || ''); } catch (error) { drawnMacros = false; complain('macro-status', error); }
      },
      redrawMacros: drawMacros,
      showSettings() { if (!byId('settings-rows').childElementCount) drawSettings(); },
    };
  }
  return {create, auraNames, addonOf};
})();
