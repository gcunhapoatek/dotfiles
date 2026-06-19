---
name: humanize-text
description: Rewrite drafted text so it reads like a real person wrote it — natural English, no AI tells, tone matched to the situation. Trigger whenever drafting or sending a Slack message (slack_send_message / _draft / _schedule via the Slack MCP), writing a draft message/email/announcement, or when the user asks to "humanize", "make this less AI", "de-AI", "make it sound natural", or "reword this". Apply BEFORE the message is sent, not after.
---

# Humanize text

Goal: text that reads like a specific human wrote it for a specific reader — not like a model filled a template. Apply to any message before it leaves: Slack, email, draft, announcement.

Run this whenever you are about to:

- call a Slack send/draft tool (`slack_send_message`, `slack_send_message_draft`, `slack_schedule_message`),
- write a draft message, email, or announcement,
- act on an explicit "humanize / make natural / less AI" request.

## Process

1. Draft the message for content first.
2. Pick the register (see **Tone**) from who reads it and why.
3. Strip the AI tells below.
4. Read it out loud in your head. If a real person wouldn't say it that way to that reader, rewrite.
5. For Slack: show the humanized draft and confirm before sending. Sending is outward-facing — don't fire without a go-ahead.

## AI tells to cut

These are the patterns that make text read as machine-written. Hunt and kill them.

- **Throat-clearing openers.** "I hope this message finds you well", "I wanted to reach out", "Just circling back". Open with the actual point.
- **Eager-assistant openers.** "Certainly!", "Of course!", "Absolutely!", "Great question!". Delete the whole word.
- **Note-flagging filler.** "It's worth noting that", "It's important to note", "Keep in mind that", "That said,", "Here's the thing:". State the thing; drop the frame.
- **Thesaurus tells.** *delve, tapestry, navigate (the complexities), landscape, realm, robust, seamless, foster, underscore, testament to.* Swap for the plain word or cut.
- **Hedge stacks.** "I think it might possibly be a good idea to perhaps consider". One hedge max, only if the uncertainty is real.
- **Filler intensifiers.** *just, really, very, actually, basically, simply, definitely, truly.* Delete; they add nothing.
- **Corporate abstraction.** "leverage", "utilize", "facilitate", "in order to", "at this point in time". Use *use, help, to, now.*
- **Rule-of-three padding.** "clear, concise, and effective" — pick the one word that's true.
- **The em-dash-and-parallelism cadence.** Not every sentence needs a dramatic dash or a "not X, but Y" flourish. Vary sentence length; let some run short.
- **Summary tax.** Closing "In summary / To recap / I hope this helps / Let me know if you have any questions!" on a 3-line message. Cut it.
- **Over-explaining.** Stating the obvious or restating the ask back. Trust the reader.
- **Emoji garnish and exclamation inflation.** One, if it fits the channel. Not a row of them.
- **Symmetry that no human writes.** Perfectly balanced bullet lengths, every item the same shape. Real notes are lumpy.

## Worked example

A typical AI draft, then the same message after the cuts:

> Hi team! I hope you're all doing well. I just wanted to quickly circle back regarding the deployment that we had scheduled for this week. It's worth noting that we've encountered a few unexpected challenges with the database migration, but rest assured we are actively working to navigate these complexities. I'll be sure to keep you all posted with any updates. Thanks so much for your patience and understanding! 🙏

Cut: opener, "just/quickly", "It's worth noting", "rest assured", "navigate these complexities", summary tax, emoji garnish. What's left is the actual news:

> Heads up: this week's deploy is slipping. The DB migration hit a snag — I'm on it and will update you by EOD tomorrow.

~70 words → 23, and the reader learns *more* (there's now a deadline).

## What natural looks like

- Lead with the point or the ask. Context after, only what's needed.
- Contractions: *don't, it's, we'll, can't.* Formal-register exception below.
- Concrete over abstract: name the file, the PR, the time, the person.
- Plain verbs. Short words when they carry the meaning.
- One idea per sentence; vary length so it has rhythm.
- It's fine to be direct. "This won't work because X" beats "I'm wondering if there might be some challenges with X".
- **Embed links when the medium supports it.** If you reference a PR, ticket, doc, file, or person and the target renders inline links (Slack, email, Markdown, GitHub), hyperlink the natural words — `[#619](url)`, `[WIL-1682](url)` — instead of pasting a bare URL or naming it with no link. A real person links what they mention. Skip only where links don't render (plaintext, terminal) or the URL isn't known.

## Don't overcorrect

Humanizing removes machine residue. It does not change what the message says or who the writer is.

- **Keep the meaning exact.** Don't drop a caveat, number, or condition to sound breezier. A hedge that's *true* ("this might break if the cache is cold") stays — only kill the empty ones.
- **Don't manufacture personality.** No jokes, warmth, or slang the original didn't have. Natural ≠ chummy. A dry status update should stay dry.
- **Preserve the writer's voice.** If the user drafted it, match *their* idiom and vocabulary — don't flatten it to a generic "natural" register. You're cleaning their text, not replacing it.
- **Shorter by default.** Humanizing usually cuts length; a real fix often drops 30–40%. Never pad back to the original word count. If the rewrite is longer, you added filler.
- **Leave exact-wording text alone.** Quoted error messages, code, commands, legal/compliance copy, names, and IDs pass through untouched. Humanize the prose around them, not them.

## Tone presets

Match register to reader:

### Internal teammate (default for team channels, DMs)

Casual, direct, peer-to-peer. Contractions, fragments OK, light humor fine. Skip the preamble entirely.

> Pushed the fix to `auth-refresh` — token expiry was using `<` instead of `<=`. Can you sanity-check before I merge?

Not:

> Hi! I hope you're doing well. I just wanted to let you know that I've gone ahead and pushed a fix...

### Manager / leadership

Concise, outcome-first, lightly more formal — but still human. Lead with the result or the decision needed. No filler, no padding. Contractions stay (formal ≠ stiff). Make the ask or status unmistakable in the first line.

> Migration's done — all 4 services cut over, zero downtime. One follow-up: the staging DB still needs the index backfill, planning that for Thursday. No action needed from you unless you want to move that date.

Not:

> I am pleased to report that the migration initiative has been successfully completed across all relevant services, and I wanted to take a moment to provide a comprehensive update...

### Scaling up (client / external / public)

When the reader is external, keep the structure above but raise polish: fewer fragments, no inside jokes, spell out acronyms once. Still cut the AI tells — polished is not the same as robotic.

## Quick check before sending

- First line carries the point or ask? 
- Could a colleague tell *you* wrote it, not a bot?
- Every sentence earns its place?
- Register matches the reader?

If yes, send. If the message is going out via Slack MCP, show the final text and confirm first.
