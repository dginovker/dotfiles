---
description: Create Patch Notes that can be pased in the public Ziva Discord
---
We have a "Patch Notes" channel in the public Ziva Discord. Look at the commits made in the last 2 weeks and help me come up with a good "patch notes" summary. Think about what users care about, and how the commits impact them    

Do not use em-dashes. Follow a format like this:

Ziva Patch Notes (Jan 14 - Jan 28)
 
New Features 
 
* TileMapLayer tools: New shape primitives for tilemaps: draw horizontal/vertical lines, stairs, and erase rectangles
* Rate limits dashboard: See your current usage and limits on the account page
* Chat titles: Conversations now get AI-generated titles instead of just showing the first message
* Open Logs button: Added to the error screen when initialization fails, making debugging easier
* UI mode setting: Choose between main screen tab or side dock (now defaults to side dock)

Improvements 
 
* Settings dialog redesign: Tabs are now icons to fit better, unified upgrade/rate limit dialogs
* Code blocks: Higher contrast for better readability
* Input box: Now resizable
* Chat header: Shows chat title instead of ID
* Memory optimization: Reduced allocation churn on Linux builds

Bug Fixes
 
* Linux release: Fixed missing CEF files
* Chat messages: Fixed angle brackets being stripped from messages
* Agent mode toggle: Fixed crash in settings dialog
* Legacy subscribers: Fixed $20/mo subscribers incorrectly getting free tier limits
* Plugin initialization: Fixed timeout issues

