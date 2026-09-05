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

**Search.** Four things, in one place. The filter, the trimming and the phone predicate lived
in `ContactsListView` as thirty lines of view code that no test could reach; they now sit in
`ContactsStore` next to the contacts they filter. The hand-rolled bar became `.searchable`,
which is what supplies the clear button, the cancel button and the `searchField` trait the
`TextField` never had — autocorrection and autocapitalisation are off, since a search over
proper nouns is the one field where the keyboard should not guess. Name matching moved from
`localizedCaseInsensitiveContains` to `localizedStandardContains`, which folds diacritics as
well as case, so `jerome` finds `Jérôme`. And `filteredContacts` is read into a local before
the body uses it: it is a computed property, and the view read it twice per render — once for
the list, once to decide whether to show the empty-search state — so the whole address book
was filtered twice per keystroke.

One consequence to know about: on iOS 26 the system, not the app, decides where a
`.searchable` field sits, and on iPhone that is now the bottom of the screen. Passing
`.navigationBarDrawer(displayMode: .always)` does not move it back. The bar changing position
is the price of adopting the system component, and I would rather pay it than keep a
hand-rolled field to preserve a habit.

**Tests.** The project arrived with one, asserting that a memberwise initialiser assigns its
parameters. It could not fail. What the brief actually names — the list after permission, the
filter by name or phone, the favourite that survives a relaunch — was untested because none
of it was reachable: the store built its own `CNContactStore`, and favourites wrote straight
to `UserDefaults`. Both now take their dependency as a value, so a test can supply contacts
or a failing fetch without a device and without touching real user defaults. Sixteen tests
cover the four load states including a failed reload with contacts already on screen, the
search paths, and the fact that every favourite toggle is written out rather than only held
in memory.

The seam is deliberately thin — closures, not protocols. A protocol per service plus a mock
per protocol would be more ceremony to defend than the two initialisers it replaces.

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

**Phone search does not normalise country codes.** A contact stored as `06 12 34 56 78` is
not found by typing `+33612345678`. The predicate reduces both sides to digits and asks
whether the stored digits *contain* the typed ones, so `"0612345678"` never contains
`"33612345678"` and the match fails. Verified at runtime: `0612345678`, `612345678` and
`34 56` all find the contact; `+33612345678` and `0033612345678` do not.

Fixing this properly means E.164 normalisation, which means libphonenumber — a dependency
I am not willing to add to a project this size. The cheap alternative is to compare the last
nine digits of each side. That resolves the international case but breaks searching by a
fragment in the middle of a number: `34 56` would stop matching. It is a trade between two
real behaviours, not a strict improvement, so I kept the current one and named the gap here
rather than shipping a heuristic I would have to defend.

Two smaller relatives of the same predicate. `Dupont Jean` does not find `Jean Dupont` —
the name test is a substring search, not per-word matching. And a query typed with
Arabic-Indic digits satisfies `isWholeNumber`, so it passes `isPhoneNumber` and then can
never match numbers stored in ASCII: an empty result with nothing explaining it.

**Micro-optimising the filter any further.** After moving search into the store I measured
three variants of the predicate. Evaluating the filter once per render instead of twice
bought most of the gain; hoisting the query-invariant work out of the per-contact loop and
precomputing each contact's digits at mapping time bought 0.48 ms and 0.36 ms respectively
on 500 contacts. The same measurement showed why: on 5000 contacts a name query still costs
6.4 ms with everything else optimised, because `localizedStandardContains` runs per contact
and cannot be precomputed. The name comparison is the floor, so tuning the phone path is
effort spent where the time is not.

## Where I was wrong

Three times, and all three are in the audit.

I classified the nested-button hit test as blocking on a code reading alone. Testing
disproved it.

I then claimed that toggling a favourite re-runs `ContactsListView.body` and recomputes the
filter, because `favorites.contains(...)` is written inside the parent's body. I measured it
with temporary probes: the parent body does **not** re-run — only the six row bodies do. The
row-content closure of a `List` is evaluated in the row's own context, so the observation
read is attributed there. My proposed fix is still worth doing, but it buys less than I
said: six full rows become six leaf views, not "the parent stops running".

Third, I wrote that a denied permission is never re-checked — grant it in Settings, come
back, and the app sits on "No Access" until relaunch. I tested both directions with the
app in the foreground and watched `launchctl list`: iOS terminates the app on *any*
Contacts permission change, granting included. The next launch starts from `.idle` and
resolves correctly. There is nothing to fix, and a `scenePhase` re-check would be dead
code. The same reasoning retires a related asymmetry in `load()` — the `.denied` catch has
no `contacts.isEmpty` guard where the generic catch does, which would swap a populated list
for the permission screen, except the process never lives long enough to do it.

The pattern in all three: a defect that is obvious on the page and absent from the device.
It is why the audit tags every claim with how I know it.

## Questions I would take to design

Two gaps are real but the right answer is a product decision, not an engineering one. I
made the conservative call and would raise both rather than invent an interface.

**A failed refresh with contacts already on screen.** It used to fail silently: the list
stayed, `loadState` stayed `.loaded`, and nothing told the user the refresh had not worked.
I now surface the error screen unconditionally, which also makes this catch agree with the
`.denied` one next to it. The cost is that a transient failure replaces a list the user was
reading. The better answer is probably to keep the list and show a non-blocking signal —
banner, toast, or an inline row — but which one, and how insistent, is a design call.

**Limited contacts access.** On iOS 18+ the user can share a subset. The app treats
`.limited` as full authorisation, which is right — you show what you were given — but it
presents a partial address book as if it were complete. Someone who shared two contacts
searches for a third, finds nothing, and has no way to understand why or to widen the
selection from inside the app. The minimum is a banner plus the Settings link we already
have; a proper "manage shared contacts" flow is a design and API question.

## What I would do next, in order

1. **`Contact` equality is unstable.** `LabeledValue` has `let id = UUID()`, and `Hashable`
   is synthesised, so two `Contact` values built from the same `CNContact` are never equal.
   That breaks SwiftUI's ability to skip unchanged subviews, and it means the
   `NavigationStack` path no longer matches its contact after a pull-to-refresh. This is the
   root cause behind several smaller symptoms, so it goes first.
2. **A granted-but-empty address book renders a blank list.** No contacts and no permission
   problem is a state the app does not name.
3. **Birthdays without a year render as year 1.** `CNContact.birthday` is a `DateComponents`
   whose `year` is often nil, and `Calendar.date(from:)` fills it with 1.
4. **Touch targets.** The star measures 22×20 pt in the list and 32×36 pt in the detail
   toolbar, against Apple's 44×44 minimum.
5. **`MockGenerator` is in the app target**, so preview fixtures ship in the release binary.

## Verification

Everything I claim to have tested was tested on an iPhone 17 Pro simulator running
iOS 26.5: navigation, favourite toggling from both screens, favourite sync between them,
persistence across a relaunch, search by name, search by phone number with a space, and the
permission-denied screen. `docs/UI-FINDINGS.md` marks anything I could not trigger.

Three claims rest on weaker evidence, and I would rather say so than let the list above cover
them.

The diacritic fix was verified by comparing both comparators directly —
`localizedCaseInsensitiveContains` fails on `jerome`/`Jérôme`, `muller`/`Müller`,
`noel`/`Noël` where `localizedStandardContains` succeeds, with no ASCII regression and no
false positive. It is not covered by a test and was not seen on screen, because neither
`MockGenerator` nor the simulator's address book holds an accented name. Adding one fixture
would close this, and it is the first thing I would write next.

The disabled autocorrection is in the code and unverified by hand: I could not give focus to
the iOS 26 search field through UI automation, so I never typed into it.

The timings quoted earlier come from a standalone benchmark on an Apple Silicon Mac, not from
Instruments on device; a phone is slower, so treat them as ratios rather than absolutes.
