# Manual test checklist

Use this on a real forum after installing or upgrading. It needs an admin
account and three throwaway member accounts. The names below are examples:

- **viewer** - the member doing the testing (must be allowed to ignore: staff,
  or in a group listed in the `ignore allowed groups` site setting)
- **quinn** - will be ignored
- **quinn2** - a look-alike name that must never be hidden
- **alice** - an ordinary member

Keep the browser console open throughout. Any line starting with
`[enhanced-ignore]`, and any new error, is a finding. Tick each box only when
you have seen the result yourself.

Status of this checklist: **none of the items below have been executed by the
author.** They are the integration tests awaiting verification on a live
forum. What *was* run is listed in the README under "Verification status".

## 0. Prepare content (as the test accounts)

- [ ] `alice` creates topic **A**. `quinn` replies (post 2). `quinn2` replies (post 3).
- [ ] `alice` replies in A by quoting both with the quote button (select text > Quote), with her own sentences before, between and after the quotes.
- [ ] `alice` posts in A, typed by hand:
      ```
      Before.

      [quote="quinn"]
      Name-only quote.
      [/quote]

      [quote="QUINN"]
      Upper-case quote.
      [/quote]

      [quote="alice"]
      Outer by alice.

      [quote="quinn"]
      Inner by quinn.
      [/quote]

      Outer tail.
      [/quote]

      [quote="quinn"]
      Outer by quinn.

      [quote="alice"]
      Inner by alice.
      [/quote]
      [/quote]

      [quote]
      Unattributed.
      [/quote]

      > Markdown blockquote mentioning quinn.

      [quote="quinn2, post:2, topic:<id of A>"]
      Mis-attributed excerpt.
      [/quote]

      Talking about quinn and @quinn in prose. After.
      ```
- [ ] `alice` replies **to quinn's post 2** using that post's Reply button.
- [ ] `quinn` and `alice` each reply to **viewer's** post in a topic of viewer's (so one post has two direct replies).
- [ ] `quinn` creates topic **B** in a category and with a tag; `alice` replies in B.
- [ ] `quinn2` creates topic **C** in the same category and tag.

## 1. Installation

- [ ] Admin > Appearance > Themes and components > Components > Install > From a git repository > `https://github.com/ieduer/discourse-enhanced-ignore` installs without an error.
- [ ] The component page shows the name "Enhanced Ignore", version 0.1.0 and one setting, `enabled_by_default` (off).
- [ ] After adding it to the active theme(s), the site loads normally for an anonymous visitor, a member and an admin, with no new console errors.
- [ ] Anonymous visitor: topics A, B and C all look exactly as before.

## 2. Per-member activation

- [ ] As `viewer`, before opting in: Preferences > Users shows an **Enhanced ignore** section with an unticked checkbox and "Enhanced ignore is off."
- [ ] Tick it: the status line changes at once; with nobody ignored it says the Ignored list is empty.
- [ ] Add `quinn` under Users > Ignored (choose a duration, Save). The status reads "on for 1 ignored user" (after a reload if needed - note which).
- [ ] Reload: the box is still ticked.
- [ ] Keyboard only: Tab reaches the checkbox, Space toggles it, the label is read with its description by a screen reader.
- [ ] Log in as `alice` in the same browser profile: her box is unticked (choices do not leak between accounts).
- [ ] As an admin, open `viewer`'s preferences: the section is not shown.
- [ ] A second browser or private window as `viewer`: the box is unticked there (browser-local, as documented).

## 3. Ignored posts

- [ ] Topic A: quinn's reply (post 2) is absent (native behaviour), other posts keep their numbers, the timeline scrubs normally.
- [ ] Topic B (started by quinn): the first post shows "Post hidden (ignored user)", with **no avatar and no name**; alice's reply is fully visible.
- [ ] The topic title, reply button, post menu and timeline in B still work.
- [ ] Unread/new indicators for B behave as they did before; nothing was marked read by itself.

## 4. Attributed and nested quotes (topic A)

- [ ] Button-made quote of quinn: replaced by one line "Quote hidden (ignored user)" - no avatar, no name, no text.
- [ ] Button-made quote of quinn2 in the same post: unchanged, expandable.
- [ ] alice's sentences before, between and after the quotes are all visible.
- [ ] Name-only quote and upper-case quote: each replaced by the placeholder.
- [ ] alice's outer quote: "Outer by alice." and "Outer tail." visible, the inner quinn quote replaced by one placeholder.
- [ ] quinn's outer quote: one placeholder for the whole block; "Inner by alice." is hidden with it; no second placeholder.
- [ ] Unattributed quote, Markdown blockquote and the prose mentioning quinn/@quinn: all visible.
- [ ] Mis-attributed quote: the excerpt is visible (expected limitation); expanding it with the chevron does **not** reveal quinn's full post.
- [ ] Selecting text and using Quote on a post that contains a placeholder still works and does not insert the placeholder text into the composer in a confusing way (note what happens).

## 5. Reply previews

- [ ] alice's reply to quinn's post is visible, **without** the "in reply to quinn" tab at its top right.
- [ ] A reply to a non-ignored user still shows its reply-to tab and expands.
- [ ] On viewer's post with two direct replies, the "Replies" button expands to show alice's reply only; quinn's entry is not shown (the count on the button may still say 2).

## 6. Topic lists and other surfaces

- [ ] Latest, New, Unread, Top: topic B is not listed; A and C are.
- [ ] The category page and the tag page: same.
- [ ] Categories page (if it shows a Latest column) and the suggested topics under a topic: B is not listed.
- [ ] In the row for topic A, quinn's avatar is missing from the posters column; other avatars remain.
- [ ] Scroll a long list to load more: later topics by quinn do not appear.
- [ ] Full-page search for a word quinn used: quinn's results are not shown, others are.
- [ ] Keyboard navigation in the list (`j` / `k`) does not get stuck on an invisible row (note what happens).

## 7. Dynamic updates

- [ ] With topic A open, have `alice` post a new reply quoting quinn: it appears live with the placeholder.
- [ ] Have `alice` edit that reply: the placeholder is still correct after the edit.
- [ ] Open a long topic and scroll/jump to a far post that quotes quinn: handled.
- [ ] With a topic open, open quinn2's user card > notification dropdown > Ignored: quinn2's posts and quotes on screen collapse without a reload (note anything that needs a reload).
- [ ] Set quinn2 back to Normal from the profile: their content returns (note whether a navigation or reload was needed).
- [ ] Go from a topic to Latest and back several times: no duplicate placeholders, no layout jumps.
- [ ] Remove quinn from Users > Ignored, reload: everything of quinn's is back.
- [ ] Watch a slow page load (throttle the network): note any flash of content before it is hidden.

## 8. Mobile

- [ ] On a phone or a narrow window (mobile view): sections 3-6 give the same results.
- [ ] Placeholders wrap and do not overflow; the Preferences checkbox is easy to tap.
- [ ] Light and dark colour schemes: placeholder text is readable in both.

## 9. Disabling

- [ ] Untick the box: after opening another page, B is listed again and quotes show Discourse's native rendering.
- [ ] Admin turns on `enabled_by_default`: a member who never chose gets it on; a member who unticked stays off.
- [ ] Admin disables the component (or removes it from the theme): after a reload nothing is hidden and the Preferences section is gone.

## 10. Uninstalling

- [ ] Delete the component. Reload as `viewer`: native behaviour everywhere, no console errors, no leftover "Enhanced ignore" section or placeholders.
- [ ] Reinstall: the earlier per-browser choice is picked up again (it lived in browser storage under a `discourse-enhanced-ignore:` key).

## Reporting

Please open an issue with the Discourse version (bottom of `/admin`), the
component commit, the checklist item number, and what you saw - using
synthetic names only.
