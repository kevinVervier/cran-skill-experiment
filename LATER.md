# LATER — tangents

*Captured mid-session, not part of the current task board. Promote when picked up.*

- Run blocks one at a time (paced, with a deliberate wait between them) instead of batching all remaining blocks into one `orchestrate.sh` call — batching 5 blocks has hit the same escalating rate-limit cascade on every attempt during blocks 6-10 (2026-09-28), each requiring manual cleanup + resume.
- Each run already writes token usage (`usage.json`/`coldstart_summary.json` per `RUN_DIR`) — use cumulative usage across recent runs to anticipate rate-limit risk before launching the next block (e.g. back off or pause proactively) instead of only reacting after a block comes back full of `API_ERROR_api_error_429`. Idea from Kevin, 2026-09-29.
