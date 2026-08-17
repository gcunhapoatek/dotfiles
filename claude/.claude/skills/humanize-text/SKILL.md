---
name: humanize-text
description: Rewrite drafted text so it reads like a real person wrote it — natural English, no AI tells, tone matched to the situation. Trigger whenever drafting a Slack message (slack_send_message_draft via the Slack MCP — direct send/schedule are hard-blocked by pre-tool-use-slack.sh), writing a draft message/email/announcement, or when the user asks to "humanize", "make this less AI", "de-AI", "make it sound natural", or "reword this". Apply BEFORE the message is sent, not after.
---

# Humanize text

Goal: text that reads like a specific human wrote it for a specific reader — not like a model filled a template. Apply to any message before it leaves: Slack, email, draft, announcement.

Run this whenever you are about to:

- call the Slack draft tool (`slack_send_message_draft` — direct send/schedule are hard-blocked by `pre-tool-use-slack.sh`),
- write a draft message, email, or announcement,
- act on an explicit "humanize / make natural / less AI" request.

## Process

1. Draft the message for content first.
2. Pick the register (see **Tone**) from who reads it and why.
3. Strip the AI tells below (phrase-level).
4. Break the statistical smoothness (see **Burstiness**) — this is the part that actually fools detectors.
5. Read it out loud in your head. If a real person wouldn't say it that way to that reader, rewrite.
6. For Slack: show the humanized draft and confirm before sending. Sending is outward-facing — don't fire without a go-ahead.

**Why two passes.** Cutting AI-tell phrases removes vocabulary an AI would use. It does not remove the *shape* — AI detectors (GPTZero, Originality.ai, Turnitin) score perplexity (how predictable each next word is) and burstiness (how much sentence length/complexity varies across the text). A draft with zero "delve" or "It's worth noting" can still read as 100% AI if every sentence is 15–20 words, subject-first, one clause, evenly hedged. Step 4 exists to fix that.

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
- **The parallelism cadence.** Not every sentence needs a "not X, but Y" flourish. Vary sentence length; let some run short.
- **Summary tax.** Closing "In summary / To recap / I hope this helps / Let me know if you have any questions!" on a 3-line message. Cut it.
- **Over-explaining.** Stating the obvious or restating the ask back. Trust the reader.
- **Emoji garnish and exclamation inflation.** One, if it fits the channel. Not a row of them.
- **Symmetry that no human writes.** Perfectly balanced bullet lengths, every item the same shape. Real notes are lumpy.
- **Thesis-body-conclusion shape.** Setup sentence, three supporting points, wrap-up sentence — even in a five-sentence Slack message. Humans front-load the point and stop when they're done, not when the structure is satisfied.
- **The em-dash tic.** One dash for a real interruption is fine; two or more per message is a detector's easiest signal. Default to a period, comma, or parenthesis instead.
- **Vague conjunctive glue.** "Additionally", "Furthermore", "Moreover", "On the other hand", "As a result", "In today's fast-paced world/environment". Real writers connect ideas by just... putting them next to each other, or with "and"/"but"/"so".
- **Inflated stakes.** "game-changer", "crucial", "vital", "unlock", "elevate", "dive into", "unpack", "cutting-edge", "in the ever-evolving landscape of". Say what changed and let the reader decide if it's a big deal.

## Burstiness: matching how humans actually vary their writing

Phrase-level cuts remove AI *vocabulary*. They don't remove AI *shape* — and detectors mostly score shape: perplexity (is each word predictable given the last few?) and burstiness (does sentence length/complexity vary a lot, or hover in a narrow band?). A perfectly clean paragraph where every sentence runs 15–20 words with one main clause will still score as machine-written. Fix the shape after you fix the words:

- **Force a wide length spread inside one paragraph.** A real paragraph mixes a 3-word sentence, a 25-word one with a subordinate clause, and something in between. If you read your draft and every sentence is roughly the same length, that's the tell — rewrite for variance, not just correctness.
- **Let sentences start differently.** AI defaults to subject-first ("The migration completed...", "The team decided..."). Humans open with "And", "But", "So", a time marker ("Thursday's the target"), or drop the subject entirely in a fragment. Don't force this into every sentence — force it into *some*.
- **Uneven paragraph lengths.** A one-line paragraph next to a five-line one reads human. Three paragraphs of near-identical length in a row reads generated.
- **Let a thought land out of order.** Real writing sometimes states the conclusion, then adds the caveat as an afterthought ("...though that assumes staging holds up") instead of pre-organizing every qualifier before the main clause. Don't over-engineer this — one instance is enough to break the smoothness; a whole message of afterthoughts is its own tell.
- **Don't reach for bullets by default.** A list where every item is a complete, parallel, similarly-sized sentence is one of the strongest structural tells there is. If the content is genuinely a short prose thought, write it as prose. Reserve bullets for cases where the human original used them or the content is truly a list (steps, options, a table of facts).
- **Skip the tidy close.** AI writing resolves; human writing often just stops once the last piece of information lands. Don't add a wrap-up sentence whose only job is to sound finished.
- **Allow one real imperfection over a longer message.** A sentence that runs on a bit before a period, a parenthetical that trails off, mixing "which" and "that" the way people actually do. Don't inject typos or bad grammar — that's a different (worse) tell — just don't sand every sentence to the same polish level.

**Caveat: this isn't a detector-beating trick, it's the actual fix.** Statistical detectors (ZeroGPT, Copyleaks, Originality.ai) score perplexity/burstiness directly, so the fixes above move the needle on those. GPTZero itself moved off raw perplexity/burstiness to a deep-learning classifier back in 2023 and now scores deeper stylistic and semantic patterns — surface-level sentence-length juggling alone won't fool it. The real target is still "does this read like a specific person thought it, not like a template got filled" — burstiness is a proxy for that, not a substitute.

## Worked example

A typical AI draft, then the same message after the cuts:

> Hi team! I hope you're all doing well. I just wanted to quickly circle back regarding the deployment that we had scheduled for this week. It's worth noting that we've encountered a few unexpected challenges with the database migration, but rest assured we are actively working to navigate these complexities. I'll be sure to keep you all posted with any updates. Thanks so much for your patience and understanding! 🙏

Cut: opener, "just/quickly", "It's worth noting", "rest assured", "navigate these complexities", summary tax, emoji garnish. What's left is the actual news, rewritten with uneven sentence length instead of one smooth em-dash sentence:

> Heads up, this week's deploy is slipping. The DB migration hit a snag we didn't see coming during testing. I'm on it, update by EOD tomorrow.

~70 words → 25. A 5-word sentence next to a 12-word one next to a 7-word fragment — that variance, not just the cut words, is what makes it read human. And the reader learns *more* (there's now a deadline).

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
- **Sentence-length spread:** eyeball the sentence lengths in the longest paragraph. If they're all clustered within a few words of each other, rewrite for variance before sending — this is the single biggest detector signal and the easiest one to miss because the *words* already look clean.
- **Shape check:** any bullet list where every item is a full, similarly-sized sentence? Any paragraph that opens with a setup and closes with a tidy wrap-up? Either one is worth flattening into plainer, lumpier prose.
- Zero or one em-dash in the whole message, not per sentence?

If yes, send. If the message is going out via Slack MCP, show the final text and confirm first.
