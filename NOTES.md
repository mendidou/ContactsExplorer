# Notes

## How I worked

I ran the app before reading it, then read it before changing it. The first pass produced
`docs/UI-FINDINGS.md` — an audit where every claim is tagged by how I know it: seen on
screen, read in the code, or not verified. That distinction turned out to matter (see
"Where I was wrong").

Then I fixed in this order: correctness first, ownership of state second, structure third,
view decomposition last. Each step is its own commit with the reasoning in the message.

## What I changed, and why

**The fetch was on the main thread.** `ContactsStore` carried a CHANGELOG saying
`2026-08-18: added @concurrent so fetching doesn't block the main thread`. There was no
`@concurrent` anywhere in the file, and with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
the whole `enumerateContacts` loop ran on the main actor. The comment described work that
was never done. Contact loading now goes through a `ContactsService` that is genuinely off
the main actor.

I kept a comment in that service explaining why `CNContactStore` and `CNContactFetchRequest`
can live inside a `@concurrent` function despite not being `Sendable` — they never escape
it, so region isolation accepts them. Promoting either to a stored property would break it,
and nothing in the code says so.

**Favorites had no owner.** The state lived in `ContactsStore`, but the persistence type
was declared at the bottom of `ContactDetailView.swift`. Now a single `FavoritesManager` is
created once in the app entry point and injected. That single instance is what keeps the
star in sync between the list and the detail — the requirement most likely to break under
refactoring, so it is the one dependency I drew explicitly.

**Structure.** `Contact` was in `Utils/`. It is the only domain model in the project, so it
moved to `Models/`. `Utils/` is a folder that names a filing failure rather than a layer.

**View decomposition.** Sections written as `private var section: some View` share their
parent's invalidation boundary — they reorganise code without reducing update cost. I turned
into view types the ones whose inputs are genuinely narrower than the parent's, and left the
rest alone. `ContactAvatarView` and `FavoriteButton` were defined inside
`ContactsListView.swift` while the detail screen also used them; they now have their own
files. Nothing that only one screen uses was promoted to a shared component.

## What I deliberately left alone

**The star nested inside the row button.** Reading the code, this looked like a hit-test
bug: a `Button` inside a `Button`. I flagged it as blocking. Then I tested it on device —
tapping the star toggles the favourite and does not navigate; tapping anywhere else
navigates. The code is correct. Changing it would have been a refactor of working code with
no defensible reason.

**Four computed view properties.** `content` is a `switch` over the load state — extracting
it would create a type that receives everything the parent has in order to re-emit the same
switch. `contactsList`, `initialsAvatar`: same reasoning, no narrower inputs, or too small
to justify a type.

**The hand-rolled search bar.** It should be `.searchable` — that would fix the missing
clear button, the missing cancel button, the fact that it never collapses on scroll, and the
keyboard that will not dismiss. I did not get to it, and I deliberately did not restructure
a component I intend to delete.

## Where I was wrong

Twice, and both are in the audit.

I classified the nested-button hit test as blocking on a code reading alone. Testing
disproved it.

I then claimed that toggling a favourite re-runs `ContactsListView.body` and recomputes the
filter, because `favorites.contains(...)` is written inside the parent's body. I measured it
with temporary probes: the parent body does **not** re-run — only the six row bodies do. The
row-content closure of a `List` is evaluated in the row's own context, so the observation
read is attributed there. My proposed fix is still worth doing, but it buys less than I
said: six full rows become six leaf views, not "the parent stops running".

## What I would do next, in order

1. **`Contact` equality is unstable.** `LabeledValue` has `let id = UUID()`, and `Hashable`
   is synthesised, so two `Contact` values built from the same `CNContact` are never equal.
   That breaks SwiftUI's ability to skip unchanged subviews, and it means the
   `NavigationStack` path no longer matches its contact after a pull-to-refresh. This is the
   root cause behind several smaller symptoms, so it goes first.
2. **Remove the debug `print` in the search filter.** It runs once per contact per keystroke.
3. **Search is diacritic-sensitive** — `localizedCaseInsensitiveContains` means "rene" does
   not find "René". `localizedStandardContains` fixes it.
4. **Replace the search bar with `.searchable`**, and disable autocapitalisation and
   autocorrection — typing `anna` currently shows `Anna`.
5. **Missing states.** A granted-but-empty address book renders a blank list. A denied
   permission is never re-checked, so granting it in Settings and coming back leaves the app
   stuck on "No Access" until relaunch.
6. **Birthdays without a year render as year 1.** `CNContact.birthday` is a `DateComponents`
   whose `year` is often nil, and `Calendar.date(from:)` fills it with 1.
7. **Touch targets.** The star measures 22×20 pt in the list and 32×36 pt in the detail
   toolbar, against Apple's 44×44 minimum.
8. **`MockGenerator` is in the app target**, so preview fixtures ship in the release binary.

Items 2 and 3 are one-line changes I would normally have done first; I left them because I
was mid-refactor and did not want a behaviour change inside a structural commit.

## Verification

Everything I claim to have tested was tested on an iPhone 17 Pro simulator running
iOS 26.5: navigation, favourite toggling from both screens, favourite sync between them,
persistence across a relaunch, search by name, search by phone number with a space, and the
permission-denied screen. `docs/UI-FINDINGS.md` marks anything I could not trigger.
