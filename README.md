# PROJECT IS ARCHIVED
... but you can still just fork it, host your own server, and change the server addresses, ctrl+f for "onrender" in all the files in `lib` and replace those URIs with your own server, and also change those Github URIs in [update.dart](https://github.com/JumpyJacko/resentral_flutter/blob/main/lib/pages/settings_subscreens/update.dart).

For now, the app should still work but you probably want to host your own server as I'm using a free server host.

#### Why?
Mainly because of my pre-Rust/pre-OOP self writing terrible code. Many odd decisions like having each page have their own web request functions instead of generalising it and placing a web request function in a separate file, separate files for UI/Views and logic, _using Flutter_, etc. The app is still technically "functional". I am very proud of my web scraping server though, and that's probably the only thing. I may come back to this project however, I will most likely not be coming back to this repository.

# reSentral
The (new) app for reSentral, a mobile-focused redesign and port of the Sentral school management system (student-side). This was created because of an active and burning disdain for the poor design of Sentral's web interface, mainly considering the mobile space. Additionally, the lack of 'Remember Me' functionality for login (while understandable) was also inconvenient.

This is an app designed and programmed by a student who is a 100% self-taught software developer. Hence, bugs, missing functionality, and broken features are to be expected as it is not _"production-ready"_ levels of code cleanliness.

The backend for this project can be found at [this repository](https://github.com/JumpyJacko/resentral_server_rs) and is written entirely in Rust using [axum](https://github.com/tokio-rs/axum) for server and network, and using [fantoccini](https://github.com/jonhoo/fantoccini). The server is also containerised with a Dockerfile.

## Where is it right now?
It's working enough to see the Daily Timetable, Full/Weekly Timetable, and Announcements.

# The Design
The original design doc (before the switch to a 'Material You' style) is available on Figma and is free to view with this link below.
https://www.figma.com/file/HwetJzpdpT6fbwVp9CNSXf/reSentral-Flutter?type=design&node-id=30%3A118&t=xELudUcmqTbJcu8i-1

<p align="center">
  <img src="https://github.com/JumpyJacko/resentral_flutter/assets/48436180/83fb748c-c377-4eaa-ba16-3cbe95477394" width=600 />
</p>

# Gallery
### Login
<img src="https://github.com/JumpyJacko/resentral_flutter/assets/48436180/b999b8f1-f9fd-4c10-abd4-f3d925743d92" width=300 />

### Timetables
<img src="https://github.com/JumpyJacko/resentral_flutter/assets/48436180/ebc74d41-177c-4c12-abe0-d98c83bd44d0" width=300 />
<img src="https://github.com/JumpyJacko/resentral_flutter/assets/48436180/fa706fe8-10ac-4771-9fcd-c991e403c8ec" width=300 />

### Announcements
<img src="https://github.com/JumpyJacko/resentral_flutter/assets/48436180/d166a0a6-12e2-4e44-89bb-1d08f59b8fcd" width=300 />
<img src="https://github.com/JumpyJacko/resentral_flutter/assets/48436180/5f8994ff-f4d7-4583-83e7-8e69b2e23327" width=300 />

### Miscellaneous
<img src="https://github.com/JumpyJacko/resentral_flutter/assets/48436180/cc8b781b-0160-44c7-8b67-29a3c8c96a2b" width=300 />
<img src="https://github.com/JumpyJacko/resentral_flutter/assets/48436180/c32cf800-3492-4ff8-ad23-82cd0f5dbf0b" width=300 />
