Gem Escape
=========

CSCI E-76 Student’s Choice Project

Summary
---------

The App I have created for the student’s choice project is a game called Gem
Escape.
The App is created using the cocos2d games framework. It provided some useful
functionality, such as animation, scheduler, auto support for retina display
etc.
No setup is required to get it working, just run and enjoy. The App itself
contains a “How To Play” section, so feel free to read it if game play is not
intuitive. The objective is to line up the gems in such a way before the times
up, that you rescue as many people as you can.
I don’t remember exactly the features I said when I submitted the proposal, but
I think I ended up implementing it far beyond the initial spec. As I mentioned
before, I will probably put this on the App store some time in the future, so
I’ve also added ads from AdMob in game. :)

Update: I didn't end up putting it in the app store. Because of reasons.

Features
---------
Features of the game include:
• Timer limits the time available, varying for each level.
• Game automatically ends when times up.
• Support for objects to be swapped. If objects can’t be swapped, the objects
will be swapped back. All with nice slide animations.
• Game start animation for objects falling into place. Different animation
for resuming a game.
• Support for multiple gestures to swap objects, clicking two objects will
    work, and also swipes. The swipes can also be just directional, so can
    swipe beyond the intended obj. These multiple gestures are implemented by
    me, and not from some library. (Library only gives touch location, not
    gesture support)
• Support for game end animation, removing gems, chaining move and remove animations.
• After level is finished, game moves on (on click) to next level if game won, or restart is game lost. If reached final level, click will always
￼restart the level.
• Game levels and objects are stored in property
add new levels and objects.
• 9 levels of varying difficulty.
• Support for level selection.
• How To Play section to help guide new players. • Support for unlocking new levels after a level • Support for storing the levels unlocked so the
lists. Easy to expand and
is completed.
user can play any level
reached.
• Various objects with different properties to make gameplay more
interesting.
• Support for pause/resume. Timer is stopped on pause and continues on
resume.
• Support
• Support
• Support
• Support for resuming last game.
• Ads only displayed in game scene.
• Game is automatically pause if user backgrounds app or clicks on an ad.
• Easily create versions of the game with ads and without. Simply change the
for restarting a level.
for fast forwarding, ending game early if player is done.
for automatically saving game progress.
DISPLAY_ADS to true/false to create ad supported / non-ad supported
versions of the game. The layout automatically changes to make best use of
the space available.

Screenshots
---------

![Alt text](http://peterl.in/images/project-gemescape-full.png "Game Play")
