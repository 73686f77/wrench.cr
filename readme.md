<div align = "center"><img src="images/icon.png" width="256" height="256" /></div>

<div align = "center">
  <h1>Wrench.cr - Useful Patch and Utilities</h1>
</div>

<p align="center">
  <a href="https://crystal-lang.org">
    <img src="https://img.shields.io/badge/built%20with-crystal-000000.svg" /></a>
  <a href="https://travis-ci.org/73686f77/wrench.cr">
    <img src="https://api.travis-ci.org/73686f77/wrench.cr.svg" /></a>
  <a href="https://github.com/73686f77/wrench.cr/releases">
    <img src="https://img.shields.io/github/release/73686f77/wrench.cr.svg" /></a>
  <a href="https://github.com/73686f77/wrench.cr/blob/master/license">
    <img src="https://img.shields.io/github/license/73686f77/wrench.cr.svg"></a>
</p>

## Description

* This repository contains some useful monkey patches.
  * But I don't recommend it to others, It will add or remove some features at any time.

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
  wrench:
    github: 73686f77/wrench.cr
```

### Installation

```bash
$ git clone https://github.com/73686f77/wrench.cr.git
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
|**[73686f77](https://github.com/73686f77)**|√|√||

## License

* MIT License
