# PIAF

**A privacy focused social media based on MATRIX**

<div>
<img src="./readmeassets/feed_page.png" width="200">
<img src="./readmeassets/chats_page.png" width="200">
<img src="./readmeassets/chat_page.png" width="200">
</div>

[Chat with us !](https://matrix.to/#/#minestrix:carnot.cc)

![](https://img.shields.io/badge/License-AGPLv3-success)


<a href='https://flathub.org/apps/details/fr.henri2h.minestrix'><img width='240' alt='Get it on Flathub' src='https://flathub.org/assets/badges/flathub-badge-i-en.png'/></a>


## 🤔 Why

The goal of PIAF is to create an alternative social media focused on privacy. We believe that privacy is a fundamental right and that when you share something, no third party should be able to see your posts or edit them.
That's why PIAF supports E2EE (not by default yet) to protect your posts and is decentralized to be able to choose where your data is stored.


We chose MATRIX because it's the best protocol for supporting decentralized, E2EE communication and because it's Open Source !!

## ✨ Features

* Simplicity
* Privacy : E2EE using [Olm](https://gitlab.matrix.org/matrix-org/olm)
* No analytics
* Post and see what your friends are saying
* Create groups
* Find your friends
* Chat : supports chats
* Not for profit

## 🚀 Goals

* [ ] E2EE
* [ ] Filter and sort your feed as you want
* [ ] P2P

## 😀🏆 Contributing

### Be a game changer, help us spread the world

* Try and tell us what you think
* Spread the world 🎉

### Want to go further, help us build the future

* Code
* Translate (will come later)

### Before publish a commit

Make sure to run

```bash
./scripts/before_commit.sh
```

## 🛣 Roadmap

### V1.0 : (Work in progress)

- [x] Account creation
- [x] Display account feed
- [x] Send posts
- [x] Send/Display images
- [ ] Adding and removing friends (partial)
- [x] Implement sorting algorithm by date
	- [x] By date
- [x] E2EE: Device verification

### V2.0 : Planned

- [ ] Implement E2E (device verification working)
- [ ] Events and groups (pages) (in progress)
- [ ] Sorting : Custom one (we could use some federate learning tech here)

## 🧐 How it works ?

## Specifications

Find our documentation in our [doc](/doc)

## 🏗 Building

WIP 🙃

```bash
flutter packages pub run build_runner build
```

### Linux

```bash
flutter build linux
```

### Installing OLM

We use the fameldy library for that [https://gitlab.com/famedly/libraries/dart-olm](https://gitlab.com/famedly/libraries/dart-olm)

## For linux platforms

### Requirements

* libsqlite3

From https://pub.dev/packages/flutter_secure_storage :

* libsecret
* libjsoncpp

```bash
sudo apt install libolm3 libsecret-1-dev libjsoncpp-dev libwebkit2gtk-4.1-dev libmpv-dev libssl-dev libsqlite3-0 libsqlite3-dev webkit2gtk-4.1
```

## Special thanks to

[famedlysdk](https://gitlab.com/famedly/famedlysdk/)

[fluffy chat](https://gitlab.com/famedly/fluffychat)

## Desktop screenshot

<div>
<img src="./readmeassets/chat_page_desktop.png" width="600">
</div>
