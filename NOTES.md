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
