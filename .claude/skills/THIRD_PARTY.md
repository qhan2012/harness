# Third-party skills

These skills come from **pstack** by Lauren Tan (poteto), MIT license.

- Source: https://github.com/backnotprop/pstack (a mirror of `cursor/plugins/pstack`)
- Commit: `f905b88` (2026-11-14)
- Skills: `benchmark-checklist`, `principle-explain-the-number`, `principle-prove-it-works`, `technical-writing`, `unslop`

## Local changes

- Removed `disable-model-invocation: true` from all five, so agent tools can trigger them automatically.
- `unslop`: added "Use when ..." to the description, so automatic triggering has a clear cue.
- `benchmark-checklist`: removed references to pstack playbooks that are not vendored here (Opening a PR, Perf issue, Hillclimb).
- `principle-prove-it-works`: removed the reference to the `show-me-your-work` skill, which is not vendored here.

To update, copy the skills again from a newer commit, reapply the changes above, and update the commit here.

## License

MIT License

Copyright (c) 2026 Lauren Tan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
