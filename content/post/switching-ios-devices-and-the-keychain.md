+++
date = "2014-12-14T22:24:54-08:00"
draft = false
title = "Switching iOS devices and the Keychain"
+++

Unfortunately some of my [MovieLoggr](http://www.movieloggr.com/) users ran into the following issue: After switching to a new phone and restoring it from a Backup MovieLoggr would behave unexpectetly (and in some cases crash) because the App could no longer access the user's password and unfortunately did not handle this gracefully.

Typically iOS applications store passwords in the encrypted *Keychain*. When creating unencrypted backups, which is the default for creating backups with iTunes, the iOS Keychain is not stored (it is stored if you create an encrypted one or use iCloud backups).  This means, after restoring your new device from a backup, all of your apps that now run on your new device can no longer access the passwords they have securely stored on your previous device.

When using the Keychain to store passwords you should be able to handle this case and request the user to re-enter their account credentials when restoring your app from an unecrypted backup. 

If the case that I described occurs, the Keychain will inform you that the password you are looking for could not be found, this is where you need to ask the user to re-enter their password. You can reproduce this case for testing purposes by choosing a different *ServiceName* for accessing the Keychain than you used for creating the Keychain entry.

P.S.: Apple's Keychain API is pretty arcane so I'm using [SSKeychain](https://github.com/soffes/sskeychain) which provides a nice abstraction instead.