
# Change Log for minestrix
A new Flutter project.

## v0.1.6 - 2022

## Feature
* Experimental space support
* Experimental story support
* New post design
* Support image reply and reply indentation (reply as thread)
* Added a theming setting page

## v0.1.5 - 2021-11-26

### Chore
* update dependecies [ef49f2f]
* update dependencies [5f8b253]
* update dependencies [3da91bc]
* update dependencies [c1e4340]

### Feature
* add back E2EE support in android build [cffe2d9]
* support for updating timeline when scrolling [5c2149a]
* improved sync [e0dac37]
* adding a way to test sync functions [aac852b]
* moved account creation code into loading page [22a8944]
* enable launching url from markdown [be5c254]
* update (added link handling + reply format) [8ab5b8d]
* update [e707441]
* allow to request history while loading user private feed [01e6bcf]
* display "see all friend" button on mobile [ffeb2ec]
* made account card bottom straight [7c970cf]
* allow changing displayname [4c13175]
* migrate to FluffyBox database [a700ff4]
* update dependencies [ee95678]
* enhance reaction system [771891b]
* enhance friend suggestions [14bbca5]
* update feed view [a426679]

### Fixes
* revert android olm [f905e9e]
* typo [c8be623]
* removed unused field [70978f6]
* leave default settings. Apparently requesting 50 events doesn't work [9f6573d]
* made desplayname widget size smaller [770e55f]
* project name [0ab702d]
* removed unused dependencies [fd904f7]
* fallback [e6f190c]
* lint + dead code [31e27a1]

### Refactor
* update dependencies [9c929fd]

## v0.1.4 - 2021-11-19

### Feature
* Added information about account creation [f09799e]
* cleaned up settings page [04701c8]
* changed image provider [eca58e7]
* engance reply box [4ff9d7c]
* display 9 friends on page [89d1ab6]
* enabled back  friend requests [3c257a5]
* added back legacy database [70b4e70]
* update dependencies [0bfda50]
* more log [a60512c]
* copied Sembast adapter from fluffy chat [17a197c]
* filter user out of friends [416950b]
* display when user is invited in friends [3cc74e9]
* moved to sembast database [2c53902]
* enhance account view [b04f527]
* initial proposal for friends suggestions [c07d63e]
* update minestrix [876d4c1]
* Migrate [User, Room] from MinestrixRoom to null safety [9f3522b]
* display encryption information for each account [3d83432]
* allow kicking and baning user from a group [17440f2]
* Display user friends [8c0e9b4]
* removed old screenshots [6203c1e]
* update readme [b891484]
* new screenshot [be31377]
* Implemented auto_router navigation [478e633]
* update changelog [67cc401]
* added auto_router [8321845]
* paving the way for timeline refresh [dd812ec]
* initial display of multi account [47afee0]
* added changelog [2cd6567]
* added user on debug view [7ccb328]
* re write post interface [7a0f540]
* added deploy in CI [a43275c]
* improved minestrix room discovery [221e4c7]
* enhancing login experience [c78cf26]
* use minestrix_chat plugin [21df9fe]
* working on database performance [d1af194]
* display login informations [eefb0be]
* update login page [5cff525]
* fixed android builds [50964c4]
* setup dark mode [2f44e65]

### Fixes
* user name was not clickable [99206e4]
* remove counter [f80dd88]
* removed unused code [05c6bff]
* removed debug code from previous migration [a592bb0]
* removed unused imports [251c306]
* dead code [4b58341]
* nullsafety on title of userFriendsPage [5e308ce]
* oups, delete too quickly :D [b370041]
* unused variables + null safety + revert debug on app.dart [2702188]
* remeber that user.displayName can be null [9fc6e3a]
* login [4a0472f]
* navigate user on sarch page [d15e10f]
* name [97c4c02]
* account creation on first connection [2b33c2b]
* password login [e7fe75c]
* sso login on web [eef924f]
* indetation [50111b3]
* login on web [da0ed4b]
* home page width [d2771bf]
* CI : delete conflicting outputs [e3b4262]
* build command [29f8d43]
* CI : generate router file [6921ff0]
* lint [9bc2084]
* CI + updated pub [65b46d6]
* navigation to user [e880456]
* route navigation on account creation [138dae4]
* blank screen on refresh [82a4f46]
* friends column overflow [b8beb37]
* display user [0fff2d4]
* allow inviting user to group [a97e318]
* null safety [7d7536b]
* removed unused stream  controller [53282fe]
* prevent overflow [eed4dea]
* added drawer to mobile view [a297191]
* typo [f398bcb]
* center elements [5541fe2]
* reaction color + emoji button color [3e39c9a]
* using post + formatting + [5cb1084]
* unused imports + overflow [8a9245f]
* unused import [2be2a52]
* message editing reinti [64728f3]

### Refactor
* removed merge artefacs [2561b38]
* migrate to null safety [e4f9d23]
* changed name from smatrix to minestrix [3758985]


This CHANGELOG.md was generated with [**Changelog for Dart**](https://pub.dartlang.org/packages/changelog)
