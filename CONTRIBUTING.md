# Contributing

Keep platform-specific implementation behind its platform folder.

For macOS changes:
1. do not modify `/Applications/Zalo.app`
2. preserve original account data
3. test original + clone launch order both ways
4. test quit/relaunch persistence
5. run diagnostics before submitting changes

Do not commit Zalo binaries or user data.
