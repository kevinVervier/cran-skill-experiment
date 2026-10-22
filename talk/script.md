# Spoken script — R/Pharma 2026

Word-by-word draft for the 10-minute slot, built from the `SAY` notes in
[talk.qmd](talk.qmd). Target ~9:00 spoken, leaving ~1:00 of slack for pauses,
clicks and the one tangent that will happen anyway.

Word counts assume ~140 words/minute. **The `DON'T` and `IF ASKED` notes in
talk.qmd are not reproduced here** — they are still the authority on precision
and on Q&A. This file is only the spoken line.

Bracketed `[CLICK]` marks a fragment advance. `//` marks a deliberate pause.

---

## 1 · orthoMTL: from a PhD idea to CRAN — 0:00–0:40

This summer I turned my PhD code into a CRAN package. I worked with an AI
agent, but I made the decisions and I checked what it did. This talk asks a
narrower question: would that agent have done better with written instructions
— a skill file?

The name is the method. MTL is multi-task learning: you fit several related
tasks jointly. Ortho means the weights of pairs of tasks are also allowed to be
orthogonal, so the tasks do not have to look alike. I wrote it in my PhD for
regression and classification. [CLICK] I extended it to survival at Novartis.
[CLICK] The clinical paper came out in April, and the code was still internal.
Then I packaged it with an agent, with me in the loop, [CLICK] and it reached
CRAN in August.

---

## 2 · Packaging with an agent — 0:40–1:15

An AI agent is a language model that edits files and runs commands itself. It
did the packaging, in a chat, with me in the loop — back and forth, me
answering its questions.

[CLICK] While writing unit tests, it found a real bug in my 2014 gradient. The
logistic loss: my labels were plus-or-minus one, but the code used the
zero-one formula. The test was a symmetry check — flip every label, the answer
must flip. It didn't. I verified it by hand, and we fixed it.

[CLICK] Then every automated check went green. No errors, no warnings.

[CLICK] Tests pass. Checks pass. Bundle built. // Submit.

---

## 3 · Then CRAN rejected us. Twice. — 1:15–1:45

So we submitted. // And it came back. // Twice.

[CLICK] An invalid LICENSE field. // [CLICK] And a hard-coded `set.seed`.

[CLICK] No automated check flagged either one. Two different CRAN volunteers
did — one issue each, on two separate submissions. Each one cost weeks of
round-trips, and the people who caught them are volunteers.

[CLICK] Neither rejection was a coding failure. Both were things the agent
simply did not know, and I could have written them down and handed them over.
[CLICK] People call that a skill file.

---

## 4 · What is a skill file? — 1:45–2:15

It is nothing exotic. It is a Markdown file of instructions the agent reads
before it starts. Posit and others publish them for CRAN; people drop them into
their projects. What you see here is an excerpt from the one I wrote afterwards,
from our own two rejections.

[CLICK] So: would one of these have got us through CRAN in one shot?

---

## 5 · We ran it like a trial — 2:15–3:15

I ran it as a trial.

Same starting package every time — our package, deliberately re-broken.
[CLICK] Five arms, block-randomised. [CLICK] Scored blind, two ways: the
machine check, and an AI judge.

And this is the part that matters for everything after it. Slide three was a
conversation — me and an agent, back and forth. These fifty-seven runs were
not. One frozen prompt, headless, nobody to answer a single question. //
Zero interaction.

> **Checkpoint: leave this slide by 3:20.**

---

## 6 · The result — 3:15–3:50

Seventeen out of fifty-seven. // Including the control — all twenty runs.

[CLICK] And this is the number to look at, and it is not a skill-file point:
all fifty-seven runs came back from `R CMD check` with no errors and no
warnings. From a deliberately broken package, one prompt, nobody to ask.

[CLICK] The agent did just as well with no skill file at all. // And that is a
ceiling — I'll say it before you do. Everything landed at the top, so there was
no room for a skill file to show a difference.

---

## 7 · Why the control did so well — 3:50–4:20

[CLICK] Because the agent runs `R CMD check` itself, and reads its own
failures.

[CLICK] A machine check beats a checklist, because it reads *your* package, not
a generic one.

[CLICK] Skill files add little where a tool already tells the truth.

So a skill file can only help where the check is silent.

---

## 8 · Where the check is silent: `set.seed()` — 4:20–5:00

Here is the one rejection the tool cannot see. `set.seed(42)`, hard-coded
inside four exported functions — our second rejection. `R CMD check` says
nothing about it.

And here, the arms did differ. Control, zero out of twenty. The two arms with a
real CRAN skill file, seven out of nine and eight out of nine.

Now — this was run after unblinding, on one criterion, with no statistical
test. // It is a lead, not a result. The re-score never touched the labels: a
deterministic rule over package files, blind tree IDs in, hits out. The honest
criticism is not bias — it is that this is a check I should have specified up
front, and I didn't think of it until the judge was shown to be broken.

---

## 9 · Then I handed it the answer — 5:00–5:20

Afterwards, I wrote a file quoting the reviewer word for word, and ran it again.

Control: zero out of ten. [CLICK] With the file: ten out of ten.

So the defect is learnable from text in context. // That is all this shows —
the file contains the answer.

---

## 10 · The part I did not expect — 5:20–6:20

My primary measure was the AI judge, applying twelve generic CRAN criteria. For
this package, ten of them never fired.

[CLICK] So look at the one that did. Our maintainer email is a company address.
It is identical in all fifty-seven runs — the agent never touched it. The judge
called it fine ten times, and a problem forty-seven times.

[CLICK] Same text. Opposite verdicts. The variation was not the packages. It
was the judge.

I only saw it by reading the judge's own justifications. The counts looked like
a clean signal.

> **Checkpoint: arrive here by 6:15.** If late, say only the three lines above.

---

## 11 · Take home — 6:20–8:00

[CLICK] One. Effects that change over time hide in averages. That is what
orthoMTL is for, and it is on CRAN.

[CLICK] Two. The agent fixed what `R CMD check` told it was broken — reliably,
with nobody in the loop. So the check is the thing I would write first.

[CLICK] Three. On the check, skill files gave me no gain I could detect — in
this one case, and nothing on top of the check I just showed you. The random
seed is the exception, and that one is post-hoc, one criterion, no test.

[CLICK] Four. I set out to measure skill files. // I measured my judge.

[CLICK] The cheap half is the half a machine can check.

[CLICK] // Thank you.

---

## Timing

| Slide | Target | Cumulative |
|:--|--:|--:|
| 1 Timeline | 0:40 | 0:40 |
| 2 Packaging | 0:35 | 1:15 |
| 3 Rejected twice | 0:30 | 1:45 |
| 4 Skill file | 0:30 | 2:15 |
| 5 Like a trial | 1:00 | 3:15 |
| 6 The result | 0:35 | 3:50 |
| 7 Why the control | 0:30 | 4:20 |
| 8 Where check is silent | 0:40 | 5:00 |
| 9 Handed it the answer | 0:20 | 5:20 |
| 10 Did not expect | 1:00 | 6:20 |
| 11 Take home | 1:40 | 8:00 |

~1,150 words ≈ 8:15 at 140 wpm. The gap to 9:00 is pauses and clicks.
