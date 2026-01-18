# Recall - Minimal Flashcards
Create flashcard sets to study, and go deeper with Pro to understand insights into your studying

[Get it on the App Store](https://apps.apple.com/us/app/recall-minimal-flashcards/id6756734270)

---

## Technical Details
For those interested in how this app was technically achieved, and my learnings from it

Utilized Frameworks:
- WidgetKit
- Foundation Models
- StoreKit
### Navigation
My approach for navigation is done through a mix of Apple's built in navigation system, and a View Router. 
A view router is used for a majority of content, and each main view is given a case that can be pushed to and popped out of. This system is similar to what I used in [hide & seek](https://github.com/jackkroll/HideAndSeek)
However, I also used NavigationLinks for some "last mile" navigation, that are just views that will inherintly be a dead end or will only be called in one view. While it offers a bit less control, it keeps the router a bit tidier which I prefer.
### Design Language
This was a bit tricky, but I settled on something that was fairly minimal and lacked a bold style and opted for a more "system" styling (though I realized after the fact that on Mac the styling is a bit blue!). Further, this is my first app to fully embrace the toolbars of iOS 26, and with so many controls it can be a challenge to effectively fit everything in without it being crowded.

I also placed text into the toolbars (which keeps everything inline), a unique quirk was a combintation of two modifiers needed to be used to get it to display properly
```swift
.fixedSize(horizontal: true, vertical: false)
.sharedBackgroundVisibility(.hidden)
```

### Foundation Models
This was my first time working with them, and it was absolutely a delight working with them the whole time as Apple has made interfacing with them incredibly easy. However, I think it's important to also handle a lot of the genreation errors that could also occur (regional, guardrail etc) which is not something really given much care it appears. 

While currently these models are not particularly good, I think the value as a developer is that implementing them is incredibly easy, and they will improve automatically as the foundation model does. The time it took to implement these features was fairly insignificant and I would encourage more developers to conisder at least dabbling with them. 

---

## Learnings!
As always, I learned a lot and there are several things I would do differently. 

**Technologies I learned with this project:** 
- Foundation Models 
- StoreKit 

(both suprisingly straightforward! Apple has amazing WWDC videos on both of these!)

### SwiftData + UserDefaults + Widgets
Widgets really were a bit of an afterthought for me, but I figured they would be a simple way to potentially boost returning usage (streaks + set visibility). 
However, by default Widgets store things entirely seperate (I personally don't think this should be the default behavior, Apple Watch's also have this behavior which I also think is a bit silly). In an effort to simply ship as the 2nd semester began, I simply added a patch to get them to pull from the same location (App Groups!!)

**Why was this a pain for me?**
- I used AppStorage for many attributes, I think probably too many. 
- Widgets were a last minute addition, and I was simply unaware they required an AppGroup

**How would I fix this going forward?**

I would like to implement some form of DataManager that abstracts away all of this and would allow me to just change a single line to pull from that AppGroup and pull from UserDefaults a bit better as currently the AppStorage approach is easy but definetly overused in my implementation

### View Routing
I realized mid project that I wouldn't simply rely upon Apples default navigation patterns. While I could've, it didn't lead to a smooth store experience (I wanted to have a dedicated Basic/Pro comparison) and wanted to properly push/pop on certain events (mainly a transaction). 

Fun Fact: Sheets have their own dedicated NavigationStack that is entirely seperate! (I'm not sure who is hosting complex multi-view navigation within a sheet but good for them!)

**What could I have done to prevent this?**
Mainly just plan ahead my navigation flow a bit better and understand where I would need deeper management on navigation
