# Notes

## How I worked

Not in one sitting — the work is spread over several short sessions. The first twenty minutes
went to reading the instructions, running the app and using it like a user, before opening any
code. Then I asked Claude to go through the codebase and point out anything obviously wrong,
without changing a single line. I used that as a starting list, not as a to-do list.

All in, it took me about four and a half hours, so slightly over the four you asked for.

## What I changed

**Structure.** I decided to move the project to MVVM and to break the screens into smaller
views. The list screen now has a view model that owns its state, and `Views/` is grouped by
screen rather than being one flat folder.

**The fetch ran on the main thread.** I found this on the way and fixed it. With
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, the whole contact enumeration was running on the
main actor. It now goes through a service that is genuinely off it.

**`@Observable`.** I preferred moving to the newer API rather than keeping `ObservableObject`,
so I changed it.

**Search.** I looked quickly at what could be improved and fixed the repetitions that were
simple and fast to fix — the filter was being evaluated twice per keystroke, and the matching
was case-insensitive but not diacritic-insensitive, so `jerome` did not find `Jérôme`.

I also replaced the hand-rolled search bar with `.searchable`. Whenever the system already
provides the component, I would rather use it than keep a custom one — here it is what brings
the clear button, the cancel button and the search field accessibility trait that the plain
`TextField` never had, and `ContentUnavailableView.search` for a query that matches nothing.

**Empty states.** Permission granted with an empty address book rendered a blank screen, with
nothing to tell the user which of the two had happened. It is now a case in the same switch as
the other states.

**Limited contacts access.** Since iOS 18 the user can share only part of their address book,
and the app was presenting that partial list as if it were the whole thing. There is now a
banner in that case, with the system `contactAccessPicker` behind a Manage button so the
selection can be widened without leaving for Settings. The picker does not add contacts to the
address book — it changes how many of them this app is allowed to see. It is a recent API and
I wanted to use it rather than send the user to Settings.

**Closures instead of protocols.** `ContactsService` and `FavoritesStorage` are structs of
closures, not protocols with a mock implementation each. For a project this size it is
arguably more than it needs, but I find it more elegant than a protocol per service, and it is
close to what TCA does, which is what I am used to.

**Mocks.** I added a mock generator and a small debug menu so the app can be filled with
generated contacts on demand. Seven contacts in the simulator are not enough to see how the
list and the search behave.

**Tests.** I wrote tests for the essential parts of the app. I largely let Claude work on this
part and paid less attention to naming there than elsewhere, but I wanted the tests to show
the closure-based seams in use. I then reviewed every test one by one and removed the ones I
did not think earned their place — including the one that came with the project, which
asserted that a memberwise initialiser assigns its parameters and could not fail.

**Commits.** I committed incrementally, one change at a time, to make the review easier to
follow.
