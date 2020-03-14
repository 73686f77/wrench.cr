<div align = "center"><img src="images/icon.png" width="256" height="256" /></div>

<div align = "center">
  <h1>Papaya.cr - Fruit Utils Repository</h1>
</div>

<p align="center">
  <a href="https://crystal-lang.org">
    <img src="https://img.shields.io/badge/built%20with-crystal-000000.svg" /></a>
  <a href="https://travis-ci.org/64726f70/papaya.cr">
    <img src="https://api.travis-ci.org/64726f70/papaya.cr.svg" /></a>
  <a href="https://github.com/64726f70/papaya.cr/releases">
    <img src="https://img.shields.io/github/release/64726f70/papaya.cr.svg" /></a>
  <a href="https://github.com/64726f70/papaya.cr/blob/master/license">
    <img src="https://img.shields.io/github/license/64726f70/papaya.cr.svg"></a>
</p>

## Description

* This repository contains some useful monkey patches.
  * But I don't recommend it to others, It will add or remove some features at any time.
* [Cherry.cr](https://github.com/636f7374/cherry.cr) needs to be used with this repository.

## Features

* HTTP (Client, Common, Request, WebSocket)
  * Client: When encountering HTTP 100 Continue, it will intelligently handle.
  * WebSocket: It can control whether to enable automatic sending (Pong, Close) packets.
* IO (Evented, IO)
  * Evented: It can control HTTP::Server client write / read timeout.
* OpenSSL (SSL)
  * Server: It can control HTTP::Server client write / read timeout.
* Stream (Stream.chunk, Through)
  * All: Chunk stream Buffer, `IO.pipe`, ...
* URI
  * URI: Quickly detect if scheme is http / https.

## Tips

* I don't recommend it to others, It will add or remove some features at any time.

### Used as Shard

Add this to your application's shard.yml:
```yaml
dependencies:
  papaya:
    github: 64726f70/papaya.cr
```

### Installation

```bash
$ git clone https://github.com/64726f70/papaya.cr.git
```

## Development

```bash
$ make test
```

## References

* ...

## Credit

* [\_Icon::wanicon/fruits](https://www.flaticon.com/packs/fruits-and-vegetables-48)

## Contributors

|Name|Creator|Maintainer|Contributor|
|:---:|:---:|:---:|:---:|
|**[64726f70](https://github.com/64726f70)**|√|√||

## License

* MIT License
