# Tasks: Gret guards the door and breathes with you (017)

- [X] T001 Gret's layers as vector drawables (`res/drawable/gret_tail.xml`, `gret_front.xml`,
      converted from `assets/mascot/gret/*.svg`; regenerate with the scratch converter, do not edit).
- [X] T002 `GretGuardView`: ring, bubbles, entrance from the left with fins rising, 8 s breath loop,
      tail wag; still with "remove animations". Layout: Gret's line by block count, Gret in the
      ring, "Hít vào…/Thở ra…", "n giây". Wait, choices, events and channel unchanged (FR-002).
- [X] T003 Native manual checklist, run together with spec 018 (details in
      `specs/018-mascot-family/tasks.md` T005): Gret blocks and breathes on every real block,
      the line follows the block count (1st, 2nd, 3rd and later), the seconds count down under
      Gret, and the choices, Back, reel, break, lifecycle and events all behave as before.
