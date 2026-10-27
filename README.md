# Redmine Easy Notes

Adds a one-line "Add note" box under the issue history, so leaving a comment does
not mean opening the whole issue edit form.

![The one-line note bar under the issue history: an "Add your note" field, an icon to open the full editor, a public/private toggle, and an "Add Note" button](doc/mini-editor.png)

Redmine has no way to add a note without revealing the full editor, which also
exposes the subject, description and every other attribute. That makes it easy to
change the issue by accident on the way to commenting. See
[feature #3143](https://www.redmine.org/issues/3143), open since 2009 and still
not in core.

## What you get

A bar styled like a journal entry appears below the notes. It contains:

* a one-line text field, placeholder "Add your note"
* an "Open Full Editor" icon that swaps the bar for the full editor (jstoolbar,
  preview, `@`-mention autocomplete, private notes, attachments), keeping
  whatever was typed
* a public/private toggle: a `users-group` icon labelled "Public Note" that
  flips to `spy` labelled "Private Note", coloured like a checked checkbox
* a notify/suppress toggle: a `mailbox` icon labelled "Watchers will be
  Notified" that flips to `mailbox-off` labelled "Notifications are
  Suppressed", coloured the same way (see [Suppressing notifications](#suppressing-notifications))
* an "Add Note" button, disabled until the field has something in it

One click on the icon, or Shift+Enter, swaps the bar for the full editor:

![The full editor in place of the bar: jstoolbar with Edit and Preview tabs, a large text area, a "Private notes" checkbox, a file picker, and "Add Note" and "Cancel" underneath](doc/full-editor.png)

## Keys and behaviour

| Action | Result |
|---|---|
| Enter | Submits the note |
| Shift+Enter | Opens the full editor, keeping the text and adding the line break |
| Cancel in the full editor | Discards the note and returns to the one-liner, both boxes empty |
| Drop a file on the one-liner | Opens the full editor, attaches the file and inserts the inline image markup, exactly as core does |
| Paste an image (Ctrl+V) into the one-liner | The same as dropping it. Clipboard text wins, as in core, so pasted text stays in the one-liner |
| Quote on an existing note | Lands in this editor instead of reopening the issue edit form |
| Edit on the issue | The bar disappears and its text moves into the edit form's own note box |

Quoting keeps whatever was already being written and appends the quote after it.
Quoting a private note keeps the reply private. If the issue edit form is already
open when you click Quote, quoting is left alone: you are editing the issue, so
the quote stays where you are looking.

There is never a second note box on the page. Core's issue edit form has one of
its own, so while that form is open the bar stands aside: it disappears, and
anything being written in it is appended to the edit form's note box, private
flag included. Cancel brings the bar back empty, because the note went to the
edit form. Save reloads the page, so it comes back empty either way.

The toggle and the full editor's "Private notes" checkbox are two views of one
value and stay in sync both ways, so the bar cannot claim a note is public while
the checkbox disagrees. Cancel does not reset it: the toggle is visible on the
bar, and quietly flipping a note back to public is the one mistake here with a
real consequence.

There is one note being composed at a time, and one of the two editors is
showing it. Switching hands the text over instead of leaving a copy behind, so
the two boxes cannot drift apart and show different things.

Suppressing notifications behaves the same way: the toggle and the full
editor's "Suppress Notifications" checkbox stay in sync, Cancel does not reset
it, and handing a note to the edit form carries it across.

## Suppressing notifications

A note can be added without anyone being emailed. The journal is saved as
usual; only the notification mail is skipped, via core's `Journal#notify`. It
is off by default and has to be chosen for each note:

* on the bar, the `mailbox` toggle
* in the full editor, and under the notes of core's issue edit form, a
  "Suppress Notifications" checkbox

This replaces [redmine_silencer](https://github.com/paginagmbh/redmine_silencer)
and uses the same permission name, `suppress_mail_notifications`, so roles that
granted it there grant it here with nothing to re-tick. **Do not install both**:
the role form would list the permission twice and the edit form would show two
checkboxes. The silencer's bulk-edit checkbox and its "ticked by default"
setting are not carried over.

The permission sits outside the module, as it did under the silencer, so the
edit form's checkbox works in every project. The bar's toggle needs the module,
like the rest of the bar.

## Plugin settings

**Administration, Plugins, Redmine Easy Notes, Configure** has four switches,
all on by default:

| Setting | Off means |
|---|---|
| Private notes toggleable icon in quick notes mini form | No public/private icon on the bar. The full editor's "Private notes" checkbox stays |
| Enable redmine_silencer feature | No suppress icon, no "Suppress Notifications" checkboxes anywhere, and a submitted `suppress_mail` is ignored |
| Suppress watchers toggleable icon in quick notes mini form | No suppress icon on the bar. The checkboxes stay. Only offered while the feature above is on |
| Files added on private notes are private to the note | Core's behaviour: see below |

With an icon switched off, a value set on the full editor's checkbox is cleared
when the editor is cancelled, since the bar has nowhere to show it.

The `suppress_mail_notifications` permission stays in the role form even with
the feature off, because permissions are registered at boot. It grants nothing
until the feature is switched back on.

## Files on private notes

Core keeps a private note to its text alone. Any file added with it is moved
into a separate, public history entry ("File added"), listed in the issue's
Files section, and downloadable by anyone who can see the issue. So a
team-only discussion still shows up to everyone else as new files.

With the switch on, a file added on a private note stays on that note:

* it is shown under the note, and mailed only with the note, to the people
  who can see private notes;
* only the note's author and users with "View private notes" can open,
  download or preview it; anyone else gets "access denied";
* the issue's Files section leaves it out, for everyone. It is listed under
  its note only.

This applies on every project, whether or not Easy notes is on there, and to
both the bar and core's edit form. Other changes saved with the note (status,
fields) still go into a public entry, as in core.

Nothing extra is stored: a file is private because it was recorded on a
private note. Switching the setting off makes those files visible and listed
again. Files added on private notes before this existed were already split off
by core into public entries, and stay public. A note made private afterwards
through core's "Edit" takes its files with it.

Only the Files section filters them out. The "Download all" zip, the issue
list's Files column and filter, the REST API and issue copies still include
them. They are hidden from the Files section so as not to be awkward, not as
access control for sensitive files.

## Switching it on per project

It is a project module, so it is off until someone turns it on. Go to
**Project settings, Modules**, tick **Easy notes**, save.

Where the module is off, the issue page is exactly the stock page: no bar, no
stylesheet, no script, and core's own Quote behaviour. Nothing about the page
changes.

Two consequences worth knowing:

* After installing, no project has it on, including existing ones. Tick the
  projects you want.
* New projects get it only if you add it to
  **Administration, Settings, Projects, Default enabled modules**.

To turn it on everywhere at once:

```ruby
# RAILS_ENV=production bin/rails runner
Project.find_each { |p| p.enable_module!(:easy_notes) unless p.module_enabled?(:easy_notes) }
```

Use `enable_module!`, which only appends. Assigning `enabled_module_names=`
replaces the whole set, so it destroys any row not in the list you pass, and
that includes modules left behind by plugins you have since uninstalled.

## Permissions

The bar renders only when `@issue.notes_addable?`, which is the "Add notes"
(`add_issue_notes`) permission. The private toggle and checkbox appear only with
`set_notes_private`. The suppress toggle and checkboxes appear only with
"Suppress email notifications" (`suppress_mail_notifications`), which the
server checks again on save. The attachment field appears only when
`attachments_addable?`.

Registering a project module requires naming at least one permission, so there
is a marker permission, `view_easy_notes`. It is declared public, which keeps it
out of the role form entirely, so no role gains or loses anything and there is
nothing to re-tick after installing. Nothing is ever checked against it; the
real gates are the module and the core permissions above.

## Requirements

Redmine 7.0.0 or later. The markup mirrors Redmine 7's journal header
(`sprite_icon`, flex `.journal-header`, `textarea_tag`), so earlier versions are
untested. No gems, no migrations, no controllers, no routes.

## Install

```bash
cd {REDMINE_ROOT}/plugins
git clone https://github.com/joaoperfig/redmine_easy_notes.git
cd ..
RAILS_ENV=production bin/rails assets:precompile
```

Then restart Redmine. The restart is not optional. Propshaft resolves
`.manifest.json` once at boot, so a running server keeps serving the old asset
digests and the plugin looks like it did nothing.

## Theming

The toggles' "on" colour is read at runtime from the computed `accent-color`
of a real checkbox in the full editor, so a theme that sets `accent-color` on
checkboxes is matched without configuration. Where that resolves to `auto`, the
CSS system colour `AccentColor` is used. To force a colour, set the property:

```css
#easy-notes { --easy-notes-private-color: #e90062; }
```

The "Add Note" button is an `<input type="submit">` rather than a
`<button type="submit">` on purpose. Themes reliably style `input[type=submit]`
and frequently miss the `button` form, so a `button` silently loses the theme's
colours and hover.

## Licence

GPL-2.0-or-later, matching Redmine.

The `spy`, `users-group`, `mailbox` and `mailbox-off` icons in
`assets/images/icons.svg` come from
[Tabler Icons](https://tabler.io/icons) (MIT, (c) 2020-2024 Pawel Kuna), the same
set Redmine core draws its own sprite from, so they match visually.
